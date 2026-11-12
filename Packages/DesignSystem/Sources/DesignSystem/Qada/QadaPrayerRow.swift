import PrayerCore
import SwiftUI

/// Ein Gebet unter „Nach Gebet“ beim Nachholen: Symbol, Name, die Zahl der offenen Gebete und ein
/// Stepper – `.qrow` in `qadaPage()`.
///
/// „−“ heißt: ein Gebet nachgeholt, „+“: ein Gebet mehr offen (Design Spec § 4). VoiceOver sagt das je
/// Taste („Ein Fadschr nachgeholt“, „Ein Fadschr mehr offen“).
public struct QadaPrayerRow: View {
    private let prayer: QadaPrayer
    private let count: String
    private let canMarkMadeUp: Bool
    private let canAddMissed: Bool
    private let onMadeUp: () -> Void
    private let onMissed: () -> Void

    /// - Parameters:
    ///   - count: die offenen Gebete, fertig geschrieben, z. B. „501“.
    ///   - onMadeUp: „−“ – ein Gebet nachgeholt.
    ///   - onMissed: „+“ – ein Gebet mehr offen.
    public init(
        _ prayer: QadaPrayer, count: String, canMarkMadeUp: Bool, canAddMissed: Bool,
        onMadeUp: @escaping () -> Void, onMissed: @escaping () -> Void
    ) {
        self.prayer = prayer
        self.count = count
        self.canMarkMadeUp = canMarkMadeUp
        self.canAddMissed = canAddMissed
        self.onMadeUp = onMadeUp
        self.onMissed = onMissed
    }

    public var body: some View {
        let name = prayer.localizedName
        HStack(spacing: QadaRowMetrics.gap) {
            HStack(spacing: QadaRowMetrics.gap) {
                Image(systemName: prayer.symbolName)
                    .font(.system(size: QadaRowMetrics.symbolSize, weight: QadaRowMetrics.symbolWeight))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(width: QadaRowMetrics.symbolBox)
                    .accessibilityHidden(true)
                Text(name)
                    .textStyle(.body, lineHeight: QadaRowMetrics.nameLineHeight)
                    .foregroundStyle(Palette.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(count)
                    .monospacedDigit()
                    .textStyle(.headline, lineHeight: QadaRowMetrics.countLineHeight)
                    .foregroundStyle(Palette.label)
                    .frame(minWidth: QadaRowMetrics.countMinWidth, alignment: .trailing)
            }
            // Name und Zahl sind für VoiceOver eine Angabe: „Fadschr, 501“.
            .accessibilityElement(children: .combine)
            StepperPill(
                name, canDecrement: canMarkMadeUp, canIncrement: canAddMissed,
                decrementLabel: L10n.qadaMinus(p: name), incrementLabel: L10n.qadaPlus(p: name),
                onDecrement: onMadeUp, onIncrement: onMissed
            )
        }
        .padding(QadaRowMetrics.insets)
        .frame(maxWidth: .infinity, minHeight: Layout.prayerRowHeight)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.row, style: .continuous))
    }
}

/// Maße einer Zeile (`.qrow`: `gap: 12px; min-height: 52px; padding: 6px 10px 6px 16px`; `.prow-ic`:
/// 24 pt, `ic(…, 20)`; `.num`: `min-width: 52px; font: 600 17px/1.2`).
enum QadaRowMetrics {
    static let insets = EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 10)
    static let gap: CGFloat = 12
    static let symbolBox: CGFloat = 24
    /// Das Symbol der Gebetskarte (14,5 pt für `ic(…, 22)`), auf die 20 pt dieser Zeile verkleinert.
    static let symbolSize: CGFloat = 13.2
    static let symbolWeight: Font.Weight = .semibold
    static let nameLineHeight: CGFloat = 1.3
    static let countLineHeight: CGFloat = 1.2
    static let countMinWidth: CGFloat = 52
    /// Abstand zwischen den Zeilen (`.qrows`: `gap: 8px`).
    static let rowGap: CGFloat = 8
}
