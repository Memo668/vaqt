import Testing
@testable import PrayerCore

/// Die Endung hinter einer Uhrzeit im Türkischen (`notifReminderBody`, Phase 11).
@Suite("Türkische Endung nach der Uhrzeit")
struct TurkishClockSuffixTests {

    @Test("die Beispiele aus docs/OPEN-QUESTIONS.md und die Mock-Zeiten", arguments: [
        ("15:36", "da"), ("12:53", "te"), ("14:00", "te"),
        ("05:16", "da"), ("07:14", "te"), ("11:52", "de"), ("16:27", "de"), ("18:17", "de"),
    ])
    func examples(time: String, suffix: String) throws {
        let clock = try #require(ClockTime(time))
        #expect(TurkishClockSuffix.locative(for: clock) == suffix)
    }

    @Test("Einer: bir, iki, üç, dört, beş, altı, yedi, sekiz, dokuz")
    func ones() {
        let suffixes = (1...9).map { TurkishClockSuffix.locative(afterNumber: $0) }
        #expect(suffixes == ["de", "de", "te", "te", "te", "da", "de", "de", "da"])
    }

    @Test("volle Zehner: on, yirmi, otuz, kırk, elli; dazu sıfır")
    func tens() {
        let suffixes = [10, 20, 30, 40, 50, 0].map { TurkishClockSuffix.locative(afterNumber: $0) }
        #expect(suffixes == ["da", "de", "da", "ta", "de", "da"])
    }

    @Test("volle Stunden zählen die Stunde, sonst die Minuten", arguments: [
        ("00:00", "da"), ("09:00", "da"), ("10:00", "da"), ("12:00", "de"), ("13:00", "te"),
        ("20:00", "de"), ("23:00", "te"), ("13:40", "ta"), ("19:23", "te"), ("06:05", "te"),
        ("21:10", "da"), ("17:59", "da"),
    ])
    func fullHours(time: String, suffix: String) throws {
        let clock = try #require(ClockTime(time))
        #expect(TurkishClockSuffix.locative(for: clock) == suffix)
    }

    @Test("jede Uhrzeit des Tages hat eine der vier Endungen")
    func everyMinute() {
        let all = Set((0..<(24 * 60)).map { TurkishClockSuffix.locative(for: ClockTime(minutesSinceMidnight: $0)) })
        #expect(all == ["da", "de", "ta", "te"])
    }
}
