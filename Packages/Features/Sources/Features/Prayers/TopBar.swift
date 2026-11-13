import DesignSystem
import SwiftUI

/// Die obere Leiste des Gebete-Tabs: der Einstellungskreis und die Chips Zeiten, Qibla und Anleitung –
/// vier einzelne Glass-Elemente, keine gemeinsame Kapsel. `topBarHTML()` im Prototyp.
///
/// Passen die Titel aller Chips nicht nebeneinander (Deutsch, große Schrift), behält nur der gewählte
/// Chip seinen Titel; die anderen werden zu Kreisen (Design Spec § 3, „TopBar“).
struct TopBar: View {
    @Binding var selection: PrayersPage
    let onSettings: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ViewThatFits(in: .horizontal) {
            bar(collapsed: false)
            bar(collapsed: true)
        }
    }

    private func bar(collapsed: Bool) -> some View {
        FloatingBar {
            GlassCircleButton(systemImage: "gearshape", label: L10n.tabSettings, action: onSettings)
            HStack(spacing: Layout.chipGap) {
                ForEach(PrayersPage.allCases) { page in
                    GlassChip(
                        page.title, symbol: page.symbol,
                        isSelected: page == selection, showsTitle: !collapsed || page == selection
                    ) {
                        select(page)
                    }
                }
            }
            // `role="tablist"` mit dem Namen des Tabs.
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.navPrayers)
            .accessibilityAddTraits(.isTabBar)
        }
    }

    /// Wechselt die Seite. Bei „Bewegung reduzieren“ ohne Bewegung (Design Spec § 4).
    private func select(_ page: PrayersPage) {
        guard page != selection else { return }
        if reduceMotion {
            selection = page
        } else {
            withAnimation(.snappy) {
                selection = page
            }
        }
    }
}

/// Die obere Leiste, wenn die Leisten senkrecht am Rand stehen (iPhone Duo): Einstellungskreis und die
/// drei Seiten als Einträge der Leiste des Systems. iOS legt sie über die Tabs in die senkrechte Leiste
/// (Design Spec § 8: „the system lays the bars out vertically – custom bars don't get this“). Jeder
/// Eintrag steht für sich, wie die Glass-Elemente der oberen Leiste; die gewählte Seite ist in Akzent
/// getönt, die Seiten zeigen nur ihr Symbol.
@available(iOS 27.1, *)
struct VerticalTopBar: ToolbarContent {
    @Binding var selection: PrayersPage
    let onSettings: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(L10n.tabSettings, systemImage: "gearshape", action: onSettings)
        }
        .axisBehavior(.verticalPreferred)
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        pageItem(.today)
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        pageItem(.qibla)
        ToolbarSpacer(.fixed, placement: .topBarLeading)
        pageItem(.guide)
    }

    private func pageItem(_ page: PrayersPage) -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                selection = page
            } label: {
                Label {
                    Text(page.title)
                } icon: {
                    page.symbol.barImage
                }
            }
            .modifier(SelectedBarItem(isSelected: page == selection))
            .accessibilityAddTraits(page == selection ? .isSelected : [])
        }
        .axisBehavior(.verticalPreferred)
    }
}

/// Die gewählte Seite in der senkrechten Leiste: eine getönte Glasfläche mit dem Symbol in Akzent, wie der
/// gewählte Chip der oberen Leiste (Spec § 8: „selected = tinted“; entschieden mit dem Plan für Phase 11:
/// „Getönte Fläche“). Die Leiste des Systems tönt einen Eintrag über den hervorgehobenen Glass-Stil.
@available(iOS 27.1, *)
private struct SelectedBarItem: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content
                .buttonStyle(.glassProminent)
                .tint(Palette.accent.opacity(GlassMetrics.selectedTintOpacity))
                .foregroundStyle(Palette.accent)
        } else {
            content
        }
    }
}

/// Die Leiste des Einstellungskreises in den Tabs Verse und Nachholen, wenn die Leisten senkrecht am
/// Rand stehen (iPhone Duo): ein Eintrag der Leiste des Systems.
@available(iOS 27.1, *)
struct VerticalSettingsBar: ToolbarContent {
    let onSettings: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(L10n.tabSettings, systemImage: "gearshape", action: onSettings)
        }
        .axisBehavior(.verticalPreferred)
    }
}

extension View {

    /// Die obere Leiste des Tabs „Gebete“: auf dem iPhone fest über dem Inhalt (`safeAreaBar`), ohne
    /// die Leiste des Systems; stehen die Leisten senkrecht am Rand, als Einträge in der Leiste des
    /// Systems.
    func prayersTopBar(selection: Binding<PrayersPage>, onSettings: @escaping () -> Void) -> some View {
        modifier(TopBarPlacement(
            bar: { TopBar(selection: selection, onSettings: onSettings) },
            verticalItems: { VerticalItems.prayers(selection: selection, onSettings: onSettings) }
        ))
    }

    /// Die obere Leiste der Tabs Verse und Nachholen mit dem Einstellungskreis, der die Einstellungen im
    /// Stapel des Tabs öffnet; wie `prayersTopBar`.
    func settingsBar(path: Binding<[SettingsRoute]>) -> some View {
        let open = { path.wrappedValue.append(.settings) }
        return modifier(TopBarPlacement(
            bar: { SettingsBar(onSettings: open) },
            verticalItems: { VerticalItems.settings(onSettings: open) }
        ))
    }
}

/// Was in die senkrechte Leiste gehört.
private enum VerticalItems {
    case prayers(selection: Binding<PrayersPage>, onSettings: () -> Void)
    case settings(onSettings: () -> Void)
}

/// Legt eine Leiste fest über die Seite – der Inhalt scrollt unter ihr durch, mit dem Randeffekt des
/// Systems – oder, wenn die Leisten senkrecht am Rand stehen, ihre Einträge in die Leiste des Systems.
private struct TopBarPlacement<Bar: View>: ViewModifier {
    let bar: () -> Bar
    let verticalItems: () -> VerticalItems

    @Environment(\.verticalBarEdge) private var verticalBarEdge

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *), verticalBarEdge != nil {
            switch verticalItems() {
            case .prayers(let selection, let onSettings):
                content.toolbar { VerticalTopBar(selection: selection, onSettings: onSettings) }
            case .settings(let onSettings):
                content.toolbar { VerticalSettingsBar(onSettings: onSettings) }
            }
        } else {
            content
                .safeAreaBar(edge: .top, spacing: 0, content: bar)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
