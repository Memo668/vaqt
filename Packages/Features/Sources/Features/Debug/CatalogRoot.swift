#if DEBUG

import DesignSystem
import PrayerCore
import SwiftUI

/// Der Bildschirm zu `-debugCatalog`: der Katalog der Bausteine statt der Tabs.
///
/// Bogen und Gebetskarten stehen im Zustand der übrigen Debug-Argumente. So gehören zu jedem
/// Referenzbild dieselben Argumente wie später für die Zeiten-Seite, nur mit `-debugCatalog arc` davor:
///
/// ```
/// -debugCatalog arc -debugFixtureTimes -debugCity jakarta -debugDate 2026-11-10 -debugTime 17:57
/// ```
struct CatalogRoot: View {
    let section: ComponentCatalog.Section
    let environment: AppEnvironment

    var body: some View {
        ComponentCatalog(
            section: section,
            phase: Self.phase(for: environment),
            isHighLatitude: environment.launchOptions.highLatitude
        )
    }

    /// Die Tagesphase zu den Debug-Argumenten, gelesen im Moment des Aufrufs.
    ///
    /// Mit `-debugFixtureTimes` kommen die Zeiten aus den Mock-Zeiten des Prototyps, sonst rechnet die
    /// App echt. Ohne Stadt (`-debugCity`, `-debugFixtureTimes` oder `-debugHighLatitude`) gibt es keinen
    /// Ort und damit `nil`; der Katalog zeigt dann seinen Standardzustand.
    static func phase(for environment: AppEnvironment) -> DayPhase? {
        let options = environment.launchOptions
        guard let city = options.effectiveCity else { return nil }
        let source: any PrayerTimesSource = options.fixtureTimes
            ? FixtureTimesSource(highLatitude: options.highLatitude)
            : AdhanTimesSource()
        let now = environment.clock.now
        let place = city.place(named: city.localizedName)
        return source.timeline(at: now, place: place, settings: CalculationSettings())?.phase(at: now)
    }
}

#endif
