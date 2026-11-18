import Foundation

/// Wann der Wecker zu Fadschr klingelt – `S.alarmMode` im Prototyp (Spec § 10.8).
///
/// Die Rohwerte sind die Kennungen des Prototyps.
public enum FajrAlarmMode: String, CaseIterable, Codable, Sendable {
    /// So viele Minuten vor Sonnenaufgang; die Weckzeit wandert mit ihm übers Jahr.
    case beforeSunrise = "before"
    /// Jeden Tag zur selben Uhrzeit, aber spätestens 5 Minuten vor Sonnenaufgang.
    case fixedTime = "fixed"
}

/// Klang des Weckers – `S.alarmSound` im Prototyp (Spec § 10.8, Nachtrag mit dem Plan für Phase 17).
public enum FajrAlarmSound: String, CaseIterable, Codable, Sendable {
    /// Der Weckton von iOS.
    case system
    /// Der kurze Adhan der gewählten Stimme, zu Fadschr ihre Fadschr-Fassung, sobald es eine Aufnahme gibt.
    case adhan
}

/// Der Wecker zu Fadschr – `S.alarmOn`, `S.alarmMode`, `S.alarmBefore`, `S.alarmTime` und `S.alarmSound` im
/// Prototyp (Spec § 10.8).
///
/// Werte außerhalb der Wahlmöglichkeiten gelten als nicht gesetzt: Die Minuten vor Sonnenaufgang bleiben in
/// 10…120, die feste Uhrzeit nicht vor 03:00. Die Obergrenze der festen Uhrzeit hängt vom Sonnenaufgang ab;
/// sie greift erst beim Wecken (`alarmDate(on:)`) und beim Stepper (`steppedFixedTime(by:sunrise:)`).
public struct FajrAlarmPreferences: Hashable, Sendable {
    /// Minuten vor Sonnenaufgang, die man wählen kann.
    public static let minutesBeforeRange = 10...120
    /// Schritt der Stepper in Minuten.
    public static let step = 5
    public static let standardMinutesBefore = 45
    /// Die früheste feste Uhrzeit, 03:00.
    public static let earliestFixedTime = ClockTime(minutesSinceMidnight: 3 * 60)
    /// Die feste Uhrzeit, wenn noch keine gewählt ist, 05:30.
    public static let standardFixedTime = ClockTime(minutesSinceMidnight: 5 * 60 + 30)
    /// So viele Minuten vor Sonnenaufgang klingelt eine feste Uhrzeit spätestens.
    public static let latestMinutesBeforeSunrise = 5

    /// Ob der Wecker an ist (`S.alarmOn`).
    public var isOn: Bool
    public var mode: FajrAlarmMode
    /// Minuten vor Sonnenaufgang bei „Vor Sonnenaufgang“ (`S.alarmBefore`).
    public var minutesBefore: Int {
        didSet { minutesBefore = Self.clampedMinutesBefore(minutesBefore) }
    }
    /// Die Uhrzeit bei „Feste Uhrzeit“ (`S.alarmTime`).
    public var fixedTime: ClockTime {
        didSet { fixedTime = Self.clampedFixedTime(fixedTime) }
    }
    public var sound: FajrAlarmSound

    public init(
        isOn: Bool = false, mode: FajrAlarmMode = .beforeSunrise,
        minutesBefore: Int = FajrAlarmPreferences.standardMinutesBefore,
        fixedTime: ClockTime = FajrAlarmPreferences.standardFixedTime, sound: FajrAlarmSound = .system
    ) {
        self.isOn = isOn
        self.mode = mode
        self.minutesBefore = Self.clampedMinutesBefore(minutesBefore)
        self.fixedTime = Self.clampedFixedTime(fixedTime)
        self.sound = sound
    }

    private static func clampedMinutesBefore(_ minutes: Int) -> Int {
        min(max(minutes, minutesBeforeRange.lowerBound), minutesBeforeRange.upperBound)
    }

    private static func clampedFixedTime(_ time: ClockTime) -> ClockTime {
        max(time, earliestFixedTime)
    }

