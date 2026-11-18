#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Der Wecker zu Fadschr: Weckzeit, Grenzen, Stepper und die Wecker der nächsten Tage (Spec § 10.8).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14.
@Suite("Wecker zu Fadschr")
struct FajrAlarmTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixturePlace("berlin")

    private func times(on day: CalendarDay? = nil) -> DayTimes {
        guard let times = FixtureTimesSource().times(on: day ?? self.day, at: berlin, settings: CalculationSettings()) else {
            preconditionFailure("Die Fixture liefert für jeden Tag Zeiten")
        }
        return times
    }

    private func clock(_ date: Date, in zone: TimeZone = .berlin) -> String {
        ClockTime(date, in: zone).description
    }

    private func plan(
        at time: String, on day: CalendarDay? = nil, source: any PrayerTimesSource = FixtureTimesSource(),
        preferences: FajrAlarmPreferences = FajrAlarmPreferences(isOn: true), limit: Int = FajrAlarmPlanner.days
    ) -> [FajrAlarmOccurrence] {
        FajrAlarmPlanner(source: source).plan(
            at: (day ?? self.day).at(time, in: .berlin), place: berlin, settings: CalculationSettings(),
            preferences: preferences, limit: limit
        )
    }

    // MARK: - Weckzeit

    @Test("Startwerte wie im Prototyp: aus, 45 Min. vor Sonnenaufgang, feste Uhrzeit 05:30, Systemton")
    func standardValues() {
        let preferences = FajrAlarmPreferences()
        #expect(!preferences.isOn)
        #expect(preferences.mode == .beforeSunrise)
        #expect(preferences.minutesBefore == 45)
        #expect(preferences.fixedTime.description == "05:30")
        #expect(preferences.sound == .system)
    }

    @Test("Vor Sonnenaufgang: 45 Min. vor 07:14 klingelt um 06:29")
    func beforeSunrise() {
        #expect(clock(FajrAlarmPreferences(isOn: true).alarmDate(on: times())) == "06:29")
        #expect(clock(FajrAlarmPreferences(isOn: true, minutesBefore: 120).alarmDate(on: times())) == "05:14")
        #expect(clock(FajrAlarmPreferences(isOn: true, minutesBefore: 10).alarmDate(on: times())) == "07:04")
    }

    @Test("Feste Uhrzeit klingelt zu ihr, aber spätestens 5 Min. vor Sonnenaufgang")
    func fixedTime() {
        let fixed = { (time: String) in
            FajrAlarmPreferences(isOn: true, mode: .fixedTime, fixedTime: clockTime(time)).alarmDate(on: self.times())
        }
        #expect(clock(fixed("05:30")) == "05:30")
        #expect(clock(fixed("07:05")) == "07:05")
        #expect(clock(fixed("07:09")) == "07:09")
        #expect(clock(fixed("07:10")) == "07:09")
        #expect(clock(fixed("08:00")) == "07:09")
        #expect(clock(fixed("03:00")) == "03:00")
    }

    @Test("Sekunden im Sonnenaufgang: Die Weckzeit liegt auf der vollen Minute")
    func roundsDownToTheMinute() {
        let base = times()
        let shifted = DayTimes(
            day: base.day, timeZone: base.timeZone, fajr: base.fajr, sunrise: base.sunrise.addingTimeInterval(30),
            dhuhr: base.dhuhr, asr: base.asr, maghrib: base.maghrib, isha: base.isha
        )
        let date = FajrAlarmPreferences(isOn: true).alarmDate(on: shifted)
        #expect(date == day.at("06:29", in: .berlin))
    }

    @Test("Grenzen: 10…120 Minuten, feste Uhrzeit nicht vor 03:00")
    func limits() {
        #expect(FajrAlarmPreferences(minutesBefore: 5).minutesBefore == 10)
        #expect(FajrAlarmPreferences(minutesBefore: 200).minutesBefore == 120)
        #expect(FajrAlarmPreferences(fixedTime: clockTime("02:00")).fixedTime.description == "03:00")
        var preferences = FajrAlarmPreferences()
        preferences.minutesBefore = 0
        #expect(preferences.minutesBefore == 10)
        preferences.fixedTime = clockTime("01:30")
        #expect(preferences.fixedTime.description == "03:00")
    }

    @Test("Späteste feste Uhrzeit: 5 Minuten vor Sonnenaufgang")
    func latestFixedTime() {
        #expect(FajrAlarmPreferences.latestFixedTime(sunrise: clockTime("07:14")).description == "07:09")
        #expect(FajrAlarmPreferences.latestFixedTime(sunrise: clockTime("04:43")).description == "04:38")
    }

    // MARK: - Stepper

    @Test("Stepper der Minuten: in 5er-Schritten zwischen 10 und 120")
    func minutesStepper() {
        #expect(FajrAlarmPreferences(minutesBefore: 45).steppedMinutesBefore(by: 1) == 50)
        #expect(FajrAlarmPreferences(minutesBefore: 45).steppedMinutesBefore(by: -1) == 40)
        #expect(FajrAlarmPreferences(minutesBefore: 120).steppedMinutesBefore(by: 1) == 120)
        #expect(FajrAlarmPreferences(minutesBefore: 10).steppedMinutesBefore(by: -1) == 10)
    }

    @Test("Stepper der Uhrzeit: ab 03:00 bis 5 Minuten vor Sonnenaufgang")
    func fixedTimeStepper() {
        let sunrise = clockTime("07:14")
        let stepped = { (time: String, direction: Int) in
            FajrAlarmPreferences(fixedTime: clockTime(time)).steppedFixedTime(by: direction, sunrise: sunrise).description
        }
        #expect(stepped("05:30", 1) == "05:35")
        #expect(stepped("05:30", -1) == "05:25")
        #expect(stepped("07:05", 1) == "07:09")
        #expect(stepped("07:09", 1) == "07:09")
        #expect(stepped("03:00", -1) == "03:00")
        #expect(stepped("03:02", -1) == "03:00")
    }

    // MARK: - Plan

    @Test("14:25: zwei Wochen ab morgen, je um 06:29")
    func planFromAfternoon() {
        let occurrences = plan(at: "14:25")
        #expect(occurrences.count == 14)
        #expect(occurrences.first?.day == day.adding(days: 1))
        #expect(occurrences.last?.day == day.adding(days: 14))
        #expect(occurrences.allSatisfy { clock($0.date) == "06:29" })
        #expect(occurrences.map(\.date) == occurrences.map(\.date).sorted())
    }

    @Test("05:00: Heute zählt noch mit")
    func planBeforeAlarm() {
        let occurrences = plan(at: "05:00")
        #expect(occurrences.first?.day == day)
        #expect(occurrences.first?.date == day.at("06:29", in: .berlin))
        #expect(occurrences.count == 14)
    }

    @Test("Genau zur Weckzeit ist heute vorbei")
    func planAtAlarmTime() {
        #expect(plan(at: "06:29").first?.day == day.adding(days: 1))
    }

    @Test("Aus: keine Wecker")
    func planOff() {
        #expect(plan(at: "05:00", preferences: FajrAlarmPreferences(isOn: false)).isEmpty)
        #expect(plan(at: "05:00", limit: 0).isEmpty)
    }

    @Test("Tage ohne Zeiten fallen aus, der Plan geht dahinter weiter")
    func missingDays() {
        let missing: Set = [day.adding(days: 1), day.adding(days: 2)]
        let occurrences = plan(at: "14:25", source: StubTimesSource(base: FixtureTimesSource(), missing: missing))
        #expect(occurrences.count == 14)
        #expect(occurrences.first?.day == day.adding(days: 3))
        #expect(!occurrences.contains { missing.contains($0.day) })
    }

    @Test("Ohne Zeiten überhaupt bleibt der Plan leer")
    func noTimesAtAll() {
        #expect(plan(at: "14:25", source: StubTimesSource(base: FixtureTimesSource(), missingAll: true)).isEmpty)
    }

    @Test("Zeitumstellung am 25.10.2026: feste Uhrzeit bleibt 05:30, vor Sonnenaufgang bleibt 45 Min. davor")
    func daylightSavingTime() {
        let source = AdhanTimesSource()
        let place = Place.berlin
        let start = calendarDay("2026-10-23")
        let fixed = FajrAlarmPlanner(source: source).plan(
            at: start.at("12:00", in: .berlin), place: place, settings: CalculationSettings(),
            preferences: FajrAlarmPreferences(isOn: true, mode: .fixedTime), limit: 5
        )
        #expect(fixed.map(\.day.description) == ["2026-10-24", "2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28"])
        #expect(fixed.allSatisfy { clock($0.date) == "05:30" })

        let before = FajrAlarmPlanner(source: source).plan(
            at: start.at("12:00", in: .berlin), place: place, settings: CalculationSettings(),
            preferences: FajrAlarmPreferences(isOn: true), limit: 5
        )
        for occurrence in before {
            let sunrise = source.times(on: occurrence.day, at: place, settings: CalculationSettings())?.sunrise
            let gap = sunrise.map { $0.timeIntervalSince(occurrence.date) } ?? 0
            #expect(gap >= 45 * 60 && gap < 46 * 60)
        }
    }

    // MARK: - Kennung

    @Test("Kennung: gleich für dieselbe Zeit und Fassung, sonst verschieden")
    func identifier() {
        let date = day.at("06:29", in: .berlin)
        let first = FajrAlarmPlanner.identifier(for: date, variant: "system|de")
        #expect(first == FajrAlarmPlanner.identifier(for: date, variant: "system|de"))
        #expect(first != FajrAlarmPlanner.identifier(for: date, variant: "adhan-voice1|de"))
        #expect(first != FajrAlarmPlanner.identifier(for: date.addingTimeInterval(60), variant: "system|de"))
        // Version 5, Variante RFC 4122
        #expect(first.uuidString.dropFirst(14).first == "5")
        #expect(["8", "9", "A", "B"].contains(first.uuidString.dropFirst(19).first.map(String.init)))
    }

    // MARK: - Speichern

    @Test("Speichern und Lesen; fehlende oder unbekannte Werte gelten als Startwert")
    func coding() throws {
        let preferences = FajrAlarmPreferences(
            isOn: true, mode: .fixedTime, minutesBefore: 60, fixedTime: clockTime("04:45"), sound: .adhan
        )
        let data = try JSONEncoder().encode(preferences)
        #expect(try JSONDecoder().decode(FajrAlarmPreferences.self, from: data) == preferences)

        let empty = try JSONDecoder().decode(FajrAlarmPreferences.self, from: Data("{}".utf8))
        #expect(empty == FajrAlarmPreferences())

        let odd = try JSONDecoder().decode(
            FajrAlarmPreferences.self,
            from: Data(#"{"isOn":true,"mode":"weekly","minutesBefore":300,"fixedMinutes":60,"sound":"bell"}"#.utf8)
        )
        #expect(odd == FajrAlarmPreferences(isOn: true, minutesBefore: 120, fixedTime: clockTime("03:00")))
    }
}

#endif
