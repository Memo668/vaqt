#if DEBUG

import Foundation

/// Das einfache Sonnenmodell des Prototyps (`sunTimes()`, eine NOAA-Näherung) – nur für die Mock-Zeiten.
///
/// Der Prototyp rechnet damit zweierlei, und `FixtureTimesSource` folgt ihm, damit die Zahlen zu den
/// Referenzbildern passen:
/// - **ein anderer Tag** (`dayTimes()`, Spec § 9.4): die Mock-Zeiten von heute plus die Verschiebung, die
///   das Modell zwischen heute und dem Tag ergibt – Fadschr 18°, Ischa 17°, Sommerzeit eingeschlossen;
/// - **„Manuelle Winkel“** an `BERLIN_SUMMER` (`manualHL()`, Spec § 9.12).
///
/// Die App selbst rechnet mit Adhan Swift (`AdhanTimesSource`); dieses Modell gibt es nur in DEBUG.
/// Formeln, Konstanten und Rundung sind die des Prototyps, auch wo sie ungenau sind.
enum FixtureSunModel {

    /// Minuten seit Mitternacht am Ort für die sechs Ereignisse – `out` in `sunTimes()`. Mit `raw` wie
    /// `sunTimes(…, raw = true)`: Erreicht die Sonne einen Winkel nicht, ist der Wert keine Zahl (`.nan`);
    /// sonst gilt dafür wie im Prototyp ein Siebtel der Nacht.
    static func minutes(
        on day: CalendarDay, at coordinates: Coordinates, in timeZone: TimeZone,
        fajrAngle: Double = 18, ishaAngle: Double = 17, asrFactor: Double = 1, raw: Bool = false
    ) -> [Prayer: Double] {
        let rad = Double.pi / 180
        // `Date.UTC(y, m, d, 12)`; `d` zählt die Tage ab dem 1.1.2000, 12 Uhr UTC.
        let utcNoon = day.date(at: ClockTime(minutesSinceMidnight: 12 * 60), in: .gmt)
        let d = utcNoon.timeIntervalSince1970 / 86_400 - 10_957.5
        let g = (357.529 + 0.98560028 * d) * rad
        let q = jsModulo(280.459 + 0.98564736 * d, 360)
        let l = (q + 1.915 * sin(g) + 0.020 * sin(2 * g)) * rad
        let e = (23.439 - 0.00000036 * d) * rad
        let declination = asin(sin(e) * sin(l))
        let rightAscension = jsModulo(atan2(cos(e) * sin(l), cos(l)) / rad / 15, 24)
        let equationOfTime = jsModulo(q / 15 - rightAscension + 12, 24) - 12
        let noon = 12 - coordinates.longitude / 15 - equationOfTime
        let latitude = coordinates.latitude * rad
        let cc = cos(latitude) * cos(declination)
        let ss = sin(latitude) * sin(declination)
        func hourAngle(_ angle: Double) -> Double {
            acos((-sin(angle * rad) - ss) / cc) / rad / 15
        }
        func asrAngle(_ factor: Double) -> Double {
            acos((sin(atan(1 / (factor + tan(abs(latitude - declination))))) - ss) / cc) / rad / 15
        }
        // `tzOffsetMin()`: der Abstand zu UTC am Mittag des Tages, in ganzen Minuten.
        let offset = Double(timeZone.secondsFromGMT(for: utcNoon) / 60) / 60

        var hours: [Prayer: Double] = [
            .fajr: noon - hourAngle(fajrAngle), .sunrise: noon - hourAngle(0.833), .dhuhr: noon,
            .asr: noon + asrAngle(asrFactor), .maghrib: noon + hourAngle(0.833), .isha: noon + hourAngle(ishaAngle),
        ]
        if !raw, let sunrise = hours[.sunrise], let maghrib = hours[.maghrib] {
            // Helle Sommernächte: ohne 18°/17° vereinfacht ein Siebtel der Nacht.
            let night = sunrise + 24 - maghrib
            if hours[.fajr]?.isFinite != true { hours[.fajr] = sunrise - night / 7 }
            if hours[.isha]?.isFinite != true { hours[.isha] = maghrib + night / 7 }
        }
        return hours.mapValues { ($0 + offset) * 60 }
    }

    /// Die Verschiebung jedes Ereignisses von `today` nach `day` in ganzen Minuten – `dl` in `dayTimes()`.
    /// Ist sie keine Zahl (die Sonne erreicht den Winkel nicht), bleibt die Zeit (0).
    static func shift(
        from today: CalendarDay, to day: CalendarDay, at coordinates: Coordinates, in timeZone: TimeZone,
        asrFactor: Double
    ) -> [Prayer: Int] {
        let from = minutes(on: today, at: coordinates, in: timeZone, asrFactor: asrFactor)
        let to = minutes(on: day, at: coordinates, in: timeZone, asrFactor: asrFactor)
        var result: [Prayer: Int] = [:]
        for prayer in Prayer.allCases {
            let delta = (to[prayer] ?? .nan) - (from[prayer] ?? .nan)
            result[prayer] = delta.isFinite ? jsRound(delta) : 0
        }
        return result
    }

    /// Fadschr und Ischa nach „Manuelle Winkel“ – `manualHL()`.
    ///
    /// Erreicht die Sonne den Winkel, gilt der Abstand zu Sonnenaufgang bzw. -untergang aus dem Modell,
    /// höchstens bis zum Nachtanteil Winkel ÷ 60 der Mock-Nacht; sonst dieser Anteil.
    ///
    /// - Parameters:
    ///   - sunrise, maghrib: die Mock-Zeiten des Tages; die Nacht dauert von Maghrib bis Sonnenaufgang.
    static func manual(
        angles: TwilightAngles, sunrise: ClockTime, maghrib: ClockTime,
        on day: CalendarDay, at coordinates: Coordinates, in timeZone: TimeZone
    ) -> (fajr: ClockTime, isha: ClockTime) {
        let sr = Double(sunrise.minutesSinceMidnight)
        let mg = Double(maghrib.minutesSinceMidnight)
        let night = sr + 1440 - mg
        let model = minutes(
            on: day, at: coordinates, in: timeZone,
            fajrAngle: Double(angles.fajr), ishaAngle: Double(angles.isha), raw: true
        )
        let boundFajr = sr - night * Double(angles.fajr) / 60
        let boundIsha = mg + night * Double(angles.isha) / 60
        let modelFajr = (model[.sunrise] ?? .nan) - (model[.fajr] ?? .nan)
        let modelIsha = (model[.isha] ?? .nan) - (model[.maghrib] ?? .nan)
        let fajr = modelFajr.isFinite ? max(sr - modelFajr, boundFajr) : boundFajr
        let isha = modelIsha.isFinite ? min(mg + modelIsha, boundIsha) : boundIsha
        return (clockTime(fajr), clockTime(isha))
    }

    /// `fmt()`: auf die Minute gerundet, über Mitternacht hinweg.
    private static func clockTime(_ minutes: Double) -> ClockTime {
        ClockTime(minutesSinceMidnight: ((jsRound(minutes) % 1440) + 1440) % 1440)
    }

    /// `Math.round`: halbe Werte nach oben.
    static func jsRound(_ value: Double) -> Int {
        Int((value + 0.5).rounded(.down))
    }

    /// `((x % m) + m) % m` mit dem `%` von JavaScript.
    private static func jsModulo(_ value: Double, _ modulus: Double) -> Double {
        (value.truncatingRemainder(dividingBy: modulus) + modulus).truncatingRemainder(dividingBy: modulus)
    }
}

#endif
