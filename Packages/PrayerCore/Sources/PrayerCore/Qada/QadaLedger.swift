import Foundation

/// Ein Gebet, das nachgeholt werden kann: die fünf Pflichtgebete und Witr (hanafitisch).
///
/// Die Rohwerte sind die Kennungen des Prototyps (`[...FIVE, 'witr']`).
public enum QadaPrayer: String, CaseIterable, Codable, CodingKeyRepresentable, Sendable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case witr

    /// Die fünf Pflichtgebete ohne Witr – `FIVE` im Prototyp.
    public static let five: [QadaPrayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
}

/// Der Stand des Nachholens – `S.qada` im Prototyp mit den Rechnungen aus `qadaPage()` und den
/// Aktionen `qstep`, `qwitr` und `qapply`.
///
/// Die Daten bleiben auf dem Gerät. Eine neue Instanz ist leer; die Beispielzahlen des Prototyps gibt es
/// nur in DEBUG (`QadaLedger.prototypeSample`).
public struct QadaLedger: Hashable, Codable, Sendable {

    /// Ein Wert mit Stepper: die drei Felder des Rechners „Verpasster Zeitraum“ und der Plan pro Tag.
    public enum Field: String, CaseIterable, Sendable {
        case years
        case months
        case days
        case perDay

        /// Grenzen des Steppers (`qstep`). An den Rändern ist der jeweilige Knopf gesperrt.
        public var range: ClosedRange<Int> {
            switch self {
            case .years: 0...60
            case .months: 0...11
            case .days: 0...30
            case .perDay: 1...20
            }
        }
    }

    /// Grenzen für die offenen Gebete je Gebet (`qStepper(…, 0, 99999)`).
    public static let openRange = 0...99_999

    /// Verpasster Zeitraum: Jahre, Monate, Tage.
    public private(set) var years: Int
    public private(set) var months: Int
    public private(set) var days: Int
    /// Plan: so viele Gebete werden pro Tag nachgeholt.
    public private(set) var perDay: Int
    /// Ob Witr mitzählt (`witr`). Ohne Witr bleiben dessen Zahlen stehen, zählen aber nicht.
    public var includesWitr: Bool

    /// Je Gebet: wie viele insgesamt nachzuholen sind (`tot`) und wie viele davon noch offen sind (`open`).
    private var total: [QadaPrayer: Int]
    private var open: [QadaPrayer: Int]

    /// Ein leerer Stand: kein Zeitraum, nichts offen, 5 Gebete pro Tag, ohne Witr.
    public init() {
        self.init(years: 0, months: 0, days: 0, perDay: 5, includesWitr: false, total: [:], open: [:])
    }

    /// Ein Stand aus gespeicherten Werten. Werte außerhalb der Grenzen werden an den Rand gesetzt.
    public init(
        years: Int, months: Int, days: Int, perDay: Int, includesWitr: Bool,
        total: [QadaPrayer: Int], open: [QadaPrayer: Int]
    ) {
        self.years = Self.clamp(years, to: Field.years.range)
        self.months = Self.clamp(months, to: Field.months.range)
        self.days = Self.clamp(days, to: Field.days.range)
        self.perDay = Self.clamp(perDay, to: Field.perDay.range)
        self.includesWitr = includesWitr
        self.total = total.mapValues { max(0, $0) }
        self.open = open.mapValues { Self.clamp($0, to: Self.openRange) }
    }

    // MARK: - Stand

    /// Die Gebete, die zählen (`qadaKeys()`): die fünf Pflichtgebete, mit Witr sechs.
    public var prayers: [QadaPrayer] {
        includesWitr ? QadaPrayer.allCases : QadaPrayer.five
    }

    /// Offene Gebete eines Gebets.
    public func openCount(of prayer: QadaPrayer) -> Int {
        open[prayer] ?? 0
    }

    /// Insgesamt nachzuholende Gebete eines Gebets.
    public func totalCount(of prayer: QadaPrayer) -> Int {
        total[prayer] ?? 0
    }

    /// Offene Gebete über alle Gebete, die zählen.
    public var openCount: Int {
        prayers.reduce(0) { $0 + openCount(of: $1) }
    }

    /// Insgesamt nachzuholende Gebete über alle Gebete, die zählen.
    public var totalCount: Int {
        prayers.reduce(0) { $0 + totalCount(of: $1) }
    }

    /// Schon nachgeholte Gebete; nie negativ.
    public var doneCount: Int {
        max(0, totalCount - openCount)
    }

