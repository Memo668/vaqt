import DesignSystem
import Foundation
import PrayerCore
import SwiftUI

/// Alles, was die App von außen bekommt: Uhr, Standortquelle und der Tab beim Start.
///
/// Uhrzeit, Datum und Ort laufen nur hierüber – nie direkt über `Date()` oder `CLLocationManager`.
public struct AppEnvironment: Sendable {
    public var clock: any AppClock
    public var locationSource: any LocationSource
    public var initialTab: AppTab
    #if DEBUG
    /// Die ausgewerteten Debug-Startargumente; spätere Phasen lesen hier z. B. `fixtureTimes`.
    public var launchOptions = LaunchOptions()
    #endif

    public init(clock: any AppClock, locationSource: any LocationSource, initialTab: AppTab = .prayers) {
        self.clock = clock
        self.locationSource = locationSource
        self.initialTab = initialTab
    }

    /// Die Umgebung der ausgelieferten App.
    public static var live: AppEnvironment {
        AppEnvironment(clock: SystemClock(), locationSource: Self.pendingLocationSource)
    }

    /// Die Umgebung beim Start der App. In DEBUG-Builds gelten die Debug-Startargumente.
    public static func launch(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        #if DEBUG
        let options = LaunchOptions(arguments: arguments)
        for problem in options.problems {
            print("Debug-Startargumente: \(problem)")
        }
        return AppEnvironment(options: options)
        #else
        return .live
        #endif
    }

    /// Platzhalter, bis Phase 3 die Standortquelle mit Core Location bringt: kein Ort, noch nicht gefragt.
    static var pendingLocationSource: any LocationSource {
        FixedLocationSource(place: nil, status: .notDetermined)
    }
}

#if DEBUG

extension AppEnvironment {

    /// Die Umgebung zu einem Satz Debug-Startargumente.
    public init(options: LaunchOptions, system: any AppClock = SystemClock(), deviceTimeZone: TimeZone = .current) {
        clock = options.makeClock(system: system, deviceTimeZone: deviceTimeZone)
        if options.effectiveCity != nil || options.locationDenied {
            locationSource = FixedLocationSource(
                place: options.effectiveCity.map { $0.place(named: $0.localizedName) },
                status: options.locationDenied ? .denied : .authorized
            )
        } else {
            locationSource = Self.pendingLocationSource
        }
        initialTab = AppTab(options.page)
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
