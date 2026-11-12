import PrayerCore
import SwiftUI

/// Hält Widgets und Live-Aktivitäten aktuell, solange die App läuft – ein unsichtbarer Begleiter an der
/// Wurzel (`AppContent`), wie `NotificationPlanning` für die Mitteilungen.
///
/// - Schreibt den Stand der Widgets und plant die Live-Aktivitäten, wenn die App nach vorn kommt – beim
///   Start und danach jedes Mal – und nach jeder Änderung an dem, was eingeht. Dabei endet, was alt ist.
/// - Solange die App vorn ist, sieht er zum nächsten Gebetsbeginn wieder nach: Die Aktivität endet dann und
///   bleibt bis 15 Minuten danach auf dem Sperrbildschirm.
struct OutsideAppPlanning: View {
    let widgets: WidgetSync
    let liveActivities: LiveActivityModel
    let clock: any AppClock

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .task(id: Trigger(isActive: scenePhase == .active, inputs: liveActivities.inputs)) {
                guard scenePhase == .active else { return }
                try? await Task.sleep(for: NotificationPlanning.settleTime)
                guard !Task.isCancelled else { return }
                widgets.publish()
                await liveActivities.reschedule()
            }
            .task(id: Wake(isActive: scenePhase == .active, date: liveActivities.nextCheck)) {
                guard scenePhase == .active, let date = liveActivities.nextCheck else { return }
                let delay = clock.deviceDate(for: date).timeIntervalSinceNow
                try? await Task.sleep(for: .seconds(max(0, delay) + 1))
                guard !Task.isCancelled else { return }
                await liveActivities.reschedule()
            }
    }

    /// Wann neu geplant wird: Die App ist vorn, und das, was eingeht, ist so.
    private struct Trigger: Equatable {
        let isActive: Bool
        let inputs: LiveActivityModel.Inputs
    }

    /// Wann wieder nachgesehen wird.
    private struct Wake: Equatable {
        let isActive: Bool
        let date: Date?
    }
}
