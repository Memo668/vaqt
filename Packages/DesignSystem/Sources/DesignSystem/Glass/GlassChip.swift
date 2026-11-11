import SwiftUI

/// Chip der oberen Leiste: eine eigene Glass-Kapsel mit Symbol und Titel.
///
/// - Ausgewählt: getöntes Glas (Akzent 17 %), Symbol und Titel in Akzent, weicher Akzentschatten,
///   kein Rahmen.
/// - Nicht ausgewählt: klares Glas, Titel in Schriftfarbe, graues Symbol.
/// - Ohne Titel (`showsTitle: false`) wird der Chip zum Kreis – so klappen die nicht gewählten Chips
///   ein, wenn die Titel nicht nebeneinander passen.
///
/// Design Spec § 3 („TopBar“) und `.chip` im Prototyp. Gebaut ist die Standardvariante „nur Titel“
/// (Spec § 7, 5b).
public struct GlassChip: View {
    private let title: String
    private let symbol: GlassSymbol
    private let isSelected: Bool
    private let showsTitle: Bool
    private let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - title: Titel des Chips; ohne sichtbaren Titel bleibt er der Text für VoiceOver.
    ///   - symbol: SF Symbol oder eigene Zeichnung.
    ///   - showsTitle: `false` für den eingeklappten Kreis.
    public init(
        _ title: String, symbol: GlassSymbol, isSelected: Bool, showsTitle: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.isSelected = isSelected
        self.showsTitle = showsTitle
        self.action = action
    }

    /// Ein Chip mit einem SF Symbol.
    public init(
        _ title: String, systemImage: String, isSelected: Bool, showsTitle: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(title, symbol: .system(systemImage), isSelected: isSelected, showsTitle: showsTitle, action: action)
    }

    public var body: some View {
        let height = GlassMetrics.barHeight(typeScale: typeScale)
        Button(action: action) {
            content(height: height)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .glassEffect(glass, in: .capsule)
        .background {
            if isSelected {
                selectionShadow
            }
        }
        // Der Text wächst bis AX1; darüber zeigt der Large Content Viewer den Titel.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityShowsLargeContentViewer {
            Label {
                Text(title)
            } icon: {
                GlassSymbolView(
                    symbol: symbol, pointSize: GlassMetrics.chipSymbolSize, box: GlassMetrics.chipSymbolBox
                )
            }
        }
    }

    /// Der weiche Akzentschatten des ausgewählten Chips (`box-shadow: 0 10px 26px` in Akzent 24 %).
    ///
    /// Er liegt hinter dem Glas und ist dort ausgespart, wo der Chip sitzt – wie ein `box-shadow`, der
    /// nur außerhalb der Fläche zu sehen ist. Sonst würde das Glas ihn als zusätzliche Tönung zeigen.
    private var selectionShadow: some View {
        let reach = ShadowToken.selectedChip.blur + ShadowToken.selectedChip.y
        return Capsule()
            .fill(.black)
            .shadow(ShadowToken.selectedChip)
            .mask {
                Rectangle()
                    .padding(-reach)
                    .overlay { Capsule().blendMode(.destinationOut) }
                    .compositingGroup()
            }
            .accessibilityHidden(true)
    }

    private var glass: Glass {
        isSelected
            ? .regular.tint(Palette.accent.opacity(GlassMetrics.selectedTintOpacity)).interactive()
            : .regular.interactive()
    }

    @ViewBuilder
    private func content(height: CGFloat) -> some View {
        let symbol = GlassSymbolView(
            symbol: symbol, pointSize: GlassMetrics.chipSymbolSize, box: GlassMetrics.chipSymbolBox
        )
        .foregroundStyle(isSelected ? Palette.accent : Palette.textSecondary)
        .frame(width: GlassMetrics.chipSymbolBox)

        if showsTitle {
            HStack(spacing: GlassMetrics.chipGap) {
                symbol
                Text(title)
                    .font(TypeScale.headline.font())
                    .foregroundStyle(isSelected ? Palette.accent : Palette.label)
                    .lineLimit(1)
            }
            .padding(.leading, GlassMetrics.chipLeading)
            .padding(.trailing, GlassMetrics.chipTrailing)
            .frame(minHeight: height)
        } else {
            symbol
                .frame(width: height, height: height)
        }
    }
}
