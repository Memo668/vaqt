import Features
import SwiftUI

@main
struct GebetszeitenApp: App {
    /// Uhr, Standortquelle und Start-Tab. In DEBUG-Builds gelten die Debug-Startargumente (CLAUDE.md).
    private let environment = AppEnvironment.launch()

    init() {
        // Mitteilungen auch bei offener App zeigen; der Delegate muss vor dem Ende des Starts stehen.
        NotificationPresenter.install()
    }

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
        // Etwa einmal am Tag weckt iOS die App kurz im Hintergrund; sie plant die Mitteilungen neu.
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) { [environment] in
            await BackgroundRefresh.run(environment: environment)
        }
    }
}
