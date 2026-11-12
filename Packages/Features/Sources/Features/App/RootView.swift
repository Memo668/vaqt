import DesignSystem
import PrayerCore
import SwiftUI

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
        let settings = SettingsStore(storage: environment.settings)
        // Die gespeicherte Sprache gilt, bevor der erste Text gelesen wird.
        L10n.chosenLanguage = settings.language
        _settings = State(initialValue: settings)
        // Das Onboarding erscheint beim ersten Start; `-debugOnboarding` zeigt es auch danach,
        // `-debugSkipOnboarding` übergeht es.
        let showsOnboarding = !settings.onboardingCompleted && !environment.skipsOnboarding
        _navigation = State(initialValue: AppNavigation(
            tab: environment.initialTab, prayersPage: environment.initialPage,
            settingsPath: environment.settingsPath, isAdhanSheetPresented: environment.opensAdhanSheet,
            onboardingStep: environment.onboardingStep ?? (showsOnboarding ? .welcome : nil)
        ))
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
        AppContent(environment: environment, settings: settings, navigation: navigation)
            .id(settings.language)
            .environment(\.locale, L10n.locale)
            .preferredColorScheme(settings.appearance.colorScheme)
    }
}

/// Der Inhalt der App: beim ersten Start das Onboarding, sonst die System-`TabView` mit den drei Tabs
/// Gebete, Verse und Nachholen; darüber das Stadt-Sheet und der Toast. Hier entstehen die Modelle der
/// Seiten – in der Sprache, die gerade gilt.
struct AppContent: View {
    let environment: AppEnvironment
    @Bindable var navigation: AppNavigation

    @State private var onboarding: OnboardingModel
    @State private var toast: ToastCenter
    @State private var today: TodayModel
    @State private var qibla: QiblaModel
    @State private var guide: GuideModel
    @State private var verses: VersesModel
    @State private var qada: QadaModel
    @State private var settingsModel: SettingsModel

    init(environment: AppEnvironment, settings: SettingsStore, navigation: AppNavigation) {
        self.environment = environment
        self.navigation = navigation
        let toast = ToastCenter()
        // Zeiten- und Qibla-Seite zeigen denselben Ort.
        let location = PlaceModel(settings: settings, locationSource: environment.locationSource)
        let today = TodayModel(
            clock: environment.clock, timesSource: environment.timesSource,
            location: location, connectivity: environment.connectivity,
            citySearch: environment.citySearch, toast: toast
        )
        _toast = State(initialValue: toast)
        _today = State(initialValue: today)
        _qibla = State(initialValue: QiblaModel(location: location, headingSource: environment.headingSource))
        // Die Anleitung nimmt ihre Zeiten aus dem Zeitstrahl der Zeiten-Seite.
        _guide = State(initialValue: GuideModel(today: today))
        // Verse und Nachholen beginnen ihren Tag um Mitternacht am Ort der Zeiten-Seite.
        _verses = State(initialValue: VersesModel(clock: environment.clock, location: location, toast: toast))
        _qada = State(initialValue: QadaModel(
            storage: environment.qadaStorage, clock: environment.clock, location: location, toast: toast
        ))
        _settingsModel = State(initialValue: SettingsModel(
            settings: settings, today: today, navigation: navigation,
            timesSource: environment.timesSource, notificationAuthorizer: environment.notificationAuthorizer,
            sourceCodeURL: AppInfo.sourceCodeURL, version: AppInfo.version
        ))
        _onboarding = State(initialValue: OnboardingModel(
            navigation: navigation, today: today, notificationAuthorizer: environment.notificationAuthorizer
        ))
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
            }
        }
        .animation(.easeInOut(duration: 0.35), value: navigation.onboardingStep == nil)
        // Das Stadt-Sheet öffnen die Zeiten-Seite, die Qibla-Seite, die Einstellungen jedes Tabs und das
        // Onboarding.
        .sheet(isPresented: $today.isCitySheetPresented) {
            CitySheet(today: today, search: today.citySearch)
        }
        .environment(settingsModel)
        .toasts(from: toast)
        .environment(\.appClock, environment.clock)
        .environment(\.locationSource, environment.locationSource)
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
}