    /// Anteil der nachgeholten Gebete von 0 bis 1; ohne Gebete 0.
    public var share: Double {
        totalCount == 0 ? 0 : Double(doneCount) / Double(totalCount)
    }

    /// Der Anteil als Prozentzahl in der Schreibweise von `locale` – die größte Zahl der Seite.
    /// Unter 10 % mit einer Nachkommastelle, z. B. „4,9 %“ (Spec § 3, Qada tracker).
    public func formattedShare(locale: Locale) -> String {
        let share = share
        let fractionDigits = share > 0 && share < 0.1 ? 1 : 0
        return share.formatted(
            .percent
                .precision(.fractionLength(0...fractionDigits))
                .rounded(rule: .toNearestOrAwayFromZero)
                .locale(locale)
        )
    }

    // MARK: - Plan

    /// Tage, bis alles nachgeholt ist: offene Gebete geteilt durch Gebete pro Tag, aufgerundet.
    public var daysToFinish: Int {
        let perDay = max(1, perDay)
        return (openCount + perDay - 1) / perDay
    }

    /// Der Tag, an dem voraussichtlich alles nachgeholt ist: heute + `daysToFinish` Tage.
    /// `nil`, wenn nichts mehr offen ist – dann steht dort „Alles nachgeholt“.
    public func finishDay(from today: CalendarDay) -> CalendarDay? {
        openCount == 0 ? nil : today.adding(days: daysToFinish)
    }

    // MARK: - Rechner „Verpasster Zeitraum“

    /// Wert eines Feldes mit Stepper.
    public subscript(field: Field) -> Int {
        switch field {
        case .years: years
        case .months: months
        case .days: days
        case .perDay: perDay
        }
    }

    /// Der verpasste Zeitraum in Tagen: Ein Jahr zählt 365 Tage, ein Monat 30 (Spec § 4).
    public var periodDays: Int {
        years * 365 + months * 30 + days
    }

    /// Gebete im verpassten Zeitraum: Tage mal Zahl der Gebete, die zählen.
    public var periodPrayers: Int {
        periodDays * prayers.count
    }

    // MARK: - Aktionen

    /// Zählt ein Feld um `delta` weiter, höchstens bis an seine Grenze – Aktion `qstep` der Stepper.
    public mutating func step(_ field: Field, by delta: Int) {
        // Mehr als die Breite des Bereichs bewirkt nichts; so läuft die Summe nie über.
        let width = field.range.upperBound - field.range.lowerBound
        let value = Self.clamp(self[field] + min(max(delta, -width), width), to: field.range)
        switch field {
        case .years: years = value
        case .months: months = value
        case .days: days = value
        case .perDay: perDay = value
        }
    }

    /// Ob sich ein Gebet als nachgeholt abhaken lässt; bei 0 offenen ist der Knopf „−“ gesperrt.
    public func canMarkMadeUp(_ prayer: QadaPrayer) -> Bool {
        openCount(of: prayer) > Self.openRange.lowerBound
    }

    /// Ob sich ein weiteres offenes Gebet eintragen lässt; an der Obergrenze ist der Knopf „+“ gesperrt.
    public func canAddMissed(_ prayer: QadaPrayer) -> Bool {
        openCount(of: prayer) < Self.openRange.upperBound
    }

    /// „−“: ein Gebet nachgeholt. Die offenen sinken um eins, die Summe bleibt.
    public mutating func markMadeUp(_ prayer: QadaPrayer) {
        guard canMarkMadeUp(prayer) else { return }
        open[prayer] = openCount(of: prayer) - 1
    }

    /// „+“: ein weiteres Gebet ist offen. Offene und Summe steigen um eins.
    public mutating func addMissed(_ prayer: QadaPrayer) {
        guard canAddMissed(prayer) else { return }
        open[prayer] = openCount(of: prayer) + 1
        total[prayer] = totalCount(of: prayer) + 1
    }

    /// „Als offen übernehmen“ – Aktion `qapply`: Jedes Gebet bekommt die Tage des verpassten Zeitraums
    /// als offen und als Summe. Witr nur, wenn es mitzählt; sonst steht es auf 0. Bisher Nachgeholtes
    /// wird dabei ersetzt.
    public mutating func applyPeriod() {
        for prayer in QadaPrayer.allCases {
            let count = prayer == .witr && !includesWitr ? 0 : periodDays
            open[prayer] = count
            total[prayer] = count
        }
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
