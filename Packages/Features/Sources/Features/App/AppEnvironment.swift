import DesignSystem
import Foundation
import PrayerCore
import SwiftUI

/// Alles, was die App von außen bekommt: Uhr, Standortquelle, Kursquelle, Zeitenquelle, Netz-Zustand,
/// Ortssuche, der Ort der Einstellungen und womit sie startet.
///
/// Uhrzeit, Datum, Ort und Kurs laufen nur hierüber – nie direkt über `Date()` oder `CLLocationManager`.
/// In DEBUG-Builds tauschen die Debug-Startargumente einzelne Quellen gegen feste Zustände, damit sich
/// jeder Referenz-Screenshot nachstellen lässt (CLAUDE.md).
public struct AppEnvironment: Sendable {
    public var clock: any AppClock
    public var locationSource: any LocationSource
    /// Quelle des Kompasskurses für die Qibla-Seite: der Kompass des Geräts, mit `-debugQiblaHeading`
    /// ein fester Kurs.
    public var headingSource: any HeadingSource
    /// Quelle der Gebetszeiten: die echte Rechnung, mit `-debugFixtureTimes` die Mock-Zeiten.
    public var timesSource: any PrayerTimesSource
    /// Ob das Gerät ein Netz hat; mit `-debugOffline` fest „kein Netz“.
    public var connectivity: any ConnectivitySource
    /// Die Ortssuche des Stadt-Sheets; mit `-debugFixtureTimes` ohne Vorschläge, wie im Prototyp.
    public var citySearch: any CitySearching
    /// Wo die Einstellungen liegen: in den UserDefaults der App Group, mit `-debugFixtureTimes` nur im
    /// Speicher.
    public var settings: SettingsStore.Storage
    /// Wo der Stand des Nachholens liegt: in den UserDefaults der App, mit `-debugFixtureTimes` nur im
    /// Speicher und mit den Zahlen des Prototyps.
    public var qadaStorage: QadaModel.Storage
    public var initialTab: AppTab
    /// Die Seite des Gebete-Tabs beim Start.
    public var initialPage: PrayersPage
    /// Ob die Einstellungen beim Start schon offen sind (`-debugTab settings`).
    public var opensSettings: Bool
    #if DEBUG
    /// Die ausgewerteten Debug-Startargumente; der Katalog liest hier seinen Zustand.
    public var launchOptions = LaunchOptions()
    #endif

    public init(
        clock: any AppClock,
        locationSource: any LocationSource,
        headingSource: any HeadingSource = FixedHeadingSource(heading: nil),
        timesSource: any PrayerTimesSource = AdhanTimesSource(),
        connectivity: any ConnectivitySource = NetworkConnectivity(),
        citySearch: any CitySearching = NoCitySearch(),
        settings: SettingsStore.Storage = .userDefaults(suiteName: nil),
        qadaStorage: QadaModel.Storage = .userDefaults(suiteName: nil),
        initialTab: AppTab = .prayers,
        initialPage: PrayersPage = .today,
        opensSettings: Bool = false
    ) {
        self.clock = clock
        self.locationSource = locationSource
        self.headingSource = headingSource
        self.timesSource = timesSource
        self.connectivity = connectivity
        self.citySearch = citySearch
        self.settings = settings
        self.qadaStorage = qadaStorage
        self.initialTab = initialTab
        self.initialPage = initialPage
        self.opensSettings = opensSettings
    }

    /// Die Umgebung der ausgelieferten App: Gerätezeit, Standort und Kurs über Core Location, echte
    /// Rechnung, Ortssuche über MapKit, Einstellungen in der App Group, das Nachholen in den
    /// UserDefaults der App.
    public static var live: AppEnvironment {
        AppEnvironment(
            clock: SystemClock(), locationSource: CoreLocationSource(),
            headingSource: CoreLocationHeadingSource(),
            citySearch: MapKitCitySearch(),
            settings: .userDefaults(suiteName: appGroupIdentifier),
            qadaStorage: .userDefaults(suiteName: nil)
        )
    }

    /// Die Umgebung beim Start der App. In DEBUG-Builds gelten die Debug-Startargumente.
    public static func launch(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        #if DEBUG
        let options = LaunchOptions(arguments: arguments)
        // Auf die Fehlerausgabe, weil sie ungepuffert ist: Die Meldung steht sofort in der Xcode-Konsole
        // und bei `xcrun simctl launch --console`.
        for problem in options.problems {
            FileHandle.standardError.write(Data("Debug-Startargumente: \(problem)\n".utf8))
        }
        return AppEnvironment(options: options)
        #else
        return .live
        #endif
    }

    /// Eine Standortquelle ohne Ort und ohne Antwort auf die Freigabe – der Standardwert der Umgebung
    /// für Previews und Tests, die keine eigene Quelle setzen.
    static var pendingLocationSource: any LocationSource {
        FixedLocationSource(place: nil, status: .notDetermined)
    }

