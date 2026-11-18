import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Wecker zu Fadschr: die Seite Einstellungen › Wecker zu Fadschr, der Wert ihrer Zeile, der Chip in der
/// Fadschr-Zeile und die Wecker bei iOS (Spec § 10.8, `PAGES.alarm` und `alarmAt()` im Prototyp).
///
/// Die Erlaubnis fragt die App, wenn man den Wecker zum ersten Mal einschaltet. Lehnt man ab, bleibt der
/// Schalter aus und gesperrt, darunter steht der Weg in die iOS-Einstellungen. Die Wecker der nächsten
/// 14 Tage meldet die App bei jedem Start an, wenn sie nach vorn kommt, nach jeder Änderung an dem, was
/// eingeht (`inputs`), und bei der Hintergrundaktualisierung (`FajrAlarmPlanner`).
@MainActor
@Observable
public final class FajrAlarmModel {

    public let settings: SettingsStore
    /// Welcher Ort gilt; derselbe wie auf der Zeiten-Seite.
    public let location: PlaceModel

    @ObservationIgnored private let clock: any AppClock
    @ObservationIgnored private let timesSource: any PrayerTimesSource
    @ObservationIgnored private let planner: FajrAlarmPlanner
    @ObservationIgnored private let scheduler: any FajrAlarmScheduling
    @ObservationIgnored private let isPlanning: Bool
    @ObservationIgnored private let testDate: Date?

    /// Ob die App Wecker stellen darf, zuletzt gelesen in `refreshAuthorization()`.
    public private(set) var authorization: AlarmAuthorization = .notDetermined
    /// Was zuletzt angemeldet wurde.
    public private(set) var planned: [ScheduledFajrAlarm] = []

    /// - Parameters:
    ///   - isPlanning: ob die App überhaupt Wecker anmeldet. Mit `-debugFixtureTimes` nicht, damit
    ///     Aufnahmen keine auslösen.
    ///   - testDate: `-debugAlarmIn` – ein zusätzlicher Wecker zu diesem Zeitpunkt (Uhr der App), zum Test
    ///     von Ton, Stummmodus und Fokus am Gerät.
    public init(
        settings: SettingsStore, location: PlaceModel, clock: any AppClock, timesSource: any PrayerTimesSource,
        scheduler: any FajrAlarmScheduling, isPlanning: Bool = true, testDate: Date? = nil
    ) {
        self.settings = settings
        self.location = location
        self.clock = clock
        self.timesSource = timesSource
        planner = FajrAlarmPlanner(source: timesSource)
        self.scheduler = scheduler
        self.isPlanning = isPlanning
        self.testDate = testDate
    }

    // MARK: - Stand

    public var preferences: FajrAlarmPreferences { settings.fajrAlarm }

    /// Ohne Erlaubnis ist der Schalter aus und gesperrt, und „iOS-Einstellungen öffnen“ erscheint.
    public var isDenied: Bool { authorization == .denied }

    /// Ob der Wecker klingelt: eingeschaltet und erlaubt (`S.alarmOn && !S.alarmDenied`).
    public var isActive: Bool { preferences.isOn && !isDenied }

    public func refreshAuthorization() async {
        authorization = await scheduler.authorization()
    }

    /// Die Zeiten von heute am Ort, der gilt (`todayTimes()`).
    private var todayTimes: DayTimes? {
        guard let place = location.place else { return nil }
        return timesSource.times(on: CalendarDay(clock.now, in: place.timeZone), at: place, settings: settings.calculation)
    }

    /// Die Weckzeit an diesem Tag, wenn der Wecker klingelt – der Chip in der Fadschr-Zeile.
    public func alarmTime(on times: DayTimes) -> ClockTime? {
        guard isActive else { return nil }
        return ClockTime(preferences.alarmDate(on: times), in: times.timeZone)
    }

    /// Die Weckzeit von heute (`alarmAt()`), auch wenn der Wecker aus ist.
    private var todayAlarmTime: ClockTime? {
        todayTimes.map { ClockTime(preferences.alarmDate(on: $0), in: $0.timeZone) }
    }

    // MARK: - Texte

    /// Wert der Zeile „Wecker zu Fadschr“: die Weckzeit von heute oder „Aus“.
    public var rowValue: String {
        guard isActive, let time = todayAlarmTime else { return L10n.off }
        return L10n.time(time)
    }

    /// „Klingelt heute um 06:29“ unter dem Schalter, solange er an ist.
    public var ringsText: String? {
        guard isActive, let time = todayAlarmTime else { return nil }
        return L10n.alarmRings(t: L10n.time(time))
    }

    /// „Heute beginnt Fadschr um 05:16, die Sonne geht um 07:14 auf.“
    public var todayFooter: String? {
        guard let times = todayTimes else { return nil }
        return L10n.alarmToday(f: L10n.time(times.clockTime(of: .fajr)), s: L10n.time(times.clockTime(of: .sunrise)))
    }

    /// „45 Min. vorher“ beim Stepper „Vor Sonnenaufgang“.
    public var minutesBeforeText: String { L10n.minBefore(n: preferences.minutesBefore) }

