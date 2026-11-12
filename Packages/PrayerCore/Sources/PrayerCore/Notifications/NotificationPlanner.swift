import Foundation

/// Welche Mitteilungen die App bei iOS vormerkt: die nächsten ab „jetzt“, mit Texten und Tönen
/// (Spec § 1, § 3 „Notifications“, § 6.4).
///
/// Je Ereignis, dessen Glocke nicht auf „Aus“ steht, kommt eine Mitteilung zu seiner Zeit; ist eine
/// Vorab-Erinnerung gewählt, dazu eine um so viele Minuten früher. Der Sonnenaufgang zählt mit, wenn seine
/// Glocke an ist (Startwert aus, wie im Prototyp). Kerahat-Fenster haben keine Mitteilung (Spec § 4). Die
/// Zeiten kommen aus der Quelle, Minutenkorrekturen eingerechnet – die Mitteilung nennt dieselbe Uhrzeit
/// wie die Gebetskarte.
///
/// iOS hält je App höchstens 64 ausstehende Mitteilungen und verwirft spätere. Deshalb plant die App ein
/// rollierendes Fenster: die nächsten 64 Mitteilungen in zeitlicher Folge, neu bei jedem Start, bei der
/// Hintergrundaktualisierung und nach jeder Änderung. Eine Erinnerung kommt nur zusammen mit ihrer
/// Mitteilung ins Fenster. Mit den Startwerten – fünf Glocken an, Erinnerung 10 Minuten vorher – sind das
/// zehn am Tag und gut sechs Tage; ohne Erinnerung knapp 13.
public struct NotificationPlanner: Sendable {

    /// So viele ausstehende Mitteilungen hält iOS je App.
    public static let pendingLimit = 64

    /// So viele Tage nach heute sucht der Plan höchstens – auch wenn nur ein Ereignis am Tag eine
    /// Mitteilung hat oder es an vielen Tagen keine Zeiten gibt.
    public static let maximumDays = 64

    public let source: any PrayerTimesSource
    public let wording: any NotificationWording
    /// Höchstzahl der Mitteilungen im Plan.
    public let limit: Int

    public init(source: any PrayerTimesSource, wording: any NotificationWording, limit: Int = NotificationPlanner.pendingLimit) {
        self.source = source
        self.wording = wording
        self.limit = limit
    }

