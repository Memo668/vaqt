import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Plant die Mitteilungen der App und hält sie aktuell (Spec § 1, „Local notifications (prayer +
/// reminder)“).
///
/// Geplant wird bei jedem Start, wenn die App nach vorn kommt, bei der Hintergrundaktualisierung und nach
/// jeder Änderung an dem, was in die Mitteilungen eingeht (`inputs`): Ort, Methode, Asr, Regel für hohe
/// Breiten, Minutenkorrektur, Glocken, Erinnerung, Klang, Stimme und Sprache. Was geplant wird, bestimmt
/// `NotificationPlanner` in PrayerCore; hier kommen Einstellungen, Ort und Uhr der App dazu.
///
/// Ohne Erlaubnis plant die App nichts und löscht, was noch aussteht. Die Glocken bleiben trotzdem
/// einstellbar (Spec § 5, „Notifications denied“).
@MainActor
@Observable
public final class NotificationModel {

    public let settings: SettingsStore
    /// Welcher Ort gilt; derselbe wie auf der Zeiten-Seite.
    public let location: PlaceModel

    @ObservationIgnored private let clock: any AppClock
    @ObservationIgnored private let planner: NotificationPlanner
    @ObservationIgnored private let authorizer: any NotificationAuthorizing
    @ObservationIgnored private let scheduler: any NotificationScheduling

    /// Ob die App Mitteilungen senden darf, zuletzt gelesen beim Planen; `nil`, solange noch nicht.
    public private(set) var authorization: NotificationAuthorization?
    /// Was zuletzt bei iOS vorgemerkt wurde.
    public private(set) var planned: [PrayerNotification] = []

    public init(
        settings: SettingsStore, location: PlaceModel, clock: any AppClock, timesSource: any PrayerTimesSource,
        authorizer: any NotificationAuthorizing, scheduler: any NotificationScheduling,
        wording: any NotificationWording = L10nNotificationWording()
    ) {
        self.settings = settings
        self.location = location
        self.clock = clock
        planner = NotificationPlanner(source: timesSource, wording: wording)
        self.authorizer = authorizer
        self.scheduler = scheduler
    }

    // MARK: - Was eingeht

    /// Alles, was in die Mitteilungen eingeht. Ändert es sich, plant die App neu.
    public struct Inputs: Hashable, Sendable {
        public var place: Place?
        public var cityName: String
        public var calculation: CalculationSettings
        public var bells: [Prayer: BellState]
        public var notifications: NotificationPreferences
        public var language: AppLanguage?
    }

    public var inputs: Inputs {
        Inputs(
            place: location.place, cityName: location.cityTitle, calculation: settings.calculation,
            bells: bells, notifications: settings.notifications, language: settings.language
        )
    }

    /// Die Wahl unter Einstellungen › Mitteilungen und an den Glocken – ohne die Stimme, die man im
    /// Adhan-Sheet wählt. Ändert sie sich und hat iOS noch nie gefragt, fragt die App jetzt
    /// (`requestIfNeverAsked()`).
    public struct Choices: Hashable, Sendable {
        public var bells: [Prayer: BellState]
        public var reminderMinutes: Int
        public var liveActivityMinutes: Int
        public var sound: NotificationSound
    }

    public var choices: Choices {
        let notifications = settings.notifications
        return Choices(
            bells: bells, reminderMinutes: notifications.reminderMinutes,
            liveActivityMinutes: notifications.liveActivityMinutes, sound: notifications.sound
        )
    }

    private var bells: [Prayer: BellState] {
        Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, settings.bell(for: $0)) })
    }

    // MARK: - Planen

    /// Liest die Erlaubnis und merkt die Mitteilungen der nächsten Tage bei iOS vor – ohne Erlaubnis
    /// keine. Was vorher ausstand, ersetzt der neue Plan.
    public func reschedule() async {
        let status = await authorizer.authorization()
        // Hat inzwischen ein neuerer Auftrag begonnen, plant der.
        guard !Task.isCancelled else { return }
        authorization = status
        let notifications = status == .authorized ? plan() : []
        scheduler.replacePending(with: notifications, now: clock.now)
        planned = notifications
    }

    /// Die Mitteilungen ab jetzt für den Ort, der gilt; ohne Ort keine.
    func plan() -> [PrayerNotification] {
        guard let place = location.place else { return [] }
        return planner.plan(
            at: clock.now, place: place, cityName: location.cityTitle, settings: settings.calculation,
            bells: bells, preferences: settings.notifications
        )
    }

    // MARK: - Erlaubnis

    /// Fragt mit dem Dialog des Systems, falls iOS noch nicht gefragt hat, und plant dann neu – „Mitteilungen
    /// erlauben“ im Onboarding.
    @discardableResult
    public func requestAuthorization() async -> NotificationAuthorization {
        let status = await authorizer.requestAuthorization()
        authorization = status
        await reschedule()
        return status
    }

    /// Hat iOS noch nie gefragt – etwa nach „Später“ im Onboarding –, fragt die App jetzt. Gerufen nach
    /// einer Änderung an Glocke oder Einstellungen › Mitteilungen (entschieden mit dem Plan für Phase 8).
    public func requestIfNeverAsked() async {
        guard await authorizer.authorization() == .notDetermined else { return }
        await requestAuthorization()
    }

    /// `-debugNotifications` beim Start: Zugestelltes abräumen, dann nach der Erlaubnis fragen, falls iOS
    /// noch nie gefragt hat. So zeigt die Aufnahme von `system/92` nur die Mitteilungen dieses Laufs.
    public func prepareDebugRun() async {
        scheduler.removeDelivered()
        await requestIfNeverAsked()
    }
}

/// Die Texte der Mitteilungen aus dem String Catalog, in der Sprache der App (`L10n`) – auch bei der
/// eigenen Sprachwahl unter Einstellungen › Sprache.
public struct L10nNotificationWording: NotificationWording {
    public init() {}

    public func prayerTitle(_ prayer: Prayer, time: ClockTime) -> String {
        L10n.notifPrayerTitle(p: prayer.localizedName, time: time.description)
    }

    public func prayerBody(_ prayer: Prayer, city: String) -> String {
        L10n.notifPrayerBody(p: prayer.localizedName, city: city)
    }

    public func reminderTitle(_ prayer: Prayer, minutes: Int) -> String {
        L10n.notifReminderTitle(p: prayer.localizedName, n: minutes)
    }

    public func reminderBody(_ prayer: Prayer, time: ClockTime) -> String {
        L10n.notifReminderBody(p: prayer.localizedName, at: time)
    }
}
