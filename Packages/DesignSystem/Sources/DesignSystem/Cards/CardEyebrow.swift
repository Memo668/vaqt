import SwiftUI

/// Kleine Zeile in Großbuchstaben oben in einer Karte: links ein Stichwort, rechts eine Angabe – z. B.
/// „JETZT · 14:00–16:27“ in der Kopfkarte der Anleitung oder „VERS DES TAGES · 10. Nov.“ beim Vers.
/// `.card-eyebrow` im Prototyp.
///
/// Caption 1, semibold, Sekundärfarbe. Beide Teile dürfen leer sein; die rechte Angabe bleibt dann
/// trotzdem rechts (`justify-content: space-between`).
public struct CardEyebrow: View {
    private let leading: String
    private let trailing: String
    private let trailingHasTabularDigits: Bool

    /// - Parameter trailingHasTabularDigits: ob die Ziffern der rechten Angabe gleich breit sind, z. B. bei
    ///   einer Zeitspanne (`.tabnum`).
    public init(leading: String, trailing: String, trailingHasTabularDigits: Bool = false) {
        self.leading = leading
        self.trailing = trailing
        self.trailingHasTabularDigits = trailingHasTabularDigits
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: CardEyebrowMetrics.gap) {
            Text(leading)
            Spacer(minLength: 0)
            Text(trailing)
                .tabularDigits(trailingHasTabularDigits)
        }
        .textStyle(.caption1, weight: .semibold, lineHeight: CardEyebrowMetrics.lineHeight)
        .tracking(CardEyebrowMetrics.tracking)
        .textCase(.uppercase)
        .foregroundStyle(Palette.textSecondary)
        .accessibilityElement(children: .combine)
    }
}

extension Text {
    /// Gleich breite Ziffern nur, wenn `isOn`.
    fileprivate func tabularDigits(_ isOn: Bool) -> Text {
        isOn ? monospacedDigit() : self
    }
}

/// Maße der Zeile (`.card-eyebrow`: `gap: 8px; font: 600 …/1.2; letter-spacing: .4px`). Bei 12 pt setzt
/// das System keine eigene Laufweite; die 0,4 pt kommen ganz dazu.
enum CardEyebrowMetrics {
    static let gap: CGFloat = 8
    static let lineHeight: CGFloat = 1.2
    static let tracking: CGFloat = 0.4
}
