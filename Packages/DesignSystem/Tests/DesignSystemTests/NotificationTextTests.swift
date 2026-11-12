import Foundation
import Testing
@testable import DesignSystem

/// Die Texte der Mitteilungen aus `T` (`notifPrayerTitle`, `notifPrayerBody`, `notifReminderTitle`,
/// `notifReminderBody`) – mit den Werten des Referenzbilds `system/92` und in allen vier Sprachen.
@Suite("Texte der Mitteilungen")
struct NotificationTextTests {

    /// Ein Text der Sprache mit eingesetzten Werten, in der Reihenfolge der Argumente von `L10n`.
    private func text(_ key: String, _ language: AppLanguage, _ arguments: String...) -> String {
        let format = L10n.textBundle(for: language).localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: arguments)
    }

    @Test("system/92: „Dhuhr · 11:52“, „Zeit für Dhuhr in Berlin.“, „Dhuhr in 10 Minuten“, „Dhuhr beginnt um 11:52 Uhr.“")
    func reference() {
        #expect(text("notifPrayerTitle", .de, "Dhuhr", "11:52") == "Dhuhr · 11:52")
        #expect(text("notifPrayerBody", .de, "Dhuhr", "Berlin") == "Zeit für Dhuhr in Berlin.")
        #expect(text("notifReminderTitle", .de, "Dhuhr", "10") == "Dhuhr in 10 Minuten")
        #expect(text("notifReminderBody", .de, "Dhuhr", "11:52") == "Dhuhr beginnt um 11:52 Uhr.")
    }

    @Test("Türkisch stellt die Stadt nach vorn")
    func turkish() {
        #expect(text("notifPrayerTitle", .tr, "Öğle", "12:53") == "Öğle · 12:53")
        #expect(text("notifPrayerBody", .tr, "Öğle", "İstanbul") == "İstanbul için Öğle vakti girdi.")
        #expect(text("notifReminderTitle", .tr, "Öğle", "10") == "Öğle vaktine 10 dakika")
        #expect(text("notifReminderBody", .tr, "Öğle", "11:52") == "Öğle vakti 11:52’de başlıyor.")
    }

    @Test("Englisch und Spanisch")
    func englishSpanish() {
        #expect(text("notifPrayerBody", .en, "Dhuhr", "Berlin") == "It’s time for Dhuhr in Berlin.")
        #expect(text("notifReminderTitle", .en, "Dhuhr", "10") == "Dhuhr in 10 minutes")
        #expect(text("notifReminderBody", .en, "Dhuhr", "11:52") == "Dhuhr begins at 11:52.")
        #expect(text("notifPrayerBody", .es, "Dhuhr", "Madrid") == "Es la hora de Dhuhr en Madrid.")
        #expect(text("notifReminderTitle", .es, "Dhuhr", "10") == "Dhuhr en 10 minutos")
        #expect(text("notifReminderBody", .es, "Dhuhr", "13:00") == "Dhuhr empieza a las 13:00.")
    }
}
