import Foundation

/// Ein Kalendertag im gregorianischen Kalender, ohne Uhrzeit und ohne Zeitzone – z. B. 2026-11-10.
public struct CalendarDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// `nil`, wenn es den Tag nicht gibt (z. B. 30. Februar).
    public init?(year: Int, month: Int, day: Int) {
        // Foundation rollt ungültige Angaben weiter (30. Februar → 2. März); deshalb zurücklesen und vergleichen.
        let calendar = Self.calendar(in: .gmt)
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        guard parts.year == year, parts.month == month, parts.day == day else { return nil }
        self.year = year
        self.month = month
        self.day = day
    }

    /// Liest „yyyy-MM-dd“, z. B. „2026-11-10“. Alles andere ergibt `nil`.
    public init?(_ text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy { ("0"..."9").contains($0) } }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2])
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// Der Tag, auf den `date` in `timeZone` fällt.
    public init(_ date: Date, in timeZone: TimeZone) {
        let parts = Self.calendar(in: timeZone).dateComponents([.year, .month, .day], from: date)
        // Der gregorianische Kalender liefert für jedes Datum Jahr, Monat und Tag.
        year = parts.year ?? 1970
        month = parts.month ?? 1
        day = parts.day ?? 1
    }

    /// Zeitpunkt dieses Tages um `time` in `timeZone`.
    ///
    /// Gibt es die Uhrzeit an dem Tag nicht (Beginn der Sommerzeit), liefert Foundation den
    /// nächsten gültigen Zeitpunkt.
    public func date(at time: ClockTime, in timeZone: TimeZone) -> Date {
        let calendar = Self.calendar(in: timeZone)
        let parts = DateComponents(year: year, month: month, day: day, hour: time.hour, minute: time.minute)
        guard let date = calendar.date(from: parts) else {
            preconditionFailure("CalendarDay \(self) ist beim Erzeugen geprüft – hier nicht erreichbar")
        }
        return date
    }

    public var description: String {
        String(year) + "-" + (month < 10 ? "0" : "") + String(month) + "-" + (day < 10 ? "0" : "") + String(day)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