    // MARK: - Weckzeit

    /// Wann der Wecker an diesem Tag klingelt – `alarmAt()` im Prototyp: bei „Vor Sonnenaufgang“ so viele
    /// Minuten vor ihm, bei „Feste Uhrzeit“ zu ihr, aber spätestens 5 Minuten vor Sonnenaufgang. Auf die
    /// volle Minute abgerundet, damit Klingeln und angezeigte Uhrzeit übereinstimmen.
    public func alarmDate(on times: DayTimes) -> Date {
        let latest = times.sunrise.addingTimeInterval(-TimeInterval(Self.latestMinutesBeforeSunrise * 60))
        let date = switch mode {
        case .beforeSunrise:
            times.sunrise.addingTimeInterval(-TimeInterval(minutesBefore * 60))
        case .fixedTime:
            min(times.day.date(at: fixedTime, in: times.timeZone), latest)
        }
        return Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60).rounded(.down) * 60)
    }

    /// Die späteste feste Uhrzeit an einem Tag mit diesem Sonnenaufgang: 5 Minuten vor ihm.
    public static func latestFixedTime(sunrise: ClockTime) -> ClockTime {
        ClockTime(minutesSinceMidnight: max(0, sunrise.minutesSinceMidnight - latestMinutesBeforeSunrise))
    }

    // MARK: - Stepper

    /// Die Minuten nach einem Schritt des Steppers nach oben (+1) oder unten (−1), in 10…120.
    public func steppedMinutesBefore(by direction: Int) -> Int {
        Self.clampedMinutesBefore(minutesBefore + direction * Self.step)
    }

    /// Die feste Uhrzeit nach einem Schritt des Steppers: von 03:00 bis 5 Minuten vor dem Sonnenaufgang des
    /// Tages, wie im Prototyp (`Math.max(180, Math.min(sr - 5, S.alarmTime + d*5))`).
    public func steppedFixedTime(by direction: Int, sunrise: ClockTime) -> ClockTime {
        let latest = Self.latestFixedTime(sunrise: sunrise).minutesSinceMidnight
        let next = min(latest, fixedTime.minutesSinceMidnight + direction * Self.step)
        return ClockTime(minutesSinceMidnight: max(Self.earliestFixedTime.minutesSinceMidnight, next))
    }
}

extension FajrAlarmPreferences: Codable {
    private enum CodingKeys: String, CodingKey {
        case isOn, mode, minutesBefore, fixedMinutes, sound
    }

    /// Fehlt ein Wert oder ist er unbekannt, gilt sein Startwert – so lesen auch spätere Fassungen ältere
    /// Stände.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fixedMinutes = try container.decodeIfPresent(Int.self, forKey: .fixedMinutes)
        self.init(
            isOn: try container.decodeIfPresent(Bool.self, forKey: .isOn) ?? false,
            mode: (try? container.decodeIfPresent(FajrAlarmMode.self, forKey: .mode)) ?? .beforeSunrise,
            minutesBefore: try container.decodeIfPresent(Int.self, forKey: .minutesBefore) ?? Self.standardMinutesBefore,
            fixedTime: fixedMinutes.map { ClockTime(minutesSinceMidnight: $0) } ?? Self.standardFixedTime,
            sound: (try? container.decodeIfPresent(FajrAlarmSound.self, forKey: .sound)) ?? .system
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isOn, forKey: .isOn)
        try container.encode(mode, forKey: .mode)
        try container.encode(minutesBefore, forKey: .minutesBefore)
        try container.encode(fixedTime.minutesSinceMidnight, forKey: .fixedMinutes)
        try container.encode(sound, forKey: .sound)
    }
}

/// Ein Klingeln des Weckers: der Tag und wann.
public struct FajrAlarmOccurrence: Hashable, Sendable {
    public let day: CalendarDay
    /// Wann der Wecker klingelt, auf der Uhr der App.
    public let date: Date
}

