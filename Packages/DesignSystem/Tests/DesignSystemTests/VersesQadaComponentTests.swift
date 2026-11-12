import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Bausteine der Seiten „Verse“ und „Nachholen“: Texte wie `relDay()`, `shortDate()`, `verseRef()`,
/// `num()` und `qadaPage()` im Prototyp, Aktionen und Größen.
@MainActor
@Suite("Verse und Nachholen – Bausteine")
struct VersesQadaComponentTests {

    /// Der Tag der Referenzbilder.
    private let referenceDay = FixtureTimes.referenceDay

    // MARK: - Verse: Tage und Texte

    @Test("heute, gestern, dann der Wochentag; Datum mit kurzem Monat", arguments: [
        ("de_DE", "Sonntag", "10. Nov.", "8. Nov."),
        ("tr_TR", "Pazar", "10 Kas", "8 Kas"),
        ("en_GB", "Sunday", "10 Nov", "8 Nov"),
        ("es_ES", "domingo", "10 nov", "8 nov"),
    ])
    func dayNames(locale: String, sunday: String, today: String, sundayDate: String) {
        let locale = Locale(identifier: locale)
        let days = VerseDay.recent(endingAt: referenceDay, locale: locale)
        #expect(days.count == 6)
        #expect(days[0].dayName == L10n.today)
        #expect(days[0].shortDate == today)
        #expect(days[0].isToday)
        #expect(days[1].dayName == L10n.yesterday)
        #expect(!days[1].isToday)
        #expect(days[2].dayName == sunday)
        #expect(days[2].shortDate == sundayDate)
    }

    @Test("die Karte heißt heute „Vers des Tages“, sonst wie der Tag")
    func cardTitle() {
        let today = VerseDay(referenceDay, today: referenceDay)
        let yesterday = VerseDay(referenceDay.adding(days: -1), today: referenceDay)
        #expect(today.cardTitle == L10n.verseToday)
        #expect(yesterday.cardTitle == L10n.yesterday)
        #expect(today.listTitle == "\(L10n.today) · \(today.shortDate)")
    }

    @Test("am 10.11.2026 zeigt die Liste die Verse des Prototyps in seiner Reihenfolge")
    func referenceList() {
        let days = VerseDay.recent(endingAt: referenceDay)
        #expect(days.map { "\($0.verse.surah):\($0.verse.ayah)" } == ["2:45", "94:5", "13:28", "2:152", "20:14", "2:286"])
        #expect(days.map(\.day) == Verse.recentDays(endingAt: referenceDay))
    }

    @Test("Quelle wie `verseRef()`: Name der Sure, Sure:Vers")
    func reference() {
        let verse = Verse.all[1]
        #expect(verse.localizedReference == "\(L10n.surahName(94)) 94:5")
        #expect(!verse.localizedSurahName.hasPrefix("surah_"))
        #expect(!verse.localizedTranslation.hasPrefix("verse_"))
    }

    @Test("Teilen und Kopieren: Arabisch, Übersetzung und Quelle in drei Zeilen")
    func shareText() {
        let verse = Verse.all[0]
        let lines = verse.shareText.components(separatedBy: "\n")
        #expect(lines == [verse.arabic, verse.localizedTranslation, verse.localizedReference])
    }

    // MARK: - Nachholen: Texte

    @Test("Zahlen mit der Zifferngruppierung der Sprache, wie `num()`", arguments: [
        ("de_DE", "2.725"), ("tr_TR", "2.725"), ("en_GB", "2,725"), ("es_ES", "2725"),
    ])
    func numbers(locale: String, expected: String) {
        #expect(QadaSummary.number(2725, locale: Locale(identifier: locale)) == expected)
        #expect(QadaSummary.number(5, locale: Locale(identifier: locale)) == "5")
    }

    @Test("die Zusammenfassung mit den Zahlen des Prototyps (iphone/60)")
    func sampleSummary() {
        let german = Locale(identifier: "de_DE")
        let summary = QadaSummary(.prototypeSample, today: referenceDay, locale: german)
        #expect(summary.percent == "4,9\u{00A0}%")
        #expect(summary.share == 133.0 / 2725.0)
        #expect(summary.done == L10n.qadaDone(a: "133", b: "2.725"))
        #expect(summary.remaining == L10n.qadaLeft(n: "2.592"))
        #expect(summary.finish == L10n.qadaFinish(date: "April 2028"))
    }

    @Test("das voraussichtliche Ende mit Monat und Jahr in der Sprache", arguments: [
        ("de_DE", "April 2028"), ("tr_TR", "Nisan 2028"), ("en_GB", "April 2028"), ("es_ES", "abril de 2028"),
    ])
    func finishMonth(locale: String, expected: String) {
        let summary = QadaSummary(.prototypeSample, today: referenceDay, locale: Locale(identifier: locale))
        #expect(summary.finish == L10n.qadaFinish(date: expected))
    }

    @Test("ist alles nachgeholt, steht rechts und unter dem Plan „Alles nachgeholt.“")
    func allDone() {
        let ledger = QadaLedger(
            years: 0, months: 0, days: 1, perDay: 5, includesWitr: false,
            total: [.fajr: 1, .dhuhr: 1], open: [:]
        )
        let summary = QadaSummary(ledger, today: referenceDay, locale: Locale(identifier: "de_DE"))
        #expect(summary.percent == "100\u{00A0}%")
        #expect(summary.remaining == L10n.qadaAllDone)
        #expect(summary.finish == L10n.qadaAllDone)
        #expect(summary.done == L10n.qadaDone(a: "2", b: "2"))
    }

