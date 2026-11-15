import SwiftUI
import WidgetKit

/// Einstieg der Widget-Extension: das Widget mit seinen fünf Größen, das Widget „Live“ (seit Phase 14) und
/// die Live-Aktivität (Spec § 1, „Outside the app“; § 9.11).
@main
struct GebetszeitenWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        PrayerLiveWidget()
        PrayerLiveActivity()
    }
}
