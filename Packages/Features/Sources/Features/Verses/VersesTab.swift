import DesignSystem
import SwiftUI

/// Der Tab „Verse“: oben der Einstellungskreis, darunter die Seite – `versesPage()` im Prototyp. Die
/// Einstellungen schieben sich als eigene Seite darüber.
struct VersesTab: View {
    let model: VersesModel
    /// Der Stapel der Einstellungen dieses Tabs (`AppNavigation.versesPath`).
    @Binding var path: [SettingsRoute]

    var body: some View {
        NavigationStack(path: $path) {
            VersesPage(model: model)
                .readsPageArrangement()
                .settingsBar(path: $path)
                .background(Palette.backgroundGrouped)
                .navigationDestination(for: SettingsRoute.self) { route in
                    SettingsDestination(route: route)
                }
        }
    }
}

/// Die Seite „Verse“: der Vers des Tages auf Arabisch mit Übersetzung und Quelle, Teilen und Kopieren,
/// darunter die letzten Tage. Antippen eines Eintrags zeigt seinen Vers oben; die Seite springt dafür
/// nach oben (`S.scrollPos.verses = 0`).
struct VersesPage: View {
    let model: VersesModel

    @State private var position = ScrollPosition(edge: .top)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Innen auf dem iPhone Duo: die Karte links, „Letzte Tage“ rechts.
        PageScroll(position: $position) {
            VersesOverview(day: model.shown, onCopy: model.copyShownVerse)
        } second: {
            RecentVerses(days: model.recent, selection: model.shownDay) { day in
                model.select(day)
                position.scrollTo(edge: .top)
            }
        }
        // Liest den Tag, wenn die App nach vorn kommt, und dann um Mitternacht am Ort.
        .task(id: DayActivity(isActive: scenePhase == .active, timeZone: model.timeZone.identifier)) {
            guard scenePhase == .active else { return }
            await model.run()
        }
    }
}
