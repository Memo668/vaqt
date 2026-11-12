import SwiftUI

/// Überschrift eines Abschnitts, z. B. „Vorher“ und „Ablauf“ in der Anleitung. `.section-h` im Prototyp.
///
/// Title 3, bold. Den Seitenrand und die Abstände darüber und darunter setzt die Seite
/// (`SectionHeader.spacingAbove`, `spacingBelow`). Für VoiceOver eine Überschrift.
public struct SectionHeader: View {
    private let title: String

    /// Abstand über der Überschrift (`margin-top: 24px`).
    public static let spacingAbove: CGFloat = Spacing.x6
    /// Abstand unter der Überschrift (`margin-bottom: 10px`).
    public static let spacingBelow: CGFloat = 10

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        // `letter-spacing: .38px` ist die Laufweite, die das System bei 20 pt ohnehin setzt.
        Text(title)
            .textStyle(.title3, weight: .bold, lineHeight: SectionHeaderMetrics.lineHeight)
            .foregroundStyle(Palette.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Maße der Abschnittsüberschrift (`.section-h`: `font: 700 …/1.25`).
enum SectionHeaderMetrics {
    static let lineHeight: CGFloat = 1.25
}
