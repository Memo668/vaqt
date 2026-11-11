import Foundation
import Testing
@testable import PrayerCore

@Suite("Heading")
struct HeadingTests {

    @Test("Winkel landen zwischen 0 und unter 360", arguments: [
        (0.0, 0.0), (359.9, 359.9), (360.0, 0.0), (361.0, 1.0), (725.0, 5.0),
        (-1.0, 359.0), (-360.0, 0.0), (-365.0, 355.0), (-0.0, 0.0),
    ])
    func normalized(degrees: Double, expected: Double) {
        #expect(abs(Heading.normalized(degrees) - expected) < 0.000_001)
        #expect((0..<360).contains(Heading.normalized(degrees)))
    }

    @Test("ein winziger negativer Winkel wird 0, nicht 360")
    func tinyNegative() {
        #expect(Heading.normalized(-1e-14) == 0)
    }

    @Test("was keine Zahl ist, wird 0", arguments: [Double.nan, .infinity, -.infinity])
    func notFinite(degrees: Double) {
        #expect(Heading.normalized(degrees) == 0)
        #expect(Heading(degrees: degrees).degrees == 0)
    }

    @Test("der Kurs wird beim Anlegen auf 0 bis unter 360 gebracht")
    func initNormalizes() {
        #expect(Heading(degrees: 497).degrees == 137)
        #expect(Heading(degrees: -90).degrees == 270)
        #expect(Heading(degrees: 137).degrees == 137)
    }

    @Test("ohne Angabe ist der Kurs genau und bezieht sich auf geografisch Nord")
    func defaults() {
        let heading = Heading(degrees: 137)
        #expect(heading.accuracy == 0)
        #expect(heading.reference == .trueNorth)
        #expect(heading.isValid)
        #expect(!heading.needsCalibration)
    }

    @Test("ganze Grad wie Math.round(h) % 360", arguments: [
        (98.3, 98), (98.5, 99), (98.49, 98), (0.4, 0), (359.4, 359), (359.5, 0), (359.99, 0), (137.0, 137),
    ])
    func wholeDegrees(degrees: Double, expected: Int) {
        #expect(Heading(degrees: degrees).wholeDegrees == expected)
    }

    @Test("die Himmelsrichtung folgt den ganzen Grad", arguments: [
        (98.0, CompassPoint.east), (137.0, .southEast), (138.0, .southEast), (0.0, .north),
        (359.6, .north), (22.4, .north), (22.5, .northEast), (247.0, .southWest),
    ])
    func compassPoint(degrees: Double, expected: CompassPoint) {
        #expect(Heading(degrees: degrees).compassPoint == expected)
    }

    @Test("der kürzeste Weg zwischen zwei Winkeln, im Uhrzeigersinn positiv", arguments: [
        (98.0, 137.0, 39.0), (137.0, 98.0, -39.0), (350.0, 10.0, 20.0), (10.0, 350.0, -20.0),
        (0.0, 179.5, 179.5), (0.0, 180.0, -180.0), (180.0, 0.0, -180.0), (45.0, 45.0, 0.0),
        (0.0, 181.0, -179.0),
    ])
    func turn(start: Double, end: Double, expected: Double) {
        #expect(abs(Heading.turn(from: start, to: end) - expected) < 0.000_001)
        #expect((-180..<180).contains(Heading.turn(from: start, to: end)))
    }

    @Test("ein negativer Wert der Genauigkeit heißt: Der Kurs ist ungültig")
    func invalid() {
        let heading = Heading(degrees: 137, accuracy: -1)
        #expect(!heading.isValid)
        #expect(heading.needsCalibration)
    }

    @Test("die Kalibrierungskarte erscheint erst über 25° Abweichung", arguments: [
        (0.0, false), (5.0, false), (25.0, false), (25.1, true), (40.0, true),
    ])
    func needsCalibration(accuracy: Double, expected: Bool) {
        #expect(Heading.poorAccuracy == 25)
        let heading = Heading(degrees: 98, accuracy: accuracy)
        #expect(heading.isValid)
        #expect(heading.needsCalibration == expected)
    }

    @Test("gleiche Kurse sind gleich; Genauigkeit und Bezug zählen mit")
    func equality() {
        #expect(Heading(degrees: 137) == Heading(degrees: 497))
        #expect(Heading(degrees: 137) != Heading(degrees: 137, accuracy: 30))
        #expect(Heading(degrees: 137) != Heading(degrees: 137, reference: .magneticNorth))
    }
}

@Suite("HeadingSource")
struct HeadingSourceTests {

    private func collect(_ source: any HeadingSource) async -> [Heading] {
        var headings: [Heading] = []
        for await heading in await source.updates() {
            headings.append(heading)
        }
        return headings
    }

    @Test("die feste Quelle liefert ihren Kurs einmal und endet")
    func fixed() async {
        let heading = Heading(degrees: 137, accuracy: 30)
        let source = FixedHeadingSource(heading: heading)
        #expect(await source.isAvailable())
        #expect(await collect(source) == [heading])
        // Jeder Zuhörer bekommt den Kurs.
        #expect(await collect(source) == [heading])
    }

    @Test("ohne Kurs verhält sich die Quelle wie ein Gerät ohne Kompass")
    func unavailable() async {
        let source = FixedHeadingSource(heading: nil)
        #expect(await !source.isAvailable())
        #expect(await collect(source).isEmpty)
    }
}
