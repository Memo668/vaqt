import Foundation

/// Die Tagesphase zu einem Zeitpunkt – das Ergebnis von `phase()` im Prototyp: welches Gebet läuft,
/// was als Nächstes kommt, welche Zeilen schon vorbei sind.
///
/// Eine Phase entsteht aus einem Zeitstrahl über drei Tage: `PrayerTimeline.phase(at:)`.
public struct DayPhase: Hashable, Codable, Sendable {

    /// Ein Ereignis auf dem Zeitstrahl.
    public struct Event: Hashable, Codable, Sendable {
        public let prayer: Prayer
        /// Tag des Ereignisses: −1 gestern, 0 heute, 1 morgen (`d`).
        public let dayOffset: Int
        /// Zeitpunkt des Ereignisses (`at`).
        public let date: Date
    }

    /// Fortschritt des Gebetstages von Fadschr bis Ischa – das Ergebnis von `dayProgress()`.
    public struct Progress: Hashable, Sendable {
        /// Anteil von 0 (Fadschr oder früher) bis 1 (Ischa oder später) (`p`).
        public let fraction: Double
        /// Ob „jetzt“ zwischen Fadschr und Ischa liegt. Nur dann zeigt der Bogen den Knopf (`active`).
        public let isActive: Bool
    }

    /// Der Zeitpunkt, für den die Phase gilt (`ns`).
    public let now: Date
    /// Die Zeiten von heute (`t`).
    public let times: DayTimes
    /// Das letzte Ereignis, das schon begonnen hat (`prev`).
    public let previous: Event
    /// Das nächste Ereignis (`next`).
    public let next: Event
    /// Das Ereignis nach dem nächsten (`next2`).
    public let following: Event

    /// Das Gebet, dessen Zeit gerade läuft (`current`). Der Sonnenaufgang beendet Fadschr: Zwischen
    /// Sonnenaufgang und Dhuhr läuft keines. Vor Fadschr läuft Ischa von gestern.
    public var current: Event? {
        previous.prayer == .sunrise ? nil : previous
    }

    /// Das Gebet, das in der Liste und im Bogen hervorgehoben wird: das laufende, sofern es ein Gebet
    /// von heute ist. Vor Fadschr ist nichts hervorgehoben (`ph.current.d === 0` in `prayerRow()`).
    public var highlighted: Prayer? {
        guard let current, current.dayOffset == 0 else { return nil }
        return current.prayer
    }

    /// Ob ein Ereignis von heute schon begonnen hat (`passed`).
    public func hasPassed(_ prayer: Prayer) -> Bool {
        times[prayer] <= now
    }

    /// Sekunden bis zum nächsten Ereignis (`remaining`).
    public var remaining: TimeInterval {
        next.date.timeIntervalSince(now)
    }

    /// Sekunden vom letzten bis zum nächsten Ereignis (`span`).
    public var span: TimeInterval {
        next.date.timeIntervalSince(previous.date)
    }

    /// Ob das nächste Ereignis erst morgen liegt – dann heißt es „Fadschr morgen in“ statt „Fadschr in“.
    public var isNextTomorrow: Bool {
        next.dayOffset == 1
    }

    /// Fortschritt von Fadschr bis Ischa für den Bogen.
    public var dayProgress: Progress {
        let length = times.isha.timeIntervalSince(times.fajr)
        guard length > 0 else { return Progress(fraction: 0, isActive: false) }
        let fraction = now.timeIntervalSince(times.fajr) / length
        return Progress(fraction: min(1, max(0, fraction)), isActive: fraction > 0 && fraction < 1)
    }

    /// Das Kerahat-Fenster von heute, das gerade läuft.
    public var activeKerahat: KerahatWindow? {
        Kerahat.activeWindow(at: now, in: times)
    }

    /// Schlüssel der Phase wie `phaseKey()`, z. B. `asr0|maghrib0|111100|-`.
    ///
    /// Er ändert sich genau dann, wenn die Seite neu aufgebaut werden muss: bei einem neuen laufenden
    /// oder nächsten Ereignis, wenn eine Zeile vorbei ist, und – sofern die App Kerahat zeigt – wenn ein
    /// Fenster beginnt oder endet. Dazwischen laufen nur Countdown und Bogen weiter.
    ///
    /// - Parameter showKerahat: der Schalter „Kerahat anzeigen“ aus den Einstellungen (`S.kerahat`).
    public func key(showKerahat: Bool) -> String {
        let current = current.map { $0.prayer.rawValue + String($0.dayOffset) } ?? "-"
        let next = next.prayer.rawValue + String(next.dayOffset)
        let passed = Prayer.allCases.map { hasPassed($0) ? "1" : "0" }.joined()
        let kerahat = (showKerahat ? activeKerahat?.id.rawValue : nil) ?? "-"
        return [current, next, passed, kerahat].joined(separator: "|")
    }
}
