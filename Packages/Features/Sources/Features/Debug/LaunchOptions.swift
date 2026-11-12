#if DEBUG

import DesignSystem
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
/// -debugQiblaAccuracy 40        Genauigkeit des Kompasses in Grad; über 25 erscheint die Kalibrierungskarte
/// -debugCatalog arc|rows|glass|cards|compass|guide|steps|verses|qada|all   Katalog der Bausteine statt der App, für den Abgleich
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
    /// Genauigkeit des festen Kompasskurses in Grad, wie `CLHeading.headingAccuracy`: die größte
    /// Abweichung, negativ für einen ungültigen Kurs. Die Referenzbilder zeigen die Karte „Kompass
    /// kalibrieren“ immer, die App nur bei schlechter Genauigkeit – damit lässt sie sich nachstellen.
    public var qiblaAccuracy: Double?
    /// Abschnitt des Katalogs, den die App statt der Tabs zeigt (`-debugCatalog`). Bogen und
    /// Gebetskarten stehen dort im Zustand der übrigen Argumente.
    public var catalog: ComponentCatalog.Section?
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
            case "-debugQiblaAccuracy":
                qiblaAccuracy = value(of: argument, from: &rest, expected: "eine Abweichung in Grad, z. B. 40") {
                    Double($0).flatMap { $0.isFinite ? $0 : nil }
                }
            case "-debugCatalog":
                let sections = ComponentCatalog.Section.allCases.map(\.rawValue).joined(separator: ", ")
                catalog = value(of: argument, from: &rest, expected: "einer der Abschnitte \(sections)") {
                    ComponentCatalog.Section(rawValue: $0)
                }
            default:
                problems.append("\(argument) ist kein bekanntes Debug-Argument.")
            }
        }
        if highLatitude, city != nil || date != nil {
            problems.append("-debugHighLatitude legt Berlin und den 21. Juni fest; -debugCity und -debugDate werden übergangen.")
        }
        if qiblaAccuracy != nil, effectiveQiblaHeading == nil {
            problems.append("-debugQiblaAccuracy wirkt nur mit festem Kurs: zusammen mit -debugQiblaHeading oder -debugFixtureTimes.")
        }
    }

    /// Der Startwert des Kompasskurses im Prototyp (`S.qibla.heading`).
    public static let prototypeQiblaHeading = 99.0

    /// Der feste Kompasskurs, der gilt; `nil` heißt, die App fragt den Kompass des Geräts.
    ///
    /// Mit `-debugFixtureTimes` gilt ohne `-debugQiblaHeading` der Startwert des Prototyps – wie bei den
    /// übrigen Startwerten von `S`. So zeigt die Qibla-Seite auch im Simulator, der keinen Kompass hat,
    /// den Zustand von `iphone/30`.
    public var effectiveQiblaHeading: Double? {
        qiblaHeading ?? (fixtureTimes ? Self.prototypeQiblaHeading : nil)
    }

    /// Die feste Kursquelle zu den Argumenten; `nil`, wenn der Kompass des Geräts gilt.
    public var fixedHeading: Heading? {
        effectiveQiblaHeading.map { Heading(degrees: $0, accuracy: qiblaAccuracy ?? 0) }
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
