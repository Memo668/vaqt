import PrayerCore
import SwiftUI

/// Wurzel der App: die System-`TabView` mit den drei Tabs Gebete, Verse und Nachholen.
public struct RootView: View {
    private let environment: AppEnvironment
    @State private var selection: AppTab

    public init(environment: AppEnvironment) {
        self.environment = environment
        _selection = State(initialValue: environment.initialTab)
    }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    // Noch leer: Gebete folgt in Phase 3, Verse und Nachholen in Phase 6.
                    Color.clear
                }
            }
        }
        .environment(\.appClock, environment.clock)
        .environment(\.locationSource, environment.locationSource)
    }
}