/// Wann der Wecker zu Fadschr in den nächsten Tagen klingelt (Spec § 10.8).
///
/// AlarmKit kennt nur Wecker zu einer festen Uhrzeit, die sich wöchentlich wiederholen, oder einzelne zu
/// einem Zeitpunkt. Die Weckzeit wandert aber mit dem Sonnenaufgang – auch eine feste Uhrzeit, wenn der
/// Sonnenaufgang sie einholt. Deshalb meldet die App einzelne Wecker für die nächsten 14 Tage an, neu bei
/// jedem Start, bei der Hintergrundaktualisierung und nach jeder Änderung – wie das rollierende Fenster der
/// Mitteilungen (entschieden mit dem Plan für Phase 17).
public struct FajrAlarmPlanner: Sendable {

    /// So viele Wecker meldet die App höchstens an: einen je Tag für zwei Wochen.
    public static let days = 14

    public let source: any PrayerTimesSource

    public init(source: any PrayerTimesSource) {
        self.source = source
    }

    /// Die nächsten Weckzeiten nach `now`, in zeitlicher Folge, höchstens `limit`; ist der Wecker aus,
    /// keine. Tage ohne Zeiten – etwa ohne Sonnenaufgang – fallen aus.
    public func plan(
        at now: Date, place: Place, settings: CalculationSettings, preferences: FajrAlarmPreferences,
        limit: Int = FajrAlarmPlanner.days
    ) -> [FajrAlarmOccurrence] {
        guard preferences.isOn, limit > 0 else { return [] }
        let today = CalendarDay(now, in: place.timeZone)
        var occurrences: [FajrAlarmOccurrence] = []
        // Heute kann schon vorbei sein; dann zählt der Tag nach dem letzten mit. Tage ohne Zeiten
        // überspringt der Plan, sucht aber nicht weiter als doppelt so weit.
        for offset in 0..<(2 * limit + 1) {
            let day = today.adding(days: offset)
            guard let times = source.times(on: day, at: place, settings: settings) else { continue }
            let date = preferences.alarmDate(on: times)
            guard date > now else { continue }
            occurrences.append(FajrAlarmOccurrence(day: day, date: date))
            if occurrences.count == limit { break }
        }
        return occurrences
    }

    /// Eine feste Kennung für einen Wecker: dieselbe Zeit mit derselben Fassung (Klang, Texte) gibt dieselbe
    /// Kennung. So lässt die App beim Neuplanen stehen, was schon richtig angemeldet ist, und meldet nur
    /// Geändertes ab und an.
    public static func identifier(for date: Date, variant: String) -> UUID {
        let text = "fajr-alarm|\(Int(date.timeIntervalSince1970))|\(variant)"
        let bytes = Array(text.utf8)
        var high = fnv1a(bytes, seed: 0xcbf2_9ce4_8422_2325)
        var low = fnv1a(bytes, seed: 0x8422_2325_cbf2_9ce4)
        var uuid = [UInt8](repeating: 0, count: 16)
        for index in 0..<8 {
            uuid[7 - index] = UInt8(truncatingIfNeeded: high)
            uuid[15 - index] = UInt8(truncatingIfNeeded: low)
            high >>= 8
            low >>= 8
        }
        // Version 5 (namensbasiert) und Variante RFC 4122, damit es eine gültige UUID ist.
        uuid[6] = (uuid[6] & 0x0F) | 0x50
        uuid[8] = (uuid[8] & 0x3F) | 0x80
        return UUID(uuid: (
            uuid[0], uuid[1], uuid[2], uuid[3], uuid[4], uuid[5], uuid[6], uuid[7],
            uuid[8], uuid[9], uuid[10], uuid[11], uuid[12], uuid[13], uuid[14], uuid[15]
        ))
    }

    /// FNV-1a mit 64 Bit – stabil über Starts und Geräte, anders als `Hasher`.
    private static func fnv1a(_ bytes: [UInt8], seed: UInt64) -> UInt64 {
        bytes.reduce(seed) { hash, byte in (hash ^ UInt64(byte)) &* 0x0000_0100_0000_01b3 }
    }
}
