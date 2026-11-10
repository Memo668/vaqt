import SwiftUI

/// Karte: eine Fläche in Kartenfarbe mit Radius 26 (`.continuous`) und 20 pt Innenabstand.
///
/// Trägt z. B. den Vers des Tages, die Kopfkarte der Anleitung oder die Zusammenfassung beim Nachholen.
/// Die Karte füllt die Breite; den Seitenrand setzt die Seite. `.card` im Prototyp.
public struct Card<Content: View>: View {
    private let padding: EdgeInsets
    private let content: Content

    /// Innenabstand der Karte (`padding: 20px`).
    public static var standardPadding: EdgeInsets {
        EdgeInsets(top: Spacing.x5, leading: Spacing.x5, bottom: Spacing.x5, trailing: Spacing.x5)
    }

    /// - Parameter padding: Innenabstand; ohne Angabe 20 pt rundum.
    public init(padding: EdgeInsets? = nil, @ViewBuilder content: () -> Content) {
        self.padding = padding ?? Self.standardPadding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.group, style: .continuous))
    }
}
