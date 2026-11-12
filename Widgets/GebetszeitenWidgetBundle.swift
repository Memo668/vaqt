import SwiftUI
import WidgetKit

/// Einstieg der Widget-Extension: das Widget mit seinen fünf Größen und die Live-Aktivität
/// (Spec § 1, „Outside the app“).
@main
struct GebetszeitenWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        PrayerLiveActivity()
    }
}
