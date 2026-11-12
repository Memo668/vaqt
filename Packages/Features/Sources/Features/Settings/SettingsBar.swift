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
