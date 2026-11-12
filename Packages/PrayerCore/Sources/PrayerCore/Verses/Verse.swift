import Foundation

/// Ein Vers für die Seite „Verse“: die Stelle im Koran und der arabische Text – ein Eintrag aus `VERSES`
/// im Prototyp.
///
/// Übersetzung und Name der Sure hängen von der Sprache ab und stehen deshalb im String Catalog
/// (`verse_<Sure>_<Vers>`, `surah_<Sure>`). Die Liste der Verse (`Verse.all`) erzeugt
/// `scripts/import-strings` aus dem Prototyp.
public struct Verse: Hashable, Sendable {
    /// Nummer der Sure, z. B. 2 für al-Baqara.
    public let surah: Int
    /// Nummer des Verses in der Sure.
    public let ayah: Int
    /// Der Vers auf Arabisch.
    public let arabic: String

    public init(surah: Int, ayah: Int, arabic: String) {
        self.surah = surah
        self.ayah = ayah
        self.arabic = arabic
    }
}

extension Verse {

    /// Wie viele Tage die Liste „Letzte Tage“ zeigt: heute und die fünf Tage davor – so viele Einträge
    /// hat sie im Prototyp.
    public static let recentDayCount = 6

    /// Der Tag, an dem der erste Vers der Liste der Vers des Tages ist: der Tag der Referenzbilder.
    /// An den Tagen davor stehen die folgenden Verse der Liste – so wie in `iphone/50`.
    public static let firstDay = CalendarDay(year: 2026, month: 11, day: 10)!

    /// Der Vers des Tages.
    ///
    /// Die Liste läuft im Kreis (Spec § 4, „one verse per day (rotating list)“): Am 10.11.2026 steht der
    /// erste Vers, am Tag davor der zweite und so fort; vom 11.11.2026 an kommen die Verse vom Ende der
    /// Liste her. So gilt jeden Tag ein anderer Vers, und die Liste „Letzte Tage“ zeigt am 10.11.2026
    /// dieselbe Folge wie der Prototyp.
    public static func ofDay(_ day: CalendarDay) -> Verse {
        all[index(of: day, count: all.count)]
    }

    /// Die Tage der Liste „Letzte Tage“: heute zuerst, dann rückwärts.
    public static func recentDays(endingAt today: CalendarDay) -> [CalendarDay] {
        (0..<recentDayCount).map { today.adding(days: -$0) }
    }

    /// Stelle in einer Liste mit `count` Versen, die am Tag `day` gilt.
    static func index(of day: CalendarDay, count: Int) -> Int {
        precondition(count > 0, "Die Liste der Verse ist leer")
        let daysBefore = firstDay.days(since: day)
        return (daysBefore % count + count) % count
    }
}
