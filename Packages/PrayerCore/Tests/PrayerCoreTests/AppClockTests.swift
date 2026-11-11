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

    @Test("die Gerätezeit zu einem Zeitpunkt der App-Uhr: bei der Debug-Uhr um den Abstand verschoben")
    func deviceDate() {
        let systemNow = Date(timeIntervalSince1970: 2_000_000_000)
        let start = systemNow.addingTimeInterval(-3_600)
        let clock = DebugClock(startingAt: start, systemNow: systemNow)
        // Zeigt die App-Uhr „start“, zeigt das Gerät „systemNow“.
        #expect(clock.deviceDate(for: start) == systemNow)
        #expect(clock.deviceDate(for: start.addingTimeInterval(90)) == systemNow.addingTimeInterval(90))
    }

    @Test("Uhr des Geräts und stehende Uhr rechnen nichts um")
    func deviceDateWithoutOffset() {
        let instant = Date(timeIntervalSince1970: 1_794_317_100)
        #expect(SystemClock().deviceDate(for: instant) == instant)
        #expect(FixedClock(instant).deviceDate(for: instant) == instant)
    }

    @Test("der Sekundentakt beginnt mit der nächsten vollen Sekunde der App-Uhr")
    func nextWholeSecond() {
        // 14:25:00,25 App-Zeit: Die nächste volle Sekunde liegt 0,75 s später.
        let instant = Date(timeIntervalSinceReferenceDate: 800_000_000.25)
        #expect(FixedClock(instant).nextWholeSecondOnDevice == Date(timeIntervalSinceReferenceDate: 800_000_001))
        // Steht die Uhr genau auf einer vollen Sekunde, beginnt der Takt sofort.
        let whole = Date(timeIntervalSinceReferenceDate: 800_000_000)
        #expect(FixedClock(whole).nextWholeSecondOnDevice == whole)

        let clock = DebugClock(startingAt: instant)
        let next = clock.nextWholeSecondOnDevice
        // In Gerätezeit liegt der Beginn höchstens eine Sekunde voraus …
        let lead = next.timeIntervalSince(Date())
        #expect(lead > -0.5 && lead <= 1)
        // … und fällt in App-Zeit auf eine volle Sekunde.
        let appSeconds = next.addingTimeInterval(clock.offset).timeIntervalSinceReferenceDate
        #expect(abs(appSeconds - appSeconds.rounded()) < 0.001)
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
