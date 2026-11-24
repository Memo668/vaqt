#if DEBUG

import Foundation

/// Die Mock-Zeiten des Prototyps als Quelle – für `-debugFixtureTimes`.
///
/// Entspricht `todayTimes()` im Prototyp: Die Zeiten hängen nur von der Stadt, der Asr-Regel, der Regel
/// für hohe Breiten (mit `-debugHighLatitude` auch den eigenen Winkeln) und den Minutenkorrekturen ab. Methode und Datum ändern nichts – jeder Tag zeigt
/// dieselben Uhrzeiten, so wie der Prototyp seinen Zeitstrahl aus einem einzigen Tag baut.
public struct FixtureTimesSource: PrayerTimesSource {

    /// `-debugHighLatitude`: Es gelten die Zeiten aus `FixtureTimes.berlinSummer`, Fadschr und Ischa je
    /// nach Regel für hohe Breiten.
    public let highLatitude: Bool

    public init(highLatitude: Bool = false) {
        self.highLatitude = highLatitude
    }

    /// Die Zeiten der Fixture-Stadt, die an den Koordinaten von `place` liegt. Für jeden anderen Ort
    /// gilt Berlin, die Stadt, in der der Prototyp startet. Die Uhrzeiten gelten in der Zeitzone des Ortes.
    public func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? {
        guard let minutes = minutes(at: place, settings: settings) else { return nil }
        return dayTimes(on: day, minutes: minutes, in: place.timeZone, madhab: settings.madhab)
    }

    /// Ein anderer Tag wie `dayTimes()` im Prototyp (Spec § 9.4): die Mock-Zeiten von heute plus die
    /// Verschiebung, die das Sonnenmodell des Prototyps zwischen `today` und `day` ergibt (Fadschr 18°,
    /// Ischa 17°, Sommerzeit eingeschlossen). Mit `-debugHighLatitude` rechnet es für Berlin.
    public func times(
        on day: CalendarDay, viewedFrom today: CalendarDay, at place: Place, settings: CalculationSettings
    ) -> DayTimes? {
        guard day != today else { return times(on: day, at: place, settings: settings) }
        guard var minutes = minutes(at: place, settings: settings) else { return nil }
        let city = city(at: place)
        let shift = FixtureSunModel.shift(
            from: today, to: day, at: city.coordinates, in: city.place(named: city.id).timeZone,
            asrFactor: settings.asr == .hanafi ? 2 : 1
        )
        for prayer in Prayer.allCases {
            minutes[prayer, default: 0] += shift[prayer] ?? 0
        }
        return dayTimes(on: day, minutes: minutes, in: place.timeZone, madhab: settings.madhab)
    }

    /// Minuten seit Mitternacht samt Korrektur, wie `todayTimes()`. Ischa darf nach Mitternacht liegen
    /// (hohe Breiten, „Nachtmitte“): Dann zählt es über 1440 hinaus und gehört zum Folgetag.
    private func minutes(at place: Place, settings: CalculationSettings) -> [Prayer: Int]? {
        guard let raw = rawTimes(at: place, settings: settings) else { return nil }
        var result: [Prayer: Int] = [:]
        for prayer in Prayer.allCases {
            let time = prayer == .asr && settings.asr == .hanafi ? raw.asrHanafi : raw[prayer]
            result[prayer] = time.minutesSinceMidnight + settings.adjustments[prayer]
        }
        if let isha = result[.isha], let maghrib = result[.maghrib], isha < maghrib {
            result[.isha] = isha + Self.minutesPerDay
        }
        return result
    }

    private func dayTimes(on day: CalendarDay, minutes: [Prayer: Int], in zone: TimeZone, madhab: Madhab) -> DayTimes {
        func instant(_ prayer: Prayer) -> Date {
            Self.instant(minutes: minutes[prayer] ?? 0, after: day, in: zone)
        }
        return DayTimes(
            day: day, timeZone: zone,
            fajr: instant(.fajr), sunrise: instant(.sunrise), dhuhr: instant(.dhuhr),
            asr: instant(.asr), maghrib: instant(.maghrib), isha: instant(.isha), madhab: madhab
        )
    }

    /// Wie der Schalter `S.highLat` im Prototyp: Mit `-debugHighLatitude` gelten Fadschr und Ischa als
    /// geschätzt, sonst nie.
    public func usesHighLatitudeRule(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> Bool {
        highLatitude
    }

    /// Die Automatik der Fixture-Stadt (`CITIES[…].auto`) – für Berlin MWL wie in den Referenzbildern
    /// `iphone/70` und `73`, auch wenn die App für Deutschland Diyanet nimmt (docs/OPEN-QUESTIONS.md,
    /// „Automatische Methode je Land“).
    public func automaticMethod(for place: Place) -> CalculationMethod {
        CalculationMethod(rawValue: city(at: place).automaticMethodID) ?? .automatic(forCountryCode: place.countryCode)
    }

    /// Die Fixture-Stadt an den Koordinaten von `place`; für jeden anderen Ort Berlin, das an erster Stelle
    /// der Liste steht (`CITY_IDS`).
    private func city(at place: Place) -> FixtureTimes.City {
        guard !highLatitude else { return FixtureTimes.cities[0] }
        return FixtureTimes.cities.first { $0.coordinates == place.coordinates } ?? FixtureTimes.cities[0]
    }

    /// Die Uhrzeiten vor den Korrekturen – `raw` in `todayTimes()`. „Manuelle Winkel“ wirken wie im
    /// Prototyp nur mit `-debugHighLatitude` (`manualHL()` mit dem Sonnenmodell des Prototyps).
    private func rawTimes(at place: Place, settings: CalculationSettings) -> FixtureTimes.Times? {
        guard highLatitude else {
            return city(at: place).times
        }
        let summer = FixtureTimes.berlinSummer
        let rule = settings.highLatitudeRule
        let fajr: ClockTime, isha: ClockTime
        if rule == .manual {
            let berlin = FixtureTimes.cities[0]
            (fajr, isha) = FixtureSunModel.manual(
                angles: settings.manualAngles, sunrise: summer.sunrise, maghrib: summer.maghrib,
                on: summer.day, at: berlin.coordinates, in: berlin.place(named: berlin.id).timeZone
            )
        } else {
            guard let ruleFajr = summer.fajr[rule], let ruleIsha = summer.isha[rule] else { return nil }
            (fajr, isha) = (ruleFajr, ruleIsha)
        }
        return FixtureTimes.Times(
            fajr: fajr, sunrise: summer.sunrise, dhuhr: summer.dhuhr, asr: summer.asr,
            asrHanafi: summer.asrHanafi, maghrib: summer.maghrib, isha: isha
        )
    }

    private static let minutesPerDay = 24 * 60

    /// Zeitpunkt `minutes` Minuten nach Mitternacht des Tages `day`, gelesen als Uhrzeit: 1508 ist 01:08
    /// am Folgetag, −20 ist 23:40 am Vortag. So stimmt die angezeigte Uhrzeit auch an Tagen mit
    /// Zeitumstellung.
    private static func instant(minutes: Int, after day: CalendarDay, in zone: TimeZone) -> Date {
        let dayOffset = Int((Double(minutes) / Double(minutesPerDay)).rounded(.down))
        return day.adding(days: dayOffset).date(at: ClockTime(minutesSinceMidnight: minutes), in: zone)
    }
}

#endif
