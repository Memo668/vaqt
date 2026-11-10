#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Mock-Quelle muss sich verhalten wie `todayTimes()` im Prototyp.
@Suite("FixtureTimesSource")
struct FixtureTimesSourceTests {

    private let source = FixtureTimesSource()
    private let summerSource = FixtureTimesSource(highLatitude: true)
    private let day = FixtureTimes.referenceDay
    private let summerDay = FixtureTimes.berlinSummer.day

    private func place(_ id: String) throws -> Place {
        try #require(FixtureTimes.city(id)).place(named: id)
    }

    private func times(
        _ settings: CalculationSettings = CalculationSettings(), on day: CalendarDay? = nil, at place: Place = .berlin,
        from source: FixtureTimesSource? = nil
    ) throws -> DayTimes {
        try #require((source ?? self.source).times(on: day ?? self.day, at: place, settings: settings))
    }

    private func clockTimes(_ times: DayTimes) -> [String] {
        Prayer.allCases.map { times.clockTime(of: $0).description }
    }

    // MARK: - Städte

    @Test("Berlin zeigt die Zeiten des Haupt-Screenshots")
    func berlin() throws {
        let times = try times()
        #expect(clockTimes(times) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(times.day == day)
        #expect(times.timeZone == .berlin)
        #expect(times.asr == day.at("14:00", in: .berlin))
    }

