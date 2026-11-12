import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Meldet die Live-Aktivitäten bei iOS an, frischt sie auf und beendet sie.
public protocol LiveActivityScheduling: Sendable {
    /// Ob Live-Aktivitäten für die App erlaubt sind (iOS-Einstellungen › Gebetszeiten › Live-Aktivitäten).
    @MainActor func areActivitiesEnabled() -> Bool
    /// Die Aktivitäten der App, die iOS kennt und die noch nicht beendet sind.
    @MainActor func existing() -> [LiveActivityLifecycle.Existing]
    /// Führt die Schritte aus, die `LiveActivityLifecycle` bestimmt hat.
    @MainActor func perform(_ actions: [LiveActivityLifecycle.Action], wording: any LiveActivityWording) async
}

/// Die Texte des Hinweises, den iOS beim geplanten Start einer Live-Aktivität verlangt
/// (`AlertConfiguration`). Es sind die Texte der Vorab-Erinnerung (entschieden mit dem Plan für Phase 9).
public protocol LiveActivityWording: Sendable {
    /// „Maghrib in 30 Minuten“.
    func alertTitle(_ prayer: Prayer, minutes: Int) -> String
    /// „Maghrib beginnt um 16:27 Uhr.“
    func alertBody(_ prayer: Prayer, time: ClockTime) -> String
}

/// Die Texte aus dem String Catalog, in der Sprache der App.
public struct L10nLiveActivityWording: LiveActivityWording {
    public init() {}

    public func alertTitle(_ prayer: Prayer, minutes: Int) -> String {
        L10n.notifReminderTitle(p: prayer.localizedName, n: String(minutes))
    }

    public func alertBody(_ prayer: Prayer, time: ClockTime) -> String {
        L10n.notifReminderBody(p: prayer.localizedName, time: time.description)
    }
}

/// Meldet nichts an – für Tests, Previews und Aufnahmen mit Mock-Zeiten ohne `-debugLiveActivity`.
public struct NoLiveActivityScheduler: LiveActivityScheduling {
    public init() {}

    @MainActor public func areActivitiesEnabled() -> Bool { false }
    @MainActor public func existing() -> [LiveActivityLifecycle.Existing] { [] }
    @MainActor public func perform(_ actions: [LiveActivityLifecycle.Action], wording: any LiveActivityWording) async {}
}

/// Plant die Live-Aktivitäten und hält sie aktuell (Spec § 3 „Live Activity“, § 4; Frage 16 entschieden
/// mit dem Plan für Phase 9: je Pflichtgebet eine, ohne Sonnenaufgang).
///
/// Geplant wird bei jedem Start, wenn die App nach vorn kommt, nach jeder Änderung an dem, was eingeht
/// (`inputs`), und bei der Hintergrundaktualisierung. Solange die App läuft, sieht sie außerdem zu jedem
/// Gebetsbeginn nach (`nextCheck`): Dann beendet sie die Aktivität, die bis 15 Minuten danach mit „Jetzt“
/// auf dem Sperrbildschirm stehen bleibt. Was geplant wird, bestimmen `LiveActivityPlanner` und
/// `LiveActivityLifecycle` in PrayerCore.
@MainActor
@Observable
public final class LiveActivityModel {

    public let settings: SettingsStore
    /// Welcher Ort gilt; derselbe wie auf der Zeiten-Seite.
    public let location: PlaceModel

    @ObservationIgnored private let clock: any AppClock
    @ObservationIgnored private let planner: LiveActivityPlanner
    @ObservationIgnored private let scheduler: any LiveActivityScheduling
    @ObservationIgnored private let wording: any LiveActivityWording
    @ObservationIgnored private let debugStart: Date?
    @ObservationIgnored private let isPlanning: Bool

    /// Was zuletzt geplant wurde.
    public private(set) var planned: [LiveActivityPlan] = []
    /// Wann die App, solange sie läuft, wieder nachsieht (Uhr der App): zum nächsten Gebetsbeginn.
    public private(set) var nextCheck: Date?

    /// - Parameters:
    ///   - isPlanning: ob die App überhaupt plant. Ohne Planen enden die bestehenden Aktivitäten
    ///     (`-debugFixtureTimes` ohne `-debugLiveActivity`).
    ///   - debugStart: `-debugLiveActivity` – genau eine Aktivität, die zum ersten Gebet nach diesem
    ///     Zeitpunkt, und sie beginnt dort.
    public init(
        settings: SettingsStore, location: PlaceModel, clock: any AppClock, timesSource: any PrayerTimesSource,
        scheduler: any LiveActivityScheduling, wording: any LiveActivityWording = L10nLiveActivityWording(),
        isPlanning: Bool = true, debugStart: Date? = nil
    ) {
        self.settings = settings
        self.location = location
        self.clock = clock
        planner = LiveActivityPlanner(source: timesSource)
        self.scheduler = scheduler
        self.wording = wording
        self.isPlanning = isPlanning
        self.debugStart = debugStart
    }

    // MARK: - Was eingeht

    /// Alles, was in die Live-Aktivitäten und die Widgets eingeht. Ändert es sich, plant die App neu.
    public struct Inputs: Hashable, Sendable {
        public var place: Place?
        public var cityName: String
        public var isCurrentLocation: Bool
        public var calculation: CalculationSettings
        public var showKerahat: Bool
        public var leadMinutes: Int
        public var language: AppLanguage?
    }

    public var inputs: Inputs {
        Inputs(
            place: location.place, cityName: location.cityTitle,
            isCurrentLocation: location.isAutomatic && location.place != nil,
            calculation: settings.calculation, showKerahat: settings.showKerahat,
            leadMinutes: settings.notifications.liveActivityMinutes, language: settings.language
        )
    }

    // MARK: - Planen

    /// Plant die Aktivitäten ab jetzt und gleicht sie mit denen ab, die iOS schon kennt. Sind
    /// Live-Aktivitäten in den iOS-Einstellungen aus, geschieht nichts.
    public func reschedule() async {
        let now = clock.now
        let plan = plan(at: now)
        #if DEBUG
        SystemLiveActivityScheduler.log.notice("Live-Aktivitäten: erlaubt \(self.scheduler.areActivitiesEnabled(), privacy: .public), im Plan \(plan.map(\.id).joined(separator: ", "), privacy: .public)")
        #endif
        guard scheduler.areActivitiesEnabled() else {
            planned = []
            nextCheck = nil
            return
        }
        let actions = LiveActivityLifecycle.actions(existing: scheduler.existing(), plan: plan, now: now)
        await scheduler.perform(actions, wording: wording)
        planned = plan
        nextCheck = LiveActivityLifecycle.nextCheck(plan: plan, now: now)
        BackgroundRefresh.liveActivityCheck = nextCheck.map { clock.deviceDate(for: $0.addingTimeInterval(LiveActivityPlanner.endDelay)) }
    }

    /// Die Aktivitäten ab `now` für den Ort, der gilt; ohne Ort keine.
    func plan(at now: Date) -> [LiveActivityPlan] {
        guard isPlanning, let place = location.place else { return [] }
        return planner.plan(
            at: now, place: place, settings: settings.calculation,
            options: LiveActivityPlanner.Options(
                leadMinutes: settings.notifications.liveActivityMinutes, cityName: location.cityTitle,
                isCurrentLocation: location.isAutomatic, showKerahat: settings.showKerahat,
                clockOffset: WidgetSync.clockOffset(of: clock)
            ),
            debugStart: debugStart
        )
    }
}
