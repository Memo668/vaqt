import Foundation
import os
import PrayerCore
import UserNotifications

/// Merkt die geplanten Mitteilungen bei iOS vor.
public protocol NotificationScheduling: Sendable {
    /// Ersetzt alle ausstehenden Mitteilungen der App durch `notifications`; eine leere Liste löscht sie.
    /// Schon zugestellte bleiben stehen.
    ///
    /// - Parameter now: jetzt, auf der Uhr der App. Von hier zählt der Abstand bis zu jeder Mitteilung –
    ///   so läuft auch die Debug-Uhr mit (`-debugTime`).
    @MainActor func replacePending(with notifications: [PrayerNotification], now: Date)

    /// Räumt die schon zugestellten Mitteilungen der App ab – nur für `-debugNotifications`, damit eine
    /// Aufnahme des Sperrbildschirms nur die Mitteilungen dieses Laufs zeigt.
    @MainActor func removeDelivered()
}

/// Mitteilungen über `UNUserNotificationCenter`.
///
/// Jede Mitteilung bekommt einen Auslöser nach Zeitabstand (`UNTimeIntervalNotificationTrigger`): Sie
/// kommt zum Zeitpunkt am Ort, auch wenn das Gerät in einer anderen Zeitzone steht oder sie wechselt. Die
/// Kennung bleibt für dieselbe Mitteilung gleich (`PrayerNotification.id`).
public struct SystemNotificationScheduler: NotificationScheduling {

    /// So viel Vorlauf braucht eine Mitteilung mindestens; was näher liegt, kommt nicht mehr.
    static let minimumLead: TimeInterval = 1

    public init() {}

    @MainActor
    public func replacePending(with notifications: [PrayerNotification], now: Date) {
        let center = UNUserNotificationCenter.current()
        // iOS arbeitet die Aufträge der Reihe nach ab: erst alles löschen, dann die neuen vormerken.
        center.removeAllPendingNotificationRequests()
        for request in notifications.compactMap({ Self.request(for: $0, now: now) }) {
            let identifier = request.identifier
            center.add(request) { error in
                if let error {
                    Self.log.error("Mitteilung \(identifier, privacy: .public) nicht vorgemerkt: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        #if DEBUG
        Self.logPending(center: center, planned: notifications.count)
        #endif
    }

    @MainActor
    public func removeDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    /// Die Anfrage an iOS für eine Mitteilung; `nil`, wenn sie nicht mehr in der Zukunft liegt.
    static func request(for notification: PrayerNotification, now: Date) -> UNNotificationRequest? {
        let lead = notification.date.timeIntervalSince(now)
        guard lead >= minimumLead else { return nil }
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = sound(for: notification.tone)
        // Keine zeitkritischen Mitteilungen (Spec § 6.6, entschieden mit dem Plan für Phase 8).
        content.interruptionLevel = .active
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: lead, repeats: false)
        return UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
    }

    /// Der Ton für iOS: keiner, der des Systems oder eine Aufnahme aus dem Bundle der App. Fehlt die
    /// Datei, spielt iOS den Ton des Systems.
    static func sound(for tone: NotificationTone) -> UNNotificationSound? {
        switch tone {
        case .silent: nil
        case .system: .default
        case .clip(let name): UNNotificationSound(named: UNNotificationSoundName(name))
        }
    }

    static let log = Logger(subsystem: "com.example.gebetszeiten", category: "notifications")

    #if DEBUG
    /// Schreibt ins Protokoll, was iOS jetzt vormerkt – die ersten sechs und die letzten zwei, damit der
    /// Eintrag nicht gekürzt wird. Für den Abgleich im Simulator:
    /// `xcrun simctl spawn booted log show --last 5m --predicate 'category == "notifications"'`.
    private static func logPending(center: UNUserNotificationCenter, planned: Int) {
        center.getPendingNotificationRequests { requests in
            let lines = requests
                .sorted { nextDate($0) < nextDate($1) }
                .map { request in
                    let sound = request.content.sound == nil ? "ohne Ton" : "Ton"
                    return "\(request.identifier) \(nextDate(request).formatted(.iso8601)) „\(request.content.title)“ – „\(request.content.body)“ (\(sound))"
                }
            let shown = lines.count > 8 ? lines.prefix(6) + ["…"] + lines.suffix(2) : lines[...]
            log.notice("Mitteilungen: \(planned) geplant, \(requests.count) ausstehend\n\(shown.joined(separator: "\n"), privacy: .public)")
        }
    }

    private static func nextDate(_ request: UNNotificationRequest) -> Date {
        (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate() ?? .distantFuture
    }
    #endif
}

/// Merkt nichts vor – mit `-debugFixtureTimes`, damit Aufnahmen und Tests keine Mitteilungen auslösen.
public struct NoNotificationScheduler: NotificationScheduling {
    public init() {}

    @MainActor
    public func replacePending(with notifications: [PrayerNotification], now: Date) {}

    @MainActor
    public func removeDelivered() {}
}
