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
        guard settings.highLatitudeRule == .manual else {
            return adhanTimes(on: day, at: place, settings: settings)
        }
        return manualTimes(on: day, at: place, settings: settings)
    }

    /// Die Zeiten aus Adhan Swift; mit `angles` statt der Winkel der Methode.
    private func adhanTimes(
        on day: CalendarDay, at place: Place, settings: CalculationSettings, angles: TwilightAngles? = nil
    ) -> DayTimes? {
        let coordinates = Adhan.Coordinates(latitude: place.coordinates.latitude, longitude: place.coordinates.longitude)
        let date = DateComponents(year: day.year, month: day.month, day: day.day)
        var parameters = Self.parameters(for: settings.effectiveMethod(for: place), settings: settings)
        if let angles {
            parameters.fajrAngle = Double(angles.fajr)
            parameters.ishaAngle = Double(angles.isha)
            // Ischa aus dem Winkel, nicht aus einem festen Abstand zu Maghrib (Umm al-Qura: 90 Minuten).
            parameters.ishaInterval = 0
        }
        guard let times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: parameters) else {
            return nil
        }
        return DayTimes(
            day: day, timeZone: place.timeZone,
            fajr: times.fajr, sunrise: times.sunrise, dhuhr: times.dhuhr,
            asr: times.asr, maghrib: times.maghrib, isha: times.isha
        )
    }

    /// Die Regel „Manuelle Winkel“ (Spec § 9.12; entschieden am 15.11.2026: „Nur in hellen Nächten“).
    ///
    /// Die Methode rechnet wie bei „Winkelbasiert“. Nur wenn diese Regel Fadschr oder Ischa des Tages
    /// bestimmt – die Sonne erreicht den Winkel der Methode nicht, oder erst nach der Grenze der Regel –,
    /// gilt für diese Zeit der eigene Winkel, wieder mit dem Nachtanteil Winkel ÷ 60 als sichere Grenze
    /// (`.twilightAngle`). Ob die Regel greift, zeigt der Vergleich mit „Nachtmitte“, der weitesten
    /// Grenze, wie in `usesHighLatitudeRule`. Im Winter ändert sich deshalb nichts. Moonsighting rechnet mit
    /// eigenen Grenzen und übergeht auch diese Regel.
    private func manualTimes(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? {
        var byMethod = settings
        byMethod.highLatitudeRule = .angle
        guard let base = adhanTimes(on: day, at: place, settings: byMethod) else { return nil }
        guard settings.effectiveMethod(for: place) != .moonsighting else { return base }

        var widest = byMethod
        widest.highLatitudeRule = .middle
        guard let reference = adhanTimes(on: day, at: place, settings: widest),
              let manual = adhanTimes(on: day, at: place, settings: byMethod, angles: settings.manualAngles)
        else { return base }
        return DayTimes(
            day: day, timeZone: place.timeZone,
            fajr: base.fajr != reference.fajr ? manual.fajr : base.fajr,
            sunrise: base.sunrise, dhuhr: base.dhuhr, asr: base.asr, maghrib: base.maghrib,
            isha: base.isha != reference.isha ? manual.isha : base.isha
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
    /// sie geschätzt sind. Bei „Manuelle Winkel“ gilt die Probe für „Winkelbasiert“ – dann gelten die
    /// eigenen Winkel. Moonsighting rechnet mit eigenen jahreszeitlichen Grenzen und übergeht die
    /// Regel (docs/OPEN-QUESTIONS.md).
    public func usesHighLatitudeRule(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> Bool {
        guard settings.effectiveMethod(for: place) != .moonsighting else { return false }
        var chosen = settings
        chosen.adjustments = MinuteAdjustments()
        // „Manuelle Winkel“ gelten genau dann, wenn „Winkelbasiert“ greift (`manualTimes`).
        if chosen.highLatitudeRule == .manual {
            chosen.highLatitudeRule = .angle
        }
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
        case .angle, .manual: .twilightAngle
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
