import DesignSystem
import SwiftUI

/// Die obere Leiste der Tabs Verse und Nachholen: nur der Einstellungskreis, an derselben Stelle wie im
/// Tab Gebete, ohne Chips – `topBarHTML()` im Prototyp, wenn `S.section` nicht `prayers` ist.
struct SettingsBar: View {
    let onSettings: () -> Void

    var body: some View {
        FloatingBar {
            GlassCircleButton(systemImage: "gearshape", label: L10n.tabSettings, action: onSettings)
        }
    }
}

extension View {

    /// Legt die Leiste mit dem Einstellungskreis fest über die Seite; der Inhalt scrollt unter ihr durch,
    /// mit dem Randeffekt des Systems. Der Kreis öffnet die Einstellungen im Stapel des Tabs.
    func settingsBar(path: Binding<[SettingsRoute]>) -> some View {
        safeAreaBar(edge: .top, spacing: 0) {
            SettingsBar {
                path.wrappedValue.append(.settings)
            }
        }
    }
}
