import ActivityKit
import AlarmKit
import DesignSystem
import Foundation
import os
import PrayerCore
import SwiftUI

/// Die Wecker über AlarmKit (iOS 26): Sie klingeln wie der Wecker von iOS, auch im Stummmodus und bei
/// Fokus (Spec § 10.8).
///
/// Die Weckanzeige zeigt nur „Wecker zu Fadschr“ und einen Knopf zum Beenden, kein Schlummern (entschieden
/// mit dem Plan für Phase 17). Ohne Countdown braucht AlarmKit keine eigene Live-Aktivität; die Anzeige
/// zeichnet iOS.
public struct SystemFajrAlarmScheduler: FajrAlarmScheduling {

    static let log = Logger(subsystem: AppInfo.bundleIdentifier, category: "alarm")

    public init() {}

    public func authorization() async -> AlarmAuthorization {
        Self.map(AlarmManager.shared.authorizationState)
    }

    public func requestAuthorization() async -> AlarmAuthorization {
        do {
            return Self.map(try await AlarmManager.shared.requestAuthorization())
        } catch {
            Self.log.notice("Erlaubnis für Wecker nicht erfragt: \(error.localizedDescription, privacy: .public)")
            return await authorization()
        }
    }

    public func replace(with alarms: [ScheduledFajrAlarm]) async {
        let manager = AlarmManager.shared
        guard manager.authorizationState == .authorized else { return }
        let existing: [Alarm]
        do {
            existing = try manager.alarms
        } catch {
            Self.log.notice("Wecker nicht gelesen: \(error.localizedDescription, privacy: .public)")
            return
        }
        let wanted = Set(alarms.map(\.id))
        for alarm in existing where !wanted.contains(alarm.id) && alarm.state != .alerting {
            do {
                try manager.cancel(id: alarm.id)
            } catch {
                Self.log.notice("Wecker nicht abgemeldet: \(error.localizedDescription, privacy: .public)")
            }
        }
        let present = Set(existing.map(\.id))
        for alarm in alarms where !present.contains(alarm.id) {
            do {
                _ = try await manager.schedule(id: alarm.id, configuration: Self.configuration(for: alarm))
            } catch AlarmManager.AlarmError.maximumLimitReached {
                // Die Wecker sind nach der Zeit geordnet: Die nächsten sind angemeldet, die späteren
                // kommen beim nächsten Planen dran.
                Self.log.notice("Höchstzahl der Wecker erreicht")
                return
            } catch {
                Self.log.notice("Wecker nicht angemeldet: \(error.localizedDescription, privacy: .public)")
            }
        }
        #if DEBUG
        Self.log.notice("Wecker: \(alarms.count, privacy: .public) im Plan, \(existing.count, privacy: .public) waren angemeldet")
        #endif
    }

    // MARK: - Bausteine

    static func configuration(for alarm: ScheduledFajrAlarm) -> AlarmManager.AlarmConfiguration<FajrAlarmMetadata> {
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: alarm.title))
        } else {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.title),
                stopButton: AlarmButton(
                    text: LocalizedStringResource(stringLiteral: alarm.stopTitle), textColor: .white,
                    systemImageName: "stop.circle"
                )
            )
        }
        let attributes = AlarmAttributes<FajrAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert), metadata: FajrAlarmMetadata(), tintColor: Palette.accent
        )
        return .alarm(schedule: .fixed(alarm.date), attributes: attributes, sound: sound(for: alarm.tone))
    }

    static func sound(for tone: NotificationTone) -> AlertConfiguration.AlertSound {
        switch tone {
        case .clip(let name): .named(name)
        case .system, .silent: .default
        }
    }

    static func map(_ state: AlarmManager.AuthorizationState) -> AlarmAuthorization {
        switch state {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .denied
        }
    }
}

/// Was die App zu einem Wecker mitgibt: nichts, er ist immer der Wecker zu Fadschr.
public struct FajrAlarmMetadata: AlarmMetadata {
    public init() {}
}
