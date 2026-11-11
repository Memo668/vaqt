import DesignSystem
import SwiftUI

/// Der Tab „Gebete“: die obere Leiste über den drei Seiten Zeiten, Qibla und Anleitung. Die
/// Einstellungen schieben sich als eigene Seite darüber; dort gibt es die Leiste nicht.
///
/// Die Leiste steht fest (`safeAreaBar`), der Inhalt scrollt unter ihr durch. Zurück aus den
/// Einstellungen steht wieder die Seite da, die vorher zu sehen war (Design Spec § 1 und § 4).
struct PrayersTab: View {
    private let today: TodayModel

    @State private var page: PrayersPage
    @State private var path: [SettingsRoute]

    /// - Parameters:
    ///   - initialPage: die Seite beim Start (`-debugTab qibla` …).
    ///   - opensSettings: ob die Einstellungen schon offen sind (`-debugTab settings`).
    init(today: TodayModel, initialPage: PrayersPage = .today, opensSettings: Bool = false) {
        self.today = today
        _page = State(initialValue: initialPage)
        _path = State(initialValue: opensSettings ? [.settings] : [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            PrayersPager(selection: $page) { page in
                switch page {
                case .today:
                    TodayPage(model: today) {
                        // „Regel ändern“ führt nach Einstellungen › Hohe Breitengrade (`goto-hl`).
                        path = [.settings, .highLatitude]
                    }
                case .qibla, .guide:
                    // Noch leer: Qibla folgt in Phase 4, die Anleitung in Phase 5.
                    PlaceholderPage()
                }
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                TopBar(selection: $page) {
                    path.append(.settings)
                }
            }
            .background(Palette.backgroundGrouped)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                SettingsPlaceholder(route: route)
            }
        }
    }
}

/// Eine Seite, die es noch nicht gibt: nur der Seitenhintergrund.
struct PlaceholderPage: View {
    var body: some View {
        Palette.backgroundGrouped
            .ignoresSafeArea()
    }
}
