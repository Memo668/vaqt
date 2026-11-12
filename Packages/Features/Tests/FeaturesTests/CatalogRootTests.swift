#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// `-debugCatalog` zeigt den Katalog der Bausteine statt der Tabs – im Zustand der übrigen Argumente.
@Suite("Debug-Katalog")
struct CatalogRootTests {

    private func environment(_ arguments: String...) -> AppEnvironment {
        AppEnvironment(options: LaunchOptions(arguments: arguments))
    }

    // MARK: Argument

    @Test("jeder Abschnitt lässt sich wählen", arguments: ComponentCatalog.Section.allCases)
    func sections(section: ComponentCatalog.Section) {
        let options = LaunchOptions(arguments: ["-debugCatalog", section.rawValue])
        #expect(options.catalog == section)
        #expect(options.problems.isEmpty)
    }

    @Test("ohne das Argument startet die App wie immer")
    func absent() {
        #expect(LaunchOptions(arguments: ["-debugSkipOnboarding", "-debugFixtureTimes"]).catalog == nil)
    }

    @Test("ein unbekannter Abschnitt wird gemeldet und nicht übernommen")
    func unknownSection() {
        let options = LaunchOptions(arguments: ["-debugCatalog", "bogen"])
        #expect(options.catalog == nil)
        #expect(options.problems.count == 1)
        #expect(options.problems.first?.contains("arc, rows, glass, cards, compass, guide, steps, verses, qada, all") == true)
    }

    @Test("fehlt der Abschnitt, wird das gemeldet und das nächste Argument trotzdem gelesen")
    func missingSection() {
        let options = LaunchOptions(arguments: ["-debugCatalog", "-debugFixtureTimes"])
        #expect(options.catalog == nil)
        #expect(options.fixtureTimes)
        #expect(options.problems.count == 1)
    }

    // MARK: Zustand

    @Test("die Argumente von iphone/10: Berlin, 14:25, Asr läuft, Maghrib ist das Nächste")
    func mainReference() throws {
        let environment = environment(
            "-debugCatalog", "arc", "-debugSkipOnboarding", "-debugFixtureTimes",
            "-debugDate", "2026-11-10", "-debugTime", "14:25"
        )
        let phase = try #require(CatalogRoot.phase(for: environment))
        #expect(phase.highlighted == .asr)
        #expect(phase.next.prayer == .maghrib)
        #expect(phase.times.clockTime(of: .maghrib) == ClockTime("16:27"))
        #expect(phase.times.day == CalendarDay("2026-11-10"))
        // Die Uhr läuft ab 14:25 weiter; bis zum Lesen vergehen höchstens ein paar Sekunden.
        #expect((7310...7320).contains(phase.remaining))
    }

    @Test("die Argumente von iphone/22: Jakarta, 17:57, Maghrib läuft")
    func jakarta() throws {
        let environment = environment(
            "-debugCatalog", "arc", "-debugFixtureTimes", "-debugCity", "jakarta",
            "-debugDate", "2026-11-10", "-debugTime", "17:57"
        )
        let phase = try #require(CatalogRoot.phase(for: environment))
        #expect(phase.highlighted == .maghrib)
        #expect(phase.next.prayer == .isha)
        #expect(phase.times.clockTime(of: .isha) == ClockTime("19:01"))
        #expect(phase.times.timeZone.identifier == "Asia/Jakarta")
    }

    @Test("vor Fadschr und nach Ischa", arguments: [
        ("05:14", nil, Prayer.fajr, false),
        ("23:30", Prayer.isha, Prayer.fajr, true),
    ])
    func edgesOfTheDay(time: String, highlighted: Prayer?, next: Prayer, tomorrow: Bool) throws {
        let environment = environment(
            "-debugCatalog", "rows", "-debugFixtureTimes", "-debugDate", "2026-11-10", "-debugTime", time
        )
        let phase = try #require(CatalogRoot.phase(for: environment))
        #expect(phase.highlighted == highlighted)
        #expect(phase.next.prayer == next)
        #expect(phase.isNextTomorrow == tomorrow)
    }

    @Test("ohne -debugFixtureTimes rechnet der Katalog echt: Berlin mit Diyanet, Maghrib um 16:28")
    func realCalculation() throws {
        let environment = environment(
            "-debugCatalog", "arc", "-debugCity", "berlin", "-debugDate", "2026-11-10", "-debugTime", "14:25"
        )
        let phase = try #require(CatalogRoot.phase(for: environment))
        #expect(phase.highlighted == .asr)
        #expect(phase.times.clockTime(of: .maghrib) == ClockTime("16:28"))
    }

