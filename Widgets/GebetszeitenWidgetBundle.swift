import SwiftUI
import WidgetKit

/// Einstieg der Widget-Extension: das Widget mit seinen fünf Größen, das Widget „Live“ (seit Phase 14), das kleine
/// Widget „Tagesbogen“ (seit Phase 19) und die Live-Aktivität (Spec § 1, „Outside the app“; § 9.11, § 12).
@main
struct GebetszeitenWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        PrayerLiveWidget()
        PrayerArcWidget()
        PrayerLiveActivity()
    }
}
