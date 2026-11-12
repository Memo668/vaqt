import DesignSystem
import PrayerCore
import SwiftUI

/// Wurzel der App: die System-`TabView` mit den drei Tabs Gebete, Verse und Nachholen, darüber der
/// Toast.
public struct RootView: View {
    private let environment: AppEnvironment

    @State private var selection: AppTab
    @State private var settings: SettingsStore
    @State private var toast: ToastCenter
    @State private var today: TodayModel
    @State private var qibla: QiblaModel
    @State private var guide: GuideModel

    public init(environment: AppEnvironment) {
        self.environment = environment
        let settings = SettingsStore(storage: environment.settings)
        let toast = ToastCenter()
        // Zeiten- und Qibla-Seite zeigen denselben Ort.
        let location = PlaceModel(settings: settings, locationSource: environment.locationSource)
        let today = TodayModel(
            clock: environment.clock, timesSource: environment.timesSource,
            location: location, connectivity: environment.connectivity,
            citySearch: environment.citySearch, toast: toast
        )
        _selection = State(initialValue: environment.initialTab)
        _settings = State(initialValue: settings)
        _toast = State(initialValue: toast)
        _today = State(initialValue: today)
        _qibla = State(initialValue: QiblaModel(location: location, headingSource: environment.headingSource))
        // Die Anleitung nimmt ihre Zeiten aus dem Zeitstrahl der Zeiten-Seite.
        _guide = State(initialValue: GuideModel(today: today))
    }

    public var body: some View {
        #if DEBUG
        if let section = environment.launchOptions.catalog {
            // `-debugCatalog`: der Katalog der Bausteine statt der App, für den Abgleich mit den Referenzbildern.
            CatalogRoot(section: section, environment: environment)
        } else {
            tabs
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    switch tab {
                    case .prayers:
                        PrayersTab(
                            today: today, qibla: qibla, guide: guide, initialPage: environment.initialPage,
                            opensSettings: environment.opensSettings
                        )
                    case .verses, .qada:
                        // Noch leer: Verse und Nachholen folgen in Phase 6.
                        Color.clear
                    }
                }
            }
        }
        .toasts(from: toast)
        .environment(\.appClock, environment.clock)
        .environment(\.locationSource, environment.locationSource)
    }
}