    /// Die Mitteilungen nach `now`, in zeitlicher Folge, höchstens `limit`.
    ///
    /// Tage, für die die Quelle keine Zeiten hat – etwa wo die Sonne nicht auf- oder untergeht –, fallen
    /// aus; der Plan geht mit dem nächsten Tag weiter, der Zeiten hat.
    ///
    /// - Parameters:
    ///   - now: jetzt, auf der Uhr der App.
    ///   - place: der Ort, der gilt. Seine Zeitzone bestimmt die Tage und die Uhrzeiten in den Texten.
    ///   - cityName: Name des Ortes im Text („Zeit für Dhuhr in Berlin.“).
    ///   - settings: Methode, Asr, Regel für hohe Breiten, Minutenkorrekturen.
    ///   - bells: Stand der Glocke je Ereignis; fehlt einer, gilt seine Voreinstellung.
    ///   - preferences: Vorab-Erinnerung, Klang und Stimme.
    public func plan(
        at now: Date, place: Place, cityName: String, settings: CalculationSettings,
        bells: [Prayer: BellState], preferences: NotificationPreferences
    ) -> [PrayerNotification] {
        let bells = Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, bells[$0] ?? .standard(for: $0)) })
        guard limit > 0, bells.values.contains(where: { $0 != .off }) else { return [] }

        let today = CalendarDay(now, in: place.timeZone)
        var slots: [Slot] = []
        var limitReachedOnDay: Int?
        // Ab gestern: Ein Ischa nach Mitternacht gehört zum Vortag und kann noch bevorstehen.
        for offset in -1...Self.maximumDays {
            if let times = source.times(on: today.adding(days: offset), at: place, settings: settings) {
                slots += Self.slots(on: times, bells: bells, preferences: preferences).filter { $0.date > now }
            }
            // Ist die Höchstzahl erreicht, kommt noch ein Tag dazu: Seine ersten Mitteilungen können vor den
            // letzten des Vortags liegen – etwa die Erinnerung an Fadschr vor einem Ischa nach Mitternacht.
            if slots.count >= limit {
                if let reached = limitReachedOnDay, offset > reached { break }
                limitReachedOnDay = limitReachedOnDay ?? offset
            }
        }

        var chosen = Array(slots.sorted().prefix(limit))
        // Eine Erinnerung ohne ihre Mitteilung bleibt draußen – am Ende des Fensters.
        let prayers = Set(chosen.filter { $0.kind == .prayer }.map(\.event))
        chosen.removeAll { $0.kind == .reminder && !prayers.contains($0.event) }
        return chosen.map { notification(for: $0, cityName: cityName, preferences: preferences) }
    }

    // MARK: - Bausteine

    /// Ein Platz im Plan, noch ohne Texte: Die Texte entstehen nur für die Mitteilungen, die ins Fenster
    /// kommen.
    struct Slot: Comparable {
        let kind: PrayerNotification.Kind
        let prayer: Prayer
        let day: CalendarDay
        let date: Date
        let eventDate: Date
        let time: ClockTime
        let tone: NotificationTone

        /// Das Ereignis, zu dem der Platz gehört: Gebet und Tag.
        var event: String {
            PrayerNotification.identifier(kind: .prayer, prayer: prayer, day: day)
        }

        /// In zeitlicher Folge. Fallen zwei auf denselben Zeitpunkt, gilt die Tagesfolge der Ereignisse
        /// und die Erinnerung vor der Mitteilung.
        static func < (lhs: Slot, rhs: Slot) -> Bool {
            (lhs.date, lhs.day, lhs.order, lhs.kind == .prayer ? 1 : 0)
                < (rhs.date, rhs.day, rhs.order, rhs.kind == .prayer ? 1 : 0)
        }

        private var order: Int {
            Prayer.allCases.firstIndex(of: prayer) ?? 0
        }
    }

    /// Die Plätze eines Tages: je Ereignis mit Glocke die Mitteilung und, falls gewählt, die Erinnerung.
    static func slots(on times: DayTimes, bells: [Prayer: BellState], preferences: NotificationPreferences) -> [Slot] {
        Prayer.allCases.flatMap { prayer -> [Slot] in
            let bell = bells[prayer] ?? .standard(for: prayer)
            guard let tone = NotificationTone.prayer(prayer, bell: bell, preferences: preferences) else { return [] }
            let date = times[prayer]
            let time = times.clockTime(of: prayer)
            var slots = [Slot(kind: .prayer, prayer: prayer, day: times.day, date: date, eventDate: date, time: time, tone: tone)]
            let minutes = preferences.reminderMinutes
            if minutes > 0, let reminderTone = NotificationTone.reminder(bell: bell, preferences: preferences) {
                slots.append(Slot(
                    kind: .reminder, prayer: prayer, day: times.day,
                    date: date.addingTimeInterval(-TimeInterval(minutes) * 60), eventDate: date, time: time, tone: reminderTone
                ))
            }
            return slots
        }
    }

    private func notification(for slot: Slot, cityName: String, preferences: NotificationPreferences) -> PrayerNotification {
        let title: String
        let body: String
        switch slot.kind {
        case .prayer:
            title = wording.prayerTitle(slot.prayer, time: slot.time)
            body = wording.prayerBody(slot.prayer, city: cityName)
        case .reminder:
            title = wording.reminderTitle(slot.prayer, minutes: preferences.reminderMinutes)
            body = wording.reminderBody(slot.prayer, time: slot.time)
        }
        return PrayerNotification(
            kind: slot.kind, prayer: slot.prayer, day: slot.day, date: slot.date, eventDate: slot.eventDate,
            title: title, body: body, tone: slot.tone
        )
    }
}
