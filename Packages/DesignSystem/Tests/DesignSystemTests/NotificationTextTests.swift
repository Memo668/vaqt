import Foundation
import PrayerCore
import Testing
@testable import DesignSystem

/// Die Texte der Mitteilungen aus `T` (`notifPrayerTitle`, `notifPrayerBody`, `notifReminderTitle`,
/// `notifReminderBody`) – mit den Werten des Referenzbilds `system/92` und in DE/TR/EN/ES, dazu die Mehrzahl der
/// Minuten in den Sprachen, die sie brauchen (Phase 15).
@Suite("Texte der Mitteilungen")
struct NotificationTextTests {

    /// Ein Text der Sprache mit eingesetzten Werten, in der Reihenfolge der Argumente von `L10n` – mit der Locale
    /// der Sprache wie `L10n.text`, sonst wählt iOS die Mehrzahl nach der Sprache des Simulators.
    private func text(_ key: String, _ language: AppLanguage, _ arguments: any CVarArg...) -> String {
        let format = L10n.textBundle(for: language).localizedString(forKey: key, value: nil, table: nil)
        let locale = Locale(identifier: L10n.regions[language.rawValue] ?? "de_DE")
        return String(format: format, locale: locale, arguments: arguments)
    }

    @Test("system/92: „Dhuhr · 11:52“, „Zeit für Dhuhr in Berlin.“, „Dhuhr in 10 Minuten“, „Dhuhr beginnt um 11:52 Uhr.“")
    func reference() {
        #expect(text("notifPrayerTitle", .de, "Dhuhr", "11:52") == "Dhuhr · 11:52")
        #expect(text("notifPrayerBody", .de, "Dhuhr", "Berlin") == "Zeit für Dhuhr in Berlin.")
        #expect(text("notifReminderTitle", .de, "Dhuhr", 10) == "Dhuhr in 10 Minuten")
        #expect(text("notifReminderBody", .de, "Dhuhr", "11:52") == "Dhuhr beginnt um 11:52 Uhr.")
    }

    @Test("Türkisch stellt die Stadt nach vorn")
    func turkish() {
        #expect(text("notifPrayerTitle", .tr, "Öğle", "12:53") == "Öğle · 12:53")
        #expect(text("notifPrayerBody", .tr, "Öğle", "İstanbul") == "İstanbul için Öğle vakti girdi.")
        #expect(text("notifReminderTitle", .tr, "Öğle", 10) == "Öğle vaktine 10 dakika")
        #expect(text("notifReminderBody", .tr, "Öğle", "11:52’de") == "Öğle vakti 11:52’de başlıyor.")
    }

    /// Phase 11, „Endung berechnen“: Die Uhrzeit trägt im Türkischen die Endung, die zu ihr passt; die
    /// übrigen Sprachen bekommen sie ohne.
    @Test("Uhrzeit der Vorab-Erinnerung: im Türkischen mit Endung", arguments: [
        ("12:53", AppLanguage.tr, "12:53’te"), ("15:36", .tr, "15:36’da"), ("14:00", .tr, "14:00’te"),
        ("11:52", .tr, "11:52’de"), ("11:52", .de, "11:52"), ("11:52", .en, "11:52"), ("13:00", .es, "13:00"),
    ])
    func reminderTime(time: String, language: AppLanguage, expected: String) throws {
        let clock = try #require(ClockTime(time))
        #expect(L10n.reminderTime(clock, in: language) == expected)
    }

    @Test("Türkisch: der ganze Satz mit berechneter Endung")
    func turkishSentence() throws {
        let clock = try #require(ClockTime("12:53"))
        #expect(text("notifReminderBody", .tr, "Öğle", L10n.reminderTime(clock, in: .tr)) == "Öğle vakti 12:53’te başlıyor.")
    }

    @Test("Englisch und Spanisch")
    func englishSpanish() {
        #expect(text("notifPrayerBody", .en, "Dhuhr", "Berlin") == "It’s time for Dhuhr in Berlin.")
        #expect(text("notifReminderTitle", .en, "Dhuhr", 10) == "Dhuhr in 10 minutes")
        #expect(text("notifReminderBody", .en, "Dhuhr", "11:52") == "Dhuhr begins at 11:52.")
        #expect(text("notifPrayerBody", .es, "Dhuhr", "Madrid") == "Es la hora de Dhuhr en Madrid.")
        #expect(text("notifReminderTitle", .es, "Dhuhr", 10) == "Dhuhr en 10 minutos")
        #expect(text("notifReminderBody", .es, "Dhuhr", "13:00") == "Dhuhr empieza a las 13:00.")
    }

    @Test("Vorab-Erinnerung: die Minuten in der Mehrzahl der Sprache", arguments: [
        (AppLanguage.de, 1, "Dhuhr in 1 Minute"), (.de, 5, "Dhuhr in 5 Minuten"),
        (.en, 1, "Dhuhr in 1 minute"), (.bs, 1, "Dhuhr za 1 minutu"), (.bs, 3, "Dhuhr za 3 minute"),
        (.bs, 10, "Dhuhr za 10 minuta"), (.sq, 1, "Dhuhr pas 1 minute"), (.sq, 10, "Dhuhr pas 10 minutash"),
        (.ar, 1, "Dhuhr بعد دقيقة واحدة"), (.ar, 2, "Dhuhr بعد دقيقتين"), (.ar, 5, "Dhuhr بعد 5 دقائق"),
        (.ar, 15, "Dhuhr بعد 15 دقيقة"),
    ])
    func reminderPlural(language: AppLanguage, minutes: Int, expected: String) {
        // Mit Locale setzt iOS Texte von rechts nach links in Isolierzeichen (U+2068 … U+2069).
        let plain = text("notifReminderTitle", language, "Dhuhr", minutes)
            .replacingOccurrences(of: "\u{2068}", with: "").replacingOccurrences(of: "\u{2069}", with: "")
        #expect(plain == expected)
    }
}
