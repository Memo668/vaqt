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
    /// Erlaubnis für Mitteilungen: die des Systems, mit `-debugFixtureTimes` fest „noch nicht gefragt“.
    public var notificationAuthorizer: any NotificationAuthorizing
    /// Wo die Mitteilungen vorgemerkt werden: bei iOS, mit `-debugFixtureTimes` nirgends.
    public var notificationScheduler: any NotificationScheduling
    /// Ob die App beim Start nach der Erlaubnis für Mitteilungen fragt, falls iOS noch nie gefragt hat
    /// (`-debugNotifications`). Sonst fragt nur das Onboarding und eine spätere Änderung an den Glocken.
    public var asksForNotificationsAtLaunch: Bool
    /// Wohin der Stand für die Widgets geht: in die App Group, in Tests nirgends.
    public var widgetPublisher: any WidgetPublishing
    /// Was die Debug-Startargumente an den Zeiten der Widgets ändern (`-debugFixtureTimes`,
    /// `-debugHighLatitude`); sonst `nil`.
    public var widgetDebug: WidgetSync.Debug?
    /// Wo die Live-Aktivitäten angemeldet werden: bei iOS, in Tests nirgends.
    public var liveActivityScheduler: any LiveActivityScheduling
    /// Ob die App Live-Aktivitäten plant. Mit `-debugFixtureTimes` ohne `-debugLiveActivity` nicht – damit
    /// Aufnahmen keine auslösen; was noch läuft, endet dann.
    public var plansLiveActivities: Bool
    /// `-debugLiveActivity`: Ab diesem Zeitpunkt läuft genau eine Live-Aktivität, die zum nächsten Gebet.
    public var liveActivityDebugStart: Date?
    /// Erlaubnis und Wecker zu Fadschr: über AlarmKit, mit `-debugFixtureTimes` nirgends.
    public var alarmScheduler: any FajrAlarmScheduling
    /// Ob die App die Wecker zu Fadschr anmeldet. Mit `-debugFixtureTimes` nicht – damit Aufnahmen keine
    /// auslösen.
    public var plansAlarms: Bool
    /// Wohin der Wechsel des App-Icons geht (Phase 20, Spec § 13.2): in der App ans System, in Tests und mit
    /// `-debugFixtureTimes` nur in den Speicher – Aufnahmen ändern so das Icon des Simulators nicht.
    public var appIcons: AppIconTarget
    /// `-debugAlarmIn`: ein zusätzlicher Wecker zu diesem Zeitpunkt (Uhr der App).
    public var alarmTestDate: Date?
    public var initialTab: AppTab
    /// Die Seite des Gebete-Tabs beim Start.
    public var initialPage: PrayersPage
    /// Die Seiten der Einstellungen, die beim Start im Tab „Gebete“ offen sind (`-debugTab settings`,
    /// `-debugTab method` …).
    public var settingsPath: [SettingsRoute]
    /// Ob das Adhan-Sheet beim Start offen ist (`-debugTab adhan`).
    public var opensAdhanSheet: Bool
    /// Ob das Stadt-Sheet beim Start über der Zeiten-Seite offen ist (`-debugTab city`).
    public var opensCitySheet: Bool
    /// Ob das Blatt „Was sind Verbotszeiten?“ beim Start über der Zeiten-Seite offen ist (`-debugTab kerahat`).
    public var opensKerahatSheet = false
    /// Ob das Onboarding beim Start übergangen wird (`-debugSkipOnboarding`).
    public var skipsOnboarding: Bool
    /// Tage, die die Zeiten-Seite beim Start vor oder zurück zeigt (`-debugDayOffset`); sonst heute.
    public var initialDayOffset = 0
    /// Durchlauf „Gebet Schritt für Schritt“, der beim Start offen ist: Gebet und Seite (`-debugWalk`,
    /// `-debugWalkStep`).
    public var initialWalk: (prayer: Prayer, index: Int)?
    /// Schritt, mit dem das Onboarding beim Start erscheint, auch wenn es schon durchlaufen ist
    /// (`-debugOnboarding`).
    public var onboardingStep: OnboardingStep?
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
        notificationAuthorizer: any NotificationAuthorizing = FixedNotificationAuthorizer(),
        notificationScheduler: any NotificationScheduling = NoNotificationScheduler(),
        asksForNotificationsAtLaunch: Bool = false,
        widgetPublisher: any WidgetPublishing = NoWidgetPublisher(),
        widgetDebug: WidgetSync.Debug? = nil,
        liveActivityScheduler: any LiveActivityScheduling = NoLiveActivityScheduler(),
        plansLiveActivities: Bool = true,
        liveActivityDebugStart: Date? = nil,
        alarmScheduler: any FajrAlarmScheduling = FixedFajrAlarmScheduler(),
        plansAlarms: Bool = true,
        alarmTestDate: Date? = nil,
        appIcons: AppIconTarget = .memory(),
        initialTab: AppTab = .prayers,
        initialPage: PrayersPage = .today,
        settingsPath: [SettingsRoute] = [],
        opensAdhanSheet: Bool = false,
        opensCitySheet: Bool = false,
        skipsOnboarding: Bool = false,
        onboardingStep: OnboardingStep? = nil
    ) {
        self.clock = clock
        self.locationSource = locationSource
        self.headingSource = headingSource
        self.timesSource = timesSource
        self.connectivity = connectivity
        self.citySearch = citySearch
        self.settings = settings
        self.qadaStorage = qadaStorage
        self.notificationAuthorizer = notificationAuthorizer
        self.notificationScheduler = notificationScheduler
        self.asksForNotificationsAtLaunch = asksForNotificationsAtLaunch
        self.widgetPublisher = widgetPublisher
        self.widgetDebug = widgetDebug
        self.liveActivityScheduler = liveActivityScheduler
        self.plansLiveActivities = plansLiveActivities
        self.liveActivityDebugStart = liveActivityDebugStart
        self.alarmScheduler = alarmScheduler
        self.plansAlarms = plansAlarms
        self.alarmTestDate = alarmTestDate
        self.appIcons = appIcons
        self.initialTab = initialTab
        self.initialPage = initialPage
        self.settingsPath = settingsPath
        self.opensAdhanSheet = opensAdhanSheet
        self.opensCitySheet = opensCitySheet
        self.skipsOnboarding = skipsOnboarding
        self.onboardingStep = onboardingStep
    }

    /// Die Umgebung der ausgelieferten App: Gerätezeit, Standort und Kurs über Core Location, echte
    /// Rechnung, Ortssuche über MapKit, Einstellungen in der App Group, das Nachholen in den
    /// UserDefaults der App, Erlaubnis und Mitteilungen über das System.
    public static var live: AppEnvironment {
        AppEnvironment(
            clock: SystemClock(), locationSource: CoreLocationSource(),
            headingSource: CoreLocationHeadingSource(),
            citySearch: MapKitCitySearch(),
            settings: .userDefaults(suiteName: appGroupIdentifier),
            qadaStorage: .userDefaults(suiteName: nil),
            notificationAuthorizer: SystemNotificationAuthorizer(),
            notificationScheduler: SystemNotificationScheduler(),
            widgetPublisher: AppGroupWidgetPublisher(suiteName: appGroupIdentifier),
            liveActivityScheduler: SystemLiveActivityScheduler(),
            alarmScheduler: SystemFajrAlarmScheduler(),
            appIcons: .system
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
    /// - `-debugNotifications`: Erlaubnis und Mitteilungen über das System, auch mit `-debugFixtureTimes`;
    ///   beim Start fragt die App nach der Erlaubnis, falls iOS noch nie gefragt hat. So lässt sich
    ///   `system/92` mit den Mock-Zeiten nachstellen.
    /// - `-debugLiveActivity`: genau eine Live-Aktivität, die zum nächsten Gebet, ab dem Start der App –
    ///   auch außerhalb des Vorlaufs und mit Mock-Zeiten. So lassen sich `system/93`–`96` nachstellen.
    ///   Die Widgets bekommen Mock-Zeiten und Debug-Uhr über die App Group.
    /// - `-debugAlarm`: der Wecker zu Fadschr an oder die Erlaubnis abgelehnt, nur im Speicher und ohne
    ///   echte Wecker – für `iphone/24` und `iphone/84`. Mit Mock-Zeiten meldet die App sonst keine Wecker an.
    /// - `-debugAlarmIn`: ein echter Wecker über AlarmKit, so viele Minuten nach dem Start.
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
            settings = .ephemeral(.prototype(
                city: options.effectiveCity, alarm: options.alarm, madhab: options.madhab, sound: options.sound, style: options.style
            ))
            qadaStorage = .ephemeral(.prototypeSample)
        } else {
            timesSource = AdhanTimesSource()
            connectivity = options.offline ? FixedConnectivity(isOnline: false) : NetworkConnectivity()
            citySearch = MapKitCitySearch()
            settings = .userDefaults(suiteName: Self.appGroupIdentifier)
            qadaStorage = .userDefaults(suiteName: nil)
        }
        if options.fixtureTimes, !options.notifications {
            // `S.notifAllowed: null` – noch nicht gefragt; „Mitteilungen erlauben“ wird erlaubt. Vorgemerkt
            // wird nichts, damit Aufnahmen keine Mitteilungen auslösen.
            notificationAuthorizer = FixedNotificationAuthorizer()
            notificationScheduler = NoNotificationScheduler()
        } else {
            notificationAuthorizer = SystemNotificationAuthorizer()
            notificationScheduler = SystemNotificationScheduler()
        }
        asksForNotificationsAtLaunch = options.notifications
        // Die Widgets zeigen dieselben Zeiten wie die App: Mock-Zeiten und Debug-Uhr gehen mit in die App
        // Group.
        widgetPublisher = AppGroupWidgetPublisher(suiteName: Self.appGroupIdentifier)
        widgetDebug = options.fixtureTimes
            ? WidgetSync.Debug(fixtureTimes: true, highLatitude: options.highLatitude) : nil
        // Mit Mock-Zeiten plant die App Live-Aktivitäten nur mit `-debugLiveActivity`, damit Aufnahmen keine
        // auslösen – wie die Mitteilungen. Was von einem früheren Lauf noch läuft, endet.
        liveActivityScheduler = SystemLiveActivityScheduler()
        plansLiveActivities = !options.fixtureTimes || options.liveActivity
        liveActivityDebugStart = options.liveActivity ? clock.now : nil
        // Mit Mock-Zeiten meldet die App keine Wecker an; `-debugAlarm` setzt nur den Stand der Erlaubnis.
        // `-debugAlarmIn` stellt immer einen echten Wecker.
        if options.fixtureTimes, options.alarmInMinutes == nil {
            alarmScheduler = FixedFajrAlarmScheduler(status: options.alarm.map { $0 == .denied ? .denied : .authorized } ?? .notDetermined)
        } else {
            alarmScheduler = SystemFajrAlarmScheduler()
        }
        plansAlarms = !options.fixtureTimes
        // Mit Mock-Zeiten (flüchtige Einstellungen) wechselt das Icon nur im Speicher, sonst wie in der App.
        appIcons = options.fixtureTimes ? .memory() : .system
        if let minutes = options.alarmInMinutes {
            alarmTestDate = clock.now.addingTimeInterval(TimeInterval(minutes * 60))
        } else {
            alarmTestDate = nil
        }
        initialTab = AppTab(options.page)
        // Der Durchlauf liegt über der Anleitung; ohne `-debugTab` ist sie die Seite darunter.
        initialPage = options.walkPrayer != nil && options.page == nil ? .guide : PrayersPage(options.page)
        settingsPath = options.page?.settingsRoute?.path ?? []
        opensAdhanSheet = options.page == .adhan
        opensCitySheet = options.page == .city
        opensKerahatSheet = options.page == .kerahat
        skipsOnboarding = options.skipOnboarding && options.onboardingStep == nil
        onboardingStep = options.onboardingStep.flatMap { OnboardingStep(rawValue: $0 - 1) }
        initialDayOffset = options.dayOffset
        initialWalk = options.walkPrayer.map { ($0, options.walkStep) }
        launchOptions = options
    }
}

