#if DEBUG

import Foundation
import PrayerCore

/// Debug-Startargumente, mit denen sich jeder Referenz-Screenshot nachstellen lässt (CLAUDE.md).
///
/// ```
/// -debugSkipOnboarding
/// -debugFixtureTimes            Mock-Zeiten aus dem Prototyp statt echter Berechnung
/// -debugDate 2026-11-10
/// -debugTime 14:25              Uhr läuft ab hier weiter
/// -debugCity berlin|istanbul|madrid|mecca|jakarta
/// -debugHighLatitude            Berlin, 21. Juni
/// -debugLocationDenied  -debugOffline
/// -debugTab today|qibla|guide|verses|qada|settings
/// -debugQiblaHeading 137
/// ```
///
/// Es gibt diesen Typ nur in DEBUG-Builds. Alles, was nicht mit `-debug` beginnt, wird übergangen.
public struct LaunchOptions: Equatable, Sendable {

    /// Ziel von `-debugTab`.
    public enum Page: String, CaseIterable, Sendable {
        case today, qibla, guide, verses, qada, settings
    }

    public var skipOnboarding = false
    public var fixtureTimes = false
    public var date: CalendarDay?
    public var time: ClockTime?
    public var city: FixtureTimes.City?
    public var highLatitude = false
    public var locationDenied = false
    public var offline = false
    public var page: Page?
    /// Kompasskurs in Grad, 0 bis unter 360.
    public var qiblaHeading: Double?
    /// Was an den Debug-Argumenten nicht verstanden wurde. Die App gibt es beim Start aus, damit
    /// ein Tippfehler nicht unbemerkt zu einem falschen Screenshot führt.
    public var problems: [String] = []

    public init() {}

    public init(arguments: [String]) {
        var rest = arguments[...]
        while let argument = rest.popFirst() {
            guard argument.hasPrefix("-debug") else { continue }
            switch argument {
            case "-debugSkipOnboarding":
                skipOnboarding = true
            case "-debugFixtureTimes":
                fixtureTimes = true
            case "-debugHighLatitude":
                highLatitude = true
            case "-debugLocationDenied":
                locationDenied = true
            case "-debugOffline":
                offline = true
            case "-debugDate":
                date = value(of: argument, from: &rest, expected: "ein Datum wie 2026-11-10") { CalendarDay($0) }
            case "-debugTime":
                time = value(of: argument, from: &rest, expected: "eine Uhrzeit wie 14:25") { ClockTime($0) }
            case "-debugCity":
                let cities = FixtureTimes.cities.map(\.id).joined(separator: ", ")
                city = value(of: argument, from: &rest, expected: "eine der Städte \(cities)") { FixtureTimes.city($0) }
            case "-debugTab":
                let pages = Page.allCases.map(\.rawValue).joined(separator: ", ")
                page = value(of: argument, from: &rest, expected: "eine der Seiten \(pages)") { Page(rawValue: $0) }
            case "-debugQiblaHeading":
                qiblaHeading = value(of: argument, from: &rest, expected: "ein Kurs von 0 bis unter 360 Grad") {
                    Double($0).flatMap { (0..<360).contains($0) ? $0 : nil }
                }
            default:
                problems.append("\(argument) ist kein bekanntes Debug-Argument.")
            }
        }
        if highLatitude, city != nil || date != nil {
            problems.append("-debugHighLatitude legt Berlin und den 21. Juni fest; -debugCity und -debugDate werden übergangen.")
        }
    }

    /// Die Stadt, die gilt.
    ///
    /// `-debugHighLatitude` bedeutet immer Berlin. Mit `-debugFixtureTimes` gilt ohne `-debugCity`
    /// ebenfalls Berlin – die Stadt, in der der Prototyp startet (`S.city`) und für die
    /// docs/PROMPTS.md die Argumente der Screenshots ohne `-debugCity` angibt.
    public var effectiveCity: FixtureTimes.City? {
        if highLatitude { return FixtureTimes.city("berlin") }
        return city ?? (fixtureTimes ? FixtureTimes.city("berlin") : nil)
    }

    /// Der Tag, der gilt. `-debugHighLatitude` bedeutet immer den Tag aus `BERLIN_SUMMER`.
    public var effectiveDate: CalendarDay? {
        highLatitude ? FixtureTimes.berlinSummer.day : date
    }

    /// Die Uhr zu den Argumenten.
    ///
    /// Ohne Datum und Uhrzeit ist es die Gerätezeit. Sonst beginnt die Uhr beim gewünschten Zeitpunkt
    /// und läuft weiter. Datum und Uhrzeit gelten in der Zeitzone der Stadt, ohne Stadt in der des Geräts.
    /// Fehlt das Datum, gilt heute; fehlt die Uhrzeit, gilt die aktuelle.
    public func makeClock(system: any AppClock = SystemClock(), deviceTimeZone: TimeZone = .current) -> any AppClock {
        guard effectiveDate != nil || time != nil else { return system }
        let timeZone = effectiveCity.flatMap { TimeZone(identifier: $0.timeZoneIdentifier) } ?? deviceTimeZone
        let systemNow = system.now
        let today = CalendarDay(systemNow, in: timeZone)
        let day = effectiveDate ?? today

        let start: Date
        if let time {
            start = day.date(at: time, in: timeZone)
        } else {
            let sinceMidnight = systemNow.timeIntervalSince(today.date(at: .midnight, in: timeZone))
            start = day.date(at: .midnight, in: timeZone).addingTimeInterval(sinceMidnight)
        }
        return DebugClock(startingAt: start, systemNow: systemNow)
    }

    /// Liest den Wert hinter einem Argument. Fehlt er oder passt er nicht, wird das als Problem notiert.
    private mutating func value<Value>(
        of argument: String,
        from rest: inout ArraySlice<String>,
        expected: String,
        parse: (String) -> Value?
    ) -> Value? {
        guard let text = rest.first, !text.hasPrefix("-debug") else {
            problems.append("\(argument) braucht einen Wert: \(expected).")
            return nil
        }
        rest.removeFirst()
        guard let value = parse(text) else {
            problems.append("\(argument) \(text) wird nicht verstanden. Erwartet wird \(expected).")
            return nil
        }
        return value
    }
}

#endif
