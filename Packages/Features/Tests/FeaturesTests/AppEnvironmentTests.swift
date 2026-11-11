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
    func live() {
        let environment = AppEnvironment.live
        #expect(environment.clock is SystemClock)
        #expect(environment.initialTab == .prayers)
        #expect(environment.initialPage == .today)
        #expect(!environment.opensSettings)
        // Echte Rechnung, das Netz des Geräts, Einstellungen in den UserDefaults. Die App Group steht in
        // der Info.plist der App; im Test gibt es die nicht, dann gelten die Standard-Defaults.
        #expect(environment.timesSource is AdhanTimesSource)
        #expect(environment.connectivity is NetworkConnectivity)
        #expect(environment.settings == .userDefaults(suiteName: nil))
        // Der Standort kommt von Core Location, die Ortssuche von MapKit.
        #expect(environment.locationSource is CoreLocationSource)
        #expect(environment.citySearch is MapKitCitySearch)
    }

    #if DEBUG

    @Test("ohne Debug-Argumente entspricht der Start der ausgelieferten App")
    func launchWithoutArguments() {
        let environment = AppEnvironment.launch(arguments: ["Gebetszeiten"])
        #expect(environment.clock is SystemClock)
        #expect(environment.initialTab == .prayers)
        #expect(environment.launchOptions == LaunchOptions())
        #expect(environment.locationSource is CoreLocationSource)
        #expect(environment.citySearch is MapKitCitySearch)
        #expect(environment.timesSource is AdhanTimesSource)
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

    @Test("-debugFixtureTimes: Mock-Zeiten, festes Netz, flüchtige Einstellungen mit den Städten des Prototyps")
    func fixtureTimes() throws {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugFixtureTimes"]))
        let source = try #require(environment.timesSource as? FixtureTimesSource)
        #expect(!source.highLatitude)
        #expect((environment.connectivity as? FixedConnectivity)?.isOnline == true)
        guard case .ephemeral(let snapshot) = environment.settings else {
            Issue.record("mit -debugFixtureTimes bleiben die Einstellungen im Speicher")
            return
        }
        #expect(snapshot.autoLocation)
        #expect(snapshot.manualPlace?.countryCode == "DE")
        #expect(snapshot.savedPlaces.map(\.countryCode) == ["DE", "TR", "ES", "SA", "ID"])
        #expect(snapshot.bells == SettingsStore.standardBells)
        // Die Ortssuche bleibt stumm: Das Sheet filtert nur die fünf Städte, wie der Prototyp.
        #expect(environment.citySearch is NoCitySearch)
        #expect(environment.locationSource is FixedLocationSource)
    }

    @Test("-debugFixtureTimes mit -debugCity: Die Stadt ist auch die gewählte")
    func fixtureCity() {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugFixtureTimes", "-debugCity", "jakarta"]))
        guard case .ephemeral(let snapshot) = environment.settings else {
            Issue.record("mit -debugFixtureTimes bleiben die Einstellungen im Speicher")
            return
        }
        #expect(snapshot.manualPlace?.countryCode == "ID")
        #expect(snapshot.devicePlace == snapshot.manualPlace)
    }

    @Test("-debugHighLatitude mit Mock-Zeiten: Berlin im Sommer")
    func fixtureHighLatitude() throws {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugFixtureTimes", "-debugHighLatitude"]))
        #expect(try #require(environment.timesSource as? FixtureTimesSource).highLatitude)
    }

    @Test("ohne -debugFixtureTimes rechnet die App echt und behält ihre Einstellungen")
    func realTimes() {
        let environment = AppEnvironment(options: LaunchOptions(arguments: ["-debugCity", "berlin", "-debugTime", "14:25"]))
        #expect(environment.timesSource is AdhanTimesSource)
        #expect(environment.connectivity is NetworkConnectivity)
        #expect(environment.settings == .userDefaults(suiteName: nil))
        #expect(environment.citySearch is MapKitCitySearch)
        // Die Stadt aus -debugCity bleibt fest; ohne sie fragt die App Core Location.
        #expect(environment.locationSource is FixedLocationSource)
        let withoutCity = AppEnvironment(options: LaunchOptions(arguments: ["-debugTime", "14:25"]))
        #expect(withoutCity.locationSource is CoreLocationSource)
    }

    @Test("-debugOffline: fest kein Netz, mit und ohne Mock-Zeiten", arguments: [
        ["-debugOffline"], ["-debugFixtureTimes", "-debugOffline"],
    ])
    func offline(arguments: [String]) {
        let environment = AppEnvironment(options: LaunchOptions(arguments: arguments))
        #expect((environment.connectivity as? FixedConnectivity)?.isOnline == false)
    }

    @Test("-debugTab wählt die Seite des Gebete-Tabs; settings öffnet die Einstellungen")
    func initialPage() {
        func environment(_ page: String) -> AppEnvironment {
            AppEnvironment(options: LaunchOptions(arguments: ["-debugTab", page]))
        }
        #expect(environment("qibla").initialPage == .qibla)
        #expect(environment("guide").initialPage == .guide)
        #expect(environment("today").initialPage == .today)
        #expect(!environment("qibla").opensSettings)
        #expect(environment("settings").opensSettings)
        #expect(environment("settings").initialPage == .today)
        #expect(environment("settings").initialTab == .prayers)
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
