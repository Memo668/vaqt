#if DEBUG

import DesignSystem
import PrayerCore
import SwiftUI

/// Der Bildschirm zu `-debugCatalog`: der Katalog der Bausteine statt der Tabs.
///
/// Bogen, Gebetskarten und Kompass stehen im Zustand der übrigen Debug-Argumente. So gehören zu jedem
/// Referenzbild dieselben Argumente wie für die Seite selbst, nur mit `-debugCatalog arc` davor:
///
/// ```
/// -debugCatalog arc -debugFixtureTimes -debugCity jakarta -debugDate 2026-11-10 -debugTime 17:57
/// -debugCatalog compass -debugFixtureTimes -debugQiblaHeading 137
/// ```
struct CatalogRoot: View {
    let section: ComponentCatalog.Section
    let environment: AppEnvironment

    var body: some View {
        ComponentCatalog(
            section: section,
            phase: Self.phase(for: environment),
            isHighLatitude: environment.launchOptions.highLatitude,
            compass: Self.compass(for: environment)
        )
    }

    /// Der Zustand des Kompasses zu den Debug-Argumenten: die Richtung zur Kaaba von der Stadt aus und
    /// der feste Kurs. Ohne festen Kurs zeigt der Katalog den Kompass eines Geräts ohne Kompass.
    ///
    /// Ohne Stadt und ohne Kurs gibt es `nil`; der Katalog zeigt dann seinen Standardzustand.
    nonisolated static func compass(for environment: AppEnvironment) -> CatalogFixtures.CompassState? {
        let options = environment.launchOptions
        guard options.effectiveCity != nil || options.effectiveQiblaHeading != nil else { return nil }
        let city = options.effectiveCity?.id ?? "berlin"
        return CatalogFixtures.CompassState(
            id: city, heading: options.effectiveQiblaHeading, bearing: CatalogFixtures.bearing(city: city)
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
