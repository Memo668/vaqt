import ActivityKit
import DesignSystem
import PrayerCore
import SwiftUI
import WidgetKit

/// Die Live-Aktivität zum nächsten Gebet: auf dem Sperrbildschirm der Bogen in Weiß auf Akzent, in der
/// Dynamic Island kompakt, minimal und erweitert (Spec § 3, „Live Activity“; Variante 5h).
///
/// Ab Gebetsbeginn ist der Inhalt `stale` (`staleDate`): Der Bogen zeigt das Gebet als laufend, statt des
/// Countdowns steht „Jetzt“. Keine Knöpfe.
struct PrayerLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerActivityAttributes.self) { context in
            let _ = Self.applyLanguage()
            LiveActivityLockScreen(content: context.state, isStale: context.isStale)
                .background(LiveActivityBackground())
                .activityBackgroundTint(Palette.LiveActivity.background)
                .activitySystemActionForegroundColor(.white)
                .environment(\.locale, L10n.locale)
                .environment(\.layoutDirection, L10n.layoutDirection)
        } dynamicIsland: { context in
            let _ = Self.applyLanguage()
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
            .keylineTint(LiveActivityMetrics.islandAccent)
            .contentMargins(.horizontal, LiveActivityMetrics.expandedInset, for: .expanded)
        }
    }

    /// Die Texte in der Sprache der App, aus der App Group – bevor die Ansichten sie lesen.
    static func applyLanguage() {
        L10n.chosenLanguage = WidgetState.sharedDefaults.flatMap(WidgetState.load(from:))?.language
    }
}
