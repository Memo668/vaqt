import Foundation
import PrayerCore
import Testing
@testable import Features

@Suite("AppTab")
struct AppTabTests {

    @Test("drei Tabs in der Reihenfolge Gebete, Verse, Nachholen")
    func order() {
        #expect(AppTab.allCases == [.prayers, .verses, .qada])
    }

    @Test("Symbole laut Design Spec")
    func symbols() {
        #expect(AppTab.allCases.map(\.systemImage) == ["moon.stars", "book", "clock.arrow.circlepath"])
    }

    @Test("jeder Tab hat einen eigenen Titel aus dem String Catalog")
    func titles() {
        let titles = AppTab.allCases.map(\.title)
        #expect(Set(titles).count == 3)
        #expect(!titles.contains { $0.isEmpty || $0.hasPrefix("nav") })
    }
}

@Suite("AppEnvironment")
struct AppEnvironmentTests {

    @Test("die ausgelieferte App nutzt die Gerätezeit und beginnt bei Gebete")
    func live() async {
        let environment = AppEnvironment.live
        #expect(environment.clock is SystemClock)
        #expect(environment.initialTab == .prayers)
        // Bis Phase 3 gibt es noch keine echte Standortquelle.
        #expect(await environment.locationSource.authorization() == .notDetermined)
        #expect(await environment.locationSource.currentPlace() == nil)
    }

    #if DEBUG

    @Test("ohne Debug-Argumente entspricht der Start der ausgelieferten App")
    func launchWithoutArguments() async {
        let environment = AppEnvironment.launch(arguments: ["Gebetszeiten"])
        #expect(environment.clock is SystemClock)
        #expect(environment.initialTab == .prayers)
        #expect(environment.launchOptions == LaunchOptions())
        #expect(await environment.locationSource.authorization() == .notDetermined)
    }

    @Test("der Start liest die Debug-Argumente")
    func launchWithArguments() {
        let environment = AppEnvironment.launch(arguments: ["Gebetszeiten", "-debugFixtureTimes", "-debugTab", "qada", "-debugTime", "14:25"])
        #expect(environment.launchOptions.fixtureTimes)
        #expect(environment.initialTab == .qada)
        #expect(environment.clock is DebugClock)
    }

    @Test("jede Seite öffnet ihren Tab", arguments: [
        (LaunchOptions.Page.today, AppTab.prayers),
        (.qibla, .prayers),
        (.guide, .prayers),
        (.settings, .prayers),
        (.verses, .verses),
        (.qada, .qada),
    ])
    func initialTab(page: LaunchOptions.Page, tab: AppTab) {
        var options = LaunchOptions()
        options.page = page
        #expect(AppEnvironment(options: options).initialTab == tab)
    }

    @Test("-debugCity liefert den Ort der Stadt")
    func city() async throws {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugCity", "jakarta"]))
        #expect(await environment.locationSource.authorization() == .authorized)
        let place = try #require(await environment.locationSource.currentPlace())
        #expect(place.countryCode == "ID")
        #expect(place.timeZoneIdentifier == "Asia/Jakarta")
        #expect(place.coordinates == FixtureTimes.city("jakarta")?.coordinates)
        #expect(!place.name.isEmpty && place.name != "c_jakarta")
    }

    @Test("-debugLocationDenied verweigert den Standort, auch mit Stadt")
    func locationDenied() async {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugCity", "berlin", "-debugLocationDenied"]))
        #expect(await environment.locationSource.authorization() == .denied)
        #expect(await environment.locationSource.requestAuthorization() == .denied)
        #expect(await environment.locationSource.currentPlace() == nil)
    }

    @Test("-debugHighLatitude liefert Berlin")
    func highLatitude() async throws {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugHighLatitude"]))
        let place = try #require(await environment.locationSource.currentPlace())
        #expect(place.countryCode == "DE")
        #expect(place.timeZoneIdentifier == "Europe/Berlin")
    }

    @Test("die Uhr folgt den Argumenten")
    func clock() throws {
        let device = FixedClock(try #require(ISO8601DateFormatter().date(from: "2030-01-01T12:00:00Z")))
        let options = LaunchOptions(arguments: ["-debugCity", "berlin", "-debugDate", "2026-11-10", "-debugTime", "14:25"])
        let environment = AppEnvironment(options: options, system: device, deviceTimeZone: .gmt)
        let clock = try #require(environment.clock as? DebugClock)
        #expect(device.now.addingTimeInterval(clock.offset) == ISO8601DateFormatter().date(from: "2026-11-10T13:25:00Z"))
    }

    #endif
}
