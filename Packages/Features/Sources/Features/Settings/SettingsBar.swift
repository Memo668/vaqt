import DesignSystem
import SwiftUI

/// Die obere Leiste der Tabs Verse und Nachholen: nur der Einstellungskreis, rechts wie im Tab Gebete
/// (Spec § 9.2), ohne Chips – `topBarHTML()` im Prototyp, wenn `S.section` nicht `prayers` ist.
struct SettingsBar: View {
    let onSettings: () -> Void

    var body: some View {
        FloatingBar {
            Spacer(minLength: 0)
            GlassCircleButton(systemImage: "gearshape", label: L10n.tabSettings, action: onSettings)
        }
    }
}
