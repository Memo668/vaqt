#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Widgets und Live-Aktivität aus der Sicht der App: Was sie für die Extension schreibt und welche
/// Aktivitäten sie anmeldet, ersetzt und beendet (Plan für Phase 9).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Asr 14:00, Maghrib 16:27, Ischa 18:17.
@MainActor
@Suite("Widgets und Live-Aktivität")
struct OutsideAppTests {

    struct Fixture {
        let settings: SettingsStore
        let location: PlaceModel
        let clock: TestClock
        let scheduler: RecordingLiveActivityScheduler
        let model: LiveActivityModel
    }

    private func fixture(
        time: String = "14:25", place: Place? = .berlin, lead: Int = 30, isPlanning: Bool = true,
        debugStart: Date? = nil
    ) -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        snapshot.autoLocation = false
        snapshot.manualPlace = place
        snapshot.notifications.liveActivityMinutes = lead
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let location = PlaceModel(settings: settings, locationSource: FixedLocationSource(place: nil, status: .notDetermined))
        let clock = TestClock(instant("2026-11-10", time))
        let scheduler = RecordingLiveActivityScheduler(clock: clock)
        let model = LiveActivityModel(
            settings: settings, location: location, clock: clock, timesSource: FixtureTimesSource(),
            scheduler: scheduler, isPlanning: isPlanning, debugStart: debugStart
        )
        return Fixture(settings: settings, location: location, clock: clock, scheduler: scheduler, model: model)
    }

    // MARK: - Live-Aktivität

    @Test("30 Min. vorher: fünf Aktivitäten angemeldet, die erste für Maghrib ab 15:57, noch geplant")
    func startValues() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        #expect(fixture.scheduler.activities.map(\.planID) == [
            "live.2026-11-10.maghrib", "live.2026-11-10.isha", "live.2026-11-11.fajr",
            "live.2026-11-11.dhuhr", "live.2026-11-11.asr",
        ])
        let maghrib = try #require(fixture.scheduler.activities.first)
        #expect(maghrib.start == instant("2026-11-10", "15:57"))
        #expect(maghrib.isPending)
        #expect(fixture.model.nextCheck == instant("2026-11-10", "16:27"))
    }

    @Test("der Hinweis beim geplanten Start hat die Texte der Vorab-Erinnerung")
    func alertTexts() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        let alert = try #require(fixture.scheduler.alerts.first)
        #expect(alert.title == L10n.notifReminderTitle(p: L10n.p_maghrib, n: "30"))
        #expect(alert.body == L10n.notifReminderBody(p: L10n.p_maghrib, at: try #require(ClockTime("16:27"))))
    }

    @Test("ein zweites Planen ohne Änderung meldet nichts neu an")
    func stable() async {
        let fixture = fixture()
        await fixture.model.reschedule()
        fixture.clock.now = instant("2026-11-10", "14:40")
        await fixture.model.reschedule()
        #expect(fixture.scheduler.performed.last?.isEmpty == true)
    }

    @Test("von 30 auf 60 Min.: die geplanten werden ersetzt, Maghrib beginnt um 15:27")
    func leadChange() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        fixture.settings.updateNotifications { $0.liveActivityMinutes = 60 }
        await fixture.model.reschedule()
        let maghrib = try #require(fixture.scheduler.activities.first { $0.planID == "live.2026-11-10.maghrib" })
        #expect(maghrib.start == instant("2026-11-10", "15:27"))
        #expect(fixture.scheduler.activities.count == 5)
    }

    @Test("Aus: alle Aktivitäten enden, auch die laufende")
    func off() async {
        let fixture = fixture(time: "16:00")
        await fixture.model.reschedule()
        #expect(fixture.scheduler.activities.first?.isPending == false)
        fixture.settings.updateNotifications { $0.liveActivityMinutes = 0 }
        await fixture.model.reschedule()
        #expect(fixture.scheduler.activities.isEmpty)
        #expect(fixture.model.planned.isEmpty)
        #expect(fixture.model.nextCheck == nil)
    }

    @Test("zum Gebetsbeginn endet die Aktivität und bleibt mit „Jetzt“ bis 15 Min. danach stehen")
    func endsAtPrayer() async throws {
        let fixture = fixture(time: "16:00")
        await fixture.model.reschedule()
        fixture.clock.now = instant("2026-11-10", "16:27")
        await fixture.model.reschedule()
        let ending = try #require(fixture.scheduler.performed.last?.first)
        guard case .end(_, let content, let dismissAt) = ending else {
            Issue.record("erwartet: Ende der Aktivität für Maghrib, war \(ending)")
            return
        }
        #expect(content?.hasBegun == true)
        #expect(dismissAt == instant("2026-11-10", "16:42"))
        #expect(!fixture.scheduler.activities.contains { $0.planID == "live.2026-11-10.maghrib" })
        #expect(fixture.model.nextCheck == instant("2026-11-10", "18:17"))
    }

    @Test("sind Live-Aktivitäten in den iOS-Einstellungen aus, geschieht nichts")
    func disabled() async {
        let fixture = fixture()
        fixture.scheduler.enabled = false
        await fixture.model.reschedule()
        #expect(fixture.scheduler.performed.isEmpty)
        #expect(fixture.model.planned.isEmpty)
    }

    @Test("ohne Ort keine Live-Aktivität")
    func noPlace() async {
        let fixture = fixture(place: nil)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.activities.isEmpty)
    }

    @Test("Mock-Zeiten ohne -debugLiveActivity: nichts geplant, was noch läuft, endet")
    func notPlanning() async {
        let running = fixture()
        await running.model.reschedule()
        let model = LiveActivityModel(
            settings: running.settings, location: running.location, clock: running.clock,
            timesSource: FixtureTimesSource(), scheduler: running.scheduler, isPlanning: false
        )
        await model.reschedule()
        #expect(running.scheduler.activities.isEmpty)
    }

    @Test("-debugLiveActivity: genau eine Aktivität zum nächsten Gebet, sofort gestartet")
    func debugStart() async throws {
        let start = instant("2026-11-10", "14:25")
        let fixture = fixture(lead: 0, debugStart: start)
        await fixture.model.reschedule()
        let maghrib = try #require(fixture.scheduler.activities.first)
        #expect(fixture.scheduler.activities.count == 1)
        #expect(maghrib.planID == "live.2026-11-10.maghrib")
        #expect(!maghrib.isPending)
        #expect(maghrib.content.countdown.highlighted == .asr)
    }

    @Test("was eingeht: Vorlauf, Ort, Kerahat und Sprache")
    func inputs() {
        let fixture = fixture()
        let before = fixture.model.inputs
        fixture.settings.updateNotifications { $0.liveActivityMinutes = 45 }
        #expect(fixture.model.inputs != before)
        let lead = fixture.model.inputs
        fixture.settings.setShowKerahat(false)
        #expect(fixture.model.inputs != lead)
        let kerahat = fixture.model.inputs
        fixture.settings.select(.istanbul)
        #expect(fixture.model.inputs != kerahat)
        #expect(fixture.model.inputs.cityName == "Istanbul")
        #expect(!fixture.model.inputs.isCurrentLocation)
    }

    // MARK: - Widgets

    @Test("der Stand der Widgets: Ort, Name, Berechnung, Kerahat und die Sprache der App")
    func widgetState() throws {
        let fixture = fixture()
        fixture.settings.updateCalculation { $0.adjustments.step(.maghrib, by: 3) }
        fixture.settings.setShowKerahat(false)
        let publisher = RecordingWidgetPublisher()
        let sync = WidgetSync(settings: fixture.settings, location: fixture.location, clock: SystemClock(), publisher: publisher)
        sync.publish()
        let state = try #require(publisher.states.last)
        #expect(state.place == .berlin)
        #expect(state.cityName == "Berlin")
        #expect(!state.isCurrentLocation)
        #expect(state.calculation.adjustments[.maghrib] == 3)
        #expect(!state.showKerahat)
        #expect(state.language == L10n.currentLanguage)
        #expect(state.debug == nil)
    }

    @Test("Mock-Zeiten und Debug-Uhr gehen mit, damit die Widgets dieselben Zahlen zeigen")
    func widgetDebug() {
        let fixture = fixture()
        let clock = DebugClock(startingAt: instant("2026-11-10", "14:25"), systemNow: Date())
        let publisher = RecordingWidgetPublisher()
        let sync = WidgetSync(
            settings: fixture.settings, location: fixture.location, clock: clock, publisher: publisher,
            debug: WidgetSync.Debug(fixtureTimes: true, highLatitude: false)
        )
        sync.publish()
        let debug = publisher.states.last?.debug
        #expect(debug?.fixtureTimes == true)
        #expect(debug?.highLatitude == false)
        #expect(abs((debug?.clockOffset ?? 0) - clock.offset) < 0.001)
    }

    @Test("der Abstand der Debug-Uhr ist auf Millisekunden gerundet, damit die Widgets nicht ständig neu laden")
    func roundedOffset() {
        #expect(WidgetSync.clockOffset(of: SystemClock()) == 0)
        let clock = DebugClock(startingAt: Date(timeIntervalSinceNow: -123.456_789))
        #expect(WidgetSync.clockOffset(of: clock) == -123.457)
    }

    // MARK: - Hintergrundaktualisierung

    @Test("die App bittet um die nächste Hintergrundaktualisierung zum Ende der nächsten Aktivität, höchstens in zwölf Stunden")
    func backgroundRefresh() {
        let now = instant("2026-11-10", "14:25")
        #expect(BackgroundRefresh.earliestBeginDate(now: now, liveActivityCheck: nil) == now.addingTimeInterval(12 * 3600))
        let check = instant("2026-11-10", "16:42")
        #expect(BackgroundRefresh.earliestBeginDate(now: now, liveActivityCheck: check) == check)
        #expect(BackgroundRefresh.earliestBeginDate(now: now, liveActivityCheck: now.addingTimeInterval(-60)) == now.addingTimeInterval(12 * 3600))
        #expect(BackgroundRefresh.earliestBeginDate(now: now, liveActivityCheck: now.addingTimeInterval(13 * 3600)) == now.addingTimeInterval(12 * 3600))
    }

    // MARK: - Debug-Argumente

    @Test("-debugLiveActivity wird verstanden")
    func launchOption() {
        let options = LaunchOptions(arguments: ["-debugFixtureTimes", "-debugLiveActivity", "-debugTime", "14:25"])
        #expect(options.liveActivity)
        #expect(options.problems.isEmpty)
    }

    @Test("Mock-Zeiten ohne -debugLiveActivity: keine Live-Aktivität; Widgets mit Mock-Zeiten")
    func fixtureEnvironment() {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugFixtureTimes", "-debugHighLatitude"]))
        #expect(!environment.plansLiveActivities)
        #expect(environment.liveActivityDebugStart == nil)
        #expect(environment.liveActivityScheduler is SystemLiveActivityScheduler)
        #expect(environment.widgetPublisher is AppGroupWidgetPublisher)
        #expect(environment.widgetDebug == WidgetSync.Debug(fixtureTimes: true, highLatitude: true))
    }

    @Test("-debugLiveActivity: die Aktivität beginnt beim Start der App")
    func debugLiveActivityEnvironment() throws {
        let environment = AppEnvironment(options: LaunchOptions(arguments: [
            "-debugFixtureTimes", "-debugLiveActivity", "-debugDate", "2026-11-10", "-debugTime", "14:25",
        ]))
        #expect(environment.plansLiveActivities)
        let start = try #require(environment.liveActivityDebugStart)
        #expect(abs(start.timeIntervalSince(instant("2026-11-10", "14:25"))) < 5)
    }

    @Test("ohne Mock-Zeiten plant die App echt")
    func realEnvironment() {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugCity", "berlin"]))
        #expect(environment.plansLiveActivities)
        #expect(environment.widgetDebug == nil)
        #expect(AppEnvironment.live.liveActivityScheduler is SystemLiveActivityScheduler)
        #expect(AppEnvironment.live.widgetPublisher is AppGroupWidgetPublisher)
    }
}

