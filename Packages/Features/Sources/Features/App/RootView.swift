import DesignSystem
import PrayerCore
import SwiftUI
import UIKit

/// Wurzel der App: Einstellungen, Sprache, Erscheinungsbild und wo man in der App steht. Darunter liegt
/// der Inhalt (`AppContent`).
///
/// Wählt man unter Einstellungen › Sprache eine andere Sprache, baut sich der Inhalt mit den neuen Texten
/// neu auf. Die Einstellungen und der Stand der Navigation liegen hier und bleiben dabei erhalten.
public struct RootView: View {
    private let environment: AppEnvironment

    @State private var settings: SettingsStore
    @State private var navigation: AppNavigation

    public init(environment: AppEnvironment) {
        self.environment = environment
        // `init` läuft bei jeder Auswertung der App; nur der erste Speicher bleibt (`@State`). Deshalb hier
        // keine Wirkung nach außen – die Sprache übernimmt `content` aus dem Speicher, der gilt.
        let settings = SettingsStore(storage: environment.settings)
        _settings = State(initialValue: settings)
        // Das Onboarding erscheint beim ersten Start; `-debugOnboarding` zeigt es auch danach,
        // `-debugSkipOnboarding` übergeht es.
        let showsOnboarding = !settings.onboardingCompleted && !environment.skipsOnboarding
        let navigation = AppNavigation(
            tab: environment.initialTab, prayersPage: environment.initialPage,
            settingsPath: environment.settingsPath, isAdhanSheetPresented: environment.opensAdhanSheet,
            opensCitySheetOnAppear: environment.opensCitySheet,
            onboardingStep: environment.onboardingStep ?? (showsOnboarding ? .welcome : nil)
        )
        navigation.opensKerahatSheetOnAppear = environment.opensKerahatSheet
        _navigation = State(initialValue: navigation)
    }

    public var body: some View {
        #if DEBUG
        if let section = environment.launchOptions.catalog {
            // `-debugCatalog`: der Katalog der Bausteine statt der App, für den Abgleich mit den Referenzbildern.
            CatalogRoot(section: section, environment: environment)
        } else {
            content
        }
        #else
        content
        #endif
    }

    private var content: some View {
        // Die Texte folgen der gewählten Sprache, bevor der Inhalt sie liest. Ändert sie sich, baut sich
        // der Inhalt neu auf (`id`); wo man steht, bleibt in `navigation`.
        L10n.chosenLanguage = settings.language
        return AppContent(environment: environment, settings: settings, navigation: navigation)
            .id(settings.language)
            // Wo die senkrechte Leiste steht (iPhone Duo), für die obere Leiste und die Abstände der Seiten.
            .readsVerticalBarEdge()
            .environment(\.locale, L10n.locale)
            // Arabisch, Urdu und Persisch von rechts nach links – auch wenn das Gerät eine andere Sprache spricht,
            // und umgekehrt (Spec § 9.10).
            .environment(\.layoutDirection, L10n.layoutDirection)
            .preferredColorScheme(settings.appearance.colorScheme)
            // Die Grundfarbe aus Einstellungen › Stil (Spec § 11.7) für die Bedienelemente des Systems – statt des
            // Assets `AccentColor`, das nur noch für den Start gilt. Dialoge des Systems nehmen die Farbe des Fensters.
            .tint(Palette.accent)
            .onChange(of: settings.style.accent, initial: true) { _, accent in
                WindowTint.apply(accent)
            }
    }
}

/// Die Farbe der Fenster der App: Dialoge des Systems (`UIAlertController`) und Teilen-Blätter nehmen sie, nicht
/// die Farbe von SwiftUI.
@MainActor
enum WindowTint {
    static func apply(_ accent: AccentColorID) {
        let color = UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? accent.dark : accent.light
            return UIColor(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
        }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            for window in scene.windows {
                window.tintColor = color
            }
        }
    }
}

/// Der Inhalt der App: beim ersten Start das Onboarding, sonst die System-`TabView` mit den drei Tabs
/// Gebete, Verse und Nachholen; darüber das Stadt-Sheet und der Toast. Hier entstehen die Modelle der
/// Seiten – in der Sprache, die gerade gilt.
struct AppContent: View {
    let environment: AppEnvironment
    @Bindable var navigation: AppNavigation

