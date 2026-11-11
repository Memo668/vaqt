import Foundation
import Testing
@testable import PrayerCore

@Suite("LocationSource")
struct LocationSourceTests {

    private let berlin = Place(
        name: "Berlin", countryCode: "DE",
        coordinates: Coordinates(latitude: 52.52, longitude: 13.405), timeZoneIdentifier: "Europe/Berlin"
    )

    @Test("mit Freigabe liefert die feste Quelle ihren Ort")
    func authorized() async {
        let source = FixedLocationSource(place: berlin, status: .authorized)
        #expect(await source.authorization() == .authorized)
        #expect(await source.requestAuthorization() == .authorized)
        #expect(await source.currentPlace() == berlin)
    }

    @Test("ohne Freigabe gibt es keinen aktuellen Ort", arguments: [LocationAuthorization.denied, .notDetermined])
    func withoutPermission(_ status: LocationAuthorization) async {
        let source = FixedLocationSource(place: berlin, status: status)
        #expect(await source.authorization() == status)
        #expect(await source.requestAuthorization() == status)
        #expect(await source.currentPlace() == nil)
    }

    @Test("Place kennt seine Zeitzone")
    func timeZone() {
        #expect(berlin.timeZone.identifier == "Europe/Berlin")
    }

    @Test("eine unbekannte Zeitzone fällt auf GMT zurück")
    func unknownTimeZone() {
        var place = berlin
        place.timeZoneIdentifier = "Nirgendwo/Nichts"
        #expect(place.timeZone == .gmt)
    }

    @Test("Place übersteht Kodieren und Dekodieren")
    func codable() throws {
        let data = try JSONEncoder().encode(berlin)
        #expect(try JSONDecoder().decode(Place.self, from: data) == berlin)
    }
}

/// Entfernung zweier Orte und der Ort ohne Namen (ohne Netz).
@Suite("Ort ohne Namen")
struct UnnamedPlaceTests {

    private let berlin = Place(
        name: "Berlin", countryCode: "DE",
        coordinates: Coordinates(latitude: 52.52, longitude: 13.405), timeZoneIdentifier: "Europe/Berlin"
    )

    private func unnamed(latitude: Double, longitude: Double, zone: String = "Europe/Paris") -> Place {
        Place(
            name: "", countryCode: nil,
            coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
        )
    }

    @Test("Entfernung entlang des Großkreises: Berlin – Potsdam rund 27 km, Berlin – München rund 504 km")
    func distance() {
        let potsdam = Coordinates(latitude: 52.3906, longitude: 13.0645)
        let munich = Coordinates(latitude: 48.1351, longitude: 11.5820)
        #expect(abs(berlin.coordinates.distanceKm(to: potsdam) - 27.2) < 1)
        #expect(abs(berlin.coordinates.distanceKm(to: munich) - 504) < 2)
        #expect(berlin.coordinates.distanceKm(to: berlin.coordinates) == 0)
        // In beide Richtungen gleich.
        #expect(abs(potsdam.distanceKm(to: berlin.coordinates) - berlin.coordinates.distanceKm(to: potsdam)) < 0.000_001)
    }

    @Test("ein Ort ohne Namen übernimmt Name, Land und Zeitzone des zuletzt bestimmten, wenn er in der Nähe liegt")
    func adoptsNearby() {
        // Berlin-Spandau, gut 13 km vom Stadtzentrum.
        let here = unnamed(latitude: 52.5352, longitude: 13.2004)
        let named = here.named(after: berlin)
        #expect(named.name == "Berlin")
        #expect(named.countryCode == "DE")
        #expect(named.timeZoneIdentifier == "Europe/Berlin")
        // Gerechnet wird mit dem neuen Standort.
        #expect(named.coordinates == here.coordinates)
        #expect(named.hasName)
    }

    @Test("weiter weg bleibt der Ort ohne Namen")
    func keepsFarAway() {
        let munich = unnamed(latitude: 48.1351, longitude: 11.5820)
        #expect(munich.named(after: berlin) == munich)
        #expect(!munich.named(after: berlin).hasName)
    }

    @Test("ein Ort mit Namen bleibt, wie er ist; ohne bekannten Ort ebenso")
    func keepsNamed() {
        let potsdam = Place(
            name: "Potsdam", countryCode: "DE",
            coordinates: Coordinates(latitude: 52.3906, longitude: 13.0645), timeZoneIdentifier: "Europe/Berlin"
        )
        #expect(potsdam.named(after: berlin) == potsdam)
        let here = unnamed(latitude: 52.5352, longitude: 13.2004)
        #expect(here.named(after: nil) == here)
        // Ein bekannter Ort ohne Namen hilft nicht weiter.
        #expect(here.named(after: unnamed(latitude: 52.52, longitude: 13.405)) == here)
    }
}
