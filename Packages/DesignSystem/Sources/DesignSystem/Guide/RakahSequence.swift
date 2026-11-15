import PrayerCore
import SwiftUI

/// Die Rakʿa-Folge in der Kopfkarte der Anleitung: nummerierte Kreise – gefüllt für laut, getönt für
/// leise rezitiert –, darunter „laut“ oder „leise“; nach der zweiten Rakʿa die Pille „Sitzen“, am Ende
/// „Sitzen · Salām“. `.rak` im Prototyp.
///
/// Passt die Folge nicht in eine Reihe, bricht sie um. Für VoiceOver ist sie ein Bild mit dem Text
/// „Ablauf der Rakʿas: 1 leise, 2 leise, …“; die Pillen nennt der Text nicht, wie im Prototyp. Laut und
/// leise hängen nicht allein an der Farbe: Unter jedem Kreis steht es als Wort.
public struct RakahSequence: View {
    private let rakahs: Rakahs

    public init(_ rakahs: Rakahs) {
        self.rakahs = rakahs
    }

    public var body: some View {
        FlowLayout(horizontalSpacing: RakahMetrics.columnGap, verticalSpacing: RakahMetrics.rowGap) {
            ForEach(rakahs.sequence, id: \.self) { item in
                switch item {
                case .rakah(let number, let isAloud):
                    unit(number: number, isAloud: isAloud)
                case .sitting:
                    pill(L10n.tashSit)
                case .finalSitting:
                    pill(L10n.tashEnd)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rakahs.accessibilityDescription)
        .accessibilityAddTraits(.isImage)
    }

    /// Eine Rakʿa (`.rak-unit`): Kreis mit Nummer, darunter laut oder leise.
    private func unit(number: Int, isAloud: Bool) -> some View {
        VStack(spacing: RakahMetrics.unitGap) {
            Text(L10n.number(number))
                .font(.system(size: RakahMetrics.numberSize, weight: .bold, design: .rounded))
                .foregroundStyle(isAloud ? Palette.onAccent : Palette.accent)
                .frame(width: RakahMetrics.dotSize, height: RakahMetrics.dotSize)
                .background(isAloud ? Palette.accent : Palette.accentTint, in: .circle)
            Text(isAloud ? L10n.recAloud : L10n.recSilent)
                .textStyle(.caption2, lineHeight: RakahMetrics.captionLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .fixedSize()
        }
        .frame(minWidth: RakahMetrics.unitMinWidth)
    }

    /// „Sitzen“ und „Sitzen · Salām“ (`.rak-sit`). Bricht nie um (`white-space: nowrap`).
    private func pill(_ text: String) -> some View {
        Text(text)
            .textStyle(.caption2, weight: .semibold, lineHeight: RakahMetrics.captionLineHeight)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize()
            .padding(.horizontal, RakahMetrics.pillPaddingX)
            .padding(.vertical, RakahMetrics.pillPaddingY)
            .background(Palette.fillTertiary, in: .capsule)
            .padding(.top, RakahMetrics.pillTop)
    }
}

/// Maße der Rakʿa-Folge (`.rak`, `.rak-unit`, `.rak-dot`, `.rak-sub`, `.rak-sit`).
enum RakahMetrics {
    /// Abstand zwischen den Gliedern und zwischen den Reihen (`.rak`: `gap: 10px 6px`).
    static let columnGap: CGFloat = 6
    static let rowGap: CGFloat = 10
    /// Eine Rakʿa (`.rak-unit`: `gap: 4px; min-width: 38px`).
    static let unitGap: CGFloat = 4
    static let unitMinWidth: CGFloat = 38
    /// Kreis (`.rak-dot`: 34 × 34 pt, `font: 700 15px/1` rund). Er wächst nicht mit Dynamic Type.
    static let dotSize: CGFloat = 34
    static let numberSize: CGFloat = 15
    /// Zeilenhöhe von „laut“/„leise“ und der Pillen (`line-height: 1.3`).
    static let captionLineHeight: CGFloat = 1.3
    /// Pille (`.rak-sit`: `margin-top: 7px; padding: 4px 9px`).
    static let pillTop: CGFloat = 7
    static let pillPaddingX: CGFloat = 9
    static let pillPaddingY: CGFloat = 4
}
