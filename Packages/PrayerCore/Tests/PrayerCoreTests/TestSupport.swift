import Foundation
@testable import PrayerCore

// Schreibhilfen für die Tests. Ein Tippfehler in einem Testwert bricht den Test sofort ab.

/// `calendarDay("2026-11-10")`
func calendarDay(_ text: String) -> CalendarDay {
    guard let day = CalendarDay(text) else { preconditionFailure("Ungültiges Datum im Test: \(text)") }
    return day
}

/// `clockTime("14:25")`
func clockTime(_ text: String) -> ClockTime {
    guard let time = ClockTime(text) else { preconditionFailure("Ungültige Uhrzeit im Test: \(text)") }
    return time
}

/// Minuten als Sekunden, z. B. `minutes(72)` für eine Spanne.
func minutes(_ count: Double) -> TimeInterval {
    count * 60
}

extension CalendarDay {

    /// Zeitpunkt „HH:mm“ oder „HH:mm:ss“ an diesem Tag in `zone`.
    func at(_ text: String, in zone: TimeZone) -> Date {
        let parts = text.split(separator: ":").map(String.init)
        guard (2...3).contains(parts.count), let time = ClockTime(parts[0] + ":" + parts[1]),
              let seconds = parts.count == 3 ? Int(parts[2]) : 0, (0...59).contains(seconds)
        else { preconditionFailure("Ungültige Uhrzeit im Test: \(text)") }
        return date(at: time, in: zone).addingTimeInterval(TimeInterval(seconds))
    }
}

extension TimeZone {
    static let berlin = zone("Europe/Berlin")
    static let istanbul = zone("Europe/Istanbul")
    static let jakarta = zone("Asia/Jakarta")
    static let riyadh = zone("Asia/Riyadh")

    private static func zone(_ identifier: String) -> TimeZone {
        guard let zone = TimeZone(identifier: identifier) else { preconditionFailure("Unbekannte Zeitzone im Test: \(identifier)") }
        return zone
    }
}

extension Place {
    /// Berlin mit den Koordinaten der Fixture (docs/OPEN-QUESTIONS.md).
    static let berlin = Place(
        name: "Berlin", countryCode: "DE",
        coordinates: Coordinates(latitude: 52.5200, longitude: 13.4050), timeZoneIdentifier: "Europe/Berlin"
    )
}

#if DEBUG

/// Der Ort einer Fixture-Stadt, z. B. `fixturePlace("jakarta")`.
func fixturePlace(_ id: String) -> Place {
    guard let city = FixtureTimes.city(id) else { preconditionFailure("Unbekannte Fixture-Stadt im Test: \(id)") }
    return city.place(named: id)
}

/// Der Zeitstrahl aus den Mock-Zeiten des Prototyps um den Tag `day`.
func fixtureTimeline(
    city: String = "berlin", on day: CalendarDay = FixtureTimes.referenceDay,
    settings: CalculationSettings = CalculationSettings(), highLatitude: Bool = false
) -> PrayerTimeline {
    let source = FixtureTimesSource(highLatitude: highLatitude)
    guard let timeline = source.timeline(around: day, at: fixturePlace(city), settings: settings) else {
        preconditionFailure("Die Fixture liefert für jeden Tag Zeiten")
    }
    return timeline
}

#endif

/// Feste Uhrzeiten an jedem Tag oder die einer anderen Quelle – an den Tagen in `missing` keine.
struct StubTimesSource: PrayerTimesSource {
    var base: (any PrayerTimesSource)?
    var times: [String] = []
    var missing: Set<CalendarDay> = []
    var missingAll = false

    init(times: [String]) {
        self.times = times
    }

    init(base: any PrayerTimesSource, missing: Set<CalendarDay> = [], missingAll: Bool = false) {
        self.base = base
        self.missing = missing
        self.missingAll = missingAll
    }

    func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? {
        guard !missingAll, !missing.contains(day) else { return nil }
        if let base {
            return base.times(on: day, at: place, settings: settings)
        }
        let dates = times.map { day.at($0, in: place.timeZone) }
        return DayTimes(
            day: day, timeZone: place.timeZone,
            fajr: dates[0], sunrise: dates[1], dhuhr: dates[2], asr: dates[3], maghrib: dates[4], isha: dates[5]
        )
    }
}