    /// „05:30“ beim Stepper „Uhrzeit“.
    public var fixedTimeText: String { L10n.time(preferences.fixedTime) }

    // MARK: - Ändern

    /// Der Schalter (`toggle-alarm`). Beim Einschalten fragt die App nach der Erlaubnis, falls iOS noch nie
    /// gefragt hat; ohne Erlaubnis bleibt der Wecker aus.
    public func setOn(_ isOn: Bool) async {
        guard isOn else {
            settings.updateFajrAlarm { $0.isOn = false }
            return
        }
        var status = await scheduler.authorization()
        if status == .notDetermined {
            status = await scheduler.requestAuthorization()
        }
        authorization = status
        guard status == .authorized else { return }
        settings.updateFajrAlarm { $0.isOn = true }
    }

    public func setMode(_ mode: FajrAlarmMode) {
        settings.updateFajrAlarm { $0.mode = mode }
    }

    public func setSound(_ sound: FajrAlarmSound) {
        settings.updateFajrAlarm { $0.sound = sound }
    }

    public func canStepMinutes(by direction: Int) -> Bool {
        preferences.steppedMinutesBefore(by: direction) != preferences.minutesBefore
    }

    public func stepMinutes(by direction: Int) {
        let minutes = preferences.steppedMinutesBefore(by: direction)
        settings.updateFajrAlarm { $0.minutesBefore = minutes }
    }

    /// Ohne Zeiten für heute gilt 5 Minuten vor Mitternacht als Obergrenze: Dann bleibt nur die Untergrenze.
    private var todaySunrise: ClockTime {
        todayTimes?.clockTime(of: .sunrise) ?? ClockTime(minutesSinceMidnight: 24 * 60 - 1)
    }

    public func canStepFixedTime(by direction: Int) -> Bool {
        preferences.steppedFixedTime(by: direction, sunrise: todaySunrise) != preferences.fixedTime
    }

    public func stepFixedTime(by direction: Int) {
        let time = preferences.steppedFixedTime(by: direction, sunrise: todaySunrise)
        settings.updateFajrAlarm { $0.fixedTime = time }
    }

    // MARK: - Was eingeht

    /// Alles, was in die Wecker eingeht. Ändert es sich, plant die App neu.
    public struct Inputs: Hashable, Sendable {
        public var place: Place?
        public var calculation: CalculationSettings
        public var preferences: FajrAlarmPreferences
        public var voice: AdhanVoice
        public var language: AppLanguage?
        public var authorization: AlarmAuthorization
    }

    public var inputs: Inputs {
        Inputs(
            place: location.place, calculation: settings.calculation, preferences: preferences,
            voice: settings.notifications.voice, language: settings.language, authorization: authorization
        )
    }

    // MARK: - Planen

    /// Liest die Erlaubnis und gleicht die Wecker bei iOS mit dem Plan ab. Ist der Wecker aus, meldet die
    /// App alle ab.
    public func reschedule() async {
        await refreshAuthorization()
        let alarms = plan(at: clock.now)
        guard authorization == .authorized else {
            planned = []
            return
        }
        await scheduler.replace(with: alarms)
        planned = alarms
    }

    /// Die Wecker ab `now` für den Ort, der gilt; ohne Ort, ausgeschaltet oder ohne Planen keine – nur der
    /// Wecker zum Test (`-debugAlarmIn`), solange er bevorsteht.
    func plan(at now: Date) -> [ScheduledFajrAlarm] {
        var alarms: [ScheduledFajrAlarm] = []
        if let testDate, testDate > now {
            alarms.append(scheduled(at: testDate))
        }
        guard isPlanning, let place = location.place else { return alarms }
        let occurrences = planner.plan(
            at: now, place: place, settings: settings.calculation, preferences: preferences
        )
        return alarms + occurrences.map { scheduled(at: $0.date) }
    }

    private func scheduled(at date: Date) -> ScheduledFajrAlarm {
        let tone = tone
        let title = L10n.alarmRow
        let stopTitle = L10n.alarmStop
        let variant = "\(Self.key(of: tone))|\(title)|\(stopTitle)"
        return ScheduledFajrAlarm(
            id: FajrAlarmPlanner.identifier(for: date, variant: variant), date: clock.deviceDate(for: date),
            title: title, stopTitle: stopTitle, tone: tone
        )
    }

    /// Der Ton des Weckers: der Weckton von iOS oder der kurze Adhan der gewählten Stimme – zu Fadschr ihre
    /// Fadschr-Fassung, sonst der normale Ausschnitt; ohne Aufnahme der Weckton (wie bei den Mitteilungen).
    var tone: NotificationTone {
        switch preferences.sound {
        case .system:
            return .system
        case .adhan:
            var notifications = settings.notifications
            notifications.sound = .adhan
            return NotificationTone.prayer(.fajr, bell: .sound, preferences: notifications) ?? .system
        }
    }

    private static func key(of tone: NotificationTone) -> String {
        switch tone {
        case .system, .silent: "system"
        case .clip(let name): "clip:\(name)"
        }
    }
}
