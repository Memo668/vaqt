import SwiftUI

/// Hält die Mitteilungen aktuell, solange die App läuft – ein unsichtbarer Begleiter an der Wurzel
/// (`AppContent`).
///
/// - Plant, wenn die App nach vorn kommt – beim Start und danach jedes Mal – und nach jeder Änderung an
///   dem, was in die Mitteilungen eingeht (`NotificationModel.inputs`). Änderungen kurz hintereinander,
///   etwa am Stepper der Minutenkorrektur, plant er einmal.
/// - Ändert man eine Glocke oder etwas unter Einstellungen › Mitteilungen und hat iOS noch nie gefragt,
///   fragt er jetzt (`NotificationModel.requestIfNeverAsked()`).
/// - Geht die App in den Hintergrund, bittet er iOS um die nächste Hintergrundaktualisierung.
struct NotificationPlanning: View {
    let model: NotificationModel
    /// `-debugNotifications`: beim Start Zugestelltes abräumen und nach der Erlaubnis fragen, falls iOS noch
    /// nie gefragt hat.
    var asksAtLaunch = false

    @Environment(\.scenePhase) private var scenePhase

    /// So lange sammelt der Begleiter Änderungen, bevor er plant.
    static let settleTime: Duration = .milliseconds(300)

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .task(id: Trigger(isActive: scenePhase == .active, inputs: model.inputs)) {
                guard scenePhase == .active else { return }
                try? await Task.sleep(for: Self.settleTime)
                guard !Task.isCancelled else { return }
                await model.reschedule()
            }
            .onChange(of: model.choices) {
                Task { await model.requestIfNeverAsked() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    BackgroundRefresh.schedule()
                }
            }
            .task {
                if asksAtLaunch {
                    await model.prepareDebugRun()
                }
            }
    }

    /// Wann neu geplant wird: Die App ist vorn, und das, was eingeht, ist so.
    private struct Trigger: Equatable {
        let isActive: Bool
        let inputs: NotificationModel.Inputs
    }
}
