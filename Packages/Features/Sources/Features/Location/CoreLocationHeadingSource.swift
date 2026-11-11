import CoreLocation
import Foundation
import PrayerCore

/// Der Kompasskurs über Core Location (Design Spec § 4: „heading from `CLLocationManager` (true north)“).
///
/// Geografisch Nord kennt Core Location nur zusammen mit dem Standort des Geräts: `trueHeading` gilt
/// laut Apple nur, solange derselbe Manager auch den Standort bestimmt. Mit Standortfreigabe läuft
/// deshalb neben dem Kompass die Ortung mit, grob und nur, solange jemand zuhört – also solange die
/// Qibla-Seite zu sehen ist. Ohne Freigabe liefert iOS nur magnetisch Nord; der Kurs trägt das als
/// `reference` und weicht dann um die örtliche Missweisung ab (docs/OPEN-QUESTIONS.md). Nach der
/// Freigabe fragt die Quelle nie selbst.
@MainActor
public final class CoreLocationHeadingSource: NSObject, HeadingSource {
    private var manager: CLLocationManager?
    /// Wer gerade zuhört. Mit dem letzten Zuhörer hören Kompass und Ortung auf.
    private var listeners: [UUID: AsyncStream<Heading>.Continuation] = [:]

    public nonisolated override init() {
        super.init()
    }

    public func isAvailable() async -> Bool {
        CLLocationManager.headingAvailable()
    }

    public func updates() async -> AsyncStream<Heading> {
        guard CLLocationManager.headingAvailable() else {
            return AsyncStream { $0.finish() }
        }
        // Es zählt nur der neueste Kurs; was die Seite nicht rechtzeitig abholt, verfällt.
        let (stream, continuation) = AsyncStream.makeStream(of: Heading.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        listeners[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in
                self?.remove(id)
            }
        }
        start()
        return stream
    }

    /// Der Kurs zu einer Meldung von Core Location.
    ///
    /// Ein negativer Wert von `trueHeading` heißt, dass sich geografisch Nord nicht bestimmen ließ –
    /// dem Gerät fehlt der Standort. Dann gilt magnetisch Nord.
    nonisolated static func heading(trueHeading: Double, magneticHeading: Double, accuracy: Double) -> Heading {
        if trueHeading >= 0 {
            return Heading(degrees: trueHeading, accuracy: accuracy, reference: .trueNorth)
        }
        return Heading(degrees: magneticHeading, accuracy: accuracy, reference: .magneticNorth)
    }

    /// Der Manager entsteht beim ersten Gebrauch auf dem Hauptthread; dorthin kommen seine Meldungen.
    private var locationManager: CLLocationManager {
        if let manager { return manager }
        let manager = CLLocationManager()
        // Ein Grad Auflösung, wie die Kursanzeige; der Kurs gilt für das aufrecht gehaltene Gerät.
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
        // Für die Missweisung genügt der grobe Standort.
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 3000
        manager.delegate = self
        self.manager = manager
        return manager
    }

    private func start() {
        let manager = locationManager
        if Self.hasLocationAccess(manager) {
            manager.startUpdatingLocation()
        }
        manager.startUpdatingHeading()
    }

    private func remove(_ id: UUID) {
        listeners[id] = nil
        guard listeners.isEmpty, let manager else { return }
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    private static func hasLocationAccess(_ manager: CLLocationManager) -> Bool {
        CoreLocationSource.authorization(for: manager.authorizationStatus) == .authorized
    }
}

// Core Location ruft auf dem Hauptthread zurück, auf dem der Manager angelegt wurde.
extension CoreLocationHeadingSource: @preconcurrency CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let heading = Self.heading(
            trueHeading: newHeading.trueHeading, magneticHeading: newHeading.magneticHeading,
            accuracy: newHeading.headingAccuracy
        )
        for listener in listeners.values {
            listener.yield(heading)
        }
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Kommt die Freigabe erst, während der Kompass läuft, gibt es ab jetzt geografisch Nord.
        if !listeners.isEmpty, Self.hasLocationAccess(manager) {
            manager.startUpdatingLocation()
        }
    }

    /// Die Karte „Kompass kalibrieren“ zeigt die App selbst; die Anzeige des Systems bleibt aus.
    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        false
    }

    // Der Standort selbst interessiert hier nicht – er dient Core Location nur für die Missweisung.
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {}
}
