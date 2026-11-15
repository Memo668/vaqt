import Foundation
import PrayerCore

/// Ein Tag der Seite „Verse“, fertig zum Anzeigen: der Vers des Tages, der Name des Tages und das Datum.
///
/// Die Texte entstehen wie `relDay()`, `shortDate()` und `verseRef()` im Prototyp, in der Sprache der App.
public struct VerseDay: Identifiable, Hashable, Sendable {
    /// Der Kalendertag.
    public let day: CalendarDay
    /// Der Vers dieses Tages.
    public let verse: Verse
    /// Ob es der heutige Tag ist.
    public let isToday: Bool
    /// „Heute“, „Gestern“ oder der Wochentag, z. B. „Sonntag“ (`relDay()`).
    public let dayName: String
    /// Tag und kurzer Monat, z. B. „10. Nov.“ (`shortDate()`).
    public let shortDate: String

    public var id: CalendarDay { day }

    /// - Parameters:
    ///   - today: der heutige Tag; von ihm aus heißt `day` „Heute“, „Gestern“ oder nach seinem Wochentag.
    ///   - locale: Sprache für Wochentag und Monat; ohne Angabe die der Texte.
    public init(_ day: CalendarDay, today: CalendarDay, locale: Locale = L10n.locale) {
        self.day = day
        verse = Verse.ofDay(day)
        isToday = day == today
        switch today.days(since: day) {
        case 0: dayName = L10n.today
        case 1: dayName = L10n.yesterday
        default: dayName = Self.format(day, template: "EEEE", locale: locale)
        }
        shortDate = Self.format(day, template: "dMMM", locale: locale)
    }

    /// Die Liste „Letzte Tage“: heute und die fünf Tage davor.
    public static func recent(endingAt today: CalendarDay, locale: Locale = L10n.locale) -> [VerseDay] {
        Verse.recentDays(endingAt: today).map { VerseDay($0, today: today, locale: locale) }
    }

    /// Stichwort oben in der Karte: „Vers des Tages“ für heute, sonst der Name des Tages, z. B. „Gestern“.
    public var cardTitle: String {
        isToday ? L10n.verseToday : dayName
    }

    /// Erste Zeile eines Eintrags der Liste: „Heute · 10. Nov.“.
    public var listTitle: String {
        "\(dayName) · \(shortDate)"
    }

    /// Schreibt einen Kalendertag mit einer Vorlage von `DateFormatter`, unabhängig von der Zeitzone.
    static func format(_ day: CalendarDay, template: String, locale: Locale) -> String {
        // Der Kalender der Region, persisch auf Persisch; ein islamischer bleibt gregorianisch (Spec § 9.10).
        var calendar = L10n.displayCalendar(for: locale)
        calendar.timeZone = .gmt
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(template)
        // Mittags in GMT liegt jeder Kalendertag eindeutig auf sich selbst.
        return formatter.string(from: day.date(at: ClockTime(minutesSinceMidnight: 12 * 60), in: .gmt))
    }
}

extension Verse {

    /// Die Übersetzung in der Sprache der App.
    ///
    /// TODO(placeholder): Die Übersetzungen sind Platzhalter des Prototyps; die lizenzierte Übersetzung
    /// fehlt noch (Spec § 6.12).
    public var localizedTranslation: String {
        L10n.verseTranslation(surah: surah, ayah: ayah)
    }

    /// Name der Sure in der Sprache der App, z. B. „Al-Baqara“.
    public var localizedSurahName: String {
        L10n.surahName(surah)
    }

    /// Die Quelle wie `verseRef()`: „Al-Baqara 2:45“.
    public var localizedReference: String {
        "\(localizedSurahName) \(L10n.number(surah)):\(L10n.number(ayah))"
    }

    /// Text zum Teilen und Kopieren: Arabisch, Übersetzung und Quelle, je eine Zeile (Spec § 4: „Share
    /// opens the system share sheet with Arabic, translation and reference“).
    public var shareText: String {
        [arabic, localizedTranslation, localizedReference].filter { !$0.isEmpty }.joined(separator: "\n")
    }
}
