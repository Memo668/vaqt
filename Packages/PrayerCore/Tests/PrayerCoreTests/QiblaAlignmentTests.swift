import Testing
@testable import PrayerCore

/// Die Statuszeile der Qibla-Seite: ausgerichtet, oder wohin und wie weit zu drehen ist.
@Suite("QiblaAlignment")
struct QiblaAlignmentTests {

    /// Berlin: 136,68° – im Prototyp und in den Referenzbildern als 137° gezeigt.
    private let berlin = Qibla(from: Coordinates(latitude: 52.5200, longitude: 13.4050))

    @Test("iphone/30: Kurs 98°, „Nach rechts drehen 39°“")
    func turnRight() {
        let alignment = berlin.alignment(with: Heading(degrees: 98))
        #expect(abs(alignment.difference - 38.68) < 0.01)
        #expect(!alignment.isAligned)
        #expect(alignment.turn == .right)
        #expect(alignment.degrees == 39)
    }

    @Test("der Startwert des Prototyps: Kurs 99°, 38° nach rechts")
    func prototypeStart() {
        let alignment = berlin.alignment(with: Heading(degrees: 99))
        #expect(alignment.turn == .right)
        #expect(alignment.degrees == 38)
    }

    @Test("iphone/31: Kurs 137°, ausgerichtet")
    func aligned() {
        let alignment = berlin.alignment(with: Heading(degrees: 137))
        #expect(alignment.isAligned)
        #expect(alignment.turn == nil)
        #expect(alignment.degrees == 0)
    }

    @Test("liegt die Qibla links vom Kurs, geht es nach links")
    func turnLeft() {
        let alignment = QiblaAlignment(bearing: 137, heading: 180)
        #expect(alignment.difference == -43)
        #expect(alignment.turn == .left)
        #expect(alignment.degrees == 43)
    }

    @Test("ausgerichtet gilt bis einschließlich 3° nach beiden Seiten", arguments: [
        (134.0, true), (140.0, true), (137.0, true), (135.5, true),
        (133.99, false), (140.01, false), (133.0, false), (141.0, false),
    ])
    func tolerance(heading: Double, expected: Bool) {
        #expect(QiblaAlignment.tolerance == 3)
        #expect(QiblaAlignment(bearing: 137, heading: heading).isAligned == expected)
    }

    @Test("knapp außerhalb der Toleranz steht wie im Prototyp noch 3° da")
    func justOutside() {
        let right = QiblaAlignment(bearing: 137, heading: 133.6)
        #expect(right.turn == .right)
        #expect(right.degrees == 3)
        let left = QiblaAlignment(bearing: 137, heading: 140.4)
        #expect(left.turn == .left)
        #expect(left.degrees == 3)
        // Ab der Hälfte wird aufgerundet.
        #expect(QiblaAlignment(bearing: 137, heading: 133.5).degrees == 4)
    }

    @Test("über Nord hinweg zählt der kürzere Weg")
    func acrossNorth() {
        let right = QiblaAlignment(bearing: 10, heading: 350)
        #expect(right.turn == .right)
        #expect(right.degrees == 20)
        let left = QiblaAlignment(bearing: 350, heading: 10)
        #expect(left.turn == .left)
        #expect(left.degrees == 20)
        #expect(QiblaAlignment(bearing: 1, heading: 359).isAligned)
    }

    @Test("genau entgegengesetzt: 180° nach links, wie im Prototyp")
    func opposite() {
        let alignment = QiblaAlignment(bearing: 0, heading: 180)
        #expect(alignment.difference == -180)
        #expect(alignment.turn == .left)
        #expect(alignment.degrees == 180)
    }

    @Test("die Abweichung liegt immer zwischen −180 und unter 180", arguments: [
        (0.0, 0.0), (359.0, 1.0), (1.0, 359.0), (90.0, 271.0), (271.0, 90.0), (295.0, 99.0),
    ])
    func range(bearing: Double, heading: Double) {
        let difference = QiblaAlignment(bearing: bearing, heading: heading).difference
        #expect((-180..<180).contains(difference))
    }
}
