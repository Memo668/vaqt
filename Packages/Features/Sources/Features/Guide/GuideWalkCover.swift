import DesignSystem
import PrayerCore
import SwiftUI

/// Das Vollbild „Gebet Schritt für Schritt“ über der App (Spec § 9.6): zeigt die Seite des laufenden
/// Durchlaufs aus `GuideModel.walk` und blättert mit den Knöpfen.
///
/// Für VoiceOver wie im Prototyp: Nach „Weiter“ bleibt der Fokus auf „Weiter“, nach „Zurück“ auf
/// „Zurück“ – auf der Startseite auf „Beginnen“ (`focusNext`). Die Zeile „Rakʿa 2 von 4 · Schritt 9 von
/// 28“ wird bei jedem Schritt angesagt (`aria-live="polite"`).
struct GuideWalkCover: View {
    let model: GuideModel

    @AccessibilityFocusState private var focus: GuideWalkScreen.Control?

    var body: some View {
        if let session = model.walk {
            GuideWalkScreen(
                walk: session.walk, index: session.index, direction: session.direction, focus: $focus,
                onPrevious: previous, onNext: next, onClose: model.closeWalk
            )
            .onChange(of: session.index) { _, index in
                announce(session.walk.localizedProgressLine(at: index))
            }
        }
    }

    private func next() {
        model.nextWalkStep()
        focus = .next
    }

    private func previous() {
        model.previousWalkStep()
        focus = model.walk?.index == 0 ? .next : .previous
    }

    /// Sagt die Zeile an, ohne den Fokus zu verschieben. Hohe Priorität, damit sie nicht hinter dem Namen
    /// des Knopfs verloren geht, auf den der Fokus springt.
    private func announce(_ line: String) {
        var announcement = AttributedString(line)
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}
