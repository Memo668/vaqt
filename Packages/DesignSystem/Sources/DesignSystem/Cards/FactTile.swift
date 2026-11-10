import SwiftUI

/// Fakten-Kachel: ein Wert mit seiner Bezeichnung darunter, z. B. „4 · Rakʿa Fard“ in der Kopfkarte
/// der Anleitung.
///
/// Mehrere Kacheln stehen mit 8 pt Abstand nebeneinander und sind gleich hoch (`.facts`); die Kachel
/// füllt deshalb den Platz, den sie bekommt. `.fact` im Prototyp.
public struct FactTile: View {
    private let value: String
    private let caption: String
    private let isProminent: Bool

    /// Abstand zwischen Kacheln in einer Reihe (`.facts`: `gap: 8px`).
    public static let spacing: CGFloat = Spacing.x2

    /// - Parameters:
    ///   - value: der Wert, z. B. „4“ oder „leise“.
    ///   - caption: die Bezeichnung, z. B. „Rezitation“.
    ///   - isProminent: `true` für eine Zahl in großer, runder Schrift (`b.big`).
    public init(value: String, caption: String, isProminent: Bool = false) {
        self.value = value
        self.caption = caption
        self.isProminent = isProminent
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FactMetrics.captionGap) {
            if isProminent {
                Text(value)
                    .font(TypeScale.title2.font(weight: .bold, design: .rounded))
                    .lineHeight(FactMetrics.prominentLineHeight, for: .title2)
            } else {
                Text(value)
                    .font(TypeScale.subheadline.font(weight: .semibold))
                    .lineHeight(FactMetrics.lineHeight, for: .subheadline)
            }
            Text(caption)
                .font(TypeScale.caption1.font())
                .foregroundStyle(Palette.textSecondary)
                .lineHeight(FactMetrics.lineHeight, for: .caption1)
        }
        .foregroundStyle(Palette.label)
        .padding(.top, FactMetrics.paddingTop)
        .padding(.horizontal, FactMetrics.paddingX)
        .padding(.bottom, FactMetrics.paddingBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.fillQuaternary, in: .rect(cornerRadius: FactMetrics.radius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Maße der Fakten-Kachel (`.fact`: `padding: 10px 11px 11px; border-radius: 14px`).
enum FactMetrics {
    static let paddingTop: CGFloat = 10
    static let paddingX: CGFloat = 11
    static let paddingBottom: CGFloat = 11
    static let radius: CGFloat = 14
    /// Abstand zwischen Wert und Bezeichnung (`margin-top: 3px`).
    static let captionGap: CGFloat = 3
    /// Zeilenhöhe von Wert und Bezeichnung (`line-height: 1.25`).
    static let lineHeight: CGFloat = 1.25
    /// Zeilenhöhe der großen Zahl (`line-height: 1.1`).
    static let prominentLineHeight: CGFloat = 1.1
}
