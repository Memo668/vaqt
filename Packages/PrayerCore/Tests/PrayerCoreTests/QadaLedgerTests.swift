import Foundation
import Testing
@testable import PrayerCore

/// Das Nachholen muss sich verhalten wie `qadaPage()` und die Aktionen `qstep`, `qwitr` und `qapply`
/// im Prototyp.
@Suite("QadaLedger")
struct QadaLedgerTests {

    private let german = Locale(identifier: "de_DE")
    private let today = calendarDay("2026-11-10")

    /// Ein Stand mit `total` insgesamt und `open` offenen Fadschr-Gebeten, sonst leer.
    private func ledger(total: Int, open: Int, perDay: Int = 5) -> QadaLedger {
        QadaLedger(
            years: 0, months: 0, days: 0, perDay: perDay, includesWitr: false,
            total: [.fajr: total], open: [.fajr: open]
        )
    }

    // MARK: - Die Zahlen des Screenshots iphone/60-qada.png

    #if DEBUG
    @Test("der Stand des Prototyps: 2.725 gesamt, 2.592 offen, 133 nachgeholt")
    func sampleCounts() {
        let ledger = QadaLedger.prototypeSample
        #expect(ledger.totalCount == 2725)
        #expect(ledger.openCount == 2592)
        #expect(ledger.doneCount == 133)
        #expect(ledger.share == 133.0 / 2725.0)
        #expect(QadaPrayer.five.map { ledger.openCount(of: $0) } == [501, 523, 530, 512, 526])
        #expect(QadaPrayer.five.map { ledger.totalCount(of: $0) } == [545, 545, 545, 545, 545])
    }

    @Test("der Stand des Prototyps: 4,9 % nachgeholt")
    func samplePercent() {
        // Zwischen Zahl und Prozentzeichen steht ein geschütztes Leerzeichen.
        #expect(QadaLedger.prototypeSample.formattedShare(locale: german) == "4,9\u{00A0}%")
    }

    @Test("der Stand des Prototyps: 519 Tage bis zum 12. April 2028")
    func sampleFinish() {
        let ledger = QadaLedger.prototypeSample
        #expect(ledger[.perDay] == 5)
        #expect(ledger.daysToFinish == 519)
        let finish = ledger.finishDay(from: today)
        #expect(finish == calendarDay("2028-04-12"))
        #expect(finish?.month == 4)
        #expect(finish?.year == 2028)
    }

    @Test("der Stand des Prototyps: 1 Jahr 6 Monate sind 545 Tage und 2.725 Gebete")
    func samplePeriod() {
        let ledger = QadaLedger.prototypeSample
        #expect(ledger[.years] == 1)
        #expect(ledger[.months] == 6)
        #expect(ledger[.days] == 0)
        #expect(!ledger.includesWitr)
        #expect(ledger.periodDays == 545)
        #expect(ledger.periodPrayers == 2725)
        #expect(ledger.prayers == QadaPrayer.five)
    }

    @Test("die Schreibweise des Anteils folgt der Sprache", arguments: [
        ("de_DE", "4,9\u{00A0}%"), ("tr_TR", "%4,9"), ("en_GB", "4.9%"), ("es_ES", "4,9\u{00A0}%"),
    ])
    func samplePercentByLanguage(locale: String, expected: String) {
        #expect(QadaLedger.prototypeSample.formattedShare(locale: Locale(identifier: locale)) == expected)
    }
    #endif

    // MARK: - Leerer Stand

    @Test("die App startet leer: nichts offen, 5 Gebete pro Tag, ohne Witr")
    func empty() {
        let ledger = QadaLedger()
        #expect(ledger.totalCount == 0)
        #expect(ledger.openCount == 0)
        #expect(ledger.doneCount == 0)
        #expect(ledger.share == 0)
        #expect(ledger.formattedShare(locale: german) == "0\u{00A0}%")
        #expect(ledger[.years] == 0)
        #expect(ledger[.months] == 0)
        #expect(ledger[.days] == 0)
        #expect(ledger[.perDay] == 5)
        #expect(!ledger.includesWitr)
        #expect(ledger.periodDays == 0)
        #expect(ledger.periodPrayers == 0)
        #expect(ledger.daysToFinish == 0)
        #expect(ledger.finishDay(from: today) == nil)
        #expect(QadaPrayer.allCases.allSatisfy { ledger.openCount(of: $0) == 0 && ledger.totalCount(of: $0) == 0 })
        #expect(!ledger.hasEntries)
    }

