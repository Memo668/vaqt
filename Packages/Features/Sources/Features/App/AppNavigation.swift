import Observation
import SwiftUI

/// Wo man in der App steht: der Tab, die Seite im Tab „Gebete“, der Stapel der Einstellungen je Tab und
/// ob das Adhan-Sheet offen ist.
///
/// Der Stand liegt außerhalb der Seiten, damit er bleibt, wenn sich die Seiten in einer neuen Sprache neu
/// aufbauen (Einstellungen › Sprache): Man steht danach dort, wo man die Sprache gewählt hat.
@MainActor
@Observable
final class AppNavigation {
    var tab: AppTab
    var prayersPage: PrayersPage
    var prayersPath: [SettingsRoute]
    var versesPath: [SettingsRoute] = []
    var qadaPath: [SettingsRoute] = []
    /// Das Adhan-Sheet (`openSheet('adhan')`), erreichbar über „Adhan anhören“.
    var isAdhanSheetPresented: Bool

    init(
        tab: AppTab = .prayers, prayersPage: PrayersPage = .today, settingsPath: [SettingsRoute] = [],
        isAdhanSheetPresented: Bool = false
    ) {
        self.tab = tab
        self.prayersPage = prayersPage
        prayersPath = settingsPath
        self.isAdhanSheetPresented = isAdhanSheetPresented
    }

    /// Der Stapel des Tabs, der gerade gewählt ist.
    var currentPath: [SettingsRoute] {
        get {
            switch tab {
            case .prayers: prayersPath
            case .verses: versesPath
            case .qada: qadaPath
            }
        }
        set {
            switch tab {
            case .prayers: prayersPath = newValue
            case .verses: versesPath = newValue
            case .qada: qadaPath = newValue
            }
        }
    }
}
