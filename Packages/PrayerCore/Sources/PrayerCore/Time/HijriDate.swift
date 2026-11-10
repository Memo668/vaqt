import Foundation

/// Ein Tag im islamischen Kalender nach Umm al-Qura.
///
/// Gerechnet wird mit dem Kalender des Systems (`Calendar(identifier: .islamicUmmAlQura)`), Tag für Tag
/// zum gregorianischen Kalendertag – wie `hijriDate()` im Prototyp. Eine Korrektur um ±1 Tag für die
/// örtliche Mondsichtung gibt es nicht (Spec § 6.7).
public struct HijriDate: Hashable, Sendable {
    /// Der gregorianische Kalendertag, zu dem das Datum gehört.
    public let gregorianDay: CalendarDay
    public let year: Int
    /// 1 (Muharram) bis 12 (Dhu l-Hiddscha).
    public let month: Int
    public let day: Int

    /// Das Hijri-Datum zu einem gregorianischen Kalendertag.
    public init(_ gregorianDay: CalendarDay) {
        self.gregorianDay = gregorianDay
        let calendar = Self.calendar
        let instant = Self.instant(of: gregorianDay)
        year = calendar.component(.year, from: instant)
        month = calendar.component(.month, from: instant)
        day = calendar.component(.day, from: instant)
    }

    /// Das Datum als Text mit ausgeschriebenem Monat in der Sprache von `locale`, ohne Ära –
    /// deutsch „30. Dschumada I 1448“, türkisch „30 Cemaziyelevvel 1448“.
    public func formatted(locale: Locale) -> String {
        let calendar = Self.calendar
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("dMMMMy")
        // Manche Sprachen hängen die Ära an („1448 هـ“). Der Prototyp lässt sie weg und räumt das Ende auf.
        formatter.dateFormat = Self.removingEra(from: formatter.dateFormat ?? "")
        return Self.trimmingEnds(formatter.string(from: Self.instant(of: gregorianDay)))
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .gmt
        return calendar
    }

    /// Mittags in GMT liegt jeder Kalendertag eindeutig auf sich selbst.
    private static func instant(of gregorianDay: CalendarDay) -> Date {
        gregorianDay.date(at: ClockTime(minutesSinceMidnight: 12 * 60), in: .gmt)
    }

    /// Entfernt das Feld der Ära (`G`) aus einem Datumsmuster. Text in einfachen Anführungszeichen bleibt.
    static func removingEra(from pattern: String) -> String {
        var result = ""
        var isQuoted = false
        for character in pattern {
            if character == "'" {
                isQuoted.toggle()
            }
            if character == "G", !isQuoted {
                continue
            }
            result.append(character)
        }
        return result
    }

    /// Entfernt Leerraum, Kommas und Punkte am Ende und Leerraum am Anfang – wie
    /// `.replace(/[\s,.]+$/, '').trim()` im Prototyp.
    static func trimmingEnds(_ text: String) -> String {
        var result = Substring(text)
        while let last = result.last, last.isWhitespace || last == "," || last == "." {
            result.removeLast()
        }
        while let first = result.first, first.isWhitespace {
            result.removeFirst()
        }
        return String(result)
    }
}