    @Test("eingetragen ist etwas, sobald ein Gebet, das zählt, nachzuholen ist – auch wenn alles nachgeholt ist")
    func entries() {
        var ledger = QadaLedger()
        ledger.addMissed(.isha)
        #expect(ledger.hasEntries)
        ledger.markMadeUp(.isha)
        #expect(ledger.openCount == 0)
        #expect(ledger.hasEntries)
    }

    @Test("ein Zeitraum im Rechner allein ist noch kein Eintrag; erst „Als offen übernehmen“")
    func periodIsNoEntry() {
        var ledger = QadaLedger()
        ledger.step(.months, by: 1)
        #expect(!ledger.hasEntries)
        ledger.applyPeriod()
        #expect(ledger.hasEntries)
        ledger.step(.months, by: -1)
        ledger.applyPeriod()
        #expect(!ledger.hasEntries)
    }

    @Test("Witr zählt nur mit, wenn es eingeschlossen ist")
    func witrEntries() {
        var ledger = QadaLedger()
        ledger.addMissed(.witr)
        #expect(!ledger.hasEntries)
        ledger.includesWitr = true
        #expect(ledger.hasEntries)
    }

    // MARK: - Anteil

    @Test("unter 10 % steht eine Nachkommastelle, sonst keine", arguments: [
        (2725, 2592, "4,9\u{00A0}%"),
        (1000, 999, "0,1\u{00A0}%"),
        (1000, 950, "5\u{00A0}%"),
        (1000, 901, "9,9\u{00A0}%"),
        (10000, 9001, "10\u{00A0}%"),
        (1000, 900, "10\u{00A0}%"),
        (1000, 895, "11\u{00A0}%"),
        (2725, 2425, "11\u{00A0}%"),
        (3, 2, "33\u{00A0}%"),
        (3, 1, "67\u{00A0}%"),
        (545, 0, "100\u{00A0}%"),
        (545, 545, "0\u{00A0}%"),
    ])
    func percent(total: Int, open: Int, expected: String) {
        #expect(ledger(total: total, open: open).formattedShare(locale: german) == expected)
    }

    @Test("nachgeholt ist nie negativ, auch wenn mehr offen als gesamt gespeichert ist")
    func doneIsNeverNegative() {
        let ledger = ledger(total: 10, open: 25)
        #expect(ledger.doneCount == 0)
        #expect(ledger.share == 0)
    }

    // MARK: - Plan

    @Test("das Ende liegt heute + ⌈offen ÷ pro Tag⌉ Tage", arguments: [
        (2592, 5, 519, "2028-04-12"),
        (2592, 1, 2592, "2033-12-15"),
        (2592, 20, 130, "2027-03-20"),
        (1, 5, 1, "2026-11-11"),
        (5, 5, 1, "2026-11-11"),
        (6, 5, 2, "2026-11-12"),
    ])
    func finish(open: Int, perDay: Int, days: Int, finish: String) {
        let ledger = ledger(total: open, open: open, perDay: perDay)
        #expect(ledger.daysToFinish == days)
        #expect(ledger.finishDay(from: today) == calendarDay(finish))
    }

    @Test("ist nichts mehr offen, gibt es kein Enddatum")
    func allDone() {
        let ledger = ledger(total: 545, open: 0)
        #expect(ledger.daysToFinish == 0)
        #expect(ledger.finishDay(from: today) == nil)
    }

    // MARK: - Stepper je Gebet

    @Test("„−“ hakt ein Gebet als nachgeholt ab: offen sinkt, die Summe bleibt")
    func markMadeUp() {
        var ledger = ledger(total: 545, open: 501)
        ledger.markMadeUp(.fajr)
        #expect(ledger.openCount(of: .fajr) == 500)
        #expect(ledger.totalCount(of: .fajr) == 545)
        #expect(ledger.doneCount == 45)
    }

    @Test("„+“ trägt ein weiteres offenes Gebet ein: offen und Summe steigen")
    func addMissed() {
        var ledger = ledger(total: 545, open: 501)
        ledger.addMissed(.fajr)
        #expect(ledger.openCount(of: .fajr) == 502)
        #expect(ledger.totalCount(of: .fajr) == 546)
        #expect(ledger.doneCount == 44)

        ledger.addMissed(.asr)
        #expect(ledger.openCount(of: .asr) == 1)
        #expect(ledger.totalCount(of: .asr) == 1)
    }

