/// Uhrzeit ohne Datum, minutengenau – z. B. 14:25.
public struct ClockTime: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    /// `nil`, wenn die Werte keine Uhrzeit ergeben (Stunde 0–23, Minute 0–59).
    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }

    /// Liest „HH:mm“, z. B. „05:16“. Alles andere ergibt `nil`.
    public init?(_ text: String) {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let hour = Self.number(parts[0]),
              let minute = Self.number(parts[1])
        else { return nil }
        self.init(hour: hour, minute: minute)
    }

    /// Minuten seit Mitternacht – wie `toMin()` im Prototyp.
    public var minutesSinceMidnight: Int { hour * 60 + minute }

    public var description: String {
        (hour < 10 ? "0" : "") + String(hour) + ":" + (minute < 10 ? "0" : "") + String(minute)
    }

    public static func < (lhs: ClockTime, rhs: ClockTime) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }

    /// Ein bis zwei ASCII-Ziffern, sonst `nil` – `Int("+5")` oder `Int("٥")` sollen nicht durchgehen.
    private static func number(_ text: Substring) -> Int? {
        guard (1...2).contains(text.count), text.allSatisfy({ ("0"..."9").contains($0) }) else { return nil }
        return Int(text)
    }
}
