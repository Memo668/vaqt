import SwiftUI

/// Großer Titel oben auf einer Seite der Tabs Verse und Nachholen, z. B. „Verse“. Er scrollt mit dem
/// Inhalt unter der oberen Leiste durch. `.page-title` im Prototyp.
///
/// Large Title, bold, Zeilenhöhe 1,2. Den Seitenrand und die Abstände darüber und darunter setzt die
/// Seite (`PageTitle.spacingAbove`, `spacingBelow`). Für VoiceOver eine Überschrift.
public struct PageTitle: View {
    private let title: String

    /// Abstand über dem Titel (`margin-top: 2px`).
    public static let spacingAbove: CGFloat = 2
    /// Abstand unter dem Titel (`margin-bottom: 14px`).
    public static let spacingBelow: CGFloat = 14

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        // `letter-spacing: .37px` ist die Laufweite, die das System bei 34 pt ohnehin setzt.
        Text(title)
            .textStyle(.largeTitle, weight: .bold, lineHeight: PageHeadingMetrics.titleLineHeight)
            .foregroundStyle(Palette.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Einleitung unter dem Titel einer Seite, z. B. „Behalte im Blick, welche Gebete du nachholen
/// möchtest. …“ – `.lede` im Prototyp.
///
/// Subheadline in Sekundärfarbe, Zeilenhöhe 1,4. Sie rückt 6 pt an den Titel heran
/// (`PageLede.spacingAbove`); den Abstand darunter setzt die Seite (`spacingBelow`).
public struct PageLede: View {
    private let text: String

    /// Abstand zum Titel: Der Titel hält 14 pt Abstand, die Einleitung zieht sich 6 pt heran
    /// (`margin-top: -6px`) – zusammen 8 pt.
    public static let spacingAbove: CGFloat = PageTitle.spacingBelow - 6
    /// Abstand unter der Einleitung (`margin-bottom: 18px`).
    public static let spacingBelow: CGFloat = 18

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        // `letter-spacing: -.24px` ist die Laufweite, die das System bei 15 pt ohnehin setzt.
        Text(text)
            .textStyle(.subheadline, lineHeight: PageHeadingMetrics.ledeLineHeight)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Maße von Titel und Einleitung (`.page-title`: `font: 700 …/1.2`; `.lede`: `line-height: 1.4`).
enum PageHeadingMetrics {
    static let titleLineHeight: CGFloat = 1.2
    static let ledeLineHeight: CGFloat = 1.4
}
