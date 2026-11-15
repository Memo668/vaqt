#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Zeitleiste der Widgets: ein Eintrag für jetzt, dann einer zu jedem Ereignis der nächsten 24 Stunden,
/// jeder mit nächstem, übernächstem und vorigem Ereignis und der Liste des mittleren Widgets (Spec § 3,
/// „Widgets“; `lockScreenHTML()` und `homeScreenHTML()` im Prototyp).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14,
/// Dhuhr 11:52, Asr 14:00, Maghrib 16:27, Ischa 18:17.
@Suite("Widgets: Zeitleiste")
struct WidgetTimelineTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixturePlace("berlin")

    private func result(
        at time: String, on day: CalendarDay? = nil, place: Place? = nil, zone: TimeZone = .berlin,
        source: any PrayerTimesSource = FixtureTimesSource(), settings: CalculationSettings = CalculationSettings()
    ) -> WidgetTimeline.Result {
        WidgetTimeline.entries(
            from: (day ?? self.day).at(time, in: zone), source: source, place: place ?? berlin, settings: settings
        )
    }

    private func snapshot(at time: String, on day: CalendarDay? = nil, settings: CalculationSettings = CalculationSettings()) throws -> WidgetSnapshot {
        let entry = try #require(result(at: time, on: day, settings: settings).entries.first)
        guard case .times(let snapshot) = entry.content else {
            Issue.record("Für \(time) gibt es keine Zeiten")
            throw CancellationError()
        }
        return snapshot
    }

    /// „14:25 maghrib 16:27“ – ab wann der Eintrag gilt, welches Ereignis das nächste ist und wann es beginnt.
    private func summary(_ result: WidgetTimeline.Result, in zone: TimeZone = .berlin) -> [String] {
        result.entries.map { entry in
            let start = ClockTime(entry.date, in: zone)
            switch entry.content {
            case .times(let snapshot): return "\(start) \(snapshot.next.prayer.rawValue) \(ClockTime(snapshot.next.date, in: zone))"
            case .noTimes: return "\(start) –"
            }
        }
    }

    // MARK: - Zeitleiste

    @Test("14:25 – Maghrib ist das nächste; danach ein Eintrag zu jedem Ereignis der nächsten 24 Stunden")
    func entries() {
        let result = result(at: "14:25")
        #expect(summary(result) == [
            "14:25 maghrib 16:27", "16:27 isha 18:17", "18:17 fajr 05:16", "05:16 sunrise 07:14",
            "07:14 dhuhr 11:52", "11:52 asr 14:00", "14:00 maghrib 16:27",
        ])
        // Die neue Zeitleiste holt das Widget beim letzten Eintrag, bevor er veraltet.
        #expect(result.reloadDate == day.adding(days: 1).at("14:00", in: .berlin))
    }

    @Test("der Stand um 14:25: zuletzt Asr, danach Ischa; in der Liste sind Fadschr bis Asr vorbei")
    func referenceSnapshot() throws {
        let snapshot = try snapshot(at: "14:25")
        #expect(snapshot.previous.prayer == .asr)
        #expect(snapshot.next.prayer == .maghrib)
        #expect(snapshot.following.prayer == .isha)
        #expect(snapshot.list.day == day)
        #expect(snapshot.passed == [.fajr, .sunrise, .dhuhr, .asr])
        #expect(snapshot.isNext(.maghrib))
        #expect(!snapshot.isNext(.isha))
        #expect(snapshot.remaining == minutes(122))
    }

    @Test("was jetzt beginnt, ist schon vorbei: um 16:27 ist Ischa das nächste")
    func eventAtNow() throws {
        let snapshot = try snapshot(at: "16:27")
        #expect(snapshot.next.prayer == .isha)
        #expect(snapshot.passed.contains(.maghrib))
    }

    @Test("zwischen Fadschr und Sonnenaufgang ist der Sonnenaufgang das nächste – wie auf der Zeiten-Seite")
    func sunriseIsNext() throws {
        let snapshot = try snapshot(at: "06:00")
        #expect(snapshot.next.prayer == .sunrise)
        #expect(snapshot.following.prayer == .dhuhr)
        #expect(snapshot.passed == [.fajr])
    }

    // MARK: - Mitternacht

    @Test("nach Ischa: Fadschr von morgen; die Liste zeigt die Zeiten von morgen, nichts abgeblendet")
    func afterIsha() throws {
        let snapshot = try snapshot(at: "23:30")
        #expect(snapshot.previous.prayer == .isha)
        #expect(snapshot.next.prayer == .fajr)
        #expect(snapshot.next.dayOffset == 1)
        #expect(snapshot.list.day == day.adding(days: 1))
        #expect(snapshot.passed.isEmpty)
    }

    @Test("nach Mitternacht vor Fadschr: die Liste zeigt heute, nichts abgeblendet")
    func beforeFajr() throws {
        let snapshot = try snapshot(at: "03:00")
        #expect(snapshot.previous.prayer == .isha)
        #expect(snapshot.previous.dayOffset == -1)
        #expect(snapshot.next.prayer == .fajr)
        #expect(snapshot.list.day == day)
        #expect(snapshot.passed.isEmpty)
    }

    @Test("Nachtmitte: nach Mitternacht kommt noch das Ischa von gestern; die Liste zeigt gestern")
    func middleOfTheNight() throws {
        var settings = CalculationSettings()
        settings.highLatitudeRule = .middle
        let next = FixtureTimes.berlinSummer.day.adding(days: 1)
        let result = result(at: "00:30", on: next, source: FixtureTimesSource(highLatitude: true), settings: settings)
        // Ischa von gestern und Fadschr von heute fallen auf 01:08: ein Eintrag, danach der Sonnenaufgang.
        #expect(summary(result).prefix(3) == ["00:30 isha 01:08", "01:08 sunrise 04:43", "04:43 dhuhr 13:12"])
        guard case .times(let snapshot) = result.entries[0].content else {
            Issue.record("keine Zeiten")
            return
        }
        #expect(snapshot.next.dayOffset == -1)
        #expect(snapshot.list.day == FixtureTimes.berlinSummer.day)
        #expect(snapshot.passed == [.fajr, .sunrise, .dhuhr, .asr, .maghrib])
        #expect(snapshot.following.prayer == .fajr)
    }

    // MARK: - Einstellungen und Orte

    @Test("die Minutenkorrektur gilt auch in den Widgets (Spec § 4)")
    func adjustments() throws {
        var settings = CalculationSettings()
        settings.adjustments = MinuteAdjustments([.maghrib: 3])
        let snapshot = try snapshot(at: "14:25", settings: settings)
        #expect(ClockTime(snapshot.next.date, in: .berlin) == clockTime("16:30"))
        #expect(snapshot.list.clockTime(of: .maghrib) == clockTime("16:30"))
    }

    @Test("Asr nach hanafitischer Rechnung: um 14:25 ist Asr (14:36) das nächste")
    func hanafiAsr() throws {
        var settings = CalculationSettings()
        settings.asr = .hanafi
        let snapshot = try snapshot(at: "14:25", settings: settings)
        #expect(snapshot.next.prayer == .asr)
        #expect(ClockTime(snapshot.next.date, in: .berlin) == clockTime("14:36"))
        #expect(!snapshot.passed.contains(.asr))
    }

    @Test("Jakarta: Tag und Uhrzeiten gelten am Ort, auch von Berlin aus gesehen")
    func jakarta() throws {
        // 23:30 in Berlin ist in Jakarta schon 05:30 am 11.11.: Fadschr und Sonnenaufgang sind vorbei.
        let result = result(at: "23:30", place: fixturePlace("jakarta"), zone: .berlin)
        #expect(summary(result, in: .jakarta).prefix(2) == ["05:30 dhuhr 11:39", "11:39 asr 14:57"])
        guard case .times(let snapshot) = result.entries[0].content else {
            Issue.record("keine Zeiten")
            return
        }
        #expect(snapshot.list.day == day.adding(days: 1))
        #expect(snapshot.passed == [.fajr, .sunrise])
    }

    @Test("Ende der Sommerzeit: der Eintrag für Fadschr liegt um 05:16 Winterzeit")
    func daylightSavingEnd() {
        let saturday = calendarDay("2026-10-24")
        let result = result(at: "20:00", on: saturday)
        #expect(result.entries[1].date == saturday.adding(days: 1).at("05:16", in: .berlin))
        #expect(result.entries[1].date.timeIntervalSince(saturday.at("18:17", in: .berlin)) == minutes(12 * 60 - 1))
    }

    // MARK: - Bogen (Phase 14)

    @Test("der Stand trägt die Tagesphase für den Bogen: um 14:25 läuft Asr, der Knopf steht zwischen Fadschr und Ischa")
    func snapshotPhase() throws {
        let snapshot = try snapshot(at: "14:25")
        #expect(snapshot.phase.highlighted == .asr)
        #expect(snapshot.phase.times.day == day)
        #expect(snapshot.phase.dayProgress.isActive)
        #expect(snapshot.now == day.at("14:25", in: .berlin))
    }

    @Test("mit arcStep: zwischen 14:25 und Maghrib alle 5 Minuten ein Eintrag, dazu der Beginn von Kerahat um 15:42")
    func arcSteps() {
        let result = WidgetTimeline.entries(
            from: day.at("14:25", in: .berlin), source: FixtureTimesSource(), place: berlin,
            settings: CalculationSettings(), arcStep: WidgetTimeline.arcStep
        )
        let untilMaghrib = result.entries.prefix { $0.date < day.at("16:27", in: .berlin) }
        let times = untilMaghrib.map { ClockTime($0.date, in: .berlin).description }
        #expect(times.first == "14:25")
        #expect(times[1] == "14:30")
        #expect(times.contains("15:40") && times.contains("15:42") && times.contains("15:45"))
        #expect(times.last == "16:25")
        // 14:25, 24 Schritte von 14:30 bis 16:25, der Beginn von Kerahat.
        #expect(times.count == 26)
        // Die Zeitleiste holt das Widget wie ohne Schritte beim letzten Ereignis.
        #expect(result.reloadDate == day.adding(days: 1).at("14:00", in: .berlin))
    }

    @Test("mit arcStep: der Knopf rückt in jedem Eintrag weiter, Kerahat läuft ab 15:42")
    func arcStepsAdvance() {
        let result = WidgetTimeline.entries(
            from: day.at("14:25", in: .berlin), source: FixtureTimesSource(), place: berlin,
            settings: CalculationSettings(), arcStep: WidgetTimeline.arcStep
        )
        let phases = result.entries.prefix(26).compactMap { entry -> DayPhase? in
            guard case .times(let snapshot) = entry.content else { return nil }
            return snapshot.phase
        }
        #expect(phases.count == 26)
        let fractions = phases.map(\.dayProgress.fraction)
        #expect(zip(fractions, fractions.dropFirst()).allSatisfy { $0 < $1 })
        let kerahat = phases.map { ClockTime($0.now, in: .berlin).description + ($0.activeKerahat == nil ? "" : " K") }
        #expect(kerahat.contains("15:40") && kerahat.contains("15:42 K") && kerahat.contains("16:25 K"))
    }

    @Test("mit arcStep: zwischen Ischa und Fadschr keine Schritte – der Bogen steht dann ohne Knopf")
    func noArcStepsAtNight() {
        let result = WidgetTimeline.entries(
            from: day.at("18:20", in: .berlin), source: FixtureTimesSource(), place: berlin,
            settings: CalculationSettings(), arcStep: WidgetTimeline.arcStep
        )
        let night = result.entries.prefix { $0.date <= day.adding(days: 1).at("05:16", in: .berlin) }
        #expect(night.map { ClockTime($0.date, in: .berlin).description } == ["18:20", "05:16"])
        // Am nächsten Morgen: Schritte ab 05:20, Kerahat nach Sonnenaufgang beginnt und endet als eigener Eintrag.
        let morning = result.entries.map { ClockTime($0.date, in: .berlin).description }
        #expect(morning.contains("05:20") && morning.contains("07:14") && morning.contains("07:59"))
        // Einen ganzen Tag: gut 13 Stunden zu je 12 Schritten plus Ereignisse und Kerahat – nicht mehr als 200.
        #expect(result.entries.count > 140 && result.entries.count < 200)
    }

    // MARK: - Ohne Zeiten

    @Test("in einer Gegend ohne Zeiten: ein Eintrag mit dem Hinweis, neu gerechnet um Mitternacht")
    func noTimesAtAll() {
        let result = result(at: "14:25", source: StubTimesSource(base: FixtureTimesSource(), missingAll: true))
        #expect(result.entries == [WidgetTimeline.Entry(date: day.at("14:25", in: .berlin), content: .noTimes)])
        #expect(result.reloadDate == day.adding(days: 1).at("00:00", in: .berlin))
    }

    @Test("fehlen die Zeiten von übermorgen, endet die Leiste am nächsten Morgen mit dem Hinweis")
    func missingLaterDay() {
        let source = StubTimesSource(base: FixtureTimesSource(), missing: [day.adding(days: 2)])
        let result = result(at: "14:25", source: source)
        #expect(summary(result) == ["14:25 maghrib 16:27", "16:27 isha 18:17", "18:17 fajr 05:16", "05:16 –"])
        #expect(result.reloadDate == day.adding(days: 2).at("00:00", in: .berlin))
    }

    @Test("fehlen die Zeiten von morgen, zeigt das Widget wie die Zeiten-Seite gleich den Hinweis")
    func missingTomorrow() {
        let source = StubTimesSource(base: FixtureTimesSource(), missing: [day.adding(days: 1)])
        #expect(summary(result(at: "14:25", source: source)) == ["14:25 –"])
    }
}

#endif