    @State private var onboarding: OnboardingModel
    @State private var adhan: AdhanPlayerModel
    @State private var toast: ToastCenter
    @State private var today: TodayModel
    @State private var qibla: QiblaModel
    @State private var guide: GuideModel
    @State private var verses: VersesModel
    @State private var qada: QadaModel
    @State private var settingsModel: SettingsModel
    @State private var notifications: NotificationModel
    @State private var widgets: WidgetSync
    @State private var liveActivities: LiveActivityModel
    @State private var alarm: FajrAlarmModel
    /// Innen auf dem iPhone Duo (regular) erscheinen die Sheets als mittige Karte.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(environment: AppEnvironment, settings: SettingsStore, navigation: AppNavigation) {
        self.environment = environment
        self.navigation = navigation
        let toast = ToastCenter()
        // Zeiten- und Qibla-Seite zeigen denselben Ort; die Mitteilungen gelten für ihn.
        let location = PlaceModel(settings: settings, locationSource: environment.locationSource)
        let notifications = NotificationModel(
            settings: settings, location: location, clock: environment.clock,
            timesSource: environment.timesSource, authorizer: environment.notificationAuthorizer,
            scheduler: environment.notificationScheduler
        )
        _notifications = State(initialValue: notifications)
        // Widgets und Live-Aktivität zeigen denselben Ort wie die Zeiten-Seite.
        _widgets = State(initialValue: WidgetSync(
            settings: settings, location: location, clock: environment.clock,
            publisher: environment.widgetPublisher, debug: environment.widgetDebug
        ))
        _liveActivities = State(initialValue: LiveActivityModel(
            settings: settings, location: location, clock: environment.clock,
            timesSource: environment.timesSource, scheduler: environment.liveActivityScheduler,
            isPlanning: environment.plansLiveActivities, debugStart: environment.liveActivityDebugStart
        ))
        // Der Wecker zu Fadschr folgt demselben Ort.
        _alarm = State(initialValue: FajrAlarmModel(
            settings: settings, location: location, clock: environment.clock,
            timesSource: environment.timesSource, scheduler: environment.alarmScheduler,
            isPlanning: environment.plansAlarms, testDate: environment.alarmTestDate
        ))
        let today = TodayModel(
            clock: environment.clock, timesSource: environment.timesSource,
            location: location, connectivity: environment.connectivity,
            citySearch: environment.citySearch, toast: toast
        )
        today.show(dayOffset: environment.initialDayOffset)
        _toast = State(initialValue: toast)
        _today = State(initialValue: today)
        _qibla = State(initialValue: QiblaModel(location: location, headingSource: environment.headingSource))
        // Die Anleitung nimmt ihre Zeiten aus dem Zeitstrahl der Zeiten-Seite.
        let guide = GuideModel(today: today)
        if let walk = environment.initialWalk {
            guide.startWalk(prayer: walk.prayer, at: walk.index)
        }
        _guide = State(initialValue: guide)
        // Verse und Nachholen beginnen ihren Tag um Mitternacht am Ort der Zeiten-Seite.
        _verses = State(initialValue: VersesModel(clock: environment.clock, location: location, toast: toast))
        _qada = State(initialValue: QadaModel(
            storage: environment.qadaStorage, clock: environment.clock, location: location, toast: toast
        ))
        _settingsModel = State(initialValue: SettingsModel(
            settings: settings, today: today, navigation: navigation,
            timesSource: environment.timesSource, notificationAuthorizer: environment.notificationAuthorizer,
            sourceCodeURL: AppInfo.sourceCodeURL, appStoreURL: AppInfo.appStoreURL, version: AppInfo.version
        ))
        _onboarding = State(initialValue: OnboardingModel(navigation: navigation, today: today, notifications: notifications))
        _adhan = State(initialValue: AdhanPlayerModel())
    }

    var body: some View {
        @Bindable var today = today
        Group {
            if navigation.onboardingStep != nil {
                OnboardingView(model: onboarding)
                    .transition(.opacity)
            } else {
                tabs
                    .transition(.opacity)
                    .onAppear(perform: openCitySheetIfRequested)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: navigation.onboardingStep == nil)
        // Das Stadt-Sheet öffnen die Zeiten-Seite, die Qibla-Seite, die Einstellungen jedes Tabs und das
        // Onboarding.
        .sheet(isPresented: $today.isCitySheetPresented) {
            CitySheet(today: today, search: today.citySearch)
                .centeredSheetCard(isRegular: horizontalSizeClass == .regular)
        }
        // Der Infopunkt einer Kerahat-Zeile (Spec § 10.2).
        .sheet(isPresented: $today.isKerahatInfoPresented) {
            KerahatInfoSheet(times: today.shownDayTimes, madhab: today.settings.calculation.madhab)
                .centeredSheetCard(isRegular: horizontalSizeClass == .regular)
        }
        // „Adhan anhören“ in den Einstellungen; Schließen hält die Wiedergabe an.
        .sheet(isPresented: $navigation.isAdhanSheetPresented, onDismiss: adhan.stop) {
            AdhanSheet(model: adhan)
                .centeredSheetCard(isRegular: horizontalSizeClass == .regular)
        }
        // Plant die Mitteilungen beim Start, wenn die App nach vorn kommt und nach jeder Änderung.
        .background {
            NotificationPlanning(model: notifications, asksAtLaunch: environment.asksForNotificationsAtLaunch)
        }
        // Widgets und Live-Aktivitäten ebenso; dabei enden alte Aktivitäten.
        .background {
            OutsideAppPlanning(widgets: widgets, liveActivities: liveActivities, clock: environment.clock)
        }
        // Die Wecker zu Fadschr ebenso (Spec § 10.8).
        .background {
            FajrAlarmPlanning(model: alarm)
        }
        .environment(settingsModel)
        .environment(alarm)
        .toasts(from: toast)
        .environment(\.appClock, environment.clock)
        .environment(\.locationSource, environment.locationSource)
    }

    /// `-debugTab city`: das Stadt-Sheet über der Zeiten-Seite, einmal beim ersten Erscheinen der Tabs.
    private func openCitySheetIfRequested() {
        if navigation.opensKerahatSheetOnAppear {
            navigation.opensKerahatSheetOnAppear = false
            today.isKerahatInfoPresented = true
        }
        guard navigation.opensCitySheetOnAppear else { return }
        navigation.opensCitySheetOnAppear = false
        today.isCitySheetPresented = true
    }

    private var tabs: some View {
        TabView(selection: $navigation.tab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    switch tab {
                    case .prayers:
                        PrayersTab(
                            today: today, qibla: qibla, guide: guide,
                            page: $navigation.prayersPage, path: $navigation.prayersPath
                        )
                    case .verses:
                        VersesTab(model: verses, path: $navigation.versesPath)
                    case .qada:
                        QadaTab(model: qada, path: $navigation.qadaPath)
                    }
                }
            }
        }
    }
}

/// Angaben aus der Info.plist der App.
enum AppInfo {

    /// Die Bundle-ID der App (`APP_BUNDLE_ID` in project.yml): Subsystem des Protokolls und Anfang der
    /// Kennung der Hintergrundaktualisierung. So steht sie nur in project.yml.
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Gebetszeiten"
    }

    /// „0.1.0 (1)“ – Version und Build (`CFBundleShortVersionString`, `CFBundleVersion`).
    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "–"
        let build = info["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }

    /// Adresse des Quellcodes (`SourceCodeURL`, gefüllt aus `SOURCE_CODE_URL` in project.yml).
    static var sourceCodeURL: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "SourceCodeURL") as? String)
            .flatMap { $0.isEmpty ? nil : URL(string: $0) }
    }

    /// Adresse für „App weiterempfehlen“ (`AppStoreURL`, gefüllt aus `APP_STORE_URL` in project.yml): während
    /// der Beta die Einladung zu TestFlight, danach die Seite der App im App Store.
    static var appStoreURL: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "AppStoreURL") as? String)
            .flatMap { $0.isEmpty ? nil : URL(string: $0) }
    }
}
