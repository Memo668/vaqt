import SwiftUI

/// Fußnote unter Karten oder einer Liste, z. B. der Hinweis am Ende der Anleitung, dass sich
/// Einzelheiten je nach Rechtsschule unterscheiden. `.card-foot` im Prototyp.
///
/// Footnote in Sekundärfarbe, 16 pt weiter eingerückt als die Karten. Den Seitenrand selbst setzt die
/// Seite.
public struct CardFootnote: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        // `letter-spacing: -.08px` ist die Laufweite, die das System bei 13 pt ohnehin setzt.
        Text(text)
            .textStyle(.footnote, lineHeight: CardFootnoteMetrics.lineHeight)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CardFootnoteMetrics.indent)
    }
}

/// Maße der Fußnote (`.card-foot`: `margin: 0 calc(var(--inset) + 16px) 8px; line-height: 1.38`).
enum CardFootnoteMetrics {
    /// Einzug über den Seitenrand hinaus.
    static let indent: CGFloat = 16
    static let lineHeight: CGFloat = 1.38
}
