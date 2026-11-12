import DesignSystem
import SwiftUI

/// Der Tab „Verse“: oben der Einstellungskreis, darunter die Seite – `versesPage()` im Prototyp. Die
/// Einstellungen schieben sich als eigene Seite darüber.
struct VersesTab: View {
    let model: VersesModel

    @State private var path: [SettingsRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            VersesPage(model: model)
                .settingsBar(path: $path)
                .background(Palette.backgroundGrouped)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: SettingsRoute.self) { route in
                    SettingsPlaceholder(route: route)
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
        ScrollView {
            VStack(spacing: 0) {
                VersesOverview(day: model.shown, onCopy: model.copyShownVerse)
                RecentVerses(days: model.recent, selection: model.shownDay) { day in
                    model.select(day)
                    position.scrollTo(edge: .top)
                }
            }
            .padding(.top, PageMetrics.contentTop)
            .padding(.bottom, PageMetrics.contentBottom)
        }
        .scrollPosition($position)
        .background(Palette.backgroundGrouped)
        // Liest den Tag, wenn die App nach vorn kommt, und dann um Mitternacht am Ort.
        .task(id: DayActivity(isActive: scenePhase == .active, timeZone: model.timeZone.identifier)) {
            guard scenePhase == .active else { return }
            await model.run()
        }
    }
}
