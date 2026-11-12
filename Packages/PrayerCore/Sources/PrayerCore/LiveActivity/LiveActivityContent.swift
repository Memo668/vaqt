import Foundation

/// Was eine Live-Aktivität zeigt – der Rechenteil von `laBanner()`, `diCompact()` und `diExpanded()` im
/// Prototyp (Spec § 3, „Live Activity“).
///
/// Die Aktivität zählt auf ein Gebet zu (`ph.next`). Auf dem Sperrbildschirm steht der kleine Bogen; iOS
/// zeichnet ihn nicht von selbst neu, deshalb steht er still: bis zum Gebetsbeginn im Stand `countdown`
/// (beim Start der Aktivität oder als die App sie zuletzt aufgefrischt hat), ab Beginn im Stand `begun`.
/// Was sich jede Sekunde ändert – Countdown, Balken, Ring –, zeichnet iOS mit `Text(timerInterval:)` und
/// `ProgressView(timerInterval:)` selbst.
///
/// Der Inhalt ist der `ContentState` der Aktivität und wird dafür als JSON gespeichert.
public struct LiveActivityContent: Codable, Hashable, Sendable {

    /// Ein Kerahat-Fenster unter dem Balken der Dynamic Island, als Anteil der Strecke vom vorigen Ereignis
    /// bis zum Gebet (`segs` in `diExpanded()`).
    public struct KerahatMark: Codable, Hashable, Sendable {
        /// Beginn, 0 bis 1.
        public let start: Double
        /// Länge, 0 bis 1.
        public let length: Double
    }

    /// Das Gebet, auf das die Aktivität zuzählt (`ph.next`). Sein Tag (`dayOffset`) zählt vom Tag des
    /// Standes `countdown` aus.
    public let prayer: DayPhase.Event
    /// Das Ereignis davor (`ph.prev`) – dort beginnt der Balken der Dynamic Island. Vor Dhuhr ist es der
    /// Sonnenaufgang.
    public let previous: DayPhase.Event
    /// Tagesphase für den Bogen bis zum Gebetsbeginn.
    public let countdown: DayPhase
    /// Tagesphase für den Bogen ab Gebetsbeginn: das Gebet läuft.
    public let begun: DayPhase
    /// Die Kerahat-Fenster unter dem Balken; leer, wenn die App Kerahat nicht zeigt.
    public let kerahat: [KerahatMark]
    /// Name des Ortes im Kopf (`cityName()`).
    public let cityName: String
    /// Ob der Ort der aktuelle Standort ist; dann steht in der Dynamic Island der Pfeil davor.
    public let isCurrentLocation: Bool
    /// Der Schalter „Kerahat-Zeiten zeigen“ (`S.kerahat`).
    public let showKerahat: Bool
    /// Uhr der App minus Gerätezeit in Sekunden. Nur mit `-debugDate`/`-debugTime` nicht 0: Dann laufen
    /// Countdown und Balken mit der Gerätezeit, zeigen aber die Zeiten der Debug-Uhr.
    public let clockOffset: TimeInterval
    /// Ob das Gebet schon begonnen hat, als die App die Aktivität beendet hat. Eine beendete Aktivität
    /// bleibt bis 15 Minuten nach Beginn auf dem Sperrbildschirm und zeigt dann „Jetzt“, auch ohne
    /// `isStale`.
    public let hasBegun: Bool

    public init(
        prayer: DayPhase.Event, previous: DayPhase.Event, countdown: DayPhase, begun: DayPhase,
        kerahat: [KerahatMark], cityName: String, isCurrentLocation: Bool, showKerahat: Bool,
        clockOffset: TimeInterval = 0, hasBegun: Bool = false
    ) {
        self.prayer = prayer
        self.previous = previous
        self.countdown = countdown
        self.begun = begun
        self.kerahat = kerahat
        self.cityName = cityName
        self.isCurrentLocation = isCurrentLocation
        self.showKerahat = showKerahat
        self.clockOffset = clockOffset
        self.hasBegun = hasBegun
    }

    /// Derselbe Inhalt, als habe das Gebet schon begonnen.
    public var markedBegun: LiveActivityContent {
        LiveActivityContent(
            prayer: prayer, previous: previous, countdown: countdown, begun: begun, kerahat: kerahat,
            cityName: cityName, isCurrentLocation: isCurrentLocation, showKerahat: showKerahat,
            clockOffset: clockOffset, hasBegun: true
        )
    }

    /// Ob das Gebet erst morgen ist – dann heißt es „Fadschr (morgen) in“ (`laLabel()`).
    public var isTomorrow: Bool {
        prayer.dayOffset == 1
    }

    /// Uhrzeit des Gebets am Ort, z. B. 16:27.
    public var prayerTime: ClockTime {
        ClockTime(prayer.date, in: countdown.times.timeZone)
    }

    /// Uhrzeit des vorigen Ereignisses am Ort, z. B. 14:00.
    public var previousTime: ClockTime {
        ClockTime(previous.date, in: countdown.times.timeZone)
    }

    /// Der Zeitpunkt der Gerätezeit, zu dem die Uhr der App `date` zeigt.
    public func deviceDate(_ date: Date) -> Date {
        date.addingTimeInterval(-clockOffset)
    }

    /// Ende des Countdowns in Gerätezeit – der Gebetsbeginn, zugleich `staleDate` der Aktivität.
    public var deviceCountdownEnd: Date {
        deviceDate(prayer.date)
    }

    /// Strecke des Balkens in Gerätezeit: vom vorigen Ereignis bis zum Gebet.
    public var deviceBarInterval: ClosedRange<Date> {
        let start = deviceDate(previous.date)
        let end = deviceDate(prayer.date)
        return start <= end ? start...end : end...end
    }

    /// Die Kerahat-Fenster, die zwischen `start` und `end` liegen, als Anteile dieser Strecke – wie die
    /// Schleife über `[-1, 0, 1]` und `kerahatWins()` in `diExpanded()`.
    static func kerahatMarks(between start: Date, and end: Date, windows: [KerahatWindow]) -> [KerahatMark] {
        let length = end.timeIntervalSince(start)
        guard length > 0 else { return [] }
        return windows.compactMap { window in
            let from = max(window.start, start)
            let to = min(window.end, end)
            guard to > from else { return nil }
            return KerahatMark(
                start: from.timeIntervalSince(start) / length,
                length: to.timeIntervalSince(from) / length
            )
        }
    }
}
