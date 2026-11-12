import Foundation

/// Die Zeiten von gestern, heute und morgen – der Zeitstrahl über drei Tage, auf dem `phase()` im
/// Prototyp arbeitet. Damit lösen sich „vor Fadschr“ und „nach Ischa“ über Mitternacht hinweg richtig auf.
public struct PrayerTimeline: Hashable, Sendable {
    public let yesterday: DayTimes
    public let today: DayTimes
    public let tomorrow: DayTimes

    public init(yesterday: DayTimes, today: DayTimes, tomorrow: DayTimes) {
        self.yesterday = yesterday
        self.today = today
        self.tomorrow = tomorrow
    }

    /// Ob `now` am Ort auf den Tag `today` fällt. Nach Mitternacht braucht es einen neuen Zeitstrahl.
    public func covers(_ now: Date) -> Bool {
        CalendarDay(now, in: today.timeZone) == today.day
    }

    /// Die Tagesphase zum Zeitpunkt `now`.
    ///
    /// Laufend ist das letzte Ereignis, das schon begonnen hat. Maßgeblich ist dabei die Tagesfolge der
    /// Ereignisse, nicht allein die Uhrzeit: Fallen zwei auf denselben Zeitpunkt, gewinnt das spätere der
    /// Folge (Ischa von gestern und Fadschr von heute um 01:08 – Fadschr gewinnt). Dasselbe gilt, wenn
    /// die Regel „Nachtmitte“ Ischa von gestern eine Minute hinter Fadschr von heute legt. Für Zeiten in
    /// aufsteigender Reihenfolge ist das Ergebnis dasselbe wie beim Sortieren nach Uhrzeit im Prototyp.
    ///
    /// - Returns: `nil`, wenn `now` nicht auf den Tag `today` fällt (`covers(_:)`) oder die Zeiten
    ///   `now` nicht einschließen.
    public func phase(at now: Date) -> DayPhase? {
        guard covers(now) else { return nil }
        let events = events
        guard let index = events.lastIndex(where: { $0.date <= now }), index + 2 < events.count else { return nil }
        return DayPhase(
            now: now, times: today,
            previous: events[index], next: events[index + 1], following: events[index + 2]
        )
    }

    /// Die Zeiten des Tages mit dem Abstand `dayOffset` zu `today`: −1 gestern, 0 heute, 1 morgen.
    public func times(dayOffset: Int) -> DayTimes {
        switch dayOffset {
        case ..<0: yesterday
        case 0: today
        default: tomorrow
        }
    }

    /// Die 18 Ereignisse der drei Tage in ihrer Tagesfolge.
    var events: [DayPhase.Event] {
        [(yesterday, -1), (today, 0), (tomorrow, 1)].flatMap { times, dayOffset in
            Prayer.allCases.map { DayPhase.Event(prayer: $0, dayOffset: dayOffset, date: times[$0]) }
        }
    }
}

extension PrayerTimesSource {

    /// Der Zeitstrahl um den Tag `day`: die Zeiten des Vortags, des Tages und des Folgetags.
    /// `nil`, wenn sich für einen der drei Tage keine Zeiten bestimmen lassen.
    public func timeline(around day: CalendarDay, at place: Place, settings: CalculationSettings) -> PrayerTimeline? {
        guard let yesterday = times(on: day.adding(days: -1), at: place, settings: settings),
              let today = times(on: day, at: place, settings: settings),
              let tomorrow = times(on: day.adding(days: 1), at: place, settings: settings)
        else { return nil }
        return PrayerTimeline(yesterday: yesterday, today: today, tomorrow: tomorrow)
    }

    /// Der Zeitstrahl für den Kalendertag, auf den `now` am Ort fällt.
    public func timeline(at now: Date, place: Place, settings: CalculationSettings) -> PrayerTimeline? {
        timeline(around: CalendarDay(now, in: place.timeZone), at: place, settings: settings)
    }
}
