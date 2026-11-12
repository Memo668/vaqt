import ActivityKit
import DesignSystem
import Foundation
import os
import PrayerCore

/// Live-Aktivitäten über ActivityKit.
///
/// Eine Aktivität, deren Start in der Zukunft liegt, meldet die App mit `Activity.request(…, start:)` an
/// (iOS 26): iOS startet sie selbst, auch wenn die App nicht läuft, und zeigt dabei den Hinweis aus
/// `alertConfiguration` – ohne eigenen Ton (entschieden mit dem Plan für Phase 9). Der Inhalt ist ab
/// Gebetsbeginn `stale`; dann zeigt die Aktivität „Jetzt“. Ein geplantes Ende kennt ActivityKit nicht;
/// das übernimmt die App, sobald sie läuft (`LiveActivityLifecycle`).
public struct SystemLiveActivityScheduler: LiveActivityScheduling {

    static let log = Logger(subsystem: "com.example.gebetszeiten", category: "liveActivity")

    /// Eine stille Tondatei im Haupt-Bundle (`App/Sounds`): Der Start der Aktivität soll nicht klingen,
    /// Mitteilung und Vorab-Erinnerung klingen schon. Ohne eigene Datei spielte iOS seinen Ton.
    static let silentSound = "live-activity-silence.caf"

    public init() {}

    @MainActor
    public func areActivitiesEnabled() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @MainActor
    public func existing() -> [LiveActivityLifecycle.Existing] {
        #if DEBUG
        for activity in Activity<PrayerActivityAttributes>.activities {
            Self.log.notice("Vorhanden: \(activity.attributes.planID, privacy: .public) – \(String(describing: activity.activityState), privacy: .public), stale ab \(String(describing: activity.content.staleDate), privacy: .public)")
        }
        #endif
        return Activity<PrayerActivityAttributes>.activities.compactMap { activity in
            switch activity.activityState {
            case .pending, .active, .stale:
                LiveActivityLifecycle.Existing(
                    activityID: activity.id, planID: activity.attributes.planID, start: activity.attributes.start,
                    isPending: activity.activityState == .pending, content: activity.content.state
                )
            default:
                nil
            }
        }
    }

    @MainActor
    public func perform(_ actions: [LiveActivityLifecycle.Action], wording: any LiveActivityWording) async {
        for action in actions {
            switch action {
            case .request(let plan):
                request(plan, wording: wording)
            case .update(let id, let content):
                await Self.update(id: id, content: content)
            case .end(let id, let content, let dismissAt):
                await Self.end(id: id, content: content, dismissAt: dismissAt)
            }
        }
    }

    /// Frischt den Inhalt einer laufenden Aktivität auf. `Activity` ist nicht `Sendable`; deshalb wird sie
    /// hier gesucht und benutzt, ohne den Hauptakteur zu verlassen.
    private nonisolated static func update(id: String, content: LiveActivityContent) async {
        guard let activity = Activity<PrayerActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        await activity.update(ActivityContent(state: content, staleDate: content.deviceCountdownEnd))
        log.notice("Aufgefrischt: \(activity.attributes.planID, privacy: .public)")
    }

    /// Beendet eine Aktivität – sofort oder so, dass sie bis `dismissAt` (Uhr der App) auf dem
    /// Sperrbildschirm stehen bleibt.
    private nonisolated static func end(id: String, content: LiveActivityContent?, dismissAt: Date?) async {
        guard let activity = Activity<PrayerActivityAttributes>.activities.first(where: { $0.id == id }) else { return }
        let offset = (content ?? activity.content.state).clockOffset
        let policy: ActivityUIDismissalPolicy = dismissAt.map { .after($0.addingTimeInterval(-offset)) } ?? .immediate
        await activity.end(content.map { ActivityContent(state: $0, staleDate: nil) }, dismissalPolicy: policy)
        let note = dismissAt == nil ? "" : " (steht bis 15 Min. nach Beginn)"
        log.notice("Beendet: \(activity.attributes.planID, privacy: .public)\(note, privacy: .public)")
    }

    /// Meldet eine Aktivität an: sofort, wenn ihr Start erreicht ist, sonst zum geplanten Zeitpunkt.
    @MainActor
    private func request(_ plan: LiveActivityPlan, wording: any LiveActivityWording) {
        let content = plan.content
        let attributes = PrayerActivityAttributes(planID: plan.id, start: plan.start)
        let activityContent = ActivityContent(state: content, staleDate: content.deviceCountdownEnd)
        let deviceStart = content.deviceDate(plan.start)
        do {
            if deviceStart <= Date() {
                _ = try Activity.request(attributes: attributes, content: activityContent, pushType: nil, style: .standard)
                Self.log.notice("Gestartet: \(plan.id, privacy: .public)")
            } else {
                let alert = AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: wording.alertTitle(plan.prayer, minutes: plan.leadMinutes)),
                    body: LocalizedStringResource(stringLiteral: wording.alertBody(plan.prayer, time: content.prayerTime)),
                    sound: .named(Self.silentSound)
                )
                _ = try Activity.request(
                    attributes: attributes, content: activityContent, pushType: nil, style: .standard,
                    alertConfiguration: alert, start: deviceStart
                )
                Self.log.notice("Geplant: \(plan.id, privacy: .public) ab \(deviceStart, privacy: .public)")
            }
        } catch {
            Self.log.error("Nicht angemeldet: \(plan.id, privacy: .public) – \(String(describing: error), privacy: .public)")
        }
    }
}
