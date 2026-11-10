import Foundation
import Testing
@testable import PrayerCore

@Suite("ClockTime")
struct ClockTimeTests {

    @Test("liest HH:mm")
    func parsesText() throws {
        let time = try #require(ClockTime("05:16"))
        #expect(time.hour == 5)
        #expect(time.minute == 16)
        #expect(time.minutesSinceMidnight == 316)
    }

    @Test("liest die Ränder des Tages")
    func parsesBounds() {
        #expect(ClockTime("00:00")?.minutesSinceMidnight == 0)
        #expect(ClockTime("23:59")?.minutesSinceMidnight == 1439)
    }

    @Test("lehnt alles andere ab", arguments: [
        "", "14", "14:", ":25", "24:00", "12:60", "-1:30", "+5:10", "1425", "14:25:00", "ab:cd", "14.25", " 14:25", "٥:١٠",
    ])
    func rejects(_ text: String) {
        #expect(ClockTime(text) == nil)
    }

    @Test("lehnt Werte außerhalb des Tages ab")
    func rejectsOutOfRange() {
        #expect(ClockTime(hour: 24, minute: 0) == nil)
        #expect(ClockTime(hour: 0, minute: 60) == nil)
        #expect(ClockTime(hour: -1, minute: 0) == nil)
    }

    @Test("schreibt zweistellig")
    func describes() {
        #expect(ClockTime("5:7")?.description == "05:07")
        #expect(ClockTime("14:25")?.description == "14:25")
    }

    @Test("Mitternacht ist 00:00")
    func midnight() {
        #expect(ClockTime.midnight == ClockTime("00:00"))
        #expect(ClockTime.midnight.minutesSinceMidnight == 0)
    }

    @Test("liest die Uhrzeit eines Zeitpunkts in einer Zeitzone")
    func fromInstant() throws {
        let instant = try #require(ISO8601DateFormatter().date(from: "2026-11-10T13:25:59Z"))
        #expect(ClockTime(instant, in: .gmt) == ClockTime("13:25"))
        #expect(ClockTime(instant, in: .berlin) == ClockTime("14:25"))
        #expect(ClockTime(instant, in: .jakarta) == ClockTime("20:25"))
    }

    @Test("Tag und Uhrzeit ergeben einen Zeitpunkt, der wieder dieselbe Uhrzeit zeigt")
    func roundTrip() throws {
        let day = try #require(CalendarDay("2027-06-21"))
        let time = try #require(ClockTime("23:59"))
        #expect(ClockTime(day.date(at: time, in: .berlin), in: .berlin) == time)
    }

    @Test("ordnet nach der Uhrzeit")
    func compares() throws {
        let early = try #require(ClockTime("05:16"))
        let late = try #require(ClockTime("14:00"))
        #expect(early < late)
        #expect([late, early].sorted() == [early, late])
    }
}
