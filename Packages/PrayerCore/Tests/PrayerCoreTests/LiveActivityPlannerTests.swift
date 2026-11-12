#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Welche Live-Aktivitäten die App anmeldet: je Pflichtgebet eine, so viele Minuten vorher wie gewählt,
/// bis 15 Minuten nach Beginn (Spec § 3 „Live Activity“, § 4; Frage 16 entschieden mit dem Plan für
/// Phase 9).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14,
/// Dhuhr 11:52, Asr 14:00, Maghrib 16:27, Ischa 18:17.
@Suite("Live-Aktivität: Plan")
struct LiveActivityPlannerTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixturePlace("berlin")

    private func options(lead: Int = 30, kerahat: Bool = true, offset: TimeInterval = 0) -> LiveActivityPlanner.Options {
        LiveActivityPlanner.Options(
            leadMinutes: lead, cityName: "Berlin", isCurrentLocation: true, showKerahat: kerahat, clockOffset: offset
        )
    }

    private func plan(
        at time: String, on day: CalendarDay? = nil, place: Place? = nil, zone: TimeZone = .berlin,
        source: any PrayerTimesSource = FixtureTimesSource(), settings: CalculationSettings = CalculationSettings(),
        lead: Int = 30, kerahat: Bool = true, offset: TimeInterval = 0
    ) -> [LiveActivityPlan] {
        LiveActivityPlanner(source: source).plan(
            at: (day ?? self.day).at(time, in: zone), place: place ?? berlin, settings: settings,
            options: options(lead: lead, kerahat: kerahat, offset: offset)
        )
    }

    /// „maghrib 2026-11-10 15:57–16:27–16:42“ – Gebet, Tag, Start, Gebetsbeginn und Ende in `zone`.
    private func summary(_ plans: some Sequence<LiveActivityPlan>, in zone: TimeZone = .berlin) -> [String] {
        plans.map {
            "\($0.prayer.rawValue) \($0.day) \(ClockTime($0.start, in: zone))–\(ClockTime($0.prayerDate, in: zone))–\(ClockTime($0.end, in: zone))"
        }
    }

    // MARK: - Startwerte

    @Test("14:25, 30 Min. vorher – je Gebet eine Aktivität, die in den nächsten 24 Stunden beginnt, ohne Sonnenaufgang")
    func startValues() {
        #expect(summary(plan(at: "14:25")) == [
            "maghrib 2026-11-10 15:57–16:27–16:42",
            "isha 2026-11-10 17:47–18:17–18:32",
            "fajr 2026-11-11 04:46–05:16–05:31",
            "dhuhr 2026-11-11 11:22–11:52–12:07",
            "asr 2026-11-11 13:30–14:00–14:15",
        ])
    }

    @Test("die Kennung bleibt für dasselbe Gebet gleich, auch wenn später neu geplant wird")
    func identifiers() {
        #expect(plan(at: "14:25").map(\.id).prefix(2) == ["live.2026-11-10.maghrib", "live.2026-11-10.isha"])
        #expect(plan(at: "15:00").map(\.id).prefix(2) == ["live.2026-11-10.maghrib", "live.2026-11-10.isha"])
    }

    @Test("Aus – keine Live-Aktivität")
    func off() {
        #expect(plan(at: "14:25", lead: 0).isEmpty)
    }

    @Test("der Vorlauf gilt, wie gewählt", arguments: NotificationPreferences.liveActivityChoices.filter { $0 > 0 })
    func lead(minutes: Int) throws {
        let dhuhr = try #require(plan(at: "06:00", lead: minutes).first)
        #expect(dhuhr.prayer == .dhuhr)
        #expect(dhuhr.prayerDate.timeIntervalSince(dhuhr.start) == TimeInterval(minutes * 60))
        #expect(dhuhr.leadMinutes == minutes)
    }

    @Test("60 statt 30 Minuten: Maghrib beginnt um 15:27")
    func sixtyMinutes() {
        #expect(summary(plan(at: "14:25", lead: 60).prefix(1)) == ["maghrib 2026-11-10 15:27–16:27–16:42"])
    }

    @Test("bei langem Vorlauf beginnt Ischa erst, wenn die Aktivität für Maghrib endet")
    func noOverlap() {
        #expect(summary(plan(at: "14:25", lead: 120).prefix(2)) == [
            "maghrib 2026-11-10 14:27–16:27–16:42",
            "isha 2026-11-10 16:42–18:17–18:32",
        ])
    }

    @Test("Jakarta: Maghrib und Ischa liegen 72 Minuten auseinander – mit 60 Min. Vorlauf beginnt Ischa um 18:04")
    func jakarta() {
        let jakarta = fixturePlace("jakarta")
        #expect(summary(plan(at: "12:00", place: jakarta, zone: .jakarta, lead: 60).prefix(3), in: .jakarta) == [
            "asr 2026-11-10 13:57–14:57–15:12",
            "maghrib 2026-11-10 16:49–17:49–18:04",
            "isha 2026-11-10 18:04–19:01–19:16",
        ])
        // 23:30 in Berlin ist in Jakarta schon 05:30 am 11.11.: als Nächstes Dhuhr.
        #expect(summary(plan(at: "23:30", place: jakarta, zone: .berlin).prefix(1), in: .jakarta) == [
            "dhuhr 2026-11-11 11:09–11:39–11:54",
        ])
    }

    @Test("iOS nimmt höchstens fünf an: um 15:45 mit 60 Min. Vorlauf fällt Maghrib von morgen weg")
    func systemLimit() {
        #expect(LiveActivityPlanner.systemLimit == 5)
        #expect(summary(plan(at: "15:45", lead: 60)).map { String($0.prefix(18)) } == [
            "maghrib 2026-11-10", "isha 2026-11-10 17", "fajr 2026-11-11 04", "dhuhr 2026-11-11 1", "asr 2026-11-11 13:",
        ])
    }

    @Test("eine Aktivität, deren Gebet begonnen hat, zählt nicht mit – um 16:30 kommen noch fünf dazu")
    func begunDoesNotCount() {
        let plans = plan(at: "16:30")
        #expect(plans.count == 6)
        #expect(plans.first?.prayer == .maghrib)
        #expect(plans.last?.id == "live.2026-11-11.maghrib")
    }

    // MARK: - Laufende Aktivitäten

    @Test("läuft der Vorlauf schon, beginnt die Aktivität sofort; ihr Bogen zeigt den Stand von jetzt")
    func alreadyRunning() throws {
        let maghrib = try #require(plan(at: "16:10").first)
        #expect(maghrib.prayer == .maghrib)
        #expect(maghrib.start == day.at("15:57", in: .berlin))
        #expect(maghrib.content.countdown.now == day.at("16:10", in: .berlin))
    }

    @Test("bis 15 Minuten nach Beginn bleibt die Aktivität im Plan, danach nicht mehr")
    func endsAfterFifteenMinutes() {
        #expect(plan(at: "16:41").first?.prayer == .maghrib)
        #expect(plan(at: "16:42").first?.prayer == .isha)
    }

    // MARK: - Inhalt

    @Test("der Bogen zeigt bis zum Beginn den Stand beim Start, ab Beginn läuft das Gebet")
    func phases() throws {
        let maghrib = try #require(plan(at: "14:25").first)
        #expect(maghrib.content.countdown.now == day.at("15:57", in: .berlin))
        #expect(maghrib.content.countdown.highlighted == .asr)
        #expect(maghrib.content.begun.now == day.at("16:27", in: .berlin))
        #expect(maghrib.content.begun.highlighted == .maghrib)
        #expect(maghrib.content.prayer.prayer == .maghrib)
        #expect(maghrib.content.previous.prayer == .asr)
        #expect(maghrib.content.prayerTime == clockTime("16:27"))
        #expect(maghrib.content.previousTime == clockTime("14:00"))
        #expect(!maghrib.content.isTomorrow)
        #expect(!maghrib.content.hasBegun)
        #expect(maghrib.content.markedBegun.hasBegun)
        #expect(maghrib.content.cityName == "Berlin")
    }

    @Test("Kerahat vor Maghrib: unter dem Balken von Asr bis Maghrib die letzten 45 Minuten")
    func kerahatBeforeMaghrib() throws {
        let maghrib = try #require(plan(at: "14:25").first)
        // 14:00 → 16:27 sind 147 Minuten; das Fenster beginnt um 15:42.
        let mark = try #require(maghrib.content.kerahat.first)
        #expect(maghrib.content.kerahat.count == 1)
        #expect(abs(mark.start - 102.0 / 147.0) < 1e-9)
        #expect(abs(mark.length - 45.0 / 147.0) < 1e-9)
    }

    @Test("vor Dhuhr beginnt der Balken beim Sonnenaufgang, mit zwei Kerahat-Fenstern")
    func kerahatBeforeDhuhr() throws {
        let dhuhr = try #require(plan(at: "06:00").first)
        #expect(dhuhr.content.previous.prayer == .sunrise)
        // 07:14 → 11:52 sind 278 Minuten: 45 nach dem Sonnenaufgang, 10 vor Dhuhr.
        #expect(dhuhr.content.kerahat.map { ($0.start * 278).rounded() } == [0, 268])
        #expect(dhuhr.content.kerahat.map { ($0.length * 278).rounded() } == [45, 10])
    }

    @Test("ohne Kerahat-Schalter keine Marken")
    func kerahatOff() throws {
        let maghrib = try #require(plan(at: "14:25", kerahat: false).first)
        #expect(maghrib.content.kerahat.isEmpty)
        #expect(!maghrib.content.showKerahat)
    }

    @Test("Abstand der Debug-Uhr: Countdown und Balken laufen in Gerätezeit, die Uhrzeiten bleiben")
    func clockOffset() throws {
        let maghrib = try #require(plan(at: "14:25", offset: 3600).first)
        #expect(maghrib.content.deviceCountdownEnd == day.at("15:27", in: .berlin))
        #expect(maghrib.content.deviceBarInterval == day.at("13:00", in: .berlin)...day.at("15:27", in: .berlin))
        #expect(maghrib.content.prayerTime == clockTime("16:27"))
    }

    @Test("der Inhalt lässt sich speichern und kommt gleich zurück")
    func codable() throws {
        let content = try #require(plan(at: "14:25").first).content
        let data = try JSONEncoder().encode(content)
        #expect(try JSONDecoder().decode(LiveActivityContent.self, from: data) == content)
    }

    // MARK: - Mitternacht und hohe Breiten

    @Test("Fadschr kurz nach Mitternacht: die Aktivität beginnt am Vortag und sagt „Fadschr (morgen) in“")
    func tomorrow() throws {
        let source = StubTimesSource(times: ["00:05", "06:30", "12:00", "15:00", "18:00", "20:00"])
        let fajr = try #require(plan(at: "22:00", source: source).first)
        #expect(fajr.prayer == .fajr)
        #expect(fajr.day == day.adding(days: 1))
        #expect(ClockTime(fajr.start, in: .berlin) == clockTime("23:35"))
        #expect(fajr.content.isTomorrow)
        // Mit den Mock-Zeiten beginnt die Aktivität für Fadschr um 04:46, am Tag des Gebets.
        let regular = try #require(plan(at: "23:30").first)
        #expect(regular.prayer == .fajr)
        #expect(!regular.content.isTomorrow)
    }

    @Test("Nachtmitte: Ischa von gestern und Fadschr fallen auf 01:08 – zwei Aktivitäten, die sich überlappen")
    func middleOfTheNight() throws {
        var settings = CalculationSettings()
        settings.highLatitudeRule = .middle
        let summer = FixtureTimes.berlinSummer.day
        let plans = plan(at: "23:00", on: summer, source: FixtureTimesSource(highLatitude: true), settings: settings)
        #expect(summary(plans.prefix(2)) == [
            "isha 2027-06-21 00:38–01:08–01:23",
            "fajr 2027-06-22 00:38–01:08–01:23",
        ])
        #expect(plans[0].id != plans[1].id)
        #expect(plans[0].content.prayer.dayOffset == -1)
    }

    @Test("Beginn der Sommerzeit: Fadschr am 28.03.2027 um 05:16 Sommerzeit, die Aktivität 30 Minuten vorher")
    func daylightSavingStart() throws {
        let fajr = try #require(plan(at: "20:00", on: calendarDay("2027-03-27")).first)
        #expect(summary([fajr]) == ["fajr 2027-03-28 04:46–05:16–05:31"])
        #expect(fajr.prayerDate.timeIntervalSince(fajr.start) == minutes(30))
    }

    @Test("fehlen die Zeiten von morgen, fehlt der Zeitstrahl um heute – keine Aktivität")
    func missingTomorrow() {
        let source = StubTimesSource(base: FixtureTimesSource(), missing: [day.adding(days: 1)])
        #expect(plan(at: "14:25", source: source).isEmpty)
    }

    @Test("in einer Gegend ohne Zeiten bleibt der Plan leer")
    func noTimesAtAll() {
        #expect(plan(at: "14:25", source: StubTimesSource(base: FixtureTimesSource(), missingAll: true)).isEmpty)
    }

    // MARK: - -debugLiveActivity

    @Test("-debugLiveActivity: genau eine Aktivität, die zum nächsten Gebet, ab dem Start der App")
    func debugStart() {
        let planner = LiveActivityPlanner(source: FixtureTimesSource())
        func debugPlan(launch: String, now: String? = nil, lead: Int = 30) -> [LiveActivityPlan] {
            let launch = day.at(launch, in: .berlin)
            return planner.plan(
                at: now.map { day.at($0, in: .berlin) } ?? launch, place: berlin, settings: CalculationSettings(),
                options: options(lead: lead), debugStart: launch
            )
        }
        // system/93: um 14:25 zählt sie auf Maghrib, im Bogen läuft Asr.
        #expect(summary(debugPlan(launch: "14:25")) == ["maghrib 2026-11-10 14:25–16:27–16:42"])
        #expect(debugPlan(launch: "14:25").first?.content.countdown.highlighted == .asr)
        // system/96: um 16:35 läuft Maghrib, sie zählt auf Ischa.
        #expect(summary(debugPlan(launch: "16:35")) == ["isha 2026-11-10 16:35–18:17–18:32"])
        #expect(debugPlan(launch: "16:35").first?.content.countdown.highlighted == .maghrib)
        // Auch wenn die Live-Aktivität aus ist; nach ihrem Ende kommt keine weitere.
        #expect(debugPlan(launch: "14:25", lead: 0).count == 1)
        #expect(debugPlan(launch: "14:25", now: "16:42").isEmpty)
    }
}

#endif
