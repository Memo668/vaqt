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

    @Test("ordnet nach der Uhrzeit")
    func compares() throws {
        let early = try #require(ClockTime("05:16"))
        let late = try #require(ClockTime("14:00"))
        #expect(early < late)
        #expect([late, early].sorted() == [early, late])
    }
}
