import CoreLocation
import DesignSystem
import Foundation
import MapKit
import PrayerCore

/// Bestimmt zu Koordinaten den Ort: Name der Stadt, Land und Zeitzone.
public protocol PlaceResolving: Sendable {

    /// Der Ort an `coordinates`; `nil`, wenn er sich nicht bestimmen lässt – etwa ohne Netz.
    func place(at coordinates: Coordinates) async -> Place?
}

/// Geocoding über MapKit (`MKReverseGeocodingRequest`). `CLGeocoder` gilt seit iOS 26 als veraltet.
/// Die Anfrage geht an Apple und enthält nur die Koordinaten.
public struct MapKitPlaceResolver: PlaceResolving {

    public init() {}

    @MainActor
    public func place(at coordinates: Coordinates) async -> Place? {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        // Der Name der Stadt in der Sprache der App, z. B. „Mekka“ statt „Makkah“.
        request.preferredLocale = L10n.locale
        guard let item = try? await request.mapItems.first, let place = Place(mapItem: item) else { return nil }
        // Gerechnet wird für den Standort des Geräts, nicht für die Mitte der gefundenen Stadt.
        return Place(
            name: place.name, countryCode: place.countryCode,
            coordinates: coordinates, timeZoneIdentifier: place.timeZoneIdentifier
        )
    }
}

/// Der aktuelle Ort über Core Location, mit der Freigabe „Beim Verwenden der App“.
///
/// Der Standort bleibt auf dem Gerät. Für den Namen der Stadt gehen die Koordinaten einmal an den
/// Geocoder von Apple; ohne Netz liefert die Quelle den Ort ohne Namen, mit der Zeitzone des Geräts.
/// Für Gebetszeiten genügt die Stadt: Gefragt wird mit einer Genauigkeit von drei Kilometern.
@MainActor
public final class CoreLocationSource: NSObject, LocationSource {
    private let resolver: any PlaceResolving
    private var manager: CLLocationManager?
    private var authorizationWaiters: [CheckedContinuation<LocationAuthorization, Never>] = []
    private var locationWaiters: [CheckedContinuation<CLLocation?, Never>] = []

    public nonisolated init(resolver: any PlaceResolving = MapKitPlaceResolver()) {
        self.resolver = resolver
        super.init()
    }

    public func authorization() async -> LocationAuthorization {
        Self.authorization(for: locationManager.authorizationStatus)
    }

    public func requestAuthorization() async -> LocationAuthorization {
        let manager = locationManager
        guard manager.authorizationStatus == .notDetermined else {
            return Self.authorization(for: manager.authorizationStatus)
        }
        return await withCheckedContinuation { continuation in
            authorizationWaiters.append(continuation)
            // Der Dialog des Systems; die Antwort kommt über `locationManagerDidChangeAuthorization`.
            manager.requestWhenInUseAuthorization()
        }
    }

    public func currentPlace() async -> Place? {
        guard await authorization() == .authorized, let location = await requestLocation() else { return nil }
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude, longitude: location.coordinate.longitude
        )
        if let place = await resolver.place(at: coordinates) {
            return place
        }
        // Ohne Netz: der Ort ohne Namen, in der Zeitzone des Geräts – es steht ja dort.
        return Place(
            name: "", countryCode: nil, coordinates: coordinates, timeZoneIdentifier: TimeZone.current.identifier
        )
    }

    /// Das auf das Nötige reduzierte Ergebnis einer Freigabe.
    nonisolated static func authorization(for status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: .authorized
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    /// Der Manager entsteht beim ersten Gebrauch auf dem Hauptthread; dorthin kommen seine Antworten.
    private var locationManager: CLLocationManager {
        if let manager { return manager }
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.delegate = self
        self.manager = manager
        return manager
    }

    private func requestLocation() async -> CLLocation? {
        let manager = locationManager
        return await withCheckedContinuation { continuation in
            locationWaiters.append(continuation)
            // Läuft schon eine Anfrage, warten alle auf dieselbe Antwort.
            if locationWaiters.count == 1 {
                manager.requestLocation()
            }
        }
    }

    private func finishLocation(_ location: CLLocation?) {
        let waiters = locationWaiters
        locationWaiters = []
        waiters.forEach { $0.resume(returning: location) }
    }
}

// Core Location ruft auf dem Hauptthread zurück, auf dem der Manager angelegt wurde.
extension CoreLocationSource: @preconcurrency CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Der Manager meldet sich auch gleich nach dem Anlegen, noch vor der Antwort auf den Dialog.
        guard manager.authorizationStatus != .notDetermined else { return }
        let status = Self.authorization(for: manager.authorizationStatus)
        let waiters = authorizationWaiters
        authorizationWaiters = []
        waiters.forEach { $0.resume(returning: status) }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finishLocation(locations.last)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        finishLocation(nil)
    }
}