// MARK: - Attrappen

/// Bildet die Live-Aktivitäten von iOS im Speicher nach: Angemeldete stehen hier, bis sie enden; vor ihrem
/// Start sind sie geplant (`isPending`).
@MainActor
final class RecordingLiveActivityScheduler: LiveActivityScheduling {
    private struct Activity {
        let id: String
        let planID: String
        let start: Date
        var content: LiveActivityContent
    }

    private let clock: any AppClock
    private var stored: [Activity] = []
    private var nextID = 0

    var enabled = true
    /// Je Aufruf die Schritte.
    private(set) var performed: [[LiveActivityLifecycle.Action]] = []
    /// Titel und Text der Hinweise beim Anmelden.
    private(set) var alerts: [(title: String, body: String)] = []

    init(clock: any AppClock) {
        self.clock = clock
    }

    var activities: [LiveActivityLifecycle.Existing] {
        existing()
    }

    func areActivitiesEnabled() -> Bool { enabled }

    func existing() -> [LiveActivityLifecycle.Existing] {
        stored.map {
            LiveActivityLifecycle.Existing(
                activityID: $0.id, planID: $0.planID, start: $0.start, isPending: $0.start > clock.now, content: $0.content
            )
        }
    }

    func perform(_ actions: [LiveActivityLifecycle.Action], wording: any LiveActivityWording) async {
        performed.append(actions)
        for action in actions {
            switch action {
            case .request(let plan):
                nextID += 1
                stored.append(Activity(id: "A\(nextID)", planID: plan.id, start: plan.start, content: plan.content))
                alerts.append((wording.alertTitle(plan.prayer, minutes: plan.leadMinutes), wording.alertBody(plan.prayer, time: plan.content.prayerTime)))
            case .update(let id, let content):
                if let index = stored.firstIndex(where: { $0.id == id }) {
                    stored[index].content = content
                }
            case .end(let id, _, _):
                stored.removeAll { $0.id == id }
            }
        }
    }
}

/// Merkt sich jeden Stand, statt ihn in die App Group zu schreiben.
@MainActor
final class RecordingWidgetPublisher: WidgetPublishing {
    private(set) var states: [WidgetState] = []

    func publish(_ state: WidgetState) {
        states.append(state)
    }
}

#endif
