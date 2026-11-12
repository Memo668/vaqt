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

/// Eine Kursquelle, die eine vorgegebene Folge von Kursen liefert und dann endet.
struct ScriptedHeadingSource: HeadingSource {
    let headings: [Heading]

    func isAvailable() async -> Bool { true }

    func updates() async -> AsyncStream<Heading> {
        AsyncStream { continuation in
            for heading in headings {
                continuation.yield(heading)
            }
            continuation.finish()
        }
    }
}

/// Eine Kursquelle wie ein echter Kompass: Sie liefert, was der Test ihr gibt, bis der Zuhörer aufhört.
actor LiveHeadingSource: HeadingSource {
    private var continuation: AsyncStream<Heading>.Continuation?
    /// Wie oft jemand zugehört und wie oft jemand aufgehört hat.
    private(set) var starts = 0
    private(set) var stops = 0

    func isAvailable() async -> Bool { true }

    func updates() async -> AsyncStream<Heading> {
        let (stream, continuation) = AsyncStream.makeStream(of: Heading.self)
        self.continuation = continuation
        starts += 1
        continuation.onTermination = { [weak self] _ in
            Task { await self?.stopped() }
        }
        return stream
    }

    func send(_ heading: Heading) {
        continuation?.yield(heading)
    }

    private func stopped() {
        stops += 1
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

    /// Die Fixture-Stadt Mekka: Sie liegt an der Kaaba.
    static let mecca = Place(
        name: "Mekka", countryCode: "SA",
        coordinates: Coordinates(latitude: 21.4225, longitude: 39.8262), timeZoneIdentifier: "Asia/Riyadh"
    )

    /// Ein Standort ohne Namen, wie ihn die Standortquelle ohne Netz liefert.
    static func unnamed(latitude: Double, longitude: Double, zone: String = "Europe/Berlin") -> Place {
        Place(
            name: "", countryCode: nil,
            coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
        )
    }
}

/// Merkt sich, was vorgemerkt werden sollte, statt es iOS zu geben.
@MainActor
final class RecordingNotificationScheduler: NotificationScheduling {
    /// Je Aufruf die Mitteilungen und das „jetzt“ der App-Uhr.
    private(set) var calls: [[PrayerNotification]] = []
    private(set) var nows: [Date] = []

    func replacePending(with notifications: [PrayerNotification], now: Date) {
        calls.append(notifications)
        nows.append(now)
    }
}

/// Eine Erlaubnis für Mitteilungen, deren Antworten der Test vorgibt: Stand vor und nach dem Fragen.
actor ScriptedNotificationAuthorizer: NotificationAuthorizing {
    private var status: NotificationAuthorization
    private let answer: NotificationAuthorization
    private(set) var requests = 0

    init(status: NotificationAuthorization, answer: NotificationAuthorization = .authorized) {
        self.status = status
        self.answer = answer
    }

    func authorization() async -> NotificationAuthorization { status }

    func requestAuthorization() async -> NotificationAuthorization {
        requests += 1
        if status == .notDetermined {
            status = answer
        }
        return status
    }
}
