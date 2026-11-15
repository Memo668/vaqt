import DesignSystem
import PrayerCore
import SwiftUI

/// Die Anleitung: Auswahl der fünf Gebete, Kopfkarte, „Vorher“ und „Ablauf“ – `guidePage()` im Prototyp.
///
/// Sie öffnet beim Gebet, dessen Zeit gerade läuft (vor Fadschr noch Ischa, zwischen Sonnenaufgang und
/// Dhuhr Dhuhr). Ein anderes Gebet lässt sich wählen; die Wahl gilt, bis das aktuelle Gebet wechselt
/// oder man die Seite verlässt. „Qibla öffnen“ wechselt zur Qibla-Seite. „Gebet Schritt für Schritt“
/// öffnet den Durchlauf durch das gezeigte Gebet als Vollbild (Spec § 9.6).
struct GuidePage: View {
    let model: GuideModel
    /// „Qibla öffnen“.
    let onOpenQibla: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @AccessibilityFocusState private var focusedPrayer: Prayer?

    var body: some View {
        @Bindable var model = model
        // Innen auf dem iPhone Duo: Auswahl, Kopfkarte und „Vorher“ links, „Ablauf“ rechts.
        PageScroll {
            GuideOverview(
                header: model.header, focus: $focusedPrayer,
                onSelect: { model.choose($0) }, onWalk: { model.startWalk() },
                onReturn: returnToCurrentPrayer, onOpenQibla: onOpenQibla
            )
        } second: {
            GuideSteps()
        }
        // Wie das Onboarding über der ganzen App; VoiceOver kehrt nach dem Schließen zum Knopf zurück.
        .fullScreenCover(item: $model.walk) { _ in
            GuideWalkCover(model: model)
        }
        // Gleicht ab, solange die App vorn ist – auch wenn gerade eine andere Seite des Tabs zu sehen ist,
        // damit beim Wischen schon das richtige Gebet dasteht. Wacht nur bei einem neuen Ereignis auf.
        .task(id: Activity(isActive: scenePhase == .active, timeline: model.timeline)) {
            guard scenePhase == .active else { return }
            await model.run()
        }
    }

    /// „Zum aktuellen Gebet“: Die Anleitung folgt wieder der Zeit. Der Knopf verschwindet; VoiceOver
    /// springt auf das aktuelle Gebet in der Auswahl (`focusNext` im Prototyp).
    private func returnToCurrentPrayer() {
        model.followTime()
        focusedPrayer = model.state.automatic
    }

    /// Wann der Abgleich neu startet: wenn die App nach vorn kommt und wenn sich der Zeitstrahl ändert.
    private struct Activity: Hashable {
        let isActive: Bool
        let timeline: PrayerTimeline?
    }
}
