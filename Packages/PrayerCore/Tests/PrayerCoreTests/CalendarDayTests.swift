import Foundation
import Testing
@testable import PrayerCore

@Suite("CalendarDay")
struct CalendarDayTests {

    private let berlin = TimeZone(identifier: "Europe/Berlin")!
    private let jakarta = TimeZone(identifier: "Asia/Jakarta")!

    private func instant(_ iso: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso))
    }

    @Test("liest yyyy-MM-dd")
    func parsesText() throws {
        let day = try #require(CalendarDay("2026-11-10"))
        #expect(day.year == 2026)
        #expect(day.month == 11)
        #expect(day.day == 10)
        #expect(day.description == "2026-11-10")
    }

    @Test("lehnt alles andere ab", arguments: [
        "", "2026-11", "2026-13-01", "2026-02-30", "2026-00-10", "2026-11-00", "10.11.2026", "26-11-10", "2026-1-5",
        "2026-11-10T14:25", "abcd-ef-gh",
    ])
    func rejects(_ text: String) {
        #expect(CalendarDay(text) == nil)
    }

    @Test("kennt Schalttage")
    func leapDays() {
        #expect(CalendarDay("2028-02-29") != nil)
        #expect(CalendarDay("2027-02-29") == nil)
    }

    @Test("14:25 in Berlin ist im November 13:25 UTC")
    func dateInWinter() throws {
        let day = try #require(CalendarDay("2026-11-10"))
        let time = try #require(ClockTime("14:25"))
        #expect(try day.date(at: time, in: berlin) == instant("2026-11-10T13:25:00Z"))
    }

    @Test("14:25 in Berlin ist im Juni 12:25 UTC")
    func dateInSummer() throws {
        let day = try #require(CalendarDay("2027-06-21"))
        let time = try #require(ClockTime("14:25"))
        #expect(try day.date(at: time, in: berlin) == instant("2027-06-21T12:25:00Z"))
    }

    @Test("derselbe Tag und dieselbe Uhrzeit sind in Jakarta ein anderer Zeitpunkt")
    func dateDependsOnTimeZone() throws {
        let day = try #require(CalendarDay("2026-11-10"))
        let time = try #require(ClockTime("17:57"))
        #expect(try day.date(at: time, in: jakarta) == instant("2026-11-10T10:57:00Z"))
    }

    @Test("ein Zeitpunkt fällt je nach Zeitzone auf verschiedene Tage")
    func dayOfInstant() throws {
        let lateEvening = try instant("2026-11-10T23:30:00Z")
        #expect(CalendarDay(lateEvening, in: .gmt) == CalendarDay("2026-11-10"))
        #expect(CalendarDay(lateEvening, in: berlin) == CalendarDay("2026-11-11"))
    }

    @Test("Tag → Zeitpunkt → Tag ergibt denselben Tag")
    func roundTrip() throws {
        let day = try #require(CalendarDay("2027-06-21"))
        let time = try #require(ClockTime("23:59"))
        #expect(CalendarDay(day.date(at: time, in: berlin), in: berlin) == day)
    }

    @Test("zählt Tage weiter, über Monats- und Jahresgrenzen", arguments: [
        ("2026-11-10", 1, "2026-11-11"),
        ("2026-11-10", -1, "2026-11-09"),
        ("2026-11-10", 0, "2026-11-10"),
        ("2026-11-30", 1, "2026-12-01"),
        ("2026-12-31", 1, "2027-01-01"),
        ("2027-01-01", -1, "2026-12-31"),
        ("2028-02-28", 1, "2028-02-29"),
        ("2027-02-28", 1, "2027-03-01"),
        ("2026-11-10", 519, "2028-04-12"),
    ])
    func addsDays(start: String, days: Int, expected: String) throws {
        #expect(try #require(CalendarDay(start)).adding(days: days) == CalendarDay(expected))
    }

    @Test("Tage mit Zeitumstellung zählen als ein Tag")
    func addsDaysAcrossClockChanges() throws {
        // 25.10.2026 hat in Berlin 25 Stunden, der 28.03.2027 nur 23.
        #expect(try #require(CalendarDay("2026-10-24")).adding(days: 2) == CalendarDay("2026-10-26"))
        #expect(try #require(CalendarDay("2027-03-27")).adding(days: 2) == CalendarDay("2027-03-29"))
    }

    @Test("zählt die Tage zwischen zwei Tagen, auch rückwärts", arguments: [
        ("2026-11-10", "2026-11-10", 0),
        ("2026-11-11", "2026-11-10", 1),
        ("2026-11-09", "2026-11-10", -1),
        ("2027-01-01", "2026-12-31", 1),
        ("2028-03-01", "2028-02-28", 2),
        ("2026-10-26", "2026-10-24", 2),
        ("2027-03-29", "2027-03-27", 2),
        ("2028-04-12", "2026-11-10", 519),
    ])
    func countsDays(day: String, since other: String, expected: Int) {
        #expect(calendarDay(day).days(since: calendarDay(other)) == expected)
        #expect(calendarDay(other).adding(days: expected) == calendarDay(day))
    }

    @Test("ordnet nach Jahr, Monat, Tag")
    func compares() throws {
        let earlier = try #require(CalendarDay("2026-11-10"))
        let later = try #require(CalendarDay("2027-06-21"))
        #expect(earlier < later)
        #expect(try #require(CalendarDay("2026-11-09")) < earlier)
        #expect(try #require(CalendarDay("2026-10-31")) < earlier)
    }
}
