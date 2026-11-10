#if DEBUG

/// Mock-Zeiten aus dem Prototyp (`CITIES`, `BERLIN_SUMMER`).
///
/// Nur Test-Fixture: Mit `-debugFixtureTimes` zeigt die App dieselben Zahlen wie die
/// Referenz-Screenshots. Die App selbst rechnet echt; in Release-Builds gibt es diese Daten nicht.
public enum FixtureTimes {

    /// Zeiten eines Tages. `asr` ist die Standardrechnung, `asrHanafi` die hanafitische.
    public struct Times: Hashable, Sendable {
        public let fajr: ClockTime
        public let sunrise: ClockTime
        public let dhuhr: ClockTime
        public let asr: ClockTime
        public let asrHanafi: ClockTime
        public let maghrib: ClockTime
        public let isha: ClockTime

        /// Zeit eines Ereignisses; für Asr die Standardrechnung.
        public subscript(prayer: Prayer) -> ClockTime {
            switch prayer {
            case .fajr: fajr
            case .sunrise: sunrise
            case .dhuhr: dhuhr
            case .asr: asr
            case .maghrib: maghrib
            case .isha: isha
            }
        }
    }

    /// Eine Stadt aus `CITIES`.
    public struct City: Identifiable, Hashable, Sendable {
        /// Kennung wie im Prototyp und in `-debugCity`, z. B. „berlin“. Der Anzeigename steht im
        /// String Catalog unter `c_<id>`.
        public let id: String
        public let countryCode: String
        /// Stadtmitte. Steht nicht im Prototyp – siehe docs/OPEN-QUESTIONS.md.
        public let coordinates: Coordinates
        /// Steht nicht im Prototyp – siehe docs/OPEN-QUESTIONS.md.
        public let timeZoneIdentifier: String
        /// Richtung zur Kaaba in Grad; `nil` in Mekka.
        public let qiblaDegrees: Int?
        /// Entfernung zur Kaaba in Kilometern.
        public let distanceKm: Int
        /// Kennung der automatischen Methode aus `METHODS`, z. B. „mwl“.
        public let automaticMethodID: String
        public let times: Times

        /// Die Stadt als `Place` mit dem übergebenen Anzeigenamen.
        public func place(named name: String) -> Place {
            Place(name: name, countryCode: countryCode, coordinates: coordinates, timeZoneIdentifier: timeZoneIdentifier)
        }
    }

    /// Der Fall hoher Breiten: Berlin am 21. Juni. Fadschr und Ischa hängen von der Regel ab.
    public struct HighLatitudeDay: Sendable {
        public let day: CalendarDay
        public let fajr: [HighLatitudeRule: ClockTime]
        public let sunrise: ClockTime
        public let dhuhr: ClockTime
        public let asr: ClockTime
        public let asrHanafi: ClockTime
        public let maghrib: ClockTime
        /// Bei der Regel „Nachtmitte“ liegt Ischa nach Mitternacht, also am Folgetag.
        public let isha: [HighLatitudeRule: ClockTime]
    }

    /// Tag, für den die Zeiten der Städte gelten: Dienstag, 10. November 2026
    /// (design/screenshots/INDEX.md).
    public static let referenceDay = day(2026, 11, 10)

    /// Uhrzeit der meisten Referenz-Screenshots: 14:25, Asr aktiv (design/screenshots/INDEX.md).
    public static let referenceTime = time("14:25")

    /// Die fünf Städte in der Reihenfolge von `CITY_IDS`.
    public static let cities: [City] = [
        City(
            id: "berlin", countryCode: "DE",
            coordinates: Coordinates(latitude: 52.5200, longitude: 13.4050), timeZoneIdentifier: "Europe/Berlin",
            qiblaDegrees: 137, distanceKm: 4130, automaticMethodID: "mwl",
            times: times("05:16", "07:14", "11:52", "14:00", "14:36", "16:27", "18:17")
        ),
        City(
            id: "istanbul", countryCode: "TR",
            coordinates: Coordinates(latitude: 41.0082, longitude: 28.9784), timeZoneIdentifier: "Europe/Istanbul",
            qiblaDegrees: 152, distanceKm: 2410, automaticMethodID: "diyanet",
            times: times("06:09", "07:36", "12:53", "15:36", "16:13", "18:00", "19:23")
        ),
        City(
            id: "madrid", countryCode: "ES",
            coordinates: Coordinates(latitude: 40.4168, longitude: -3.7038), timeZoneIdentifier: "Europe/Madrid",
            qiblaDegrees: 104, distanceKm: 4600, automaticMethodID: "mwl",
            times: times("06:18", "07:51", "13:00", "15:43", "16:25", "18:06", "19:33")
        ),
        City(
            id: "mecca", countryCode: "SA",
            coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262), timeZoneIdentifier: "Asia/Riyadh",
            qiblaDegrees: nil, distanceKm: 0, automaticMethodID: "ummalqura",
            times: times("05:08", "06:27", "12:05", "15:17", "16:05", "17:41", "19:11")
        ),
        City(
            id: "jakarta", countryCode: "ID",
            coordinates: Coordinates(latitude: -6.2088, longitude: 106.8456), timeZoneIdentifier: "Asia/Jakarta",
            qiblaDegrees: 295, distanceKm: 7920, automaticMethodID: "kemenag",
            times: times("04:06", "05:24", "11:39", "14:57", "16:02", "17:49", "19:01")
        ),
    ]

    /// Die Stadt mit der Kennung `id`, z. B. „berlin“.
    public static func city(_ id: String) -> City? {
        cities.first { $0.id == id }
    }

    /// `BERLIN_SUMMER`: Berlin, 21. Juni 2027. Die Nacht dauert von 21:33 bis 04:43 (430 Minuten).
    public static let berlinSummer = HighLatitudeDay(
        day: day(2027, 6, 21),
        fajr: [.angle: time("02:34"), .seventh: time("03:42"), .middle: time("01:08")],
        sunrise: time("04:43"),
        dhuhr: time("13:12"),
        asr: time("17:33"),
        asrHanafi: time("18:48"),
        maghrib: time("21:33"),
        isha: [.angle: time("23:35"), .seventh: time("22:34"), .middle: time("01:08")]
    )

    // MARK: - Schreibhilfen für die Tabellen oben

    private static func time(_ text: String) -> ClockTime {
        guard let time = ClockTime(text) else { preconditionFailure("Ungültige Uhrzeit in den Fixture-Daten: \(text)") }
        return time
    }

    private static func day(_ year: Int, _ month: Int, _ day: Int) -> CalendarDay {
        guard let value = CalendarDay(year: year, month: month, day: day) else {
            preconditionFailure("Ungültiges Datum in den Fixture-Daten: \(year)-\(month)-\(day)")
        }
        return value
    }

    private static func times(
        _ fajr: String, _ sunrise: String, _ dhuhr: String, _ asr: String,
        _ asrHanafi: String, _ maghrib: String, _ isha: String
    ) -> Times {
        Times(
            fajr: time(fajr), sunrise: time(sunrise), dhuhr: time(dhuhr), asr: time(asr),
            asrHanafi: time(asrHanafi), maghrib: time(maghrib), isha: time(isha)
        )
    }
}

#endif