    /// Die App Group aus der Info.plist der App (`AppGroupIdentifier`, gefüllt aus `APP_GROUP_ID` in
    /// project.yml). In ihr liegen die Einstellungen, damit Widgets und Live-Aktivität sie lesen können.
    /// Ohne den Eintrag – etwa in Tests – gelten die Standard-Defaults.
    static var appGroupIdentifier: String? {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !identifier.isEmpty
        else { return nil }
        return identifier
    }
}

#if DEBUG

extension AppEnvironment {

    /// Die Umgebung zu einem Satz Debug-Startargumente.
    ///
    /// - `-debugFixtureTimes`: Mock-Zeiten, festes Netz, keine Ortssuche und flüchtige Einstellungen mit
    ///   den Startwerten von `S` im Prototyp – so sieht jede Aufnahme gleich aus. Das Nachholen zeigt dann
    ///   die Zahlen des Prototyps (`QadaLedger.prototypeSample`), ebenfalls nur im Speicher.
    /// - `-debugCity`, `-debugHighLatitude`, `-debugLocationDenied`: feste Standortquelle; sonst
    ///   Core Location.
    /// - `-debugQiblaHeading`, `-debugQiblaAccuracy`: fester Kompasskurs; mit `-debugFixtureTimes` auch
    ///   ohne Angabe der Startwert des Prototyps. Sonst der Kompass des Geräts.
    /// - `-debugOffline`: fest „kein Netz“.
    public init(options: LaunchOptions, system: any AppClock = SystemClock(), deviceTimeZone: TimeZone = .current) {
        clock = options.makeClock(system: system, deviceTimeZone: deviceTimeZone)
        if options.effectiveCity != nil || options.locationDenied {
            locationSource = FixedLocationSource(
                place: options.effectiveCity.map { $0.place(named: $0.localizedName) },
                status: options.locationDenied ? .denied : .authorized
            )
        } else {
            locationSource = CoreLocationSource()
        }
        if let heading = options.fixedHeading {
            headingSource = FixedHeadingSource(heading: heading)
        } else {
            headingSource = CoreLocationHeadingSource()
        }
        if options.fixtureTimes {
            timesSource = FixtureTimesSource(highLatitude: options.highLatitude)
            connectivity = FixedConnectivity(isOnline: !options.offline)
            citySearch = NoCitySearch()
            settings = .ephemeral(.prototype(city: options.effectiveCity))
            qadaStorage = .ephemeral(.prototypeSample)
        } else {
            timesSource = AdhanTimesSource()
            connectivity = options.offline ? FixedConnectivity(isOnline: false) : NetworkConnectivity()
            citySearch = MapKitCitySearch()
            settings = .userDefaults(suiteName: Self.appGroupIdentifier)
            qadaStorage = .userDefaults(suiteName: nil)
        }
        initialTab = AppTab(options.page)
        initialPage = PrayersPage(options.page)
        opensSettings = options.page == .settings
        launchOptions = options
    }
}

extension AppTab {

    /// Der Tab, in dem eine Seite aus `-debugTab` liegt. Zeiten, Qibla, Anleitung und die
    /// Einstellungen gehören zum Tab „Gebete“.
    init(_ page: LaunchOptions.Page?) {
        switch page {
        case .verses: self = .verses
        case .qada: self = .qada
        case .today, .qibla, .guide, .settings, nil: self = .prayers
        }
    }
}

extension PrayersPage {

    /// Die Seite des Gebete-Tabs zu `-debugTab`. Alles außer Qibla und Anleitung beginnt bei den Zeiten.
    init(_ page: LaunchOptions.Page?) {
        switch page {
        case .qibla: self = .qibla
        case .guide: self = .guide
        case .today, .verses, .qada, .settings, nil: self = .today
        }
    }
}

extension SettingsStore.Snapshot {

    /// Die Startwerte von `S` im Prototyp: Standort automatisch, die Stadt der Fixture als gewählte und
    /// als aktuelle Stadt (`S.city`, `S.deviceCity`), die fünf Städte aus `CITY_IDS` als gespeicherte.
    static func prototype(city: FixtureTimes.City?) -> SettingsStore.Snapshot {
        var snapshot = SettingsStore.Snapshot()
        let place = city.map { $0.place(named: $0.localizedName) }
        snapshot.manualPlace = place
        snapshot.devicePlace = place
        snapshot.savedPlaces = FixtureTimes.cities.map { $0.place(named: $0.localizedName) }
        return snapshot
    }
}

extension FixtureTimes.City {

    /// Anzeigename aus dem String Catalog (`c_berlin` …).
    var localizedName: String {
        switch id {
        case "berlin": L10n.c_berlin
        case "istanbul": L10n.c_istanbul
        case "madrid": L10n.c_madrid
        case "mecca": L10n.c_mecca
        case "jakarta": L10n.c_jakarta
        default: id
        }
    }
}

#endif

extension EnvironmentValues {

    /// Die Uhr der App. Views lesen „jetzt“ nur hierüber.
    @Entry public var appClock: any AppClock = SystemClock()

    /// Die Standortquelle der App.
    @Entry public var locationSource: any LocationSource = AppEnvironment.pendingLocationSource
}
