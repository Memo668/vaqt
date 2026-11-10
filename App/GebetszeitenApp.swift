import Features
import SwiftUI

@main
struct GebetszeitenApp: App {
    /// Uhr, Standortquelle und Start-Tab. In DEBUG-Builds gelten die Debug-Startargumente (CLAUDE.md).
    private let environment = AppEnvironment.launch()

    var body: some Scene {
        WindowGroup {
            RootView(environment: environment)
        }
    }
}
