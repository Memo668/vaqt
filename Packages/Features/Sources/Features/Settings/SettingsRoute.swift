import DesignSystem
import SwiftUI

/// Ein Ziel im Stapel der Einstellungen – die Kennungen aus `PAGES` im Prototyp, soweit andere Seiten
/// schon dorthin führen. Die Bildschirme selbst folgen in Phase 7.
enum SettingsRoute: Hashable, Sendable {
    /// Die Einstellungen (`settings`), erreichbar über den Einstellungskreis.
    case settings
    /// Einstellungen › Hohe Breitengrade (`hl`), erreichbar über „Regel ändern“ auf der Zeiten-Seite.
    case highLatitude

    /// Titel der Seite aus dem String Catalog (`PAGE_TITLE`).
    var title: String {
        switch self {
        case .settings: L10n.settings
        case .highLatitude: L10n.highLat
        }
    }
}

/// Platzhalter für eine Seite der Einstellungen: Leiste mit Zurück-Knopf und Titel, noch ohne Inhalt.
struct SettingsPlaceholder: View {
    let route: SettingsRoute

    var body: some View {
        Palette.backgroundGrouped
            .ignoresSafeArea()
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(route == .settings ? .large : .inline)
    }
}
