#if DEBUG

import Foundation

/// Die Mock-Zeiten des Prototyps als Quelle – für `-debugFixtureTimes`.
///
/// Entspricht `todayTimes()` im Prototyp: Die Zeiten hängen nur von der Stadt, der Asr-Regel, der Regel
/// für hohe Breiten und den Minutenkorrekturen ab. Methode und Datum ändern nichts – jeder Tag zeigt
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
        guard let raw = rawTimes(at: place, rule: settings.highLatitudeRule) else { return nil }
        let zone = place.timeZone

        // Minuten seit Mitternacht samt Korrektur, wie in `todayTimes()`.
        func minutes(_ prayer: Prayer) -> Int {
            let time = prayer == .asr && settings.asr == .hanafi ? raw.asrHanafi : raw[prayer]
            return time.minutesSinceMidnight + settings.adjustments[prayer]
        }
        let maghrib = minutes(.maghrib)
        var isha = minutes(.isha)
        // Ischa darf nach Mitternacht liegen (hohe Breiten, „Nachtmitte“): Dann gehört es zum Folgetag.
        if isha < maghrib {
            isha += Self.minutesPerDay
        }

        func instant(_ minutes: Int) -> Date {
            Self.instant(minutes: minutes, after: day, in: zone)
        }
        return DayTimes(
            day: day, timeZone: zone,
            fajr: instant(minutes(.fajr)), sunrise: instant(minutes(.sunrise)), dhuhr: instant(minutes(.dhuhr)),
            asr: instant(minutes(.asr)), maghrib: instant(maghrib), isha: instant(isha)
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

    /// Die Uhrzeiten vor den Korrekturen – `d` in `todayTimes()`.
    private func rawTimes(at place: Place, rule: HighLatitudeRule) -> FixtureTimes.Times? {
        guard highLatitude else {
            return city(at: place).times
        }
        let summer = FixtureTimes.berlinSummer
        guard let fajr = summer.fajr[rule], let isha = summer.isha[rule] else { return nil }
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
