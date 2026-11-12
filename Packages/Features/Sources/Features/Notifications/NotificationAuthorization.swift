import Foundation
import UserNotifications

/// Ob die App Mitteilungen senden darf – `S.notifAllowed` im Prototyp (`null`, `true`, `false`).
public enum NotificationAuthorization: Sendable, Equatable {
    /// Noch nicht gefragt.
    case notDetermined
    /// In den iOS-Einstellungen ausgeschaltet oder beim Fragen abgelehnt.
    case denied
    /// Erlaubt, auch vorläufig.
    case authorized
}

/// Liest und erfragt die Erlaubnis für Mitteilungen.
///
/// Gefragt wird nur im dritten Schritt des Onboardings, nach „Mitteilungen erlauben“ (Spec § 1). Die
/// Einstellungen lesen den Stand für ihren Fußtext. Mitteilungen planen kommt in Phase 8.
public protocol NotificationAuthorizing: Sendable {
    /// Der Stand, ohne zu fragen.
    func authorization() async -> NotificationAuthorization
    /// Fragt mit dem Dialog des Systems, falls noch nicht gefragt wurde, und liefert den neuen Stand.
    func requestAuthorization() async -> NotificationAuthorization
}

/// Die Erlaubnis über `UNUserNotificationCenter`.
public struct SystemNotificationAuthorizer: NotificationAuthorizing {

    public init() {}

    public func authorization() async -> NotificationAuthorization {
        Self.map(await UNUserNotificationCenter.current().notificationSettings().authorizationStatus)
    }

    public func requestAuthorization() async -> NotificationAuthorization {
        // Hinweis und Ton; Kennzeichen am App-Symbol braucht die App nicht.
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        return await authorization()
    }

    static func map(_ status: UNAuthorizationStatus) -> NotificationAuthorization {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized, .provisional, .ephemeral: .authorized
        @unknown default: .denied
        }
    }
}

/// Eine feste Erlaubnis – für `-debugFixtureTimes`, Tests und Previews.
public struct FixedNotificationAuthorizer: NotificationAuthorizing {
    /// Der Stand vor dem Fragen.
    public let status: NotificationAuthorization
    /// Die Antwort auf die Frage.
    public let answer: NotificationAuthorization

    public init(status: NotificationAuthorization = .notDetermined, answer: NotificationAuthorization = .authorized) {
        self.status = status
        self.answer = answer
    }

    public func authorization() async -> NotificationAuthorization {
        status
    }

    public func requestAuthorization() async -> NotificationAuthorization {
        status == .notDetermined ? answer : status
    }
}
