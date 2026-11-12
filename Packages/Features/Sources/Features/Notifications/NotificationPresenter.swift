import Foundation
import UserNotifications

/// Zeigt Mitteilungen auch, während die App offen ist – als Banner und in der Liste, mit Ton, so wie bei
/// geschlossener App (Annahme mit dem Plan für Phase 8). Antippen öffnet die App dort, wo sie war.
///
/// Ohne Delegate zeigt iOS eine Mitteilung bei offener App gar nicht an.
public final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {

    public static let shared = NotificationPresenter()

    /// Setzt den Delegate; muss beim Start geschehen, bevor die App fertig gestartet ist.
    @MainActor
    public static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