    @Test("bei 0 offenen ist „−“ gesperrt und bewirkt nichts")
    func lowerBound() {
        var ledger = ledger(total: 545, open: 1)
        #expect(ledger.canMarkMadeUp(.fajr))
        ledger.markMadeUp(.fajr)
        #expect(ledger.openCount(of: .fajr) == 0)
        #expect(!ledger.canMarkMadeUp(.fajr))
        ledger.markMadeUp(.fajr)
        #expect(ledger.openCount(of: .fajr) == 0)
        #expect(!ledger.canMarkMadeUp(.dhuhr))
    }

    @Test("bei 99.999 offenen ist „+“ gesperrt und bewirkt nichts")
    func upperBound() {
        #expect(QadaLedger.openRange == 0...99_999)
        var ledger = ledger(total: 99_998, open: 99_998)
        #expect(ledger.canAddMissed(.fajr))
        ledger.addMissed(.fajr)
        #expect(ledger.openCount(of: .fajr) == 99_999)
        #expect(!ledger.canAddMissed(.fajr))
        ledger.addMissed(.fajr)
        #expect(ledger.openCount(of: .fajr) == 99_999)
        #expect(ledger.totalCount(of: .fajr) == 99_999)
    }

    // MARK: - Stepper für Zeitraum und Plan

    @Test("die Grenzen der Stepper: Jahre 0–60, Monate 0–11, Tage 0–30, pro Tag 1–20")
    func ranges() {
        #expect(QadaLedger.Field.allCases.map(\.rawValue) == ["years", "months", "days", "perDay"])
        #expect(QadaLedger.Field.years.range == 0...60)
        #expect(QadaLedger.Field.months.range == 0...11)
        #expect(QadaLedger.Field.days.range == 0...30)
        #expect(QadaLedger.Field.perDay.range == 1...20)
    }

    @Test("ein Stepper zählt um eins und bleibt an seinen Grenzen stehen", arguments: QadaLedger.Field.allCases)
    func steps(field: QadaLedger.Field) {
        var ledger = QadaLedger()
        let start = ledger[field]
        ledger.step(field, by: 1)
        #expect(ledger[field] == start + 1)
        ledger.step(field, by: -1)
        #expect(ledger[field] == start)

        for _ in 0..<100 { ledger.step(field, by: 1) }
        #expect(ledger[field] == field.range.upperBound)
        for _ in 0..<100 { ledger.step(field, by: -1) }
        #expect(ledger[field] == field.range.lowerBound)
    }

    @Test("ein übergroßer Schritt läuft nicht über")
    func hugeSteps() {
        var ledger = QadaLedger()
        ledger.step(.years, by: .max)
        #expect(ledger[.years] == 60)
        ledger.step(.years, by: .min)
        #expect(ledger[.years] == 0)
    }

    @Test("ein Schritt ändert nur sein Feld")
    func stepsOneField() {
        var ledger = QadaLedger()
        ledger.step(.months, by: 1)
        #expect(ledger[.years] == 0)
        #expect(ledger[.months] == 1)
        #expect(ledger[.days] == 0)
        #expect(ledger[.perDay] == 5)
    }

    @Test("der Zeitraum in Tagen: ein Jahr zählt 365, ein Monat 30", arguments: [
        (0, 0, 0, 0), (1, 0, 0, 365), (0, 1, 0, 30), (0, 0, 1, 1), (1, 6, 0, 545), (2, 11, 30, 1090), (60, 11, 30, 22260),
    ])
    func period(years: Int, months: Int, days: Int, expected: Int) {
        let ledger = QadaLedger(
            years: years, months: months, days: days, perDay: 5, includesWitr: false, total: [:], open: [:]
        )
        #expect(ledger.periodDays == expected)
        #expect(ledger.periodPrayers == expected * 5)
    }

    // MARK: - Witr

    @Test("mit Witr zählen sechs Gebete")
    func witr() {
        var ledger = QadaLedger(
            years: 1, months: 6, days: 0, perDay: 5, includesWitr: false,
            total: [.fajr: 545, .witr: 100], open: [.fajr: 501, .witr: 40]
        )
        #expect(ledger.prayers == QadaPrayer.five)
        #expect(ledger.totalCount == 545)
        #expect(ledger.openCount == 501)
        #expect(ledger.periodPrayers == 2725)

        ledger.includesWitr = true
        #expect(ledger.prayers == QadaPrayer.allCases)
        #expect(ledger.totalCount == 645)
        #expect(ledger.openCount == 541)
        #expect(ledger.periodPrayers == 3270)

        // Ohne Witr bleiben dessen Zahlen stehen, zählen aber nicht.
        ledger.includesWitr = false
        #expect(ledger.openCount(of: .witr) == 40)
        #expect(ledger.openCount == 501)
    }

