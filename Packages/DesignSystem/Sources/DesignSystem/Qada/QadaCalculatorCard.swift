import PrayerCore
import SwiftUI

/// Der Nachhol-Rechner als eigene Karte ganz unten auf der Seite „Nachholen“ (Spec § 9.8, § 10.7, `.qcalc` in
/// `qadaPage()`): oben eine Kachel mit dem Symbol des Tabs, Titel und Einleitung; darunter vier
/// nummerierte Schritte – für wen (Mann oder Frau, bei Frauen Regel und Wochenbett), Zeitraum (Jahre,
/// Monate, Tage mit je einem Stepper), Witr, Ergebnis groß in Akzent –, dann der Knopf „Als offen
/// übernehmen“, der Hinweis dazu und „Alles zurücksetzen“ mit Warnung. Bei 0 Tagen ist der Knopf gesperrt.
/// Die Karte hat einen feinen Rand in Akzent.
public struct QadaCalculatorCard: View {
    private let ledger: QadaLedger
    private let onAction: (QadaAction) -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
    @State private var confirmsReset = false

    public init(ledger: QadaLedger, onAction: @escaping (QadaAction) -> Void) {
        self.ledger = ledger
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            head
            VStack(alignment: .leading, spacing: QadaCalculatorMetrics.stepGap) {
                step(1) { person }
                step(2) { period }
                step(3) { witr }
                step(4) { result }
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

            // Spec § 10.7: „Alles zurücksetzen“ in Rot, mit Warnung vorher.
            Button(L10n.qadaReset, role: .destructive) {
                confirmsReset = true
            }
            .buttonStyle(.borderless)
            .textStyle(.body, lineHeight: QadaCalculatorMetrics.witrLineHeight)
            .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget)
            .padding(.top, QadaCalculatorMetrics.resetTop)
            .alert(L10n.qadaResetTitle, isPresented: $confirmsReset) {
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.qadaResetConfirm, role: .destructive) {
                    onAction(.reset)
                }
            } message: {
                Text(L10n.qadaResetBody)
            }
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

    /// Schritt 1: Mann oder Frau als Segmente; bei Frauen zwei Felder für die Tage, an denen die Gebete
    /// entfallen, und der Hinweis dazu (Spec § 10.7).
    private var person: some View {
        VStack(alignment: .leading, spacing: 0) {
            label(L10n.qcWho)
            Picker(L10n.qcWho, selection: Binding(get: { ledger.person }, set: { onAction(.setPerson($0)) })) {
                Text(L10n.qcMan).tag(QadaLedger.Person.man)
                Text(L10n.qcWoman).tag(QadaLedger.Person.woman)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            if ledger.person == .woman {
                HStack(spacing: QadaCalculatorMetrics.fieldGap) {
                    field(.menstruationDays)
                    field(.postnatalDays)
                }
                .padding(.top, QadaCalculatorMetrics.personFieldsTop)
                Text(hyphenating: L10n.qcWomanNote)
                    .textStyle(.footnote, lineHeight: QadaCalculatorMetrics.labelLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, QadaCalculatorMetrics.detailTop)
            }
        }
    }

    /// Schritt 2: Jahre, Monate und Tage in drei gleich breiten Feldern.
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
            // Zwei Zeilen für die längeren Titel bei Frauen („Wochenbett insgesamt (Tage)“, Spec § 10.7).
            Text(title)
                .textStyle(.caption1, lineHeight: QadaCalculatorMetrics.labelLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
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
            Text(ledger.waivedDays > 0
                 ? L10n.qcResultDetailF(d: ledger.spanDays, x: ledger.waivedDays, k: ledger.prayers.count)
                 : L10n.qcResultDetail(d: ledger.periodDays, k: ledger.prayers.count))
                .textStyle(.footnote, lineHeight: QadaCalculatorMetrics.labelLineHeight)
                .monospacedDigit()
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, QadaCalculatorMetrics.detailTop)
        }
    }
}

/// Maße der Karte (`.qcalc`, `.qc-*` im Prototyp).
enum QadaCalculatorMetrics {
    /// Abstand der Felder für Regel und Wochenbett unter den Segmenten.
    static let personFieldsTop: CGFloat = 10
    /// Abstand von „Alles zurücksetzen“ zum Hinweis darüber (`.qc-reset`: `margin-top: 14px`).
    static let resetTop: CGFloat = 6
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
