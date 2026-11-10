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
