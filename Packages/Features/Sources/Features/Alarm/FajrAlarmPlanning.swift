import SwiftUI

/// Hält die Wecker zu Fadschr aktuell, solange die App läuft – ein unsichtbarer Begleiter an der Wurzel
/// (`AppContent`), wie `OutsideAppPlanning` für die Live-Aktivitäten.
///
/// Plant, wenn die App nach vorn kommt – beim Start und danach jedes Mal – und nach jeder Änderung an dem,
/// was eingeht: Ort, Berechnung, Wecker, Sprache und Erlaubnis.
struct FajrAlarmPlanning: View {
    let model: FajrAlarmModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .task(id: Trigger(isActive: scenePhase == .active, inputs: model.inputs)) {
                guard scenePhase == .active else { return }
                try? await Task.sleep(for: NotificationPlanning.settleTime)
                guard !Task.isCancelled else { return }
                await model.reschedule()
            }
    }

    /// Wann neu geplant wird: Die App ist vorn, und das, was eingeht, ist so.
    private struct Trigger: Equatable {
        let isActive: Bool
        let inputs: FajrAlarmModel.Inputs
    }
}
