import Foundation
import Testing
@testable import PrayerCore

@Suite("AppClock")
struct AppClockTests {

    @Test("SystemClock zeigt die Gerätezeit")
    func systemClock() {
        let before = Date()
        let now = SystemClock().now
        let after = Date()
        #expect(before <= now && now <= after)
    }

    @Test("FixedClock bleibt stehen")
    func fixedClock() {
        let instant = Date(timeIntervalSince1970: 1_794_317_100)
        let clock = FixedClock(instant)
        #expect(clock.now == instant)
        #expect(clock.now == instant)
    }

    @Test("DebugClock beginnt beim vorgegebenen Zeitpunkt")
    func debugClockStart() {
        let start = Date(timeIntervalSince1970: 1_794_317_100)
        let clock = DebugClock(startingAt: start)
        // Zwischen Erzeugen und Ablesen vergeht nur die Laufzeit dieser Zeilen.
        #expect(abs(clock.now.timeIntervalSince(start)) < 1)
    }

    @Test("DebugClock merkt sich den Abstand zur Gerätezeit")
    func debugClockOffset() {
        let systemNow = Date(timeIntervalSince1970: 2_000_000_000)
        let start = systemNow.addingTimeInterval(-3_600)
        #expect(DebugClock(startingAt: start, systemNow: systemNow).offset == -3_600)
    }

    @Test("DebugClock läuft in Echtzeit weiter")
    func debugClockRuns() async throws {
        let start = Date(timeIntervalSince1970: 1_794_317_100)
        let clock = DebugClock(startingAt: start)
        let first = clock.now
        try await Task.sleep(for: .milliseconds(60))
        let elapsed = clock.now.timeIntervalSince(first)
        #expect(elapsed >= 0.05)
        #expect(elapsed < 5)
    }
}
