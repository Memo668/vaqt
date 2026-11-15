import PrayerCore
import SwiftUI

/// Gebetskarte: eine alleinstehende Karte je Tagesereignis, keine gruppierte Liste.
///
/// Symbol · Name · Chip „Jetzt“ · Uhrzeit · Glocke. Das laufende Gebet hat eine mit Akzent gemischte
/// Karte, einen weichen Akzentschatten und Schrift in Akzent; vergangene Ereignisse stehen in
/// Sekundärfarbe. Unter dem Namen steht bei Sonnenaufgang, Dhuhr und Asr die Kerahat-Zeile mit einem
/// Punkt in Kerahat-Farbe. Der Zustand hängt nie allein an der Farbe: Das laufende Gebet trägt den Chip.
///
/// Design Spec § 3 („PrayerRow“), `prayerRow()` und `.prow` im Prototyp.
public struct PrayerRow: View {
    private let model: PrayerRowModel
    private let bell: BellState
    private let onBell: () -> Void

    @ScaledMetric(relativeTo: .caption2) private var chipLineHeight = TypeScale.caption2.pointSize
    @ScaledMetric(relativeTo: .caption) private var captionSize = TypeScale.caption1.pointSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - bell: Stand der Mitteilung für dieses Ereignis.
    ///   - onBell: Tippen auf die Glocke; die Seite wechselt den Stand (`BellState.next`).
    public init(_ model: PrayerRowModel, bell: BellState, onBell: @escaping () -> Void) {
        self.model = model
        self.bell = bell
        self.onBell = onBell
    }

    public var body: some View {
        HStack(spacing: RowMetrics.gap) {
            Image(systemName: model.prayer.symbolName)
                .font(.system(size: RowMetrics.symbolSize, weight: RowMetrics.symbolWeight))
                .foregroundStyle(symbolColor)
                .frame(width: RowMetrics.symbolBox)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: RowMetrics.captionGap) {
                nameLine
                if stacksTime {
                    time
                }
                if let kerahat = model.kerahat {
                    caption(kerahat)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !stacksTime {
                time
            }

            BellButton(state: bell, prayerName: model.prayer.localizedName, isCurrent: isCurrent, action: onBell)
        }
        .padding(.leading, RowMetrics.leading)
        .padding(.trailing, RowMetrics.trailing)
        .frame(minHeight: Layout.prayerRowHeight)
        .background(
            isCurrent ? Palette.currentRow : Palette.backgroundCell,
            in: .rect(cornerRadius: Radius.row, style: .continuous)
        )
        .shadow(isCurrent ? ShadowToken.currentRow : ShadowToken.row)
        .accessibilityElement(children: .contain)
    }

    private var isCurrent: Bool {
        model.status == .current
    }

    /// Ab den AX-Größen steht die Uhrzeit unter dem Namen: So haben Name, Uhrzeit und Kerahat-Zeile die
    /// Breite der Karte, und keine Uhrzeit bricht mitten in der Zahl um (Spec § 4: „rows wrap“; Phase 11).
    private var stacksTime: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    private var time: some View {
        Text(L10n.time(model.time))
            .font(TypeScale.body.font(weight: isCurrent ? .semibold : nil))
            .monospacedDigit()
            .tracking(Typography.prayerTimeTracking)
            .foregroundStyle(textColor)
            .fixedSize()
    }

    // MARK: - Name, Marken, Kerahat-Zeile

    /// Name, Info-Marke und Chip stehen nebeneinander; passt das nicht, rutscht der Chip in die nächste
    /// Zeile (`flex-wrap`). Ab den AX-Größen stehen sie immer untereinander, und der Name bricht um.
    @ViewBuilder
    private var nameLine: some View {
        if stacksTime {
            VStack(alignment: .leading, spacing: RowMetrics.nameGap) {
                name
                    .fixedSize(horizontal: false, vertical: true)
                if model.showsHighLatitudeMark || isCurrent {
                    HStack(spacing: RowMetrics.nameGap) { marks }
                }
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: RowMetrics.nameGap) {
                    name
                    marks
                }
                VStack(alignment: .leading, spacing: RowMetrics.nameGap) {
                    name
                    HStack(spacing: RowMetrics.nameGap) { marks }
                }
            }
        }
    }

    private var name: some View {
        Text(hyphenating: model.prayer.localizedName)
            .textStyle(.body, weight: isCurrent ? .semibold : nil, lineHeight: RowMetrics.nameLineHeight)
            .foregroundStyle(textColor)
    }

    @ViewBuilder
    private var marks: some View {
        if model.showsHighLatitudeMark {
            Image(systemName: "info.circle")
                .font(.system(size: RowMetrics.infoSize))
                .foregroundStyle(Palette.accent)
                .accessibilityLabel(L10n.highLatTitle)
        }
        if isCurrent {
            Text(L10n.now)
                .font(Typography.nowChip)
                .tracking(Typography.nowChipTracking)
                .textCase(.uppercase)
                .foregroundStyle(Palette.onAccent)
                .fixedSize()
                .frame(height: chipLineHeight)
                .padding(.horizontal, RowMetrics.chipPaddingX)
                .padding(.vertical, RowMetrics.chipPaddingY)
                .background(Palette.accent, in: .rect(cornerRadius: RowMetrics.chipRadius, style: .continuous))
        }
    }

