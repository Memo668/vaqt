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
