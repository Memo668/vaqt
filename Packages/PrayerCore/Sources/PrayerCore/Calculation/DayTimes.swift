import Foundation

/// Die sechs Zeiten eines Tages an einem Ort, als Zeitpunkte – das Ergebnis von `todayTimes()` im Prototyp.
///
/// Die Minutenkorrekturen sind schon enthalten. Die Zeiten gehören zum Kalendertag `day`, liegen aber
/// nicht zwingend darauf: Bei hohen Breiten fällt Ischa mit der Regel „Nachtmitte“ auf den Folgetag.
public struct DayTimes: Hashable, Codable, Sendable {
    /// Der Kalendertag in `timeZone`, zu dem die Zeiten gehören.
    public let day: CalendarDay
    /// Zeitzone des Ortes; in ihr werden die Zeiten angezeigt.
    public let timeZone: TimeZone
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date

    public init(
        day: CalendarDay, timeZone: TimeZone,
        fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date
    ) {
        self.day = day
        self.timeZone = timeZone
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }

    /// Zeitpunkt eines Ereignisses.
    public subscript(prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: fajr
        case .sunrise: sunrise
        case .dhuhr: dhuhr
        case .asr: asr
        case .maghrib: maghrib
        case .isha: isha
        }
    }

    /// Uhrzeit eines Ereignisses am Ort, wie sie angezeigt wird – z. B. 14:00, oder 01:08 für ein Ischa
    /// nach Mitternacht.
    public func clockTime(of prayer: Prayer) -> ClockTime {
        ClockTime(self[prayer], in: timeZone)
    }
}