    private func caption(_ kerahat: PrayerRowModel.KerahatCaption) -> some View {
        HStack(alignment: .top, spacing: RowMetrics.dotGap) {
            Circle()
                .fill(Palette.kerahat)
                .opacity(kerahat.isActive ? 1 : RowMetrics.dotOpacity)
                .frame(width: RowMetrics.dotSize, height: RowMetrics.dotSize)
                // `margin-top: calc(.62em - 2.5px)`: Der Punkt sitzt auf Höhe der Ziffernmitte.
                .padding(.top, captionSize * 0.62 - RowMetrics.dotSize / 2)
                .accessibilityHidden(true)
            Text(kerahat.text)
                .textStyle(.caption1, lineHeight: RowMetrics.captionLineHeight)
                .monospacedDigit()
                .foregroundStyle(kerahatColor(isActive: kerahat.isActive))
                // Die Zeitspanne bricht nie um (Spec § 3). Ab den AX-Größen ist sie breiter als die Karte:
                // Dann steht sie in der zweiten Zeile und wird etwas kleiner, statt in der Zahl umzubrechen.
                .lineLimit(stacksTime ? RowMetrics.stackedCaptionLines : nil)
                .minimumScaleFactor(stacksTime ? RowMetrics.stackedCaptionMinimumScale : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Farben

    /// Auf der Karte des laufenden Gebets ist die Schrift hell etwas dunkler (`Palette.currentRowAccent`,
    /// Phase 11: Kontrast 4,5 : 1).
    private var textColor: Color {
        switch model.status {
        case .current: Palette.currentRowAccent
        case .passed: Palette.textSecondary
        case .upcoming: Palette.label
        }
    }

    private func kerahatColor(isActive: Bool) -> Color {
        switch (model.status, isActive) {
        case (.current, true): Palette.currentRowKerahatText
        case (.current, false): Palette.currentRowTextSecondary
        case (_, true): Palette.kerahatText
        case (_, false): Palette.textSecondary
        }
    }

    private var symbolColor: Color {
        switch model.status {
        case .current: Palette.accent
        case .passed: Palette.labelTertiary
        case .upcoming: Palette.textSecondary
        }
    }
}

/// Maße der Gebetskarte (`.prow` und ihre Teile).
enum RowMetrics {
    /// Abstand zwischen Symbol, Name, Uhrzeit und Glocke (`gap: 12px`).
    static let gap: CGFloat = 12
    /// Innenabstand vor dem Symbol (`padding-inline: 16px 4px`).
    static let leading: CGFloat = 16
    /// Innenabstand hinter der Glocke.
    static let trailing: CGFloat = 4
    /// Breite des Symbolfelds (`.prow-ic`).
    static let symbolBox: CGFloat = 24
    /// Symbol des Ereignisses – `ic(PICON[p], 22)`. Als Schriftgröße eines SF Symbols so gewählt, dass
    /// es so breit erscheint wie die Zeichnung des Prototyps (knapp 18 pt).
    static let symbolSize: CGFloat = 14.5
    /// Strichstärke des Symbols: Der Prototyp zeichnet mit 1,65 pt.
    static let symbolWeight: Font.Weight = .semibold
    /// Abstand zwischen Name, Info-Marke und Chip, waagerecht wie senkrecht (`.prow-name`: `gap: 6px`).
    static let nameGap: CGFloat = 6
    /// Zeilenhöhe des Namens (`line-height: 1.3`).
    static let nameLineHeight: CGFloat = 1.3
    /// Info-Marke für hohe Breiten – `ic('info', 15)`.
    static let infoSize: CGFloat = 13
    /// Chip „Jetzt“: `padding: 3px 6px; border-radius: 5px`.
    static let chipPaddingX: CGFloat = 6
    static let chipPaddingY: CGFloat = 3
    static let chipRadius: CGFloat = 5
    /// Abstand zwischen Name und Kerahat-Zeile: die 6 pt zwischen den Zeilen von `.prow-name`, um
    /// 1 pt verringert (`.prow-sub`: `margin-top: -1px`).
    static let captionGap: CGFloat = 5
    /// Zeilenhöhe der Kerahat-Zeile (`line-height: 1.25`).
    static let captionLineHeight: CGFloat = 1.25
    /// Punkt vor der Kerahat-Zeile (`.k-dot`): 5 pt, Abstand 5 pt, 75 % Deckkraft außerhalb des Fensters.
    static let dotSize: CGFloat = 5
    static let dotGap: CGFloat = 5
    static let dotOpacity = 0.75
    /// Ab den AX-Größen: die Kerahat-Zeile in höchstens zwei Zeilen – „Kerahat“ und die Spanne –, die
    /// Spanne bis auf 70 % kleiner, wenn sie sonst nicht in eine Zeile passt (Phase 11).
    static let stackedCaptionLines = 2
    static let stackedCaptionMinimumScale: CGFloat = 0.7
}
