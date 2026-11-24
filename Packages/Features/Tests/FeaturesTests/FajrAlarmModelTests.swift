#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Der Wecker zu Fadschr aus der Sicht der App: Erlaubnis, Schalter, Seite, Chip und die Wecker bei iOS
/// (Spec § 10.8, Plan für Phase 17).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14.
@MainActor
@Suite("Wecker zu Fadschr: Modell")
struct FajrAlarmModelTests {

    struct Fixture {
        let settings: SettingsStore
        let clock: TestClock
        let scheduler: FixedFajrAlarmScheduler
        let model: FajrAlarmModel
    }

    private func fixture(
        time: String = "14:25", place: Place? = .berlin, alarm: FajrAlarmPreferences = FajrAlarmPreferences(),
        status: AlarmAuthorization = .notDetermined, answer: AlarmAuthorization = .authorized,
        isPlanning: Bool = true, testDate: Date? = nil
    ) -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        snapshot.autoLocation = false
        snapshot.manualPlace = place
        snapshot.fajrAlarm = alarm
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let location = PlaceModel(settings: settings, locationSource: FixedLocationSource(place: nil, status: .notDetermined))
        let clock = TestClock(instant("2026-11-10", time))
        let scheduler = FixedFajrAlarmScheduler(status: status, answer: answer)
        let model = FajrAlarmModel(
            settings: settings, location: location, clock: clock, timesSource: FixtureTimesSource(),
            scheduler: scheduler, isPlanning: isPlanning, testDate: testDate
        )
        return Fixture(settings: settings, clock: clock, scheduler: scheduler, model: model)
    }

    private var on: FajrAlarmPreferences { FajrAlarmPreferences(isOn: true) }

    // MARK: - Schalter und Erlaubnis

    @Test("Einschalten fragt nach der Erlaubnis; erlaubt ist der Wecker an")
    func switchOnAllowed() async {
        let fixture = fixture()
        await fixture.model.setOn(true)
        #expect(fixture.scheduler.authorizationRequests == 1)
        #expect(fixture.settings.fajrAlarm.isOn)
        #expect(fixture.model.isActive)
        #expect(fixture.model.authorization == .authorized)
    }

    @Test("Abgelehnt bleibt der Wecker aus, die Seite zeigt den gesperrten Schalter")
    func switchOnDenied() async {
        let fixture = fixture(answer: .denied)
        await fixture.model.setOn(true)
        #expect(!fixture.settings.fajrAlarm.isOn)
        #expect(fixture.model.isDenied)
        #expect(!fixture.model.isActive)
        #expect(fixture.model.rowValue == L10n.off)
    }

    @Test("Schon erlaubt: Einschalten fragt nicht noch einmal")
    func switchOnAlreadyAllowed() async {
        let fixture = fixture(status: .authorized)
        await fixture.model.setOn(true)
        #expect(fixture.scheduler.authorizationRequests == 0)
        #expect(fixture.settings.fajrAlarm.isOn)
    }

    @Test("Später in den iOS-Einstellungen verboten: Der Wecker gilt als aus, die Wahl bleibt gespeichert")
    func deniedLater() async {
        let fixture = fixture(alarm: on, status: .denied)
        await fixture.model.refreshAuthorization()
        #expect(fixture.settings.fajrAlarm.isOn)
        #expect(!fixture.model.isActive)
        #expect(fixture.model.ringsText == nil)
    }

    @Test("Ausschalten fragt nichts und meldet beim nächsten Planen alle Wecker ab")
    func switchOff() async {
        let fixture = fixture(alarm: on, status: .authorized)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.count == 14)
        await fixture.model.setOn(false)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.isEmpty)
        #expect(fixture.scheduler.authorizationRequests == 0)
    }

    // MARK: - Texte

    @Test("Seite und Zeile: „Klingelt heute um 06:29“, Wert 06:29, Fadschr 05:16 und Sonnenaufgang 07:14")
    func texts() async {
        let fixture = fixture(alarm: on, status: .authorized)
        await fixture.model.refreshAuthorization()
        #expect(fixture.model.rowValue == "06:29")
        #expect(fixture.model.ringsText == L10n.alarmRings(t: "06:29"))
        #expect(fixture.model.todayFooter == L10n.alarmToday(f: "05:16", s: "07:14"))
        #expect(fixture.model.minutesBeforeText == L10n.minBefore(n: 45))
        #expect(fixture.model.fixedTimeText == "05:30")
    }

    @Test("Aus: Zeile „Aus“, kein Text unter dem Schalter, kein Chip")
    func textsOff() async throws {
        let fixture = fixture(status: .authorized)
        await fixture.model.refreshAuthorization()
        #expect(fixture.model.rowValue == L10n.off)
        #expect(fixture.model.ringsText == nil)
        let times = try #require(FixtureTimesSource().times(on: day("2026-11-10"), at: .berlin, settings: CalculationSettings()))
        #expect(fixture.model.alarmTime(on: times) == nil)
    }

    @Test("Chip: die Weckzeit des gezeigten Tages")
    func chip() async throws {
        let fixture = fixture(alarm: FajrAlarmPreferences(isOn: true, minutesBefore: 60), status: .authorized)
        await fixture.model.refreshAuthorization()
        let times = try #require(FixtureTimesSource().times(on: day("2026-11-11"), at: .berlin, settings: CalculationSettings()))
        #expect(fixture.model.alarmTime(on: times)?.description == "06:14")
    }

    // MARK: - Stepper

    @Test("Stepper: Minuten in 5er-Schritten, feste Uhrzeit bis 5 Min. vor Sonnenaufgang")
    func steppers() {
        let fixture = fixture(alarm: FajrAlarmPreferences(isOn: true, minutesBefore: 120, fixedTime: clock("07:05")))
        #expect(!fixture.model.canStepMinutes(by: 1))
        fixture.model.stepMinutes(by: -1)
        #expect(fixture.settings.fajrAlarm.minutesBefore == 115)
        fixture.model.setMode(.fixedTime)
        #expect(fixture.model.canStepFixedTime(by: 1))
        fixture.model.stepFixedTime(by: 1)
        #expect(fixture.settings.fajrAlarm.fixedTime.description == "07:09")
        #expect(!fixture.model.canStepFixedTime(by: 1))
        #expect(fixture.model.canStepFixedTime(by: -1))
    }

    // MARK: - Planen

    @Test("14:25, an: 14 Wecker ab morgen 06:29 mit dem Weckton und dem Titel „Wecker zu Fadschr“")
    func plan() async throws {
        let fixture = fixture(alarm: on, status: .authorized)
        await fixture.model.reschedule()
        let alarms = fixture.scheduler.alarms
        #expect(alarms.count == 14)
        let first = try #require(alarms.first)
        #expect(first.date == instant("2026-11-11", "06:29"))
        #expect(first.title == L10n.alarmRow)
        #expect(first.stopTitle == L10n.alarmStop)
        #expect(first.tone == .system)
        #expect(Set(alarms.map(\.id)).count == 14)
    }

    @Test("Kurzer Adhan: dieselbe Aufnahme wie bei den Mitteilungen, unabhängig von deren Klang")
    func adhanTone() async {
        let fixture = fixture(alarm: FajrAlarmPreferences(isOn: true, sound: .adhan), status: .authorized)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.count == 14)
        #expect(fixture.scheduler.alarms.allSatisfy { $0.tone == .clip("adhan.caf") })
        fixture.settings.updateNotifications { $0.sound = .silent }
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.first?.tone == .clip("adhan.caf"))
    }

    @Test("Gleicher Plan, gleiche Kennungen; anderer Klang, andere Kennungen")
    func stableIdentifiers() async {
        let fixture = fixture(alarm: on, status: .authorized)
        await fixture.model.reschedule()
        let first = fixture.scheduler.alarms.map(\.id)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.map(\.id) == first)
        fixture.model.setSound(.adhan)
        await fixture.model.reschedule()
        #expect(Set(fixture.scheduler.alarms.map(\.id)).isDisjoint(with: first))
    }

    @Test("Ohne Erlaubnis, ohne Ort oder ohne Planen: nichts angemeldet")
    func nothingPlanned() async {
        let denied = fixture(alarm: on, status: .denied)
        await denied.model.reschedule()
        #expect(denied.scheduler.alarms.isEmpty)
        #expect(denied.model.planned.isEmpty)

        let nowhere = fixture(place: nil, alarm: on, status: .authorized)
        await nowhere.model.reschedule()
        #expect(nowhere.scheduler.alarms.isEmpty)

        let notPlanning = fixture(alarm: on, status: .authorized, isPlanning: false)
        await notPlanning.model.reschedule()
        #expect(notPlanning.scheduler.alarms.isEmpty)
    }

    @Test("-debugAlarmIn: ein Wecker zum Test, auch wenn der Wecker aus ist und nicht geplant wird")
    func testAlarm() async throws {
        let date = instant("2026-11-10", "14:27")
        let fixture = fixture(status: .authorized, isPlanning: false, testDate: date)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.alarms.map(\.date) == [date])
    }

    @Test("Was eingeht: Ort, Wecker und Erlaubnis lösen neues Planen aus, die Mitteilungen nicht")
    func inputs() async {
        let fixture = fixture(alarm: on)
        let start = fixture.model.inputs
        fixture.model.setMode(.fixedTime)
        #expect(fixture.model.inputs != start)
        let fixed = fixture.model.inputs
        fixture.settings.select(.istanbul)
        #expect(fixture.model.inputs != fixed)
        let moved = fixture.model.inputs
        // Der Wecker hat seinen eigenen Klang; der Klang der Mitteilungen geht nicht ein.
        fixture.settings.updateNotifications { $0.sound = .system }
        #expect(fixture.model.inputs == moved)
        await fixture.model.setOn(true)
        #expect(fixture.model.inputs != moved)
    }

    private func clock(_ text: String) -> ClockTime {
        guard let time = ClockTime(text) else { preconditionFailure("Ungültige Uhrzeit im Test: \(text)") }
        return time
    }
}

#endif
