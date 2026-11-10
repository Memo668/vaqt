import Testing
@testable import PrayerCore

/// Der Stand der Mitteilung muss sich verhalten wie `BELL_ORDER` und `S.notif` im Prototyp.
@Suite("Glocke")
struct BellStateTests {

    @Test("die Kennungen sind die des Prototyps, in der Reihenfolge von BELL_ORDER")
    func rawValues() {
        #expect(BellState.allCases.map(\.rawValue) == ["sound", "silent", "off"])
    }

    @Test("Tippen wechselt Ton → Lautlos → Aus → Ton", arguments: [
        (BellState.sound, BellState.silent),
        (.silent, .off),
        (.off, .sound),
    ])
    func next(state: BellState, expected: BellState) {
        #expect(state.next == expected)
    }

    @Test("nach drei Mal Tippen steht die Glocke wieder am Anfang", arguments: BellState.allCases)
    func cycle(state: BellState) {
        #expect(state.next.next.next == state)
    }

    @Test("die Voreinstellung ist die des Prototyps: Gebete mit Ton, Ischa lautlos, Sonnenaufgang aus")
    func standard() {
        #expect(Prayer.allCases.map { BellState.standard(for: $0) } == [.sound, .off, .sound, .sound, .sound, .silent])
    }
}
