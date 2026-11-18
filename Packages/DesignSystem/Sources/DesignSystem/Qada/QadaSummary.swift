import Foundation
import PrayerCore

/// Die Texte der Zusammenfassung und des Plans beim Nachholen, fertig zum Anzeigen – wie `qadaPage()`
/// sie aus `S.qada` schreibt, in der Sprache der App.
public struct QadaSummary: Equatable, Sendable {
    /// Der Anteil nachgeholt, die größte Zahl der Seite: „4,9 %“.
    public let percent: String
    /// Der Anteil von 0 bis 1 für den Balken.
    public let share: Double
    /// „133 von 2.725 nachgeholt“.
    public let done: String
    /// Rechts unter dem Balken: „Noch 2.592 offen“; ist nichts mehr offen, „Alles nachgeholt.“
    public let remaining: String
    /// Unter dem Plan: „Voraussichtlich fertig: April 2028“; ist nichts mehr offen, „Alles nachgeholt.“
    public let finish: String

    /// - Parameters:
    ///   - today: der heutige Tag; von ihm aus zählt der Plan bis zum voraussichtlichen Ende.
    ///   - locale: Sprache für Zahlen, Prozent und Monat; ohne Angabe die der Texte.
    public init(_ ledger: QadaLedger, today: CalendarDay, locale: Locale = L10n.locale) {
        percent = ledger.formattedShare(locale: locale)
        share = ledger.share
        done = L10n.qadaDone(a: Self.number(ledger.doneCount, locale: locale), b: Self.number(ledger.totalCount, locale: locale))
        if let day = ledger.finishDay(from: today) {
            finish = L10n.qadaFinish(date: VerseDay.format(day, template: "MMMMy", locale: locale))
            remaining = L10n.qadaLeft(n: Self.number(ledger.openCount, locale: locale))
        } else {
            finish = L10n.qadaAllDone
            remaining = L10n.qadaAllDone
        }
    }

    /// Eine Zahl mit der Zifferngruppierung der Sprache, wie `num()` im Prototyp: „2.725“, englisch
    /// „2,725“, spanisch „2725“.
    public static func number(_ value: Int, locale: Locale = L10n.locale) -> String {
        value.formatted(.number.locale(locale))
    }
}

extension QadaPrayer {

    /// Name aus dem String Catalog (`p_fajr` … `p_witr`).
    public var localizedName: String {
        switch self {
        case .fajr: L10n.p_fajr
        case .dhuhr: L10n.p_dhuhr
        case .asr: L10n.p_asr
        case .maghrib: L10n.p_maghrib
        case .isha: L10n.p_isha
        case .witr: L10n.p_witr
        }
    }

    /// SF Symbol wie bei den Gebetskarten; Witr trägt das Symbol von Ischa (`PICON.witr`).
    public var symbolName: String {
        switch self {
        case .fajr: Prayer.fajr.symbolName
        case .dhuhr: Prayer.dhuhr.symbolName
        case .asr: Prayer.asr.symbolName
        case .maghrib: Prayer.maghrib.symbolName
        case .isha, .witr: Prayer.isha.symbolName
        }
    }
}

extension QadaLedger.Field {

    /// Titel der Zeile aus dem String Catalog (`years`, `months`, `days`, `qadaPerDay`).
    public var localizedTitle: String {
        switch self {
        case .years: L10n.years
        case .months: L10n.months
        case .days: L10n.days
        case .perDay: L10n.qadaPerDay
        case .menstruationDays: L10n.qcHayz
        case .postnatalDays: L10n.qcNifas
        }
    }
}
