import PrayerCore
import SwiftUI

/// Zeile unter Einstellungen › Pro Gebet: Symbol, Name und drei Segmente mit den Glocken – Ton, Lautlos,
/// Aus (`PAGES.perPrayer` im Prototyp, Spec § 3 „Segmented icon picker“).
///
/// Das Symbol steht in Sekundärfarbe in einem Feld von 24 pt; die Trennlinie der Liste beginnt erst beim
/// Namen (`.row.has-ic`: 52 pt).
public struct PrayerNotificationRow: View {
    private let prayer: Prayer
    private let state: BellState
    private let onSelect: (BellState) -> Void

    public init(prayer: Prayer, state: BellState, onSelect: @escaping (BellState) -> Void) {
        self.prayer = prayer
        self.state = state
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: ListRowMetrics.gap) {
            Image(systemName: prayer.symbolName)
                .font(.system(size: SettingsBlockMetrics.prayerSymbolSize, weight: SettingsBlockMetrics.prayerSymbolWeight))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: SettingsBlockMetrics.symbolBox)
                .accessibilityHidden(true)
            Text(hyphenating: prayer.localizedName)
                .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            SegmentedControl(
                prayer.localizedName,
                segments: BellState.allCases.map {
                    .init(value: $0, title: $0.localizedName, systemImage: $0.symbolName)
                },
                selection: state,
                segmentWidth: SegmentMetrics.symbolSegmentWidth,
                onSelect: onSelect
            )
            .fixedSize()
        }
    }
}

/// Zeile unter Einstellungen › Minutenkorrektur: Name, Uhrzeit von heute, Korrektur und Stepper
/// (`PAGES.adjust` im Prototyp).
public struct AdjustmentRow: View {
    private let title: String
    private let time: String
    private let value: String
    private let stepper: StepperPill

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - time: die Uhrzeit von heute mit der Korrektur, z. B. „05:16“.
    ///   - value: die Korrektur, z. B. „+2 Min.“.
    ///   - decrementLabel: VoiceOver-Text von „−“, z. B. „Fadschr eine Minute früher“ (`adjMinus`).
    ///   - incrementLabel: VoiceOver-Text von „+“ (`adjPlus`).
    public init(
        _ title: String, time: String, value: String,
        canDecrement: Bool, canIncrement: Bool,
        decrementLabel: String, incrementLabel: String,
        onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void
    ) {
        self.title = title
        self.time = time
        self.value = value
        stepper = StepperPill(
            title, canDecrement: canDecrement, canIncrement: canIncrement,
            decrementLabel: decrementLabel, incrementLabel: incrementLabel,
            onDecrement: onDecrement, onIncrement: onIncrement
        )
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Ab den AX-Größen untereinander: Name, Uhrzeit, Korrektur, Stepper – nebeneinander brachen
            // Uhrzeit und Korrektur mitten in der Zahl um (Phase 11).
            VStack(alignment: .leading, spacing: ListRowMetrics.gap) {
                VStack(alignment: .leading, spacing: ListRowMetrics.detailGap) {
                    titleText
                        .fixedSize(horizontal: false, vertical: true)
                    timeText
                        .fixedSize()
                    valueText
                        .fixedSize()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                stepper
            }
        } else {
            HStack(spacing: ListRowMetrics.gap) {
                HStack(spacing: ListRowMetrics.gap) {
                    VStack(alignment: .leading, spacing: ListRowMetrics.detailGap) {
                        titleText
                        timeText
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    valueText
                        .multilineTextAlignment(.trailing)
                }
                // Für VoiceOver eine Angabe: „Fadschr, 05:16, 0 Min.“
                .accessibilityElement(children: .combine)
                stepper
            }
        }
    }

    private var titleText: some View {
        Text(hyphenating: title)
            .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
            .foregroundStyle(Palette.label)
    }

    private var timeText: some View {
        Text(time)
            .monospacedDigit()
            .textStyle(.footnote, lineHeight: ListRowMetrics.lineHeight)
            .foregroundStyle(Palette.textSecondary)
    }

    private var valueText: some View {
        Text(value)
            .monospacedDigit()
            .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
            .foregroundStyle(Palette.textSecondary)
    }
}

/// Die Seite „Datenschutz“: Schild auf getöntem Kreis, Überschrift und zwei Absätze, mittig
/// (`PAGES.privacy`, `.prose` im Prototyp).
public struct PrivacyNote: View {
    private let title: String
    private let paragraphs: [String]

    public init(title: String, paragraphs: [String]) {
        self.title = title
        self.paragraphs = paragraphs
    }

    public var body: some View {
        VStack(spacing: 0) {
            IconBadge(systemImage: "checkmark.shield", symbolSize: IconBadgeMetrics.shieldSymbolSize)
            Text(title)
                .tracking(SettingsBlockMetrics.proseTitleTracking)
                .textStyle(.title2, weight: .bold, lineHeight: SettingsBlockMetrics.proseTitleLineHeight)
                .foregroundStyle(Palette.label)
                .padding(.top, SettingsBlockMetrics.proseTitleTop)
                .padding(.bottom, SettingsBlockMetrics.proseTitleBottom)
                .accessibilityAddTraits(.isHeader)
            ForEach(paragraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .textStyle(.body, lineHeight: SettingsBlockMetrics.proseLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.bottom, SettingsBlockMetrics.paragraphGap)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, SettingsBlockMetrics.proseInsetX)
        .padding(.top, SettingsBlockMetrics.proseTop)
        .padding(.bottom, SettingsBlockMetrics.proseBottom - SettingsBlockMetrics.paragraphGap)
    }
}

/// Maße der Bausteine der Einstellungen (`.prow-ic`, `.prose`).
enum SettingsBlockMetrics {
    /// Feld des Symbols vor dem Namen (`.prow-ic`: 24 pt) und das Symbol darin – `ic(PICON[p], 20)`, wie
    /// das Symbol der Gebetskarten (`ic(…, 22)`) auf 20 pt verkleinert.
    static let symbolBox: CGFloat = 24
    static let prayerSymbolSize: CGFloat = 13.2
    static let prayerSymbolWeight: Font.Weight = .semibold

    /// `.prose { padding: 6px 28px 24px }`
    static let proseTop: CGFloat = 6
    static let proseInsetX: CGFloat = 28
    static let proseBottom: CGFloat = 24
    /// `.prose h2 { margin: 22px 0 10px; font: 700 var(--fs-title2)/1.25; letter-spacing: .35px }`
    static let proseTitleTop: CGFloat = 22
    static let proseTitleBottom: CGFloat = 10
    static let proseTitleLineHeight: CGFloat = 1.25
    static let proseTitleTracking: CGFloat = 0.35
    /// `.prose p { margin: 0 0 12px; line-height: 1.45 }`
    static let proseLineHeight: CGFloat = 1.45
    static let paragraphGap: CGFloat = 12
}