    @Test("Namen und Symbole je Gebet; Witr trägt das Symbol von Ischa")
    func prayers() {
        #expect(QadaPrayer.allCases.map(\.symbolName) == [
            "sun.horizon", "sun.max", "sun.min", "sunset", "moon.stars", "moon.stars",
        ])
        #expect(QadaPrayer.witr.localizedName == L10n.p_witr)
        #expect(QadaPrayer.fajr.localizedName == Prayer.fajr.localizedName)
        #expect(Set(QadaPrayer.allCases.map(\.localizedName)).count == 6)
        #expect(QadaLedger.Field.allCases.map(\.localizedTitle) == [L10n.years, L10n.months, L10n.days, L10n.qadaPerDay])
    }

    @Test("die Symbole der Seiten gibt es im System", arguments: [
        "square.and.arrow.up", "square.on.square", "checkmark", "moon.stars", "sunset",
    ])
    func symbolExists(name: String) {
        #expect(UIImage(systemName: name) != nil)
    }

    // MARK: - Nachholen: Aktionen

    @Test("die Aktionen der Seite wirken wie `qstep`, `qwitr` und `qapply`")
    func actions() {
        var ledger = QadaLedger.prototypeSample
        ledger.apply(.step(.perDay, by: 1))
        #expect(ledger[.perDay] == 6)
        ledger.apply(.step(.days, by: -1))
        #expect(ledger[.days] == 0)
        ledger.apply(.markMadeUp(.fajr))
        #expect(ledger.openCount(of: .fajr) == 500)
        #expect(ledger.totalCount(of: .fajr) == 545)
        ledger.apply(.addMissed(.isha))
        #expect(ledger.openCount(of: .isha) == 527)
        #expect(ledger.totalCount(of: .isha) == 546)
        ledger.apply(.setWitr(true))
        #expect(ledger.prayers == QadaPrayer.allCases)
        ledger.apply(.applyPeriod)
        #expect(QadaPrayer.allCases.allSatisfy { ledger.openCount(of: $0) == 545 && ledger.totalCount(of: $0) == 545 })
        #expect(ledger.periodPrayers == 3270)
    }

    // MARK: - Größen

    /// Die Höhe einer Ansicht bei vorgegebener Breite.
    private func height<V: View>(_ view: V, width: CGFloat = 358) -> CGFloat {
        let host = UIHostingController(
            rootView: view.frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        )
        return host.sizeThatFits(in: CGSize(width: width, height: 10_000)).height
    }

    /// SwiftUI rundet Texthöhen auf Gerätepixel.
    private func close(_ value: CGFloat, _ expected: CGFloat, tolerance: CGFloat = 0.7) -> Bool {
        abs(value - expected) <= tolerance
    }

    @Test("eine Zeile „Nach Gebet“ ist 52 pt hoch (`.qrow`)")
    func prayerRowHeight() {
        let row = QadaPrayerRow(.fajr, count: "501", canMarkMadeUp: true, canAddMissed: true, onMadeUp: {}, onMissed: {})
        #expect(close(height(row), 52), "\(height(row))")
    }

    @Test("Zeile mit Stepper 54 pt (11 + 32 + 11), Link 44 pt, Schalter mit Zusatz 63 pt")
    func groupRowHeights() {
        let stepper = StepperRow("Jahre", value: "1", canDecrement: true, canIncrement: true, onDecrement: {}, onIncrement: {})
        #expect(close(height(stepper), 54), "\(height(stepper))")
        let link = LinkRow("Als offen übernehmen", systemImage: "checkmark") {}
        #expect(close(height(link), 44.1), "\(height(link))")
        let toggle = SwitchRow("Witr einbeziehen", detail: "Nach hanafitischer Lehre verpflichtend", isOn: .constant(false))
        // 11 + 22,1 (Titel) + 2 + 16,9 (Zusatz) + 11
        #expect(close(height(toggle), 63), "\(height(toggle))")
    }

    @Test("Gruppe: Kopf 18 + 7 pt über der Fläche, Fuß 7 + 17,9 pt darunter")
    func groupHeight() {
        let group = InsetGroup(header: "Plan", footer: "Voraussichtlich fertig: April 2028") {
            StepperRow("Pro Tag nachholen", value: "5", canDecrement: true, canIncrement: true, onDecrement: {}, onIncrement: {})
        }
        #expect(close(height(group, width: 358), 18 + 7 + 54 + 7 + 17.94, tolerance: 1), "\(height(group, width: 358))")
    }

    @Test("ein Eintrag der letzten Tage: 86 pt mit einer Zeile Übersetzung, 106 pt mit zweien")
    func verseListItemHeights() {
        let short = VerseDay(referenceDay, today: referenceDay)
        // 13 + 16,9 + 3 + 20,25 + 3 + 16,9 + 13
        #expect(close(height(VerseListItem(short, isSelected: true) {}), 86.05), "\(height(VerseListItem(short, isSelected: true) {}))")
        // Schmal genug, dass die Übersetzung auf zwei Zeilen umbricht. Jede Zeile rundet auf Gerätepixel.
        let item = VerseListItem(VerseDay(referenceDay, today: referenceDay), isSelected: false) {}
        let twoLines = height(item, width: 200)
        #expect(close(twoLines, 86.05 + 20.25, tolerance: 1), "\(twoLines)")
    }

    @Test("die Zusammenfassung ist 173 pt hoch (`.qsum`)")
    func summaryHeight() {
        let summary = QadaSummary(.prototypeSample, today: referenceDay, locale: Locale(identifier: "de_DE"))
        // 22 + 58,8 + 2 + 19,5 + 18 + 8 + 10 + 16,9 + 18
        let measured = height(QadaSummaryCard(summary))
        #expect(close(measured, 173.2, tolerance: 1), "\(measured)")
    }
}
