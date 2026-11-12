import DesignSystem
import SwiftUI

/// Der Tab „Nachholen“: oben der Einstellungskreis, darunter die Seite – `qadaPage()` im Prototyp. Die
/// Einstellungen schieben sich als eigene Seite darüber.
struct QadaTab: View {
    let model: QadaModel
    /// Der Stapel der Einstellungen dieses Tabs (`AppNavigation.qadaPath`).
    @Binding var path: [SettingsRoute]

    var body: some View {
        NavigationStack(path: $path) {
            QadaPage(model: model)
                .settingsBar(path: $path)
                .background(Palette.backgroundGrouped)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SettingsRoute.self) { route in
                    SettingsDestination(route: route)
                }
        }
    }
}

/// Die Seite „Nachholen“: Titel und Einleitung, die Zusammenfassung mit dem Anteil als größter Zahl, der
/// Plan, „Nach Gebet“, der Rechner für den verpassten Zeitraum und „Als offen übernehmen“.
///
/// Solange nichts eingetragen ist, fehlen Zusammenfassung und Plan.
struct QadaPage: View {
    let model: QadaModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                QadaOverview(ledger: model.ledger, today: model.today, onAction: model.perform)
                QadaDetails(ledger: model.ledger, onAction: model.perform)
            }
            .padding(.top, PageMetrics.contentTop)
            .padding(.bottom, PageMetrics.contentBottom)
        }
        .background(Palette.backgroundGrouped)
        // Liest den Tag, wenn die App nach vorn kommt, und dann um Mitternacht am Ort.
        .task(id: DayActivity(isActive: scenePhase == .active, timeZone: model.timeZone.identifier)) {
            guard scenePhase == .active else { return }
            await model.run()
        }
    }
}

/// Wann eine Seite ihren Tag neu liest: wenn die App nach vorn kommt und wenn der Ort in eine andere
/// Zeitzone wechselt.
struct DayActivity: Hashable {
    let isActive: Bool
    let timeZone: String
}
