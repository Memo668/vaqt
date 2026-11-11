import Adhan
import Foundation

// In dieser Datei treffen gleichnamige Typen aufeinander. Ohne Zusatz sind die eigenen gemeint
// (`CalculationMethod`, `Coordinates`, `HighLatitudeRule`), die von Adhan Swift tragen `Adhan.` davor.

/// Die echte Berechnung der Gebetszeiten mit Adhan Swift.
///
/// Gerechnet wird auf dem Gerät, ohne Netz. Für neun der elf Methoden gelten die Voreinstellungen von
/// Adhan Swift samt den Minuten, die die jeweilige Stelle auf ihre Zeiten aufschlägt (z. B. Diyanet:
/// Sonnenaufgang −7, Dhuhr +5, Asr +4, Maghrib +7). JAKIM und Kemenag haben dort keine Voreinstellung
/// und rechnen mit den reinen Winkeln aus `METHODS`. Vor der Veröffentlichung sind beide gegen
/// offizielle Tabellen zu prüfen (docs/OPEN-QUESTIONS.md).
public struct AdhanTimesSource: PrayerTimesSource {

    public init() {}

    public func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? {
        let coordinates = Adhan.Coordinates(latitude: place.coordinates.latitude, longitude: place.coordinates.longitude)
        let date = DateComponents(year: day.year, month: day.month, day: day.day)
        let parameters = Self.parameters(for: settings.effectiveMethod(for: place), settings: settings)
        guard let times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: parameters) else {
            return nil
        }
        return DayTimes(
            day: day, timeZone: place.timeZone,
            fajr: times.fajr, sunrise: times.sunrise, dhuhr: times.dhuhr,
            asr: times.asr, maghrib: times.maghrib, isha: times.isha
        )
    }

    /// Ob die Regel für hohe Breiten an dem Tag Fadschr oder Ischa bestimmt.
    ///
    /// Adhan Swift sagt das nicht selbst. Es rechnet beide Zeiten zuerst aus dem Dämmerungswinkel und
    /// begrenzt sie dann mit der Regel: Fadschr liegt nie früher, Ischa nie später als die Grenze der
    /// Regel. Erreicht die Sonne den Winkel gar nicht, gilt die Grenze selbst. Daraus folgt die Probe:
    ///
    /// - „Nachtmitte“ ist die weiteste der drei Grenzen. Ändert sich Fadschr oder Ischa, wenn man statt
    ///   der gewählten Regel mit ihr rechnet, hat die gewählte Regel gegriffen.
    /// - Ist „Nachtmitte“ selbst gewählt, greift sie genau dann, wenn Ischa und das Fadschr des Folgetags
    ///   an der Nachtmitte zusammenfallen.
    ///
    /// Die Minutenkorrekturen bleiben außen vor: Sie verschieben die Zeiten, ändern aber nichts daran, ob
    /// sie geschätzt sind. Moonsighting rechnet mit eigenen jahreszeitlichen Grenzen und übergeht die
    /// Regel (docs/OPEN-QUESTIONS.md).
    public func usesHighLatitudeRule(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> Bool {
        guard settings.effectiveMethod(for: place) != .moonsighting else { return false }
        var chosen = settings
        chosen.adjustments = MinuteAdjustments()
        guard let today = times(on: day, at: place, settings: chosen) else { return false }

        if chosen.highLatitudeRule == .middle {
            guard let tomorrow = times(on: day.adding(days: 1), at: place, settings: chosen) else { return false }
            return abs(tomorrow.fajr.timeIntervalSince(today.isha)) <= Self.middleOfNightTolerance
        }
        var widest = chosen
        widest.highLatitudeRule = .middle
        guard let reference = times(on: day, at: place, settings: widest) else { return false }
        return today.fajr != reference.fajr || today.isha != reference.isha
    }

    /// So nah liegen Ischa und das Fadschr des Folgetags beieinander, wenn beide auf die Nachtmitte
    /// fallen: Die Nächte zweier Tage sind nicht gleich lang, und jede Zeit ist auf die Minute gerundet.
    private static let middleOfNightTolerance: TimeInterval = 180

    /// Die Parameter von Adhan Swift zu einer Methode und den Einstellungen.
    static func parameters(for method: CalculationMethod, settings: CalculationSettings) -> CalculationParameters {
        var parameters = preset(for: method)
        parameters.madhab = settings.asr == .hanafi ? .hanafi : .shafi
        parameters.highLatitudeRule = switch settings.highLatitudeRule {
        case .angle: .twilightAngle
        case .seventh: .seventhOfTheNight
        case .middle: .middleOfTheNight
        }
        let adjustments = settings.adjustments
        parameters.adjustments = PrayerAdjustments(
            fajr: adjustments[.fajr], sunrise: adjustments[.sunrise], dhuhr: adjustments[.dhuhr],
            asr: adjustments[.asr], maghrib: adjustments[.maghrib], isha: adjustments[.isha]
        )
        return parameters
    }

    /// Die Voreinstellung von Adhan Swift zu einer Methode; für JAKIM und Kemenag die Winkel aus `METHODS`.
    private static func preset(for method: CalculationMethod) -> CalculationParameters {
        switch method {
        case .mwl:
            return Adhan.CalculationMethod.muslimWorldLeague.params
        case .isna:
            return Adhan.CalculationMethod.northAmerica.params
        case .egyptian:
            return Adhan.CalculationMethod.egyptian.params
        case .ummAlQura:
            return Adhan.CalculationMethod.ummAlQura.params
        case .karachi:
            return Adhan.CalculationMethod.karachi.params
        case .diyanet:
            return Adhan.CalculationMethod.turkey.params
        case .singapore:
            return Adhan.CalculationMethod.singapore.params
        case .tehran:
            return Adhan.CalculationMethod.tehran.params
        case .moonsighting:
            return Adhan.CalculationMethod.moonsightingCommittee.params
        case .jakim, .kemenag:
            // Reine Winkel, ohne Sicherheitsminuten. Die Initialisierer von `CalculationParameters`
            // sind nicht öffentlich, deshalb der Weg über `.other`.
            var parameters = Adhan.CalculationMethod.other.params
            parameters.fajrAngle = method.fajrAngle
            if case .angle(let ishaAngle) = method.isha {
                parameters.ishaAngle = ishaAngle
            }
            return parameters
        }
    }
}
