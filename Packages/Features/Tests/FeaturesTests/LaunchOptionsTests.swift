#if DEBUG

import Foundation
import PrayerCore
import Testing
@testable import Features

@Suite("Debug-Startargumente")
struct LaunchOptionsTests {

    private func instant(_ iso: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso))
    }

    // MARK: Lesen

    @Test("ohne Argumente gilt nichts")
    func empty() {
        let options = LaunchOptions(arguments: [])
        #expect(options == LaunchOptions())
        #expect(options.problems.isEmpty)
    }

    @Test("der Pfad des Programms und fremde Argumente werden übergangen")
    func ignoresOtherArguments() {
        let options = LaunchOptions(arguments: ["/path/Gebetszeiten", "-AppleLanguages", "(tr)", "-NSDoubleLocalizedStrings", "YES"])
        #expect(options == LaunchOptions())
    }

    @Test("die Argumente des Haupt-Screenshots")
    func reference() {
        let options = LaunchOptions(arguments: [
            "Gebetszeiten", "-debugSkipOnboarding", "-debugFixtureTimes",
            "-debugDate", "2026-11-10", "-debugTime", "14:25", "-debugCity", "berlin", "-debugTab", "today",
        ])
        #expect(options.skipOnboarding)
        #expect(options.fixtureTimes)
        #expect(options.date == CalendarDay("2026-11-10"))
        #expect(options.time == ClockTime("14:25"))
        #expect(options.city?.id == "berlin")
        #expect(options.page == .today)
        #expect(!options.highLatitude)
        #expect(!options.locationDenied)
        #expect(!options.offline)
        #expect(options.qiblaHeading == nil)
        #expect(options.problems.isEmpty)
    }

    @Test("Schalter ohne Wert")
    func flags() {
        let options = LaunchOptions(arguments: ["-debugLocationDenied", "-debugOffline", "-debugHighLatitude"])
        #expect(options.locationDenied)
        #expect(options.offline)
        #expect(options.highLatitude)
        #expect(!options.skipOnboarding)
        #expect(!options.fixtureTimes)
        #expect(options.problems.isEmpty)
    }

    @Test("jede Stadt aus dem Prototyp", arguments: ["berlin", "istanbul", "madrid", "mecca", "jakarta"])
    func cities(id: String) {
        let options = LaunchOptions(arguments: ["-debugCity", id])
        #expect(options.city?.id == id)
        #expect(options.problems.isEmpty)
    }

    @Test("jede Seite", arguments: LaunchOptions.Page.allCases)
    func pages(page: LaunchOptions.Page) {
        let options = LaunchOptions(arguments: ["-debugTab", page.rawValue])
        #expect(options.page == page)
        #expect(options.problems.isEmpty)
    }

    @Test("Kompasskurs", arguments: [("137", 137.0), ("0", 0.0), ("359.5", 359.5)])
    func heading(text: String, expected: Double) {
        let options = LaunchOptions(arguments: ["-debugQiblaHeading", text])
        #expect(options.qiblaHeading == expected)
        #expect(options.problems.isEmpty)
    }

    @Test("Genauigkeit des Kompasses, auch negativ für einen ungültigen Kurs", arguments: [
        ("40", 40.0), ("0", 0.0), ("12.5", 12.5), ("-1", -1.0),
    ])
    func accuracy(text: String, expected: Double) {
        let options = LaunchOptions(arguments: ["-debugQiblaHeading", "98", "-debugQiblaAccuracy", text])
        #expect(options.qiblaAccuracy == expected)
        #expect(options.fixedHeading == Heading(degrees: 98, accuracy: expected))
        #expect(options.problems.isEmpty)
    }

    @Test("ohne -debugQiblaHeading fragt die App den Kompass des Geräts")
    func noFixedHeading() {
        let options = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugTab", "qibla"])
        #expect(options.effectiveQiblaHeading == nil)
        #expect(options.fixedHeading == nil)
    }

    @Test("mit -debugFixtureTimes gilt ohne -debugQiblaHeading der Startwert des Prototyps, 99°")
    func fixtureHeading() {
        #expect(LaunchOptions.prototypeQiblaHeading == 99)
        let fixture = LaunchOptions(arguments: ["-debugFixtureTimes", "-debugTab", "qibla"])
        #expect(fixture.qiblaHeading == nil)
        #expect(fixture.effectiveQiblaHeading == 99)
        #expect(fixture.fixedHeading == Heading(degrees: 99))

        let explicit = LaunchOptions(arguments: ["-debugFixtureTimes", "-debugQiblaHeading", "137"])
        #expect(explicit.effectiveQiblaHeading == 137)
        #expect(explicit.fixedHeading == Heading(degrees: 137))
    }

    @Test("die Genauigkeit gilt auch für den Startwert des Prototyps")
    func fixtureAccuracy() {
        let options = LaunchOptions(arguments: ["-debugFixtureTimes", "-debugQiblaAccuracy", "40"])
        #expect(options.fixedHeading == Heading(degrees: 99, accuracy: 40))
        #expect(options.fixedHeading?.needsCalibration == true)
        #expect(options.problems.isEmpty)
    }

    @Test("-debugQiblaAccuracy ohne festen Kurs wird gemeldet")
    func accuracyWithoutHeading() {
        let options = LaunchOptions(arguments: ["-debugQiblaAccuracy", "40"])
        #expect(options.qiblaAccuracy == 40)
        #expect(options.fixedHeading == nil)
        #expect(options.problems.count == 1)
        #expect(options.problems.first?.contains("-debugQiblaAccuracy") == true)
    }

    @Test("bei doppelten Argumenten gilt das letzte")
    func lastWins() {
        let options = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugCity", "jakarta", "-debugTime", "08:04", "-debugTime", "16:05"])
        #expect(options.city?.id == "jakarta")
        #expect(options.time == ClockTime("16:05"))
    }

    // MARK: Fehler

    @Test("ein falscher Wert wird gemeldet und nicht übernommen", arguments: [
        ["-debugDate", "10.11.2026"],
        ["-debugDate", "2026-02-30"],
        ["-debugTime", "25:00"],
        ["-debugTime", "1425"],
        ["-debugCity", "paris"],
        ["-debugCity", "Berlin"],
        ["-debugTab", "home"],
        ["-debugQiblaHeading", "360"],
        ["-debugQiblaHeading", "-10"],
        ["-debugQiblaHeading", "nan"],
        ["-debugQiblaHeading", "süd"],
        ["-debugQiblaAccuracy", "schlecht"],
        ["-debugQiblaAccuracy", "inf"],
    ])
    func invalidValue(arguments: [String]) {
        let options = LaunchOptions(arguments: arguments)
        var expected = LaunchOptions()
        expected.problems = options.problems
        #expect(options == expected)
        #expect(options.problems.count == 1)
        #expect(options.problems.first?.contains(arguments[0]) == true)
        #expect(options.problems.first?.contains(arguments[1]) == true)
    }

    @Test("ein fehlender Wert am Ende wird gemeldet")
    func missingValueAtEnd() {
        let options = LaunchOptions(arguments: ["-debugSkipOnboarding", "-debugTime"])
        #expect(options.skipOnboarding)
        #expect(options.time == nil)
        #expect(options.problems.count == 1)
        #expect(options.problems.first?.contains("-debugTime") == true)
    }

    @Test("folgt statt des Werts ein Debug-Argument, wird das trotzdem gelesen")
    func missingValueBeforeFlag() {
        let options = LaunchOptions(arguments: ["-debugCity", "-debugOffline", "-debugTab", "qada"])
        #expect(options.city == nil)
        #expect(options.offline)
        #expect(options.page == .qada)
        #expect(options.problems.count == 1)
        #expect(options.problems.first?.contains("-debugCity") == true)
    }

    @Test("ein unbekanntes Debug-Argument wird gemeldet")
    func unknownArgument() {
        let options = LaunchOptions(arguments: ["-debugFixtureTime", "-debugOffline"])
        #expect(!options.fixtureTimes)
        #expect(options.offline)
        #expect(options.problems == ["-debugFixtureTime ist kein bekanntes Debug-Argument."])
    }

    // MARK: Hohe Breiten

    @Test("-debugHighLatitude bedeutet Berlin am 21. Juni 2027")
    func highLatitude() {
        let options = LaunchOptions(arguments: ["-debugHighLatitude"])
        #expect(options.effectiveCity?.id == "berlin")
        #expect(options.effectiveDate == CalendarDay("2027-06-21"))
        #expect(options.problems.isEmpty)
    }

    @Test("-debugHighLatitude geht vor -debugCity und -debugDate und meldet den Widerspruch")
    func highLatitudeWins() {
        let options = LaunchOptions(arguments: ["-debugHighLatitude", "-debugCity", "jakarta", "-debugDate", "2026-11-10"])
        #expect(options.effectiveCity?.id == "berlin")
        #expect(options.effectiveDate == CalendarDay("2027-06-21"))
        #expect(options.problems.count == 1)
    }

    @Test("ohne -debugHighLatitude gelten Stadt und Datum wie angegeben")
    func effectiveValues() {
        let options = LaunchOptions(arguments: ["-debugCity", "madrid", "-debugDate", "2026-11-10"])
        #expect(options.effectiveCity?.id == "madrid")
        #expect(options.effectiveDate == CalendarDay("2026-11-10"))
    }

    @Test("mit -debugFixtureTimes gilt ohne -debugCity Berlin")
    func fixtureDefaultsToBerlin() {
        #expect(LaunchOptions(arguments: ["-debugFixtureTimes"]).effectiveCity?.id == "berlin")
        #expect(LaunchOptions(arguments: ["-debugFixtureTimes", "-debugCity", "jakarta"]).effectiveCity?.id == "jakarta")
        #expect(LaunchOptions(arguments: ["-debugSkipOnboarding"]).effectiveCity == nil)
    }

    @Test("die Argumente aus docs/PROMPTS.md für den Haupt-Screenshot ergeben Berlin, 14:25 Ortszeit")
    func promptsReference() throws {
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let options = LaunchOptions(arguments: ["-debugSkipOnboarding", "-debugFixtureTimes", "-debugDate", "2026-11-10", "-debugTime", "14:25"])
        #expect(options.effectiveCity?.id == "berlin")
        #expect(options.problems.isEmpty)
        let clock = try #require(options.makeClock(system: device, deviceTimeZone: .gmt) as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant("2026-11-10T13:25:00Z")))
    }

    // MARK: Uhr

    @Test("ohne Datum und Uhrzeit bleibt es bei der Gerätezeit")
    func systemClock() throws {
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let clock = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugOffline"]).makeClock(system: device)
        #expect(clock is FixedClock)
        #expect(clock.now == device.now)
    }

    @Test("Datum und Uhrzeit gelten in der Zeitzone der Stadt", arguments: [
        ("berlin", "2026-11-10", "14:25", "2026-11-10T13:25:00Z"),
        ("istanbul", "2026-11-10", "14:25", "2026-11-10T11:25:00Z"),
        ("madrid", "2026-11-10", "14:25", "2026-11-10T13:25:00Z"),
        ("mecca", "2026-11-10", "14:25", "2026-11-10T11:25:00Z"),
        ("jakarta", "2026-11-10", "17:57", "2026-11-10T10:57:00Z"),
    ])
    func clockInCityTimeZone(city: String, date: String, time: String, expected: String) throws {
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let options = LaunchOptions(arguments: ["-debugCity", city, "-debugDate", date, "-debugTime", time])
        let clock = try #require(options.makeClock(system: device, deviceTimeZone: .gmt) as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant(expected)))
    }

    @Test("ohne Stadt gelten Datum und Uhrzeit in der Zeitzone des Geräts")
    func clockInDeviceTimeZone() throws {
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let options = LaunchOptions(arguments: ["-debugDate", "2026-11-10", "-debugTime", "14:25"])
        let clock = try #require(options.makeClock(system: device, deviceTimeZone: tokyo) as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant("2026-11-10T05:25:00Z")))
    }

    @Test("nur eine Uhrzeit: heute zu dieser Zeit")
    func clockWithTimeOnly() throws {
        // 1. Januar 2030, 12:00 UTC ist in Berlin 13:00 am selben Tag.
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let options = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugTime", "07:30"])
        let clock = try #require(options.makeClock(system: device) as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant("2030-01-01T06:30:00Z")))
    }

    @Test("nur ein Datum: dieser Tag zur aktuellen Uhrzeit")
    func clockWithDateOnly() throws {
        // 13:00 Uhr Berliner Zeit bleibt 13:00 Uhr, nur am 10. November 2026.
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let options = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugDate", "2026-11-10"])
        let clock = try #require(options.makeClock(system: device) as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant("2026-11-10T12:00:00Z")))
    }

    @Test("-debugHighLatitude stellt die Uhr auf den 21. Juni 2027 in Berlin")
    func clockForHighLatitude() throws {
        let device = FixedClock(try instant("2030-01-01T12:00:00Z"))
        let options = LaunchOptions(arguments: ["-debugHighLatitude", "-debugTime", "14:25"])
        let clock = try #require(options.makeClock(system: device, deviceTimeZone: .gmt) as? DebugClock)
        // Im Juni gilt in Berlin Sommerzeit: 14:25 ist 12:25 UTC.
        #expect(device.now.addingTimeInterval(clock.offset) == (try instant("2027-06-21T12:25:00Z")))
    }
}

#endif
