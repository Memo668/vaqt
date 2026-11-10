import Foundation
import Testing
@testable import PrayerCore

@Suite("Qibla")
struct QiblaTests {

    private func qibla(_ latitude: Double, _ longitude: Double) -> Qibla {
        Qibla(from: Coordinates(latitude: latitude, longitude: longitude))
    }

    @Test("Berlin: etwa 137° und 4130 km")
    func berlin() {
        let qibla = Qibla(from: Place.berlin.coordinates)
        #expect(abs(qibla.bearing - 136.68) < 0.01)
        #expect(abs(qibla.distanceKm - 4130.2) < 0.1)
        #expect(qibla.bearing.rounded() == 137)
        #expect(qibla.distanceKm.rounded() == 4130)
        #expect(!qibla.isInMecca)
    }

    @Test("die Richtung trifft die Referenzwerte aus den Tests von Adhan Swift", arguments: [
        ("Washington, D.C.", 38.9072, -77.0369, 56.560),
        ("New York", 40.7128, -74.0059, 58.481),
        ("San Francisco", 37.7749, -122.4194, 18.843),
        ("Anchorage", 61.2181, -149.9003, 350.883),
        ("Sydney", -33.8688, 151.2093, 277.499),
        ("Auckland", -36.8485, 174.7633, 261.197),
        ("London", 51.5074, -0.1278, 118.987),
        ("Paris", 48.8566, 2.3522, 119.163),
        ("Oslo", 59.9139, 10.7522, 139.027),
        ("Islamabad", 33.7294, 73.0931, 255.882),
        ("Tokio", 35.6895, 139.6917, 293.021),
    ])
    func referenceBearings(city: String, latitude: Double, longitude: Double, expected: Double) {
        let bearing = qibla(latitude, longitude).bearing
        #expect(abs(bearing - expected) < 0.001, "\(city): \(bearing)")
        #expect((0..<360).contains(bearing))
    }

    #if DEBUG
    @Test("Richtung und Entfernung passen zu den Städten des Prototyps", arguments: ["berlin", "istanbul", "madrid", "jakarta"])
    func fixtureCities(id: String) throws {
        let city = try #require(FixtureTimes.city(id))
        let qibla = Qibla(from: city.coordinates)
        #expect(Int(qibla.bearing.rounded()) == city.qiblaDegrees)
        // Die Entfernungen im Prototyp sind auf 10 km gerundet.
        #expect(Int((qibla.distanceKm / 10).rounded()) * 10 == city.distanceKm)
        #expect(!qibla.isInMecca)
    }

    @Test("die Fixture-Stadt Mekka liegt in Mekka")
    func fixtureMecca() throws {
        let city = try #require(FixtureTimes.city("mecca"))
        let qibla = Qibla(from: city.coordinates)
        #expect(qibla.isInMecca)
        #expect(qibla.distanceKm < 0.1)
        #expect(Int(qibla.distanceKm.rounded()) == city.distanceKm)
    }
    #endif

    @Test("an der Kaaba ist die Entfernung null")
    func atTheKaaba() {
        let qibla = Qibla(from: Qibla.kaaba)
        #expect(qibla.distanceKm == 0)
        #expect(qibla.isInMecca)
        #expect(Qibla.kaaba == Coordinates(latitude: 21.4225241, longitude: 39.8261818))
    }

    @Test("„in Mekka“ gilt unter 5 km")
    func meccaRadius() {
        #expect(Qibla.meccaRadiusKm == 5)
        // Ein Breitengrad sind 111,195 km: 0,044° nördlich der Kaaba sind 4,89 km, 0,046° sind 5,11 km.
        let inside = qibla(Qibla.kaaba.latitude + 0.044, Qibla.kaaba.longitude)
        let outside = qibla(Qibla.kaaba.latitude + 0.046, Qibla.kaaba.longitude)
        #expect(abs(inside.distanceKm - 4.893) < 0.001)
        #expect(inside.isInMecca)
        #expect(abs(outside.distanceKm - 5.115) < 0.001)
        #expect(!outside.isInMecca)
        // Von Norden aus liegt die Kaaba genau im Süden.
        #expect(abs(outside.bearing - 180) < 0.001)
    }

    @Test("Dschidda liegt nicht in Mekka")
    func jeddah() {
        let qibla = qibla(21.4858, 39.1925)
        #expect(!qibla.isInMecca)
        #expect((60...70).contains(qibla.distanceKm))
        #expect((90...100).contains(qibla.bearing))
    }

    @Test("die Entfernung folgt dem Großkreis")
    func greatCircle() {
        // Vom Nordpol sind es 68,5774759 Breitengrade bis zur Kaaba.
        #expect(abs(qibla(90, 0).distanceKm - 7625.478) < 0.01)
        // Der Gegenpunkt der Kaaba ist einen halben Erdumfang entfernt: π · 6371,0088 km.
        let antipode = qibla(-Qibla.kaaba.latitude, Qibla.kaaba.longitude - 180)
        #expect(abs(antipode.distanceKm - 20015.114) < 0.01)
        // Auf dem Äquator, 90° westlich des Längengrads der Kaaba: ein Viertel des Erdumfangs.
        #expect(abs(qibla(0, Qibla.kaaba.longitude - 90).distanceKm - 10007.557) < 0.01)
    }

    @Test("gleiche Orte ergeben gleiche Werte")
    func equality() {
        #expect(qibla(52.52, 13.405) == qibla(52.52, 13.405))
        #expect(qibla(52.52, 13.405) != qibla(41.0082, 28.9784))
    }
}
