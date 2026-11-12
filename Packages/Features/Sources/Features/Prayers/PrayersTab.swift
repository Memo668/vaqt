import DesignSystem
import SwiftUI

/// Der Tab „Gebete“: die obere Leiste über den drei Seiten Zeiten, Qibla und Anleitung. Die
/// Einstellungen schieben sich als eigene Seite darüber; dort gibt es die Leiste nicht.
///
/// Die Leiste steht fest (`safeAreaBar`), der Inhalt scrollt unter ihr durch. Zurück aus den
/// Einstellungen steht wieder die Seite da, die vorher zu sehen war (Design Spec § 1 und § 4).
///
/// Der Ort gilt für alle Seiten des Tabs. Deshalb bestimmt ihn der Tab, und das Stadt-Sheet hängt
/// hier: Die Zeiten-Seite öffnet es über die Stadt und das Banner, die Qibla-Seite über „Stadt wählen“.
struct PrayersTab: View {
    private let today: TodayModel
    private let qibla: QiblaModel
    private let guide: GuideModel

    @State private var page: PrayersPage
    @State private var path: [SettingsRoute]
    @Environment(\.scenePhase) private var scenePhase

    /// - Parameters:
    ///   - initialPage: die Seite beim Start (`-debugTab qibla` …).
    ///   - opensSettings: ob die Einstellungen schon offen sind (`-debugTab settings`).
    init(
        today: TodayModel, qibla: QiblaModel, guide: GuideModel,
        initialPage: PrayersPage = .today, opensSettings: Bool = false
    ) {
        self.today = today
        self.qibla = qibla
        self.guide = guide
        _page = State(initialValue: initialPage)
        _path = State(initialValue: opensSettings ? [.settings] : [])
    }

    var body: some View {
        @Bindable var today = today
        NavigationStack(path: $path) {
            PrayersPager(selection: $page) { item in
                switch item {
                case .today:
                    TodayPage(model: today) {
                        // „Regel ändern“ führt nach Einstellungen › Hohe Breitengrade (`goto-hl`).
                        path = [.settings, .highLatitude]
                    }
                case .qibla:
                    QiblaPage(model: qibla, isSelected: page == .qibla) {
                        today.isCitySheetPresented = true
                    }
                case .guide:
                    GuidePage(model: guide) {
                        // „Qibla öffnen“ wechselt die Seite wie der Chip.
                        page = .qibla
                    }
                }
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                TopBar(selection: $page) {
                    path.append(.settings)
                }
            }
            // Wer die Anleitung verlässt – Chip, Wischen, „Qibla öffnen“ –, hebt die manuelle Wahl auf
            // (`goPane()`). Ein anderer Tab und die Einstellungen lassen sie stehen, wie im Prototyp.
            .onChange(of: page) { previous, _ in
                if previous == .guide {
                    guide.followTime()
                }
            }
            .background(Palette.backgroundGrouped)
            .toolbar(.hidden, for: .navigationBar)
            // Beim ersten Erscheinen und immer, wenn die App wieder nach vorn kommt.
            .task(id: scenePhase) {
                if scenePhase == .active {
                    await today.activate()
                }
            }
            .sheet(isPresented: $today.isCitySheetPresented) {
                CitySheet(today: today, search: today.citySearch)
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                SettingsPlaceholder(route: route)
            }
        }
    }
}
