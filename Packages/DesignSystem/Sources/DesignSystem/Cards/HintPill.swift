import SwiftUI

/// Hinweis-Pille: ein kleiner, ruhiger Hinweis ohne Aktion, z. B. „Offline · alles wird auf dem Gerät
/// berechnet“ unter dem Datum der Zeiten-Seite.
///
/// Design Spec § 3 („Banner / note / hint pill“), `.hint-pill` im Prototyp.
public struct HintPill: View {
    private let text: String
    private let systemImage: String

    /// - Parameter systemImage: SF Symbol vor dem Text, z. B. `wifi.slash`.
    public init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: HintPillMetrics.gap) {
            Image(systemName: systemImage)
                .font(.system(size: HintPillMetrics.symbolSize, weight: HintPillMetrics.symbolWeight))
                .frame(minWidth: HintPillMetrics.symbolBox)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.footnote, weight: .medium, lineHeight: HintPillMetrics.lineHeight)
        }
        .foregroundStyle(Palette.textSecondary)
        .padding(.horizontal, HintPillMetrics.paddingX)
        .padding(.vertical, HintPillMetrics.paddingY)
        .background(Palette.fillTertiary, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

/// Maße der Hinweis-Pille (`.hint-pill`).
enum HintPillMetrics {
    /// Abstand zwischen Symbol und Text (`gap: 6px`).
    static let gap: CGFloat = 6
    /// Innenabstand (`padding: 5px 11px`).
    static let paddingX: CGFloat = 11
    static let paddingY: CGFloat = 5
    /// Zeilenhöhe des Textes (`font: 500 …/1.25`).
    static let lineHeight: CGFloat = 1.25
    /// Feld des Symbols – `ic('wifiSlash', 14)`.
    static let symbolBox: CGFloat = 14
    /// Das Symbol als Schriftgröße eines SF Symbols, so breit wie die Zeichnung des Prototyps.
    static let symbolSize: CGFloat = 10.5
    static let symbolWeight: Font.Weight = .medium
}
