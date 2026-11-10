import Foundation
import Testing
@testable import PrayerCore

@Suite("HijriDate")
struct HijriDateTests {

    private func hijri(_ day: String) -> HijriDate {
        HijriDate(calendarDay(day))
    }

    @Test("der 10.11.2026 ist der 30. Dschumada I 1448")
    func referenceDay() {
        let date = hijri("2026-11-10")
        #expect(date.year == 1448)
        #expect(date.month == 5)
        #expect(date.day == 30)
        #expect(date.gregorianDay == calendarDay("2026-11-10"))
        #expect(date.formatted(locale: Locale(identifier: "de_DE")) == "30. Dschumada I 1448")
    }

    @Test("der Text folgt der Sprache, ohne Ära", arguments: [
        ("de_DE", "30. Dschumada I 1448"),
        ("tr_TR", "30 Cemaziyelevvel 1448"),
        ("en_GB", "30 Jumada I 1448"),
        ("es_ES", "30 de jumada I de 1448"),
    ])
    func languages(locale: String, expected: String) {
        // Dieselben Texte liefert `hijriDate()` im Prototyp für die vier Sprachen.
        #expect(hijri("2026-11-10").formatted(locale: Locale(identifier: locale)) == expected)
    }

    @Test("Berlin im Sommer: Der 21.06.2027 ist der 16. Muharram 1449", arguments: [
        ("de_DE", "16. Muharram 1449"),
        ("tr_TR", "16 Muharrem 1449"),
        ("en_GB", "16 Muharram 1449"),
        ("es_ES", "16 de muharram de 1449"),
    ])
    func summer(locale: String, expected: String) {
        #expect(hijri("2027-06-21").formatted(locale: Locale(identifier: locale)) == expected)
    }

    @Test("Monats- und Jahreswechsel nach Umm al-Qura", arguments: [
        ("2025-06-26", 1447, 1, 1),
        ("2026-02-17", 1447, 8, 29),
        ("2026-02-18", 1447, 9, 1),
        ("2026-03-19", 1447, 9, 30),
        ("2026-03-20", 1447, 10, 1),
        ("2026-05-27", 1447, 12, 10),
        ("2026-06-16", 1448, 1, 1),
        ("2026-11-09", 1448, 5, 29),
        ("2026-11-11", 1448, 6, 1),
        ("2027-02-08", 1448, 9, 1),
        ("2027-06-06", 1449, 1, 1),
    ])
    func anchors(day: String, year: Int, month: Int, dayOfMonth: Int) {
        let date = hijri(day)
        #expect(date.year == year)
        #expect(date.month == month)
        #expect(date.day == dayOfMonth)
    }

    @Test("der Tag nach dem 30. Dschumada I ist der 1. Dschumada II")
    func nextDay() {
        #expect(hijri("2026-11-11").formatted(locale: Locale(identifier: "de_DE")) == "1. Dschumada II 1448")
    }

    @Test("wo die Sprache die Ära anhängt, fällt sie weg")
    func withoutEra() {
        // Arabisch (Saudi-Arabien) schreibt „١٤٤٨ هـ“; übrig bleibt das Datum mit dem Jahr am Ende.
        let text = hijri("2026-11-10").formatted(locale: Locale(identifier: "ar_SA"))
        #expect(!text.contains("هـ"))
        #expect(text.hasSuffix("١٤٤٨"))
        #expect(text.hasPrefix("٣٠"))
    }

    @Test("das Feld der Ära verschwindet aus dem Muster, Text in Anführungszeichen bleibt", arguments: [
        ("d MMMM، y G", "d MMMM، y "),
        ("d. MMMM y", "d. MMMM y"),
        ("d 'de' MMMM 'de' y", "d 'de' MMMM 'de' y"),
        ("GGGG y 'G' d", " y 'G' d"),
        ("", ""),
    ])
    func removesEra(pattern: String, expected: String) {
        #expect(HijriDate.removingEra(from: pattern) == expected)
    }

    @Test("am Ende fallen Leerraum, Kommas und Punkte weg, am Anfang Leerraum", arguments: [
        ("30. Dschumada I 1448 ", "30. Dschumada I 1448"),
        ("30 Jumada I 1448, ", "30 Jumada I 1448"),
        (" 1448 Cemaziyelevvel 30", "1448 Cemaziyelevvel 30"),
        ("1448.", "1448"),
        ("30. Dschumada I 1448", "30. Dschumada I 1448"),
        (" , .", ""),
        ("", ""),
    ])
    func trims(text: String, expected: String) {
        #expect(HijriDate.trimmingEnds(text) == expected)
    }

    @Test("gleiche Tage sind gleich, verschiedene nicht")
    func equality() {
        #expect(hijri("2026-11-10") == hijri("2026-11-10"))
        #expect(hijri("2026-11-10") != hijri("2026-11-11"))
    }
}
