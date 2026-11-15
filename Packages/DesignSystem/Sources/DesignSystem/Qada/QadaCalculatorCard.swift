import PrayerCore
import SwiftUI

/// Der Nachhol-Rechner als eigene Karte ganz unten auf der Seite „Nachholen“ (Spec § 9.8, `.qcalc` in
/// `qadaPage()`): oben eine Kachel mit dem Symbol des Tabs, Titel und Einleitung; darunter drei
/// nummerierte Schritte – Zeitraum (Jahre, Monate, Tage mit je einem Stepper), Witr, Ergebnis groß in
/// Akzent –, dann der Knopf „Als offen übernehmen“ und der Hinweis dazu. Bei 0 Tagen ist der Knopf
/// gesperrt. Die Karte hat einen feinen Rand in Akzent.
public struct QadaCalculatorCard: View {
    private let ledger: QadaLedger
    private let onAction: (QadaAction) -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    public init(ledger: QadaLedger, onAction: @escaping (QadaAction) -> Void) {
        self.ledger = ledger
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            VStack(alignment: .leading, spacing: QadaCalculatorMetrics.stepGap) {
                step(1) { period }
                step(2) { witr }
                step(3) { result }
            }
            .padding(.top, QadaCalculatorMetrics.stepsTop)
            .padding(.bottom, QadaCalculatorMetrics.stepsBottom)

            PrimaryButton(L10n.qadaApply, systemImage: "checkmark") {
                onAction(.applyPeriod)
            }
            .disabled(ledger.periodDays == 0)

            Text(hyphenating: L10n.qadaApplyFooter)
                .textStyle(.footnote, lineHeight: QadaCalculatorMetrics.footLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, QadaCalculatorMetrics.footTop)
                .padding(.horizontal, QadaCalculatorMetrics.footInsetX)
        }
        .padding(QadaCalculatorMetrics.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.group, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.group, style: .continuous)
                .strokeBorder(Palette.accent.opacity(QadaCalculatorMetrics.outlineOpacity), lineWidth: QadaCalculatorMetrics.outlineWidth)
        }
    }

    // MARK: - Kopf

    /// `.qc-head`: Kachel in Akzent mit dem Symbol des Tabs, daneben Titel und Einleitung.
    private var head: some View {
        HStack(alignment: .top, spacing: QadaCalculatorMetrics.headGap) {
            RoundedRectangle(cornerRadius: QadaCalculatorMetrics.tileRadius, style: .continuous)
                .fill(Palette.accent)
                .frame(width: QadaCalculatorMetrics.tileSize, height: QadaCalculatorMetrics.tileSize)
                .overlay {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: QadaCalculatorMetrics.tileSymbolSize, weight: .medium))
                        .foregroundStyle(Palette.onAccent)
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: QadaCalculatorMetrics.titleBottom) {
                Text(hyphenating: L10n.qcTitle)
                    .textStyle(.title3, weight: .bold, lineHeight: QadaCalculatorMetrics.titleLineHeight)
                    .foregroundStyle(Palette.label)
                    .accessibilityAddTraits(.isHeader)
                Text(hyphenating: L10n.qcLead)
                    .textStyle(.subheadline, lineHeight: QadaCalculatorMetrics.leadLineHeight)
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Schritte

    /// Ein Schritt mit seiner Nummer im getönten Kreis (`.qc-steps > li`, `.qc-n`).
    private func step(_ number: Int, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: QadaCalculatorMetrics.numberGap) {
            Text(L10n.number(number))
                .font(.system(size: QadaCalculatorMetrics.numberFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.accent)
                .frame(width: QadaCalculatorMetrics.numberSize, height: QadaCalculatorMetrics.numberSize)
                .background(Palette.accentTint, in: .circle)
                .padding(.top, QadaCalculatorMetrics.numberTop)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// `.qc-label`
    private func label(_ text: String) -> some View {
        Text(text)
            .textStyle(.subheadline, weight: .semibold, lineHeight: QadaCalculatorMetrics.labelLineHeight)
            .foregroundStyle(Palette.label)
            .padding(.bottom, QadaCalculatorMetrics.labelBottom)
            .accessibilityAddTraits(.isHeader)
    }

    /// Schritt 1: Jahre, Monate und Tage in drei gleich breiten Feldern.
    private var period: some View {
        VStack(alignment: .leading, spacing: 0) {
            label(L10n.qcStep1)
            HStack(spacing: QadaCalculatorMetrics.fieldGap) {
                field(.years)
                field(.months)
                field(.days)
            }
        }
    }

    /// `.qc-field`: Name, Zahl und ein kleiner Stepper.
    private func field(_ field: QadaLedger.Field) -> some View {
        let value = ledger[field]
        let title = field.localizedTitle
        let size = QadaCalculatorMetrics.fieldValueSize * min(max(typeScale, 0), QadaCalculatorMetrics.valueMaxScale)
        return VStack(spacing: QadaCalculatorMetrics.fieldInnerGap) {
            Text(title)
                .textStyle(.caption1, lineHeight: QadaCalculatorMetrics.labelLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(QadaSummary.number(value))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Palette.label)
                .lineHeight(1, fontSize: size)
                .accessibilityLabel("\(title) \(QadaSummary.number(value))")
            StepperPill(
                title, canDecrement: value > field.range.lowerBound, canIncrement: value < field.range.upperBound,
                size: .compact,
                onDecrement: { onAction(.step(field, by: -1)) }, onIncrement: { onAction(.step(field, by: 1)) }
            )
        }
        .padding(QadaCalculatorMetrics.fieldPadding)
        .frame(maxWidth: .infinity)
        .background(Palette.fillQuaternary, in: .rect(cornerRadius: QadaCalculatorMetrics.fieldRadius, style: .continuous))
    }

    /// Schritt 2: der Schalter „Witr einbeziehen“, ohne eigene Fläche (`.qc-witr .row`).
    private var witr: some View {
        Toggle(isOn: Binding(get: { ledger.includesWitr }, set: { onAction(.setWitr($0)) })) {
            VStack(alignment: .leading, spacing: QadaCalculatorMetrics.witrDetailGap) {
                Text(hyphenating: L10n.witr)
                    .textStyle(.body, lineHeight: QadaCalculatorMetrics.witrLineHeight)
                    .foregroundStyle(Palette.label)
                Text(hyphenating: L10n.witrSub)
                    .textStyle(.footnote, lineHeight: QadaCalculatorMetrics.witrLineHeight)
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
        .tint(Palette.accent)
        .frame(minHeight: Layout.minTapTarget)
    }

    /// Schritt 3: die Zahl der Gebete groß in Akzent, dahinter „Gebete nachzuholen“, darunter
    /// „545 Tage × 5 Gebete“.
    private var result: some View {
        let size = QadaCalculatorMetrics.resultSize * min(max(typeScale, 0), QadaCalculatorMetrics.valueMaxScale)
        let number = QadaSummary.number(ledger.periodPrayers)
        let unit = Text(L10n.qcResultUnit(n: ledger.periodPrayers))
            .textStyle(.subheadline, lineHeight: QadaCalculatorMetrics.labelLineHeight)
            .foregroundStyle(Palette.textSecondary)
        let value = Text(number)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .tracking(QadaCalculatorMetrics.resultTracking)
            .foregroundStyle(Palette.accent)
            .lineHeight(QadaCalculatorMetrics.resultLineHeight, fontSize: size)
        return VStack(alignment: .leading, spacing: 0) {
            label(L10n.qcStep3)
            // `flex-wrap`: Passt die Einheit nicht mehr daneben, rückt sie unter die Zahl.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: QadaCalculatorMetrics.resultGap) {
                    value
                    unit
                }
                VStack(alignment: .leading, spacing: QadaCalculatorMetrics.resultWrapGap) {
                    value
                    unit
                }
            }
            .accessibilityElement(children: .combine)
            Text(L10n.qcResultDetail(d: ledger.periodDays, k: ledger.prayers.count))
                .textStyle(.footnote, lineHeight: QadaCalculatorMetrics.labelLineHeight)
                .monospacedDigit()
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, QadaCalculatorMetrics.detailTop)
        }
    }
}

/// Maße der Karte (`.qcalc`, `.qc-*` im Prototyp).
enum QadaCalculatorMetrics {
    /// `.qcalc`: `padding: 18px 18px 16px`, Rand innen 1,5 pt in Akzent zu 30 %.
    static let padding = EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)
    static let outlineOpacity = 0.3
    static let outlineWidth: CGFloat = 1.5

    /// `.qc-head`: `gap: 12px`; Kachel 44 pt, Ecken 12, `ic('qada', 24)`; Titel 700 Title 3/1,25 mit 3 pt
    /// Abstand, Einleitung Subheadline/1,38.
    static let headGap: CGFloat = 12
    static let tileSize: CGFloat = 44
    static let tileRadius: CGFloat = 12
    static let tileSymbolSize: CGFloat = 20
    static let titleLineHeight: CGFloat = 1.25
    static let titleBottom: CGFloat = 3
    static let leadLineHeight: CGFloat = 1.38

    /// `.qc-steps`: `gap: 16px; margin: 18px 0 16px`; `li`: `gap: 12px`; `.qc-n`: 24 pt, 700 13 pt rund,
    /// `margin-top: 1px`.
    static let stepGap: CGFloat = 16
    static let stepsTop: CGFloat = 18
    static let stepsBottom: CGFloat = 16
    static let numberGap: CGFloat = 12
    static let numberSize: CGFloat = 24
    static let numberFontSize: CGFloat = 13
    static let numberTop: CGFloat = 1

    /// `.qc-label`: `margin-bottom: 8px`, 600 Subheadline/1,3.
    static let labelBottom: CGFloat = 8
    static let labelLineHeight: CGFloat = 1.3

    /// `.qc-fields`: `gap: 8px`; `.qc-field`: `gap: 6px; padding: 10px 4px 9px`, Ecken 12; die Zahl
    /// 700 24 pt rund, wächst höchstens auf das 1,2-Fache.
    static let fieldGap: CGFloat = 8
    static let fieldInnerGap: CGFloat = 6
    static let fieldPadding = EdgeInsets(top: 10, leading: 4, bottom: 9, trailing: 4)
    static let fieldRadius: CGFloat = 12
    static let fieldValueSize: CGFloat = 24
    static let valueMaxScale: CGFloat = 1.2

    /// Witr: Zeile ohne Fläche, mindestens 44 pt hoch; Titel und Zusatz wie in einer Liste.
    static let witrDetailGap: CGFloat = 2
    static let witrLineHeight: CGFloat = 1.3

    /// `.qc-result`: `gap: 2px 8px`; Zahl 700 40 pt rund, Zeilenhöhe 1,05, `letter-spacing: -.5px`, in
    /// Akzent; `.qc-detail`: `margin-top: 3px`.
    static let resultSize: CGFloat = 40
    static let resultLineHeight: CGFloat = 1.05
    static let resultTracking: CGFloat = -0.5
    static let resultGap: CGFloat = 8
    static let resultWrapGap: CGFloat = 2
    static let detailTop: CGFloat = 3

    /// `.qc-foot`: `margin: 10px 2px 0`, Fußnote/1,38.
    static let footTop: CGFloat = 10
    static let footInsetX: CGFloat = 2
    static let footLineHeight: CGFloat = 1.38
}
