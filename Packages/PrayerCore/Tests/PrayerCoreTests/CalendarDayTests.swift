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

    @Test("ordnet nach Jahr, Monat, Tag")
    func compares() throws {
        let earlier = try #require(CalendarDay("2026-11-10"))
        let later = try #require(CalendarDay("2027-06-21"))
        #expect(earlier < later)
        #expect(try #require(CalendarDay("2026-11-09")) < earlier)
        #expect(try #require(CalendarDay("2026-10-31")) < earlier)
    }
}