    @Test("jede Fixture-Stadt zeigt ihre Zeiten in ihrer Zeitzone", arguments: [
        ("berlin", ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"]),
        ("istanbul", ["06:09", "07:36", "12:53", "15:36", "18:00", "19:23"]),
        ("madrid", ["06:18", "07:51", "13:00", "15:43", "18:06", "19:33"]),
        ("mecca", ["05:08", "06:27", "12:05", "15:17", "17:41", "19:11"]),
        ("jakarta", ["04:06", "05:24", "11:39", "14:57", "17:49", "19:01"]),
    ])
    func cities(id: String, expected: [String]) throws {
        let place = try place(id)
        let times = try times(at: place)
        #expect(clockTimes(times) == expected)
        #expect(times.timeZone == place.timeZone)
        for prayer in Prayer.allCases {
            #expect(CalendarDay(times[prayer], in: place.timeZone) == day, "\(id) \(prayer)")
        }
    }

    @Test("für jeden anderen Ort gilt Berlin, mit den Uhrzeiten in der Zeitzone des Ortes")
    func unknownPlace() throws {
        let hamburg = Place(
            name: "Hamburg", countryCode: "DE",
            coordinates: Coordinates(latitude: 53.5511, longitude: 9.9937), timeZoneIdentifier: "Europe/Berlin"
        )
        #expect(try clockTimes(times(at: hamburg)) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])

        let tokyo = Place(
            name: "Tokio", countryCode: "JP",
            coordinates: Coordinates(latitude: 35.6762, longitude: 139.6503), timeZoneIdentifier: "Asia/Tokyo"
        )
        let times = try times(at: tokyo)
        #expect(clockTimes(times) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(times.timeZone.identifier == "Asia/Tokyo")
    }

    // MARK: - Einstellungen

    @Test("Asr hanafitisch nimmt die zweite Asr-Zeit der Stadt", arguments: [
        ("berlin", "14:36"), ("istanbul", "16:13"), ("madrid", "16:25"), ("mecca", "16:05"), ("jakarta", "16:02"),
    ])
    func hanafi(id: String, expected: String) throws {
        let place = try place(id)
        let hanafi = try times(CalculationSettings(asr: .hanafi), at: place)
        let standard = try times(at: place)
        #expect(hanafi.clockTime(of: .asr) == clockTime(expected))
        for prayer in Prayer.allCases where prayer != .asr {
            #expect(hanafi[prayer] == standard[prayer])
        }
    }

    @Test("Minutenkorrekturen werden auf die Mock-Zeiten gerechnet")
    func adjustments() throws {
        let settings = CalculationSettings(adjustments: MinuteAdjustments([.fajr: -2, .dhuhr: 5, .isha: 30]))
        #expect(try clockTimes(times(settings)) == ["05:14", "07:14", "11:57", "14:00", "16:27", "18:47"])
    }

    @Test("die Korrektur für Asr gilt auch für die hanafitische Zeit")
    func adjustmentWithHanafi() throws {
        let settings = CalculationSettings(asr: .hanafi, adjustments: MinuteAdjustments([.asr: 4]))
        #expect(try times(settings).clockTime(of: .asr) == clockTime("14:40"))
    }

    @Test("Methode und Regel für hohe Breiten ändern die Mock-Zeiten der Städte nicht")
    func ignoresMethodAndRule() throws {
        let plain = try times()
        for method in CalculationMethod.allCases {
            #expect(try times(CalculationSettings(method: method)) == plain)
        }
        for rule in HighLatitudeRule.allCases {
            #expect(try times(CalculationSettings(highLatitudeRule: rule)) == plain)
        }
    }

    @Test("jeder Tag zeigt dieselben Uhrzeiten")
    func everyDay() throws {
        for text in ["2026-11-09", "2026-11-11", "2027-02-28", "2028-02-29"] {
            let other = calendarDay(text)
            let times = try times(on: other)
            #expect(clockTimes(times) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"], "\(text)")
            #expect(times.day == other)
            #expect(CalendarDay(times.fajr, in: .berlin) == other)
        }
    }

    // MARK: - Zeitumstellung

    @Test("an Tagen mit Zeitumstellung stimmen die Uhrzeiten; der Tag ist 25 oder 23 Stunden lang")
    func clockChanges() throws {
        let autumn = try times(on: calendarDay("2026-10-25"))
        #expect(clockTimes(autumn) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(autumn.fajr.timeIntervalSince(try times(on: calendarDay("2026-10-24")).fajr) == 25 * 3600)
        #expect(try times(on: calendarDay("2026-10-26")).fajr.timeIntervalSince(autumn.fajr) == 24 * 3600)

        let spring = try times(on: calendarDay("2027-03-28"))
        #expect(clockTimes(spring) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(spring.fajr.timeIntervalSince(try times(on: calendarDay("2027-03-27")).fajr) == 23 * 3600)
    }

    // MARK: - Hohe Breiten (Berlin, 21. Juni)

    @Test("Berlin im Sommer: Fadschr und Ischa hängen an der Regel", arguments: [
        (HighLatitudeRule.angle, ["02:34", "04:43", "13:12", "17:33", "21:33", "23:35"]),
        (.seventh, ["03:42", "04:43", "13:12", "17:33", "21:33", "22:34"]),
        (.middle, ["01:08", "04:43", "13:12", "17:33", "21:33", "01:08"]),
    ])
    func summer(rule: HighLatitudeRule, expected: [String]) throws {
        let times = try times(CalculationSettings(highLatitudeRule: rule), on: summerDay, from: summerSource)
        #expect(clockTimes(times) == expected)
        #expect(times.day == summerDay)
        #expect(Prayer.allCases.map { times[$0] } == Prayer.allCases.map { times[$0] }.sorted())
    }

    @Test("Berlin im Sommer: Asr hanafitisch um 18:48")
    func summerHanafi() throws {
        let times = try times(CalculationSettings(asr: .hanafi), on: summerDay, from: summerSource)
        #expect(times.clockTime(of: .asr) == clockTime("18:48"))
    }

    @Test("Nachtmitte: Ischa liegt nach Mitternacht und gehört trotzdem zum Tag")
    func ishaAfterMidnight() throws {
        let settings = CalculationSettings(highLatitudeRule: .middle)
        let times = try times(settings, on: summerDay, from: summerSource)
        #expect(times.isha == summerDay.adding(days: 1).at("01:08", in: .berlin))
        #expect(CalendarDay(times.isha, in: .berlin) == summerDay.adding(days: 1))
        #expect(times.fajr == summerDay.at("01:08", in: .berlin))

        // Ischa von gestern und Fadschr von heute fallen auf denselben Zeitpunkt.
        let yesterday = try self.times(settings, on: summerDay.adding(days: -1), from: summerSource)
        #expect(yesterday.isha == times.fajr)
    }

    @Test("ein Ischa, das die Korrektur über Mitternacht schiebt, zeigt die Uhrzeit des Folgetags")
    func adjustmentAcrossMidnight() throws {
        // Winkelbasiert liegt Ischa um 23:35; mit +30 Minuten sind es 00:05 am Folgetag.
        let settings = CalculationSettings(adjustments: MinuteAdjustments([.isha: 30]))
        let times = try times(settings, on: summerDay, from: summerSource)
        #expect(times.clockTime(of: .isha) == clockTime("00:05"))
        #expect(times.isha == summerDay.adding(days: 1).at("00:05", in: .berlin))
        #expect(times.isha.timeIntervalSince(times.maghrib) == minutes(152))
    }

    @Test("mit -debugHighLatitude gilt Berlin im Sommer für jeden Ort und jeden Tag")
    func summerEverywhere() throws {
        let jakarta = try place("jakarta")
        let times = try times(on: day, at: jakarta, from: summerSource)
        #expect(clockTimes(times) == ["02:34", "04:43", "13:12", "17:33", "21:33", "23:35"])
        #expect(times.timeZone == .jakarta)
        #expect(summerSource.highLatitude)
        #expect(!source.highLatitude)
    }
}

/// `ClockTime(minutesSinceMidnight:)` läuft um wie `fmt()` im Prototyp.
@Suite("ClockTime aus Minuten")
struct ClockTimeMinutesTests {

    @Test("Minuten seit Mitternacht ergeben die Uhrzeit", arguments: [
        (0, "00:00"), (316, "05:16"), (1439, "23:59"), (1440, "00:00"), (1508, "01:08"), (-20, "23:40"), (-1440, "00:00"),
        (2948, "01:08"),
    ])
    func wraps(minutes: Int, expected: String) {
        #expect(ClockTime(minutesSinceMidnight: minutes) == clockTime(expected))
    }
}

#endif
