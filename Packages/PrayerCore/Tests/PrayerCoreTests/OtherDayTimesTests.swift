import Foundation
import Testing
@testable import PrayerCore

/// Zeiten für einen beliebigen Tag – die Tage vor und zurück auf der Zeiten-Seite (Spec § 9.4).
@Suite("Zeiten für einen anderen Tag")
struct OtherDayTimesTests {

    private let source = AdhanTimesSource()
    private let mwl = CalculationSettings(method: .mwl)
    private let today = calendarDay("2026-11-10")

    private var tromso: Place {
        Place(
            name: "Tromsø", countryCode: "NO",
            coordinates: Coordinates(latitude: 69.6492, longitude: 18.9553), timeZoneIdentifier: "Europe/Oslo"
        )
    }

    private func times(_ day: String, at place: Place = .berlin, _ settings: CalculationSettings? = nil) throws -> DayTimes {
        try #require(source.times(
            on: calendarDay(day), viewedFrom: today, at: place, settings: settings ?? mwl
        ))
    }

    /// Minuten zwischen zwei Uhrzeiten am Ort.
    private func clockDifference(_ prayer: Prayer, _ a: DayTimes, _ b: DayTimes) -> Int {
        b.clockTime(of: prayer).minutesSinceMidnight - a.clockTime(of: prayer).minutesSinceMidnight
    }

    // MARK: - Echte Rechnung

    @Test("Echt: ein anderer Tag ist derselbe wie `times(on:)` – die Seite rechnet nichts Eigenes")
    func sameAsAnyDay() throws {
        for offset in [-365, -1, 1, 2, 100, 365] {
            let day = today.adding(days: offset)
            let viewed = try #require(source.times(on: day, viewedFrom: today, at: .berlin, settings: mwl))
            #expect(viewed == source.times(on: day, at: .berlin, settings: mwl))
            #expect(viewed.day == day)
        }
    }

    @Test("Echt: ±365 Tage – jeder Tag hat seine eigenen, geordneten Zeiten", arguments: [-365, -200, -1, 1, 45, 200, 365])
    func wholeYear(offset: Int) throws {
        let day = today.adding(days: offset)
        let times = try #require(source.times(on: day, viewedFrom: today, at: .berlin, settings: mwl))
        #expect(times.day == day)
        let order = Prayer.allCases.map { times[$0] }
        #expect(order == order.sorted())
        // Der Tag des Datums: Sonnenaufgang liegt am Ort an genau diesem Kalendertag.
        #expect(CalendarDay(times.sunrise, in: .berlin) == day)
    }

    @Test("Sommerzeit beginnt (29.03.2026): Die Uhrzeiten springen eine Stunde nach vorn")
    func daylightSavingStarts() throws {
        let before = try times("2026-03-28")
        let after = try times("2026-03-29")
        // Dhuhr rückt am Tag selbst um gut eine Minute früher; auf der Uhr eine Stunde später.
        #expect((59...61).contains(clockDifference(.dhuhr, before, after)))
        #expect((57...61).contains(clockDifference(.maghrib, before, after)))
        // Fadschr liegt am 29.03. nach der Umstellung um 02:00 und schon in Sommerzeit.
        #expect(after.clockTime(of: .fajr) > clockTime("03:00"))
        #expect((57...61).contains(clockDifference(.fajr, before, after)))
        // Abstand in echter Zeit: ein Tag minus eine Minute oder so – nicht 23 Stunden.
        #expect(abs(after.dhuhr.timeIntervalSince(before.dhuhr) - 24 * 3600) < 120)
    }

    @Test("Sommerzeit endet (25.10.2026): Die Uhrzeiten springen eine Stunde zurück")
    func daylightSavingEnds() throws {
        let before = try times("2026-10-24")
        let after = try times("2026-10-25")
        #expect((-61 ... -59).contains(clockDifference(.dhuhr, before, after)))
        // Fadschr rückt im Herbst täglich knapp zwei Minuten später, Ischa ebenso früher.
        #expect((-61 ... -56).contains(clockDifference(.fajr, before, after)))
        #expect((-63 ... -59).contains(clockDifference(.isha, before, after)))
        #expect(abs(after.dhuhr.timeIntervalSince(before.dhuhr) - 24 * 3600) < 120)
    }

    @Test("Hohe Breiten: Berlin im Juni hat mit jeder Regel Zeiten, Fadschr und Ischa geschätzt")
    func berlinSummer() throws {
        for rule in HighLatitudeRule.allCases {
            let settings = CalculationSettings(method: .mwl, highLatitudeRule: rule)
            let times = try times("2027-06-21", settings)
            #expect(times.fajr < times.sunrise)
            #expect(times.isha > times.maghrib)
            #expect(source.usesHighLatitudeRule(on: calendarDay("2027-06-21"), at: .berlin, settings: settings))
        }
    }

    @Test("Hohe Breiten: In Tromsø gibt es zur Mitternachtssonne und in der Polarnacht keine Zeiten, im März schon")
    func tromsoPolar() {
        #expect(source.times(on: calendarDay("2027-06-21"), viewedFrom: today, at: tromso, settings: mwl) == nil)
        #expect(source.times(on: calendarDay("2026-12-21"), viewedFrom: today, at: tromso, settings: mwl) == nil)
        #expect(source.times(on: calendarDay("2027-03-21"), viewedFrom: today, at: tromso, settings: mwl) != nil)
    }

    // MARK: - Mock-Zeiten

    /// Werte aus `dayTimes()` des Prototyps (10.11.2026, Uhr der Stadt), mit dem Prototyp selbst gerechnet.
    @Test("Mock-Zeiten: ein anderer Tag wie `dayTimes()` im Prototyp", arguments: [
        ("berlin", 1, "05:18 07:16 11:52 13:59 16:25 18:16"),
        ("berlin", -1, "05:14 07:12 11:52 14:01 16:29 18:18"),
        ("berlin", 7, "05:26 07:27 11:53 13:52 16:17 18:09"),
        ("berlin", 138, "04:46 06:45 13:13 16:42 19:39 21:29"),
        ("berlin", -226, "04:42 06:42 13:13 16:43 19:41 21:32"),
        ("berlin", 349, "05:50 07:44 12:52 15:23 17:57 19:43"),
        ("berlin", 365, "05:16 07:14 11:52 14:00 16:27 18:17"),
        ("istanbul", 140, "05:15 06:41 13:14 16:49 19:36 20:58"),
        ("madrid", -365, "06:18 07:51 13:00 15:43 18:06 19:33"),
        ("mecca", 7, "05:11 06:31 12:06 15:16 17:39 19:10"),
        ("jakarta", -226, "04:40 05:54 12:00 15:12 18:00 19:09"),
    ])
    func fixtureShift(city: String, offset: Int, expected: String) throws {
        let fixture = FixtureTimesSource()
        let day = today.adding(days: offset)
        let times = try #require(fixture.times(on: day, viewedFrom: today, at: fixturePlace(city), settings: CalculationSettings()))
        #expect(Prayer.allCases.map { times.clockTime(of: $0).description }.joined(separator: " ") == expected)
        #expect(times.day == day)
    }

    @Test("Mock-Zeiten: heute bleibt heute, Asr hanafitisch verschiebt sich mit")
    func fixtureTodayAndHanafi() throws {
        let fixture = FixtureTimesSource()
        let place = fixturePlace("berlin")
        #expect(fixture.times(on: today, viewedFrom: today, at: place, settings: CalculationSettings())
            == fixture.times(on: today, at: place, settings: CalculationSettings()))
        let hanafi = try #require(fixture.times(
            on: today.adding(days: 1), viewedFrom: today, at: place, settings: CalculationSettings(asr: .hanafi)
        ))
        #expect(hanafi.clockTime(of: .asr) == clockTime("14:35"))
    }

    @Test("Mock-Zeiten mit -debugHighLatitude: Berlin ab dem 21.06.2027, auch mit eigenen Winkeln", arguments: [
        (HighLatitudeRule.angle, 30, "02:54 05:10 13:17 17:30 21:16 02:04"),
        (.angle, -30, "02:45 05:00 13:07 17:20 21:06 01:47"),
        (.angle, 180, "04:58 08:13 12:07 13:37 15:53 18:54"),
        (.manual, 1, "02:56 04:43 13:12 17:33 21:33 23:21"),
        (.manual, 30, "03:16 05:10 13:17 17:30 21:16 01:50"),
    ])
    func fixtureHighLatitude(rule: HighLatitudeRule, offset: Int, expected: String) throws {
        let fixture = FixtureTimesSource(highLatitude: true)
        let summer = FixtureTimes.berlinSummer.day
        let times = try #require(fixture.times(
            on: summer.adding(days: offset), viewedFrom: summer, at: fixturePlace("berlin"),
            settings: CalculationSettings(highLatitudeRule: rule)
        ))
        #expect(Prayer.allCases.map { times.clockTime(of: $0).description }.joined(separator: " ") == expected)
    }
}
