import ActivityKit
import DesignSystem
import PrayerCore
import SwiftUI
import WidgetKit

/// Die Live-Aktivität zum nächsten Gebet: auf dem Sperrbildschirm der Bogen in Weiß auf Akzent, in der
/// Dynamic Island kompakt, minimal und erweitert (Spec § 3, „Live Activity“; Variante 5h).
///
/// Zu ihrem `staleDate` (Gebetsbeginn oder Beginn der Verbotszeit) schrumpft sie auf eine schmale Zeile; in
/// der Verbotszeit ist sie orange (Spec § 10.3). Keine Knöpfe.
struct PrayerLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            let _ = Self.apply(context.state)
            // Spec § 10.3: der Verlauf mit 30 % Deckkraft über durchsichtigem Grund, in der Verbotszeit orange; seit
            // § 11.7 im Stil der App (Grundfarbe, farbig, nur Bogen, schwarz-weiß, invertiert).
            let look = LiveActivityLook(content: context.state)
            LiveActivityLockScreen(content: context.state, isStale: context.isStale)
                .background(LiveActivityBackground(look: look))
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(Color(look.colors.foreground))
                .environment(\.locale, L10n.locale)
                .environment(\.layoutDirection, L10n.layoutDirection)
        } dynamicIsland: { context in
            let _ = Self.apply(context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityExpandedLeading(content: context.state)
                        .environment(\.layoutDirection, L10n.layoutDirection)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityExpandedTrailing(content: context.state)
                        .environment(\.layoutDirection, L10n.layoutDirection)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityExpandedBottom(content: context.state, isStale: context.isStale)
                        .environment(\.layoutDirection, L10n.layoutDirection)
                }
            } compactLeading: {
                LiveActivityCompactLeading(content: context.state)
                    .environment(\.layoutDirection, L10n.layoutDirection)
            } compactTrailing: {
                LiveActivityCompactTrailing(content: context.state, isStale: context.isStale)
                    .environment(\.layoutDirection, L10n.layoutDirection)
            } minimal: {
                LiveActivityMinimal(content: context.state)
                    .environment(\.layoutDirection, L10n.layoutDirection)
            }
            .keylineTint(LiveActivityMetrics.islandAccent(context.state))
            .contentMargins(.horizontal, LiveActivityMetrics.expandedInset, for: .expanded)
        }
    }

    /// Die Texte in der Sprache der App, aus der App Group, und die Grundfarbe der Aktivität – bevor die Ansichten
    /// sie lesen. Inhalte ohne Stil (vor dem Nachtrag zu Phase 18) nehmen den Stil der App Group.
    static func apply(_ content: LiveActivityContent) {
        let state = WidgetState.sharedDefaults.flatMap(WidgetState.load(from:))
        L10n.chosenLanguage = state?.language
        AccentStore.shared.accent = (content.style ?? state?.effectiveStyle ?? .standard).accent
    }
}
