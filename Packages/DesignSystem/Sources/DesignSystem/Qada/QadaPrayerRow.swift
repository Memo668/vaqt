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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                HStack(spacing: QadaRowMetrics.gap) {
                    HStack(spacing: QadaRowMetrics.gap) {
                        symbol
                        nameText
                            .frame(maxWidth: .infinity, alignment: .leading)
                        countText
                            .frame(minWidth: QadaRowMetrics.countMinWidth, alignment: .trailing)
                    }
                    // Name und Zahl sind für VoiceOver eine Angabe: „Fadschr, 501“.
                    .accessibilityElement(children: .combine)
                    stepper
                }
            }
        }
        .padding(QadaRowMetrics.insets)
        .frame(maxWidth: .infinity, minHeight: Layout.prayerRowHeight)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.row, style: .continuous))
    }
}

extension QadaPrayerRow {

    /// Ab den AX-Größen untereinander: Symbol und Name, darunter die Zahl, darunter der Stepper – nebeneinander
    /// zerfielen Name und Zahl („Dhuh-r“, „50-1“; Phase 11).
    private var stacked: some View {
        VStack(alignment: .leading, spacing: QadaRowMetrics.gap) {
            HStack(alignment: .top, spacing: QadaRowMetrics.gap) {
                symbol
                VStack(alignment: .leading, spacing: QadaRowMetrics.stackedGap) {
                    nameText
                        .fixedSize(horizontal: false, vertical: true)
                    countText
                        .fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            stepper
        }
    }

    private var symbol: some View {
        Image(systemName: prayer.symbolName)
            .font(.system(size: QadaRowMetrics.symbolSize, weight: QadaRowMetrics.symbolWeight))
            .foregroundStyle(Palette.textSecondary)
            .frame(width: QadaRowMetrics.symbolBox)
            .accessibilityHidden(true)
    }

    private var nameText: some View {
        Text(hyphenating: prayer.localizedName)
            .textStyle(.body, lineHeight: QadaRowMetrics.nameLineHeight)
            .foregroundStyle(Palette.label)
    }

    private var countText: some View {
        Text(count)
            .monospacedDigit()
            .textStyle(.headline, lineHeight: QadaRowMetrics.countLineHeight)
            .foregroundStyle(Palette.label)
    }

    private var stepper: some View {
        let name = prayer.localizedName
        return StepperPill(
            name, canDecrement: canMarkMadeUp, canIncrement: canAddMissed,
            decrementLabel: L10n.qadaMinus(p: name), incrementLabel: L10n.qadaPlus(p: name),
            onDecrement: onMadeUp, onIncrement: onMissed
        )
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
    /// Ab den AX-Größen: Abstand zwischen Name und Zahl.
    static let stackedGap: CGFloat = 2
}
