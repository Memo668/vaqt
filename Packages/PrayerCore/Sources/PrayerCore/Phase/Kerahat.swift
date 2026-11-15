import Foundation

/// Ein Kerahat-Fenster: eine Zeitspanne, in der nach hanafitischer und Diyanet-Praxis nicht gebetet wird.
///
/// Das Fenster ist halboffen: Der Beginn gehört dazu, das Ende nicht – wie `m >= w.a && m < w.b` in
/// `activeKerahat()`.
public struct KerahatWindow: Hashable, Sendable, Identifiable {

    /// Die drei Fenster eines Tages. Die Rohwerte sind die Kennungen des Prototyps (`id`).
    ///
    /// `Codable`, weil der Bogen sie als Kennung in `ForEach` nutzt und WidgetKit die Ansichten der Widgets
    /// archiviert – sonst meldet SwiftUI dort „ID type is not Encodable“ (Phase 14).
    public enum Kind: String, CaseIterable, Codable, Sendable {
        /// Nach dem Sonnenaufgang.
        case sunrise
        /// Vor Dhuhr, wenn die Sonne im Zenit steht.
        case zenith
        /// Vor Maghrib.
        case sunset
    }

    public let id: Kind
    /// Beginn (`a`).
    public let start: Date
    /// Ende (`b`); der Zeitpunkt selbst gehört nicht mehr zum Fenster.
    public let end: Date
    /// Die Zeile der Gebetsliste, unter der das Fenster steht (`row`). Das Fenster vor Maghrib steht
    /// bei Asr, weil es am Ende der Asr-Zeit liegt.
    public let row: Prayer

    /// Ob `date` im Fenster liegt.
    public func contains(_ date: Date) -> Bool {
        start <= date && date < end
    }
}

/// Die Kerahat-Fenster eines Tages – `KERAHAT_MIN`, `kerahatWins()` und `activeKerahat()` im Prototyp.
///
/// Nur Anzeige: Es gibt dazu keine Mitteilungen (Spec § 4). Ob die App die Fenster zeigt, entscheidet
/// der Schalter in den Einstellungen; hier wird immer gerechnet.
public enum Kerahat {

    /// Dauer des Fensters nach dem Sonnenaufgang in Minuten (`KERAHAT_MIN.sunrise`).
    public static let minutesAfterSunrise = 45
    /// Dauer des Fensters vor Dhuhr in Minuten (`KERAHAT_MIN.zenith`).
    public static let minutesBeforeDhuhr = 10
    /// Dauer des Fensters vor Maghrib in Minuten (`KERAHAT_MIN.sunset`).
    public static let minutesBeforeMaghrib = 45

    /// Die drei Fenster zu den Zeiten eines Tages, in zeitlicher Reihenfolge. Gerechnet wird mit den
    /// Zeiten samt Minutenkorrektur.
    public static func windows(for times: DayTimes) -> [KerahatWindow] {
        [
            KerahatWindow(
                id: .sunrise,
                start: times.sunrise, end: times.sunrise.addingTimeInterval(seconds(minutesAfterSunrise)),
                row: .sunrise
            ),
            KerahatWindow(
                id: .zenith,
                start: times.dhuhr.addingTimeInterval(-seconds(minutesBeforeDhuhr)), end: times.dhuhr,
                row: .dhuhr
            ),
            KerahatWindow(
                id: .sunset,
                start: times.maghrib.addingTimeInterval(-seconds(minutesBeforeMaghrib)), end: times.maghrib,
                row: .asr
            ),
        ]
    }

    /// Das Fenster, das zum Zeitpunkt `now` läuft; `nil`, wenn keines läuft.
    public static func activeWindow(at now: Date, in times: DayTimes) -> KerahatWindow? {
        windows(for: times).first { $0.contains(now) }
    }

    private static func seconds(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }
}
