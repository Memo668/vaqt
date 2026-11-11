import Foundation
import PrayerCore
@testable import Features

// Schreibhilfen und Attrappen für die Tests der Zeiten-Seite.

/// Eine Uhr, die der Test stellt.
final class TestClock: AppClock, @unchecked Sendable {
    private let lock = NSLock()
    private var instant: Date

    init(_ instant: Date) {
        self.instant = instant
    }

    var now: Date {
        get { lock.withLock { instant } }
        set { lock.withLock { instant = newValue } }
    }
}

/// Eine Standortquelle, deren Antworten der Test vorgibt: Stand der Freigabe vor und nach der Abfrage
/// und die Orte, die sie der Reihe nach liefert.
actor ScriptedLocationSource: LocationSource {
    private var status: LocationAuthorization
    private let statusAfterRequest: LocationAuthorization
    private var places: [Place?]
    private(set) var requests = 0
    private(set) var lookups = 0

    /// - Parameter places: die Orte für aufeinanderfolgende Aufrufe von `currentPlace()`; der letzte gilt
    ///   für alle weiteren.
    init(status: LocationAuthorization, afterRequest: LocationAuthorization? = nil, places: [Place?] = []) {
        self.status = status
        statusAfterRequest = afterRequest ?? status
        self.places = places
    }

    func authorization() async -> LocationAuthorization { status }

    func requestAuthorization() async -> LocationAuthorization {
        requests += 1
        status = statusAfterRequest
        return status
    }

    func currentPlace() async -> Place? {
        guard status == .authorized else { return nil }
        lookups += 1
        return places.count > 1 ? places.removeFirst() : places.first ?? nil
    }
}

/// Eine Quelle ohne Zeiten – wie dort, wo die Sonne nicht auf- oder untergeht.
struct NoTimesSource: PrayerTimesSource {
    func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? { nil }
}

/// Meldet das Netz in der vorgegebenen Folge und endet dann.
struct ScriptedConnectivity: ConnectivitySource {
    let states: [Bool]

    func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            for state in states {
                continuation.yield(state)
            }
            continuation.finish()
        }
    }
}

/// `day("2026-11-10")`
func day(_ text: String) -> CalendarDay {
    guard let day = CalendarDay(text) else { preconditionFailure("Ungültiges Datum im Test: \(text)") }
    return day
}

/// Zeitpunkt „HH:mm“ an einem Tag in einer Zeitzone, z. B. `instant("2026-11-10", "14:25", in: "Europe/Berlin")`.
func instant(_ date: String, _ time: String, in zone: String = "Europe/Berlin") -> Date {
    guard let clock = ClockTime(time), let timeZone = TimeZone(identifier: zone) else {
        preconditionFailure("Ungültige Uhrzeit oder Zeitzone im Test: \(time), \(zone)")
    }
    return day(date).date(at: clock, in: timeZone)
}

extension Place {

    static let berlin = Place(
        name: "Berlin", countryCode: "DE",
        coordinates: Coordinates(latitude: 52.5200, longitude: 13.4050), timeZoneIdentifier: "Europe/Berlin"
    )

    static let istanbul = Place(
        name: "Istanbul", countryCode: "TR",
        coordinates: Coordinates(latitude: 41.0082, longitude: 28.9784), timeZoneIdentifier: "Europe/Istanbul"
    )

    static let munich = Place(
        name: "München", countryCode: "DE",
        coordinates: Coordinates(latitude: 48.1351, longitude: 11.5820), timeZoneIdentifier: "Europe/Berlin"
    )

    /// Ein Standort ohne Namen, wie ihn die Standortquelle ohne Netz liefert.
    static func unnamed(latitude: Double, longitude: Double, zone: String = "Europe/Berlin") -> Place {
        Place(
            name: "", countryCode: nil,
            coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
        )
    }
}
