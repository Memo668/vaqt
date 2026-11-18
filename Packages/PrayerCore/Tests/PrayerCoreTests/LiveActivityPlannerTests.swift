#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Welche Live-Aktivitäten die App anmeldet: je Pflichtgebet eine, so viele Minuten vorher wie gewählt, bis
/// zum Gebetsbeginn; bei Dhuhr und Maghrib, wenn ihre Verbotszeit in die Strecke fällt, eine grüne bis zu
/// deren Beginn und eine orange bis zum Gebet (Spec § 3 „Live Activity“, § 4, § 10.3).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14,
/// Dhuhr 11:52, Asr 14:00, Maghrib 16:27, Ischa 18:17. Verbotszeiten: 07:14–07:59, 11:42–11:52, 15:42–16:27.
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

    /// „maghrib 2026-11-10 15:57–16:27–16:27 orange“ – Gebet, Tag, Start, Gebetsbeginn, Wechsel in `zone` und
    /// der Teil: grün vor einer Verbotszeit, orange in ihr, sonst nichts.
    private func summary(_ plans: some Sequence<LiveActivityPlan>, in zone: TimeZone = .berlin) -> [String] {
        plans.map {
            let kind = switch $0.content.kind {
            case .regular: ""
            case .beforeProhibited: " grün"
            case .prohibited: " orange"
            }
            return "\($0.prayer.rawValue) \($0.day) \(ClockTime($0.start, in: zone))–\(ClockTime($0.prayerDate, in: zone))–\(ClockTime($0.end, in: zone))\(kind)"
        }
    }

    // MARK: - Startwerte

    @Test("14:25, 30 Min. vorher – Maghrib ganz in der Verbotszeit, Dhuhr in zwei Teilen, höchstens fünf")
    func startValues() {
        #expect(summary(plan(at: "14:25")) == [
            "maghrib 2026-11-10 15:57–16:27–16:27 orange",
            "isha 2026-11-10 17:47–18:17–18:17",
            "fajr 2026-11-11 04:46–05:16–05:16",
            "dhuhr 2026-11-11 11:22–11:52–11:42 grün",
            "dhuhr 2026-11-11 11:42–11:52–11:52 orange",
        ])
    }

    @Test("die Kennung bleibt für dasselbe Gebet gleich, auch wenn später neu geplant wird; der orange Teil hängt .verbot an")
    func identifiers() {
        #expect(plan(at: "14:25").map(\.id).prefix(2) == ["live.2026-11-10.maghrib.verbot", "live.2026-11-10.isha"])
        #expect(plan(at: "15:00").map(\.id).prefix(2) == ["live.2026-11-10.maghrib.verbot", "live.2026-11-10.isha"])
        #expect(plan(at: "14:25").map(\.id).suffix(2) == ["live.2026-11-11.dhuhr", "live.2026-11-11.dhuhr.verbot"])
    }

    @Test("die neueste Aktivität hat die höchste Relevanz – sie steht oben und in der Dynamic Island")
    func relevance() {
        let plans = plan(at: "14:25")
        #expect(plans.map(\.relevance) == plans.map(\.relevance).sorted())
        #expect(Set(plans.map(\.relevance)).count == plans.count)
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

    @Test("60 statt 30 Minuten: Maghrib beginnt um 15:27 grün, um 15:42 orange")
    func sixtyMinutes() {
        #expect(summary(plan(at: "14:25", lead: 60).prefix(2)) == [
            "maghrib 2026-11-10 15:27–16:27–15:42 grün",
            "maghrib 2026-11-10 15:42–16:27–16:27 orange",
        ])
    }

    @Test("bei langem Vorlauf beginnt Ischa erst mit Maghrib")
    func noOverlap() {
        #expect(summary(plan(at: "14:25", lead: 120).prefix(3)) == [
            "maghrib 2026-11-10 14:27–16:27–15:42 grün",
            "maghrib 2026-11-10 15:42–16:27–16:27 orange",
            "isha 2026-11-10 16:27–18:17–18:17",
        ])
    }

    @Test("Jakarta: Maghrib und Ischa liegen 72 Minuten auseinander – mit 60 Min. Vorlauf beginnt Ischa um 18:01")
    func jakarta() {
        let jakarta = fixturePlace("jakarta")
        #expect(summary(plan(at: "12:00", place: jakarta, zone: .jakarta, lead: 60).prefix(4), in: .jakarta) == [
            "asr 2026-11-10 13:57–14:57–14:57",
            "maghrib 2026-11-10 16:49–17:49–17:04 grün",
            "maghrib 2026-11-10 17:04–17:49–17:49 orange",
            "isha 2026-11-10 18:01–19:01–19:01",
        ])
        // 23:30 in Berlin ist in Jakarta schon 05:30 am 11.11.: als Nächstes Dhuhr, grün bis zur Verbotszeit.
        #expect(summary(plan(at: "23:30", place: jakarta, zone: .berlin).prefix(1), in: .jakarta) == [
            "dhuhr 2026-11-11 11:09–11:39–11:29 grün",
        ])
    }

    @Test("iOS nimmt höchstens fünf an, beide Teile zählen: um 15:45 mit 60 Min. Vorlauf bis Dhuhr von morgen")
    func systemLimit() {
        #expect(LiveActivityPlanner.systemLimit == 5)
        #expect(summary(plan(at: "15:45", lead: 60)) == [
            "maghrib 2026-11-10 15:42–16:27–16:27 orange",
            "isha 2026-11-10 17:17–18:17–18:17",
            "fajr 2026-11-11 04:16–05:16–05:16",
            "dhuhr 2026-11-11 10:52–11:52–11:42 grün",
            "dhuhr 2026-11-11 11:42–11:52–11:52 orange",
        ])
    }

    @Test("hat das Gebet begonnen, ist seine Aktivität nicht mehr im Plan – um 16:30 kommen fünf neue")
    func begunLeavesThePlan() {
        let plans = plan(at: "16:30")
        #expect(plans.count == 5)
        #expect(plans.first?.prayer == .isha)
        #expect(plans.last?.id == "live.2026-11-11.asr")
    }

    // MARK: - Laufende Aktivitäten

    @Test("läuft der Vorlauf schon, beginnt die Aktivität sofort; ihr Bogen zeigt den Stand von jetzt")
    func alreadyRunning() throws {
        let maghrib = try #require(plan(at: "16:10").first)
        #expect(maghrib.prayer == .maghrib)
        #expect(maghrib.start == day.at("15:57", in: .berlin))
        #expect(maghrib.content.countdown.now == day.at("16:10", in: .berlin))
        #expect(maghrib.content.isProhibited)
    }

    @Test("zum Gebetsbeginn wechselt die Aktivität und fällt aus dem Plan; die grüne schon zur Verbotszeit")
    func endsAtTheChange() {
        #expect(plan(at: "16:26").first?.prayer == .maghrib)
        #expect(plan(at: "16:27").first?.prayer == .isha)
        #expect(summary(plan(at: "11:41", lead: 30).prefix(2)) == [
            "dhuhr 2026-11-10 11:22–11:52–11:42 grün", "dhuhr 2026-11-10 11:42–11:52–11:52 orange",
        ])
        #expect(summary(plan(at: "11:42", lead: 30).prefix(1)) == ["dhuhr 2026-11-10 11:42–11:52–11:52 orange"])
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
        // Spec § 10.3: ganz in der Verbotszeit (ab 15:42) – orange, Wechsel zum Gebetsbeginn.
        #expect(maghrib.content.kind == .prohibited)
        #expect(maghrib.content.prohibitedStart == day.at("15:42", in: .berlin))
        #expect(maghrib.content.prohibitedStartTime == clockTime("15:42"))
        #expect(maghrib.content.staleDate == day.at("16:27", in: .berlin))
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
        // Grün bis 11:42; der orange Teil ab dort, beide zählen auf 11:52.
        #expect(dhuhr.content.kind == .beforeProhibited)
        #expect(dhuhr.content.staleDate == day.at("11:42", in: .berlin))
        let orange = try #require(plan(at: "06:00").dropFirst().first)
        #expect(orange.prayer == .dhuhr && orange.content.kind == .prohibited)
        #expect(orange.start == day.at("11:42", in: .berlin))
    }

    @Test("ohne Kerahat-Schalter keine Marken")
    func kerahatOff() throws {
        let maghrib = try #require(plan(at: "14:25", kerahat: false).first)
        #expect(maghrib.content.kerahat.isEmpty)
        #expect(!maghrib.content.showKerahat)
        // Ohne Kerahat auch kein Orange: eine grüne Aktivität bis zum Gebet.
        #expect(maghrib.content.kind == .regular)
        #expect(maghrib.id == "live.2026-11-10.maghrib")
    }

    @Test("Abstand der Debug-Uhr: Countdown und Balken laufen in Gerätezeit, die Uhrzeiten bleiben")
    func clockOffset() throws {
        let maghrib = try #require(plan(at: "14:25", offset: 3600).first)
        #expect(maghrib.content.deviceCountdownEnd == day.at("15:27", in: .berlin))
        #expect(maghrib.content.deviceBarInterval == day.at("13:00", in: .berlin)...day.at("15:27", in: .berlin))
        #expect(maghrib.content.prayerTime == clockTime("16:27"))
        #expect(maghrib.content.deviceStaleDate == day.at("15:27", in: .berlin))
    }

    @Test("der Inhalt lässt sich speichern und kommt gleich zurück")
    func codable() throws {
        let content = try #require(plan(at: "14:25").first).content
        let data = try JSONEncoder().encode(content)
        #expect(try JSONDecoder().decode(LiveActivityContent.self, from: data) == content)
    }

    @Test("ein Inhalt aus Build 2 ohne Teil und Verbotszeit gilt als grün bis zum Gebet")
    func decodesOlderContent() throws {
        let content = try #require(plan(at: "14:25", kerahat: false).first).content
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(content)) as? [String: Any])
        json["segment"] = nil
        json["prohibitedStart"] = nil
        let old = try JSONDecoder().decode(LiveActivityContent.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.kind == .regular)
        #expect(old.staleDate == old.prayer.date)
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
            "isha 2027-06-21 00:38–01:08–01:08",
            "fajr 2027-06-22 00:38–01:08–01:08",
        ])
        #expect(plans[0].id != plans[1].id)
        #expect(plans[0].content.prayer.dayOffset == -1)
    }

    @Test("Beginn der Sommerzeit: Fadschr am 28.03.2027 um 05:16 Sommerzeit, die Aktivität 30 Minuten vorher")
    func daylightSavingStart() throws {
        let fajr = try #require(plan(at: "20:00", on: calendarDay("2027-03-27")).first)
        #expect(summary([fajr]) == ["fajr 2027-03-28 04:46–05:16–05:16"])
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

    @Test("-debugLiveActivity: die Aktivität zum nächsten Gebet ab dem Start der App, bei Maghrib in zwei Teilen")
    func debugStart() {
        let planner = LiveActivityPlanner(source: FixtureTimesSource())
        func debugPlan(launch: String, now: String? = nil, lead: Int = 30) -> [LiveActivityPlan] {
            let launch = day.at(launch, in: .berlin)
            return planner.plan(
                at: now.map { day.at($0, in: .berlin) } ?? launch, place: berlin, settings: CalculationSettings(),
                options: options(lead: lead), debugStart: launch
            )
        }
        // system/93: um 14:25 zählt sie auf Maghrib, im Bogen läuft Asr; ab 15:42 der orange Teil.
        #expect(summary(debugPlan(launch: "14:25")) == [
            "maghrib 2026-11-10 14:25–16:27–15:42 grün", "maghrib 2026-11-10 15:42–16:27–16:27 orange",
        ])
        #expect(debugPlan(launch: "14:25").first?.content.countdown.highlighted == .asr)
        // system/96: um 16:35 läuft Maghrib, sie zählt auf Ischa.
        #expect(summary(debugPlan(launch: "16:35")) == ["isha 2026-11-10 16:35–18:17–18:17"])
        #expect(debugPlan(launch: "16:35").first?.content.countdown.highlighted == .maghrib)
        // Auch wenn die Live-Aktivität aus ist; nach dem Gebetsbeginn kommt keine weitere.
        #expect(debugPlan(launch: "14:25", lead: 0).count == 2)
        #expect(debugPlan(launch: "14:25", now: "16:27").isEmpty)
    }
}

#endif
