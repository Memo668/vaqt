#if DEBUG

import Foundation
import PrayerCore

/// Die Zustände der Referenzbilder als Tagesphasen, gerechnet aus den Mock-Zeiten des Prototyps.
///
/// Nur DEBUG: für den Katalog, die Previews und die Tests.
public enum CatalogFixtures {

    /// Ein Zustand des Bogens aus der Abnahme von Phase 2 (docs/BUILD-PLAN.md).
    public struct ArcState: Identifiable, Hashable, Sendable {
        /// Kurzname, z. B. „14:25“ oder „vor Fadschr“ – die Namen aus dem Bauplan.
        public let id: String
        /// Fixture-Stadt, z. B. „berlin“.
        public let city: String
        /// Uhrzeit am Ort, „HH:mm“ oder „HH:mm:ss“.
        public let time: String
        /// Referenzbild unter design/screenshots, ohne Endung.
        public let reference: String
        public let isDark: Bool
        public let isRightToLeft: Bool

        public var phase: DayPhase {
            CatalogFixtures.phase(city: city, time: time)
        }
    }

    /// Die acht Zustände der Abnahme. Die Sekunden sind so gewählt, dass der Countdown dieselbe Zahl
    /// zeigt wie das Referenzbild.
    public static let arcStates: [ArcState] = [
        ArcState(id: "14:25", city: "berlin", time: "14:25:01", reference: "iphone/10-home-asr-active", isDark: false, isRightToLeft: false),
        ArcState(id: "vor Fadschr", city: "berlin", time: "05:14:46", reference: "iphone/12-home-before-fajr", isDark: false, isRightToLeft: false),
        ArcState(id: "08:04", city: "berlin", time: "08:04:01", reference: "iphone/13-home-after-sunrise", isDark: false, isRightToLeft: false),
        ArcState(id: "07:30", city: "berlin", time: "07:30:01", reference: "iphone/14-home-kerahat-active", isDark: false, isRightToLeft: false),
        ArcState(id: "16:05", city: "berlin", time: "16:05:01", reference: "iphone/15-home-kerahat-before-maghrib", isDark: false, isRightToLeft: false),
        ArcState(id: "nach Ischa", city: "berlin", time: "23:30:01", reference: "iphone/16-home-after-isha-dark", isDark: true, isRightToLeft: false),
        ArcState(id: "Jakarta", city: "jakarta", time: "17:57:01", reference: "iphone/22-home-jakarta-close-markers", isDark: false, isRightToLeft: false),
        ArcState(id: "RTL", city: "berlin", time: "14:25:02", reference: "iphone/20-home-rtl", isDark: false, isRightToLeft: true),
    ]

    /// Die Tagesphase einer Fixture-Stadt am 10.11.2026 zur Uhrzeit `time` („HH:mm“ oder „HH:mm:ss“).
    public static func phase(city: String = "berlin", time: String = "14:25") -> DayPhase {
        guard let fixture = FixtureTimes.city(city) else {
            preconditionFailure("Unbekannte Fixture-Stadt: \(city)")
        }
        let parts = time.split(separator: ":").map(String.init)
        guard (2...3).contains(parts.count), let clock = ClockTime(parts[0] + ":" + parts[1]),
              let seconds = parts.count == 3 ? Int(parts[2]) : 0, (0...59).contains(seconds)
        else {
            preconditionFailure("Ungültige Uhrzeit: \(time)")
        }
        let place = fixture.place(named: city)
        let day = FixtureTimes.referenceDay
        let now = day.date(at: clock, in: place.timeZone).addingTimeInterval(TimeInterval(seconds))
        let timeline = FixtureTimesSource().timeline(around: day, at: place, settings: CalculationSettings())
        guard let phase = timeline?.phase(at: now) else {
            preconditionFailure("Die Fixture liefert für jeden Zeitpunkt des Tages eine Phase")
        }
        return phase
    }

    /// Der Countdown als fester Text wie `cdDigital()`: „2:01:59“, unter einer Stunde „1:14“.
    ///
    /// Der laufende Countdown ist ein Baustein der Zeiten-Seite (Phase 3); der Katalog zeigt hier nur
    /// Schrift und Lage.
    public static func countdownText(_ remaining: TimeInterval) -> String {
        let total = max(0, Int(remaining.rounded(.down)))
        let hours = total / 3600, minutes = total % 3600 / 60, seconds = total % 60
        func pad(_ value: Int) -> String { (value < 10 ? "0" : "") + String(value) }
        return hours > 0 ? "\(hours):\(pad(minutes)):\(pad(seconds))" : "\(minutes):\(pad(seconds))"
    }
}

#endif
