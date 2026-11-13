import SwiftUI

/// Runder Glass-Button – der Einstellungskreis der oberen Leiste.
///
/// Echtes Liquid Glass des Systems: `.buttonStyle(.glass)` mit `.buttonBorderShape(.circle)`
/// (Design Spec § 3, „TopBar“). Der Durchmesser ist die Höhe der Leiste und wächst mit ihr.
public struct GlassCircleButton: View {
    private let systemImage: String
    private let label: String
    private let action: () -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - systemImage: SF Symbol, z. B. `gearshape`.
    ///   - label: Text für VoiceOver und den Large Content Viewer, z. B. `L10n.tabSettings`.
    public init(systemImage: String, label: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.label = label
        self.action = action
    }

    public var body: some View {
        let diameter = GlassMetrics.barHeight(typeScale: typeScale)
        Button(action: action) {
            // Der Stil des Systems legt eigenen Innenabstand um den Inhalt. Damit der Kreis genau so
            // groß wird wie die Leiste hoch ist, füllt der Inhalt den Platz, den der Stil ihm lässt.
            Image(systemName: systemImage)
                .font(.system(size: GlassMetrics.circleSymbolSize, weight: GlassMetrics.symbolWeight))
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(width: diameter, height: diameter)
        .accessibilityLabel(label)
        .accessibilityShowsLargeContentViewer {
            Label(label, systemImage: systemImage)
        }
    }
}

/// Maße der Glass-Bausteine der oberen Leiste (`.gear-btn`, `.chip`).
public enum GlassMetrics {
    /// Symbol im Einstellungskreis – `ic('gear', 24)`. Als Schriftgröße eines SF Symbols so gewählt,
    /// dass es so breit erscheint wie die Zeichnung des Prototyps (knapp 21 pt).
    static let circleSymbolSize: CGFloat = 20
    /// Symbol in einem Chip – `ic(icon, 22)`; im Prototyp 18 pt breit.
    static let chipSymbolSize: CGFloat = 18
    /// Strichstärke der Symbole: Der Prototyp zeichnet mit 1,65 bis 1,8 pt.
    static let symbolWeight: Font.Weight = .medium
    /// Breite des Symbolfelds in einem Chip.
    static let chipSymbolBox: CGFloat = 22
    /// Abstand zwischen Symbol und Titel (`gap: 7px`).
    static let chipGap: CGFloat = 7
    /// Innenabstand vor dem Symbol (`padding: 0 18px 0 14px`).
    static let chipLeading: CGFloat = 14
    /// Innenabstand hinter dem Titel.
    static let chipTrailing: CGFloat = 18
    /// So weit darf der Titel des gewählten Chips schrumpfen, wenn er bei großer Schrift nicht passt.
    static let chipTitleMinimumScale: CGFloat = 0.8
    /// Tönung des ausgewählten Chips: Akzent mit 17 % Deckkraft – auch der gewählten Seite in der senkrechten
    /// Leiste auf dem iPhone Duo (Phase 11).
    public static let selectedTintOpacity = 0.17

    /// Höhe der Leiste bei der aktuellen Schriftgröße: 52 pt, höchstens das 1,15-Fache.
    static func barHeight(typeScale: CGFloat) -> CGFloat {
        Layout.topBarHeight * min(max(typeScale, 1), Layout.topBarMaxScale)
    }
}
