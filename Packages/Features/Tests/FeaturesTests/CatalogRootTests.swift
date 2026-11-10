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
        #expect(options.problems.first?.contains("arc, rows, glass, cards, all") == true)
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
    }
}

#endif