    @Test("die Kennungen der Gebete sind die des Prototyps")
    func prayerRawValues() {
        #expect(QadaPrayer.allCases.map(\.rawValue) == ["fajr", "dhuhr", "asr", "maghrib", "isha", "witr"])
        #expect(QadaPrayer.five.map(\.rawValue) == Prayer.five.map(\.rawValue))
    }

    // MARK: - „Als offen übernehmen“

    @Test("ohne Witr bekommen die fünf Gebete die Tage des Zeitraums, Witr steht auf 0")
    func applyWithoutWitr() {
        var ledger = QadaLedger(
            years: 1, months: 6, days: 0, perDay: 5, includesWitr: false,
            total: [.fajr: 900, .witr: 77], open: [.fajr: 12, .witr: 33]
        )
        ledger.applyPeriod()
        #expect(QadaPrayer.five.map { ledger.openCount(of: $0) } == [545, 545, 545, 545, 545])
        #expect(QadaPrayer.five.map { ledger.totalCount(of: $0) } == [545, 545, 545, 545, 545])
        #expect(ledger.openCount(of: .witr) == 0)
        #expect(ledger.totalCount(of: .witr) == 0)
        #expect(ledger.totalCount == 2725)
        #expect(ledger.openCount == 2725)
        #expect(ledger.doneCount == 0)
        #expect(ledger.formattedShare(locale: german) == "0\u{00A0}%")
    }

    @Test("mit Witr bekommen alle sechs Gebete die Tage des Zeitraums")
    func applyWithWitr() {
        var ledger = QadaLedger(
            years: 1, months: 6, days: 0, perDay: 5, includesWitr: true, total: [:], open: [:]
        )
        ledger.applyPeriod()
        #expect(QadaPrayer.allCases.map { ledger.openCount(of: $0) } == [545, 545, 545, 545, 545, 545])
        #expect(ledger.totalCount == 3270)
        #expect(ledger.openCount == ledger.periodPrayers)
        #expect(ledger.daysToFinish == 654)
    }

    @Test("ein leerer Zeitraum setzt alles auf 0")
    func applyEmptyPeriod() {
        var ledger = ledger(total: 545, open: 501)
        ledger.applyPeriod()
        #expect(ledger.totalCount == 0)
        #expect(ledger.openCount == 0)
        #expect(ledger.finishDay(from: today) == nil)
    }

    // MARK: - Speichern

    @Test("gespeicherte Werte außerhalb der Grenzen werden an den Rand gesetzt")
    func clampsStoredValues() {
        let ledger = QadaLedger(
            years: 99, months: -3, days: 31, perDay: 0, includesWitr: false,
            total: [.fajr: -5, .dhuhr: 200_000], open: [.fajr: -1, .dhuhr: 200_000]
        )
        #expect(ledger[.years] == 60)
        #expect(ledger[.months] == 0)
        #expect(ledger[.days] == 30)
        #expect(ledger[.perDay] == 1)
        #expect(ledger.totalCount(of: .fajr) == 0)
        #expect(ledger.openCount(of: .fajr) == 0)
        #expect(ledger.openCount(of: .dhuhr) == 99_999)
        #expect(ledger.totalCount(of: .dhuhr) == 200_000)
    }

    @Test("übersteht Kodieren und Dekodieren")
    func codable() throws {
        var ledger = QadaLedger(
            years: 1, months: 6, days: 0, perDay: 7, includesWitr: true,
            total: [.fajr: 545, .witr: 545], open: [.fajr: 501, .witr: 12]
        )
        ledger.markMadeUp(.witr)
        let data = try JSONEncoder().encode(ledger)
        #expect(try JSONDecoder().decode(QadaLedger.self, from: data) == ledger)
    }

    @Test("die Zahlen je Gebet werden unter den Kennungen der Gebete gespeichert")
    func encodesByPrayerID() throws {
        let ledger = QadaLedger(
            years: 0, months: 0, days: 0, perDay: 5, includesWitr: false, total: [.fajr: 545], open: [.fajr: 501]
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = String(decoding: try encoder.encode(ledger), as: UTF8.self)
        #expect(json == #"{"days":0,"includesWitr":false,"months":0,"open":{"fajr":501},"perDay":5,"total":{"fajr":545},"years":0}"#)
    }
}
