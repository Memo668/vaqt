import Foundation

/// Eine geplante Mitteilung: zur Zeit eines Ereignisses oder als Vorab-Erinnerung davor (Spec § 1,
/// „Local notifications (prayer + reminder)“).
public struct PrayerNotification: Hashable, Sendable, Identifiable {

    /// Mitteilung zur Gebetszeit oder Vorab-Erinnerung.
    public enum Kind: String, Hashable, Sendable {
        /// „Dhuhr · 11:52“ – „Zeit für Dhuhr in Berlin.“
        case prayer
        /// „Dhuhr in 10 Minuten“ – „Dhuhr beginnt um 11:52 Uhr.“
        case reminder
    }

    /// Kennung, die für dieselbe Mitteilung gleich bleibt, z. B. „prayer.2026-11-10.dhuhr“ oder
    /// „reminder.2026-11-10.dhuhr“.
    public let id: String
    public let kind: Kind
    public let prayer: Prayer
    /// Der Tag, zu dem die Zeit gehört. Ein Ischa nach Mitternacht gehört zum Vortag.
    public let day: CalendarDay
    /// Wann die Mitteilung kommt, auf der Uhr der App.
    public let date: Date
    /// Zeitpunkt des Ereignisses selbst; bei der Erinnerung später als `date`.
    public let eventDate: Date
    public let title: String
    public let body: String
    public let tone: NotificationTone

    public init(
        kind: Kind, prayer: Prayer, day: CalendarDay, date: Date, eventDate: Date,
        title: String, body: String, tone: NotificationTone
    ) {
        id = Self.identifier(kind: kind, prayer: prayer, day: day)
        self.kind = kind
        self.prayer = prayer
        self.day = day
        self.date = date
        self.eventDate = eventDate
        self.title = title
        self.body = body
        self.tone = tone
    }

    /// „prayer.2026-11-10.dhuhr“, „reminder.2026-11-10.dhuhr“.
    public static func identifier(kind: Kind, prayer: Prayer, day: CalendarDay) -> String {
        kind.rawValue + "." + day.description + "." + prayer.rawValue
    }
}

/// Die Texte einer Mitteilung – `notifPrayerTitle`, `notifPrayerBody`, `notifReminderTitle` und
/// `notifReminderBody` aus `T` im Prototyp.
///
/// PrayerCore kennt den String Catalog nicht. Die App setzt die Texte in ihrer Sprache ein (Features,
/// `L10nNotificationWording`); Tests nehmen eigene.
public protocol NotificationWording: Sendable {
    /// „Dhuhr · 11:52“
    func prayerTitle(_ prayer: Prayer, time: ClockTime) -> String
    /// „Zeit für Dhuhr in Berlin.“
    func prayerBody(_ prayer: Prayer, city: String) -> String
    /// „Dhuhr in 10 Minuten“
    func reminderTitle(_ prayer: Prayer, minutes: Int) -> String
    /// „Dhuhr beginnt um 11:52 Uhr.“
    func reminderBody(_ prayer: Prayer, time: ClockTime) -> String
}