    @Test("mit -debugHighLatitude gelten die Sommerzeiten aus dem Prototyp")
    func highLatitude() throws {
        let environment = environment(
            "-debugCatalog", "rows", "-debugFixtureTimes", "-debugHighLatitude", "-debugTime", "23:47"
        )
        let phase = try #require(CatalogRoot.phase(for: environment))
        #expect(phase.times.day == CalendarDay("2027-06-21"))
        #expect(phase.times.clockTime(of: .fajr) == ClockTime("02:34"))
        #expect(phase.times.clockTime(of: .isha) == ClockTime("23:35"))
        #expect(phase.highlighted == .isha)
    }

    @Test("ohne Stadt gibt es keinen Zustand; der Katalog zeigt dann seinen eigenen")
    func withoutCity() {
        #expect(CatalogRoot.phase(for: environment("-debugCatalog", "all")) == nil)
        #expect(CatalogRoot.compass(for: environment("-debugCatalog", "all")) == nil)
        #expect(CatalogRoot.guide(for: environment("-debugCatalog", "all")) == nil)
    }

    // MARK: Anleitung

    @Test("die Argumente von iphone/40: Asr läuft, 14:00–16:27")
    func guide() throws {
        let environment = environment(
            "-debugCatalog", "guide", "-debugFixtureTimes", "-debugDate", "2026-11-10", "-debugTime", "14:25"
        )
        let header = try #require(CatalogRoot.guide(for: environment))
        #expect(header.prayer == .asr)
        #expect(header.status == L10n.now)
        #expect(header.window == "14:00\u{2060}–\u{2060}16:27")
        #expect(header.returnPrayer == nil)
    }

    @Test("am Vormittag folgt die Anleitung im Katalog dem nächsten Gebet")
    func guideMorning() throws {
        let environment = environment(
            "-debugCatalog", "guide", "-debugFixtureTimes", "-debugDate", "2026-11-10", "-debugTime", "08:04"
        )
        let header = try #require(CatalogRoot.guide(for: environment))
        #expect(header.prayer == .dhuhr)
        #expect(header.status == L10n.guideNext)
    }

    // MARK: Kompass

    @Test("die Argumente von iphone/31: Berlin, Kurs 137°, ausgerichtet")
    func compassAligned() throws {
        let environment = environment("-debugCatalog", "compass", "-debugFixtureTimes", "-debugQiblaHeading", "137")
        let state = try #require(CatalogRoot.compass(for: environment))
        let bearing = try #require(state.bearing)
        #expect(state.heading == 137)
        #expect(abs(bearing - 136.68) < 0.01)
        #expect(state.isAligned)
    }

    @Test("mit -debugFixtureTimes ohne Kurs: der Startwert des Prototyps, 99°")
    func compassPrototypeStart() throws {
        let state = try #require(CatalogRoot.compass(for: environment("-debugCatalog", "compass", "-debugFixtureTimes")))
        #expect(state.heading == 99)
        #expect(!state.isAligned)
    }

    @Test("die Argumente von iphone/32: in Mekka fehlt die Richtung und damit die Nadel")
    func compassMecca() throws {
        let environment = environment(
            "-debugCatalog", "compass", "-debugFixtureTimes", "-debugCity", "mecca", "-debugQiblaHeading", "138"
        )
        let state = try #require(CatalogRoot.compass(for: environment))
        #expect(state.heading == 138)
        #expect(state.bearing == nil)
    }

    @Test("ohne festen Kurs zeigt der Katalog den Kompass eines Geräts ohne Kompass")
    func compassWithoutHeading() throws {
        let state = try #require(CatalogRoot.compass(for: environment("-debugCatalog", "compass", "-debugCity", "jakarta")))
        let bearing = try #require(state.bearing)
        #expect(state.heading == nil)
        #expect(Int(bearing.rounded()) == 295)
    }

    @Test("nur ein Kurs, keine Stadt: Berlin")
    func compassHeadingOnly() throws {
        let state = try #require(CatalogRoot.compass(for: environment("-debugCatalog", "compass", "-debugQiblaHeading", "98")))
        let bearing = try #require(state.bearing)
        #expect(state.heading == 98)
        #expect(Int(bearing.rounded()) == 137)
    }
}

#endif
