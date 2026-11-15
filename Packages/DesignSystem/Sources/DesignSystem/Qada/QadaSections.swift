import PrayerCore
import SwiftUI

/// Was auf der Seite „Nachholen“ angetippt wurde – die Aktionen `qstep`, `qwitr` und `qapply` im
/// Prototyp. Die Seite reicht sie an ihr Modell weiter.
public enum QadaAction: Equatable, Sendable {
    /// Ein Stepper des Plans oder des Rechners: ein Feld um eins weiter oder zurück.
    case step(QadaLedger.Field, by: Int)
    /// „−“ bei einem Gebet: eines nachgeholt.
    case markMadeUp(QadaPrayer)
    /// „+“ bei einem Gebet: eines mehr offen.
    case addMissed(QadaPrayer)
    /// Der Schalter „Witr einbeziehen“.
    case setWitr(Bool)
    /// „Als offen übernehmen“.
    case applyPeriod
}

extension QadaLedger {

    /// Führt eine Aktion der Seite aus – wie `qstep`, `qwitr` und `qapply` im Prototyp.
    public mutating func apply(_ action: QadaAction) {
        switch action {
        case .step(let field, let delta): step(field, by: delta)
        case .markMadeUp(let prayer): markMadeUp(prayer)
        case .addMissed(let prayer): addMissed(prayer)
        case .setWitr(let isOn): includesWitr = isOn
        case .applyPeriod: applyPeriod()
        }
    }
}

/// Der erste Teil der Seite „Nachholen“: Titel, Einleitung, Zusammenfassung und Plan – `.col-a` in
/// `qadaPage()`. Auf dem inneren Display des iPhone Duo wird das die linke Spalte (Design Spec § 8).
///
/// Solange nichts eingetragen ist, fehlen Zusammenfassung und Plan (entschieden am 12.11.2026). Mit dem
/// Seitenrand; den Abstand zur oberen Leiste setzt die Seite.
public struct QadaOverview: View {
    private let ledger: QadaLedger
    private let summary: QadaSummary
    private let onAction: (QadaAction) -> Void

    /// - Parameters:
    ///   - today: der heutige Tag; von ihm aus zählt der Plan bis zum voraussichtlichen Ende.
    ///   - onAction: der Stepper des Plans.
    public init(ledger: QadaLedger, today: CalendarDay, onAction: @escaping (QadaAction) -> Void) {
        self.ledger = ledger
        summary = QadaSummary(ledger, today: today)
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageTitle(L10n.navQada)
                .padding(.top, PageTitle.spacingAbove)
                .padding(.bottom, PageLede.spacingAbove)
            PageLede(L10n.qadaIntro)
                .padding(.bottom, PageLede.spacingBelow)
            if ledger.hasEntries {
                QadaSummaryCard(summary)
                InsetGroup(header: L10n.qadaPlan, footer: summary.finish) {
                    QadaFieldRow(field: .perDay, ledger: ledger, onAction: onAction)
                }
                .padding(.top, QadaLayout.cardBottom)
            }
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Der zweite Teil der Seite „Nachholen“: „Nach Gebet“ mit einem Stepper je Gebet, der Rechner
/// „Verpasster Zeitraum“ mit dem Witr-Schalter, „Als offen übernehmen“ und die Fußnote – `.col-b` in
/// `qadaPage()`.
///
/// Mit dem Seitenrand, dem Abstand über „Nach Gebet“ und dem unter der Fußnote (`margin-bottom: 8px`).
public struct QadaDetails: View {
    private let ledger: QadaLedger
    private let onAction: (QadaAction) -> Void

    @Environment(\.pageArrangement) private var arrangement

    public init(ledger: QadaLedger, onAction: @escaping (QadaAction) -> Void) {
        self.ledger = ledger
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(L10n.qadaByPrayer)
                .padding(.top, QadaLayout.byPrayerTop(afterPlan: ledger.hasEntries, startsPart: arrangement.isSplit))
                .padding(.bottom, SectionHeader.spacingBelow)
            VStack(spacing: QadaRowMetrics.rowGap) {
                ForEach(ledger.prayers, id: \.self) { prayer in
                    QadaPrayerRow(
                        prayer, count: QadaSummary.number(ledger.openCount(of: prayer)),
                        canMarkMadeUp: ledger.canMarkMadeUp(prayer), canAddMissed: ledger.canAddMissed(prayer),
                        onMadeUp: { onAction(.markMadeUp(prayer)) }, onMissed: { onAction(.addMissed(prayer)) }
                    )
                }
            }
            // Der Rechner als Karte ganz unten, nach den Zählern (Spec § 9.8).
            QadaCalculatorCard(ledger: ledger, onAction: onAction)
                .padding(.top, QadaLayout.calculatorTop)
            CardFootnote(L10n.qadaFooter)
                .padding(.top, QadaLayout.cardBottom)
                .padding(.bottom, QadaLayout.footnoteBottom)
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Eine Zeile mit Stepper für ein Feld des Plans oder des Rechners – `stepRow()` im Prototyp.
private struct QadaFieldRow: View {
    let field: QadaLedger.Field
    let ledger: QadaLedger
    let onAction: (QadaAction) -> Void

    var body: some View {
        let value = ledger[field]
        StepperRow(
            field.localizedTitle, value: QadaSummary.number(value),
            canDecrement: value > field.range.lowerBound, canIncrement: value < field.range.upperBound,
            onDecrement: { onAction(.step(field, by: -1)) }, onIncrement: { onAction(.step(field, by: 1)) }
        )
    }
}

/// Abstände der Seite „Nachholen“.
enum QadaLayout {
    /// Abstand unter der Zusammenfassung (`.card`: `margin-bottom: 10px`).
    static let cardBottom: CGFloat = 10
    /// Abstand zwischen den Zählern und der Karte des Rechners (`.qc-gap`: 22 pt).
    static let calculatorTop: CGFloat = 22
    /// Abstand unter der Fußnote (`.card-foot`: `margin-bottom: 8px`).
    static let footnoteBottom: CGFloat = 8

    /// Abstand über „Nach Gebet“. Im CSS fallen der Abstand unter dem Teil davor und der über der
    /// Überschrift (24 pt) zusammen: unter dem Plan gelten dessen 32 pt (`.group-wrap`), ohne Plan – im
    /// leeren Zustand – die 24 pt der Überschrift, weil die Einleitung nur 18 pt hält. Innen auf dem
    /// iPhone Duo beginnt „Nach Gebet“ die rechte Spalte, in der Tischhaltung den unteren Teil: dann
    /// gelten die 24 pt der Überschrift, wie bei „Ablauf“ und „Letzte Tage“.
    ///
    /// Auf dem Main Actor, weil die Abstände von `SectionHeader` und `PageLede` als Teil eines `View`
    /// dort liegen.
    @MainActor
    static func byPrayerTop(afterPlan: Bool, startsPart: Bool = false) -> CGFloat {
        if startsPart { return SectionHeader.spacingAbove }
        return afterPlan ? max(InsetGroupMetrics.spacingBelow, SectionHeader.spacingAbove)
            : max(PageLede.spacingBelow, SectionHeader.spacingAbove)
    }
}
