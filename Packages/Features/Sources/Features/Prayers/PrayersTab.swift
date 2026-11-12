import DesignSystem
import SwiftUI

/// Der Tab „Gebete“: die obere Leiste über den drei Seiten Zeiten, Qibla und Anleitung. Die
/// Einstellungen schieben sich als eigene Seite darüber; dort gibt es die Leiste nicht.
///
/// Die Leiste steht fest (`safeAreaBar`), der Inhalt scrollt unter ihr durch. Stehen die Leisten
/// senkrecht am Rand (iPhone Duo), legt iOS Einstellungskreis und Chips als Einträge in die senkrechte
/// Leiste (Design Spec § 8). Zurück aus den Einstellungen steht wieder die Seite da, die vorher zu sehen
/// war (Design Spec § 1 und § 4).
///
/// Der Ort gilt für alle Seiten des Tabs. Deshalb bestimmt ihn der Tab. Das Stadt-Sheet hängt an der
/// Wurzel der App (`AppContent`), damit es auch die Einstellungen jedes Tabs und das Onboarding öffnen:
/// Die Zeiten-Seite öffnet es über die Stadt und das Banner, die Qibla-Seite über „Stadt wählen“.
struct PrayersTab: View {
    let today: TodayModel
    let qibla: QiblaModel
    let guide: GuideModel
    /// Die Seite des Tabs (`S.tab`) und der Stapel der Einstellungen (`AppNavigation`).
    @Binding var page: PrayersPage
    @Binding var path: [SettingsRoute]

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
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
            // Innen auf dem iPhone Duo stehen die Teile jeder Seite in zwei Spalten am Falz. Gemessen wird
            // am Pager, dessen Rahmen beim Wischen stillsteht.
            .readsPageArrangement()
            // Neben der senkrechten Leiste endet der Pager an ihrem Rand: Die nächste Seite schaut sonst
            // hinter der Leiste hervor.
            .clipsPagesAtVerticalBar()
            .prayersTopBar(selection: $page) {
                path.append(.settings)
            }
            // Wer die Anleitung verlässt – Chip, Wischen, „Qibla öffnen“ –, hebt die manuelle Wahl auf
            // (`goPane()`). Ein anderer Tab und die Einstellungen lassen sie stehen, wie im Prototyp.
            .onChange(of: page) { previous, _ in
                if previous == .guide {
                    guide.followTime()
                }
            }
            .background(Palette.backgroundGrouped)
            // Beim ersten Erscheinen und immer, wenn die App wieder nach vorn kommt.
            .task(id: scenePhase) {
                if scenePhase == .active {
                    await today.activate()
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                SettingsDestination(route: route)
            }
        }
    }
}

extension View {

    /// Stehen die Leisten senkrecht am Rand, schneidet die Ansicht links und rechts an ihrem Rahmen ab –
    /// oben und unten reicht sie weiter unter die Ränder des Systems, damit der Inhalt dort durchscrollt.
    /// Auf dem iPhone bleibt sie, wie sie ist.
    func clipsPagesAtVerticalBar() -> some View {
        modifier(VerticalBarClip())
    }
}

private struct VerticalBarClip: ViewModifier {
    @Environment(\.verticalBarEdge) private var verticalBarEdge

    func body(content: Content) -> some View {
        if verticalBarEdge != nil {
            content.mask {
                Rectangle().ignoresSafeArea(edges: .vertical)
            }
        } else {
            content
        }
    }
}
