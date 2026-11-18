import Foundation
import PrayerCore

/// Ob die App Wecker stellen darf (AlarmKit) – `S.alarmDenied` im Prototyp.
public enum AlarmAuthorization: Sendable, Equatable {
    /// Noch nicht gefragt.
    case notDetermined
    /// In den iOS-Einstellungen ausgeschaltet oder beim Fragen abgelehnt.
    case denied
    /// Erlaubt.
    case authorized
}

/// Ein Wecker, wie die App ihn bei iOS anmeldet.
public struct ScheduledFajrAlarm: Hashable, Sendable {
    /// Feste Kennung aus Zeit und Fassung (`FajrAlarmPlanner.identifier`).
    public let id: UUID
    /// Wann er klingelt, in Gerätezeit – danach weckt iOS.
    public let date: Date
    /// Titel der Weckanzeige, „Wecker zu Fadschr“.
    public let title: String
    /// Knopf der Weckanzeige unter iOS 26.0, „Stopp“; ab iOS 26.1 stellt iOS ihn selbst.
    public let stopTitle: String
    /// Der Ton: der Weckton von iOS oder eine Aufnahme im Bundle der App, mit Endung.
    public let tone: NotificationTone

    public init(id: UUID, date: Date, title: String, stopTitle: String, tone: NotificationTone) {
        self.id = id
        self.date = date
        self.title = title
        self.stopTitle = stopTitle
        self.tone = tone
    }
}

/// Liest und erfragt die Erlaubnis für Wecker und meldet die Wecker bei iOS an.
public protocol FajrAlarmScheduling: Sendable {
    /// Der Stand, ohne zu fragen.
    func authorization() async -> AlarmAuthorization
    /// Fragt mit dem Dialog des Systems, falls noch nicht gefragt wurde, und liefert den neuen Stand.
    func requestAuthorization() async -> AlarmAuthorization
    /// Gleicht die angemeldeten Wecker der App mit `alarms` ab: Was fehlt, kommt dazu, was nicht mehr im
    /// Plan steht, wird abgemeldet. Ein Wecker, der gerade klingelt, bleibt.
    func replace(with alarms: [ScheduledFajrAlarm]) async
}

/// Eine feste Erlaubnis, nichts wird angemeldet – für `-debugFixtureTimes`, Tests und Previews. Merkt sich,
/// was zuletzt angemeldet werden sollte.
public final class FixedFajrAlarmScheduler: FajrAlarmScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var status: AlarmAuthorization
    private let answer: AlarmAuthorization
    private var scheduled: [ScheduledFajrAlarm] = []
    private var requests = 0

    /// - Parameters:
    ///   - status: der Stand vor dem Fragen.
    ///   - answer: die Antwort auf die Frage.
    public init(status: AlarmAuthorization = .notDetermined, answer: AlarmAuthorization = .authorized) {
        self.status = status
        self.answer = answer
    }

    public func authorization() async -> AlarmAuthorization {
        lock.withLock { status }
    }

    public func requestAuthorization() async -> AlarmAuthorization {
        lock.withLock {
            requests += 1
            if status == .notDetermined { status = answer }
            return status
        }
    }

    public func replace(with alarms: [ScheduledFajrAlarm]) async {
        lock.withLock { scheduled = alarms }
    }

    /// Was zuletzt angemeldet werden sollte.
    public var alarms: [ScheduledFajrAlarm] {
        lock.withLock { scheduled }
    }

    /// Wie oft nach der Erlaubnis gefragt wurde.
    public var authorizationRequests: Int {
        lock.withLock { requests }
    }
}
