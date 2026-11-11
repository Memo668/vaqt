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
