import Foundation

/// Die sechs Zeiten eines Tages an einem Ort, als Zeitpunkte – das Ergebnis von `todayTimes()` im Prototyp.
///
/// Die Minutenkorrekturen sind schon enthalten. Die Zeiten gehören zum Kalendertag `day`, liegen aber
/// nicht zwingend darauf: Bei hohen Breiten fällt Ischa mit der Regel „Nachtmitte“ auf den Folgetag.
///
/// Seit dem Nachtrag zu Phase 18 tragen die Zeiten die Rechtsschule, mit der sie gerechnet sind (`madhab`,
/// aus `CalculationSettings`). Daraus ergeben sich ihre Kerahat-Fenster (`Kerahat.windows(for:)`) – überall
/// gleich, in der App, in den Widgets und in der Live-Aktivität, die die Zeiten mitträgt. Der Prototyp hängt
/// dafür den Wochentag an die Zeiten (`tt.day`) und liest `S.madhab`.
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
    /// Die Rechtsschule, deren Verbotszeiten zu diesen Zeiten gehören (Spec § 11.6).
    public let madhab: Madhab

    public init(
        day: CalendarDay, timeZone: TimeZone,
        fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date,
        madhab: Madhab = .standard
    ) {
        self.day = day
        self.timeZone = timeZone
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.madhab = madhab
    }

    /// Zeiten, die vor dem Nachtrag zu Phase 18 gespeichert wurden – etwa im Inhalt einer Live-Aktivität –,
    /// haben keine Rechtsschule: Dann gilt Hanafi, wie bis dahin überall.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(CalendarDay.self, forKey: .day)
        timeZone = try container.decode(TimeZone.self, forKey: .timeZone)
        fajr = try container.decode(Date.self, forKey: .fajr)
        sunrise = try container.decode(Date.self, forKey: .sunrise)
        dhuhr = try container.decode(Date.self, forKey: .dhuhr)
        asr = try container.decode(Date.self, forKey: .asr)
        maghrib = try container.decode(Date.self, forKey: .maghrib)
        isha = try container.decode(Date.self, forKey: .isha)
        madhab = (try? container.decodeIfPresent(Madhab.self, forKey: .madhab)) ?? .standard
    }

    private enum CodingKeys: String, CodingKey {
        case day, timeZone, fajr, sunrise, dhuhr, asr, maghrib, isha, madhab
    }

    /// Ob der Tag, zu dem die Zeiten gehören, ein Freitag ist – für die schafiitische Ausnahme vor Dhuhr.
    /// Der Wochentag hängt nur am Kalendertag, nicht an der Uhrzeit.
    public var isFriday: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let date = calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day)) ?? .distantPast
        // Gregorianisch: 1 = Sonntag, 6 = Freitag (im Prototyp `getDay() === 5`).
        return calendar.component(.weekday, from: date) == 6
    }

    /// Dieselben Zeiten mit einer anderen Rechtsschule.
    public func with(madhab: Madhab) -> DayTimes {
        DayTimes(
            day: day, timeZone: timeZone, fajr: fajr, sunrise: sunrise, dhuhr: dhuhr, asr: asr,
            maghrib: maghrib, isha: isha, madhab: madhab
        )
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
