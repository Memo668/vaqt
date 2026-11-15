import DesignSystem
import SwiftUI

/// Die obere Leiste des Gebete-Tabs: die Chips Zeiten, Qibla und Anleitung in der Mitte, der
/// Einstellungskreis rechts – vier einzelne Glass-Elemente, keine gemeinsame Kapsel. `topBarHTML()` im
/// Prototyp (Spec § 9.2); bei RTL steht der Kreis links.
///
/// Die Chips stehen mittig auf der Leiste. Passen ihre Titel nicht zwischen den Kreis und einen gleich
/// breiten Platz auf der anderen Seite (Deutsch, große Schrift), behält nur der gewählte Chip seinen
/// Titel; die anderen werden zu Kreisen (Design Spec § 3, „TopBar“). Reicht auch das nicht ganz – etwa
/// „Anleitung“ gewählt –, rücken die Chips nur so weit von der Mitte weg, dass sie den Kreis nicht
/// berühren. Im Prototyp laufen sie dann ein Stück unter den Kreis.
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
            // Mit Titeln nur, wenn auf der anderen Seite ein Platz so breit wie der Kreis frei bleibt
            // (`grid-template-columns: var(--bar-h) 1fr var(--bar-h)`).
            TopBarLayout(spacing: Layout.chipGap, reservesLeadingSpace: !collapsed) {
                chips(collapsed: collapsed)
                GlassCircleButton(systemImage: "gearshape", label: L10n.tabSettings, action: onSettings)
            }
        }
    }

    private func chips(collapsed: Bool) -> some View {
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

/// Anordnung der oberen Leiste: der Kreis am Ende, die Chips mittig auf der ganzen Leiste – höchstens so
/// weit rechts, dass zwischen ihnen und dem Kreis der Abstand der Leiste bleibt.
///
/// Die ideale Breite entscheidet, ob eine Form der Leiste passt (`ViewThatFits`): mit Titeln zählt ein
/// zweiter Platz in der Breite des Kreises dazu, zusammengeklappt nur Chips, Abstand und Kreis.
private struct TopBarLayout: SwiftUI.Layout {
    let spacing: CGFloat
    let reservesLeadingSpace: Bool

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let chips = subviews[0].sizeThatFits(.unspecified)
        let gear = subviews[1].sizeThatFits(.unspecified)
        let ideal = chips.width + spacing + gear.width + (reservesLeadingSpace ? gear.width + spacing : 0)
        return CGSize(width: proposal.width ?? ideal, height: max(chips.height, gear.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let gear = subviews[1].sizeThatFits(.unspecified)
        let gearX = bounds.maxX - gear.width
        subviews[1].place(
            at: CGPoint(x: gearX, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(gear)
        )
        // Was links vom Kreis frei ist; reicht es nicht, wird der gewählte Chip schmaler.
        let available = max(0, gearX - spacing - bounds.minX)
        let chips = subviews[0].sizeThatFits(ProposedViewSize(width: available, height: nil))
        let width = min(chips.width, available)
        let centred = bounds.midX - width / 2
        let x = max(bounds.minX, min(centred, gearX - spacing - width))
        subviews[0].place(
            at: CGPoint(x: x, y: bounds.midY), anchor: .leading,
            proposal: ProposedViewSize(width: width, height: chips.height)
        )
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
            // Die gewählte Seite in Akzent. Eine getönte Fläche wie beim Chip (Spec § 8: „selected = tinted“)
            // lässt die Leiste des Systems nicht zu: Mit dem hervorgehobenen Glass-Stil zeichnet sie das Symbol
            // immer weiß – auf 17 % Akzent kaum lesbar, auf vollem Akzent dunkel nur 2 : 1 (Phase 11).
            .tint(page == selection ? Palette.accent : nil)
            .accessibilityAddTraits(page == selection ? .isSelected : [])
        }
        .axisBehavior(.verticalPreferred)
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
