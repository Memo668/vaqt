import Foundation

/// Ein Kerahat-Fenster: eine Zeitspanne, in der nicht gebetet wird – je nach Rechtsschule nur keine
/// freiwilligen Gebete (Spec § 11.6).
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

/// Die Kerahat-Fenster eines Tages – `KERAHAT_MIN_BY`, `kerahatWins()` und `activeKerahat()` im Prototyp.
///
/// Seit dem Nachtrag zu Phase 18 hängen sie von der Rechtsschule ab, mit der die Zeiten gerechnet sind
/// (`DayTimes.madhab`, Spec § 11.6): Hanafi und Hanbali haben drei Fenster, Maliki keines vor Dhuhr, Schafii
/// freitags keines vor Dhuhr. Die Dauer kommt je Schule aus `durations(for:)`.
///
/// Nur Anzeige: Es gibt dazu keine Mitteilungen (Spec § 4). Ob die App die Fenster zeigt, entscheidet
/// der Schalter in den Einstellungen; hier wird immer gerechnet.
public enum Kerahat {

    /// Dauer der Fenster einer Rechtsschule in Minuten (`KERAHAT_MIN_BY`).
    public struct Durations: Hashable, Sendable {
        /// Nach dem Sonnenaufgang.
        public let afterSunrise: Int
        /// Vor Dhuhr; `nil`, wenn die Schule dort kein Fenster kennt (Maliki).
        public let beforeDhuhr: Int?
        /// Vor Maghrib.
        public let beforeMaghrib: Int
    }

    /// Die Dauer je Schule, entschieden am 24.11.2026 (Recherche in `docs/OPEN-QUESTIONS.md`): Hanafi nach
    /// Diyanet 45 / 10 / 45, Schafii 25 / 10 / 25 (JAKIM), Hanbali 20 / 10 / 20, Maliki 20 / – / 20.
    public static func durations(for madhab: Madhab) -> Durations {
        switch madhab {
        case .hanafi: Durations(afterSunrise: 45, beforeDhuhr: 10, beforeMaghrib: 45)
        case .shafii: Durations(afterSunrise: 25, beforeDhuhr: 10, beforeMaghrib: 25)
        case .hanbali: Durations(afterSunrise: 20, beforeDhuhr: 10, beforeMaghrib: 20)
        case .maliki: Durations(afterSunrise: 20, beforeDhuhr: nil, beforeMaghrib: 20)
        }
    }

    /// Dauer des Fensters nach dem Sonnenaufgang in Minuten, hanafitisch (`KERAHAT_MIN.sunrise`).
    public static let minutesAfterSunrise = 45
    /// Dauer des Fensters vor Dhuhr in Minuten, hanafitisch (`KERAHAT_MIN.zenith`).
    public static let minutesBeforeDhuhr = 10
    /// Dauer des Fensters vor Maghrib in Minuten, hanafitisch (`KERAHAT_MIN.sunset`).
    public static let minutesBeforeMaghrib = 45

    /// Ob die Schule an diesem Tag ein Fenster vor Dhuhr kennt: nicht bei Maliki, bei Schafii nicht am Freitag.
    public static func hasZenithWindow(_ madhab: Madhab, onFriday isFriday: Bool) -> Bool {
        switch madhab {
        case .hanafi, .hanbali: true
        case .maliki: false
        case .shafii: !isFriday
        }
    }

    /// Die Fenster zu den Zeiten eines Tages, in zeitlicher Reihenfolge, nach der Rechtsschule der Zeiten.
    /// Gerechnet wird mit den Zeiten samt Minutenkorrektur.
    public static func windows(for times: DayTimes) -> [KerahatWindow] {
        let minutes = durations(for: times.madhab)
        var windows = [
            KerahatWindow(
                id: .sunrise,
                start: times.sunrise, end: times.sunrise.addingTimeInterval(seconds(minutes.afterSunrise)),
                row: .sunrise
            ),
        ]
        if let zenith = minutes.beforeDhuhr, hasZenithWindow(times.madhab, onFriday: times.isFriday) {
            windows.append(KerahatWindow(
                id: .zenith,
                start: times.dhuhr.addingTimeInterval(-seconds(zenith)), end: times.dhuhr,
                row: .dhuhr
            ))
        }
        windows.append(KerahatWindow(
            id: .sunset,
            start: times.maghrib.addingTimeInterval(-seconds(minutes.beforeMaghrib)), end: times.maghrib,
            row: .asr
        ))
        return windows
    }

    /// Das Fenster, das zum Zeitpunkt `now` läuft; `nil`, wenn keines läuft.
    public static func activeWindow(at now: Date, in times: DayTimes) -> KerahatWindow? {
        windows(for: times).first { $0.contains(now) }
    }

    private static func seconds(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }
}
