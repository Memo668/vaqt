import Testing
@testable import PrayerCore

@Suite("CompassPoint")
struct CompassPointTests {

    @Test("acht Richtungen im Uhrzeigersinn ab Nord, wie dirs im Prototyp")
    func order() {
        #expect(CompassPoint.allCases == [
            .north, .northEast, .east, .southEast, .south, .southWest, .west, .northWest,
        ])
        #expect(CompassPoint.allCases.map(\.rawValue) == Array(0..<8))
        #expect(CompassPoint.sector == 45)
    }

    @Test("jede Richtung deckt 22,5° nach beiden Seiten ab – dirName()", arguments: [
        (0.0, CompassPoint.north), (22.4, .north), (22.5, .northEast), (45.0, .northEast),
        (67.4, .northEast), (67.5, .east), (90.0, .east), (112.5, .southEast), (135.0, .southEast),
        (157.4, .southEast), (157.5, .south), (180.0, .south), (225.0, .southWest), (270.0, .west),
        (315.0, .northWest), (337.4, .northWest), (337.5, .north), (359.9, .north),
    ])
    func sectors(degrees: Double, expected: CompassPoint) {
        #expect(CompassPoint(degrees: degrees) == expected)
    }

    @Test("Winkel außerhalb von 0 bis 360 zählen mit", arguments: [
        (360.0, CompassPoint.north), (405.0, .northEast), (-45.0, .northWest), (-90.0, .west), (720.0, .north),
    ])
    func wraps(degrees: Double, expected: CompassPoint) {
        #expect(CompassPoint(degrees: degrees) == expected)
    }

    @Test("die Städte des Prototyps: 137° SO, 152° SO, 104° O, 295° NW", arguments: [
        (137.0, CompassPoint.southEast), (152.0, .southEast), (104.0, .east), (295.0, .northWest),
    ])
    func prototypeCities(degrees: Double, expected: CompassPoint) {
        #expect(CompassPoint(degrees: degrees) == expected)
    }

    @Test("die Mitte jeder Richtung in Grad")
    func degrees() {
        #expect(CompassPoint.allCases.map(\.degrees) == [0, 45, 90, 135, 180, 225, 270, 315])
        for point in CompassPoint.allCases {
            #expect(CompassPoint(degrees: point.degrees) == point)
        }
    }

    @Test("Nord, Ost, Süd und West sind die Haupthimmelsrichtungen")
    func cardinals() {
        #expect(CompassPoint.allCases.filter(\.isCardinal) == [.north, .east, .south, .west])
    }
}