extension AppTab {

    /// Der Tab, in dem eine Seite aus `-debugTab` liegt. Zeiten, Qibla, Anleitung, die Einstellungen,
    /// das Adhan- und das Stadt-Sheet gehören zum Tab „Gebete“.
    init(_ page: LaunchOptions.Page?) {
        switch page {
        case .verses: self = .verses
        case .qada: self = .qada
        default: self = .prayers
        }
    }
}

extension PrayersPage {

    /// Die Seite des Gebete-Tabs zu `-debugTab`. Alles außer Qibla und Anleitung beginnt bei den Zeiten.
    init(_ page: LaunchOptions.Page?) {
        switch page {
        case .qibla: self = .qibla
        case .guide: self = .guide
        default: self = .today
        }
    }
}

extension SettingsStore.Snapshot {

    /// Die Startwerte von `S` im Prototyp: Standort automatisch, die Stadt der Fixture als gewählte und
    /// als aktuelle Stadt (`S.city`, `S.deviceCity`), die fünf Städte aus `CITY_IDS` als gespeicherte.
    static func prototype(
        city: FixtureTimes.City?, alarm: LaunchOptions.AlarmState? = nil, madhab: Madhab? = nil, sound: NotificationSound? = nil,
        style: AppStyle? = nil
    ) -> SettingsStore.Snapshot {
        var snapshot = SettingsStore.Snapshot()
        if let style {
            snapshot.style = style
        }
        if let madhab {
            snapshot.calculation.madhab = madhab
        }
        if let sound {
            snapshot.notifications.sound = sound
        }
        switch alarm {
        case .before: snapshot.fajrAlarm = FajrAlarmPreferences(isOn: true)
        case .fixed: snapshot.fajrAlarm = FajrAlarmPreferences(isOn: true, mode: .fixedTime, sound: .adhan)
        case .denied, nil: break
        }
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
