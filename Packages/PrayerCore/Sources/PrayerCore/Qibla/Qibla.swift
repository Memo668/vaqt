import Adhan
import Foundation

// In dieser Datei treffen gleichnamige Typen aufeinander. Ohne Zusatz sind die eigenen gemeint
// (`Qibla`, `Coordinates`), die von Adhan Swift tragen `Adhan.` davor.

/// Richtung und Entfernung zur Kaaba von einem Ort aus.
public struct Qibla: Hashable, Sendable {

    /// Die Kaaba in Mekka – dieselben Koordinaten, mit denen Adhan Swift die Richtung bestimmt.
    public static let kaaba = Coordinates(latitude: 21.4225241, longitude: 39.8261818)

    /// Näher als so viele Kilometer an der Kaaba gilt ein Ort als „in Mekka“: Die Qibla-Seite zeigt dann
    /// eine Meldung statt der Nadel. Unter 1 km, so entschieden am 10.11.2026 (docs/OPEN-QUESTIONS.md).
    public static let meccaRadiusKm = 1.0

    /// Richtung zur Kaaba in Grad ab geografisch Nord im Uhrzeigersinn, von 0 bis unter 360.
    public let bearing: Double

    /// Entfernung zur Kaaba in Kilometern entlang des Großkreises.
    public let distanceKm: Double

    public init(from coordinates: Coordinates) {
        let origin = Adhan.Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        bearing = Adhan.Qibla(coordinates: origin).direction
        distanceKm = coordinates.distanceKm(to: Self.kaaba)
    }

    /// Ob der Ort in Mekka liegt. Die Richtung sagt dort nichts mehr aus.
    public var isInMecca: Bool {
        distanceKm < Self.meccaRadiusKm
    }

    // MARK: - Anzeige

    /// Die Richtung in ganzen Grad, 0 bis 359 – so nennt sie die Qibla-Seite („Qibla 137° SO“).
    public var wholeDegrees: Int {
        Int(bearing.rounded()) % 360
    }

    /// Die Himmelsrichtung, in der die Kaaba liegt, bestimmt aus den ganzen Grad wie `dirName(q)` im
    /// Prototyp.
    public var compassPoint: CompassPoint {
        CompassPoint(degrees: Double(wholeDegrees))
    }

    /// Ab dieser Entfernung in Kilometern rundet die Anzeige auf 10 km.
    public static let coarseDistanceKm = 10.0

    /// Die Entfernung, wie die Qibla-Seite sie zeigt: auf 10 km gerundet, wie die Werte des Prototyps
    /// (4130, 2410, 4600, 7920 km). Unter 10 km auf ganze Kilometer – sonst stünde wenige Kilometer vor
    /// der Kaaba „0 km“ (docs/OPEN-QUESTIONS.md).
    public var displayDistanceKm: Int {
        guard distanceKm >= Self.coarseDistanceKm else { return Int(distanceKm.rounded()) }
        return Int((distanceKm / Self.coarseDistanceKm).rounded()) * Int(Self.coarseDistanceKm)
    }

    /// Wie ein Gerät mit diesem Kurs zur Qibla steht.
    public func alignment(with heading: Heading) -> QiblaAlignment {
        QiblaAlignment(bearing: bearing, heading: heading.degrees)
    }
}
