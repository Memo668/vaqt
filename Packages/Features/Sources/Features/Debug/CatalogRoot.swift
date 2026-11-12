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
/// -debugCatalog guide -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25
/// ```
struct CatalogRoot: View {
    let section: ComponentCatalog.Section
    let environment: AppEnvironment

    var body: some View {
        ComponentCatalog(
            section: section,
            phase: Self.phase(for: environment),
            isHighLatitude: environment.launchOptions.highLatitude,
            compass: Self.compass(for: environment),
            guide: Self.guide(for: environment),
            today: Self.today(for: environment),
            outside: Self.outside(for: environment)
        )
    }

    /// Widgets und Live-Aktivität zu den Debug-Argumenten: der Eintrag der Zeitleiste für jetzt und die
    /// Aktivität zum nächsten Gebet, als habe sie eben begonnen. Ohne Stadt gibt es `nil`; der Katalog
    /// zeigt dann Berlin um 14:25.
    nonisolated static func outside(for environment: AppEnvironment) -> CatalogOutsideState? {
        let options = environment.launchOptions
        guard let city = options.effectiveCity else { return nil }
        let source: any PrayerTimesSource = options.fixtureTimes
            ? FixtureTimesSource(highLatitude: options.highLatitude)
            : AdhanTimesSource()
        let place = city.place(named: city.localizedName)
        return CatalogOutsideState.make(
            source: source, place: place, cityName: place.name, isCurrentLocation: true,
            settings: CalculationSettings(), showKerahat: true, now: environment.clock.now,
            clockOffset: WidgetSync.clockOffset(of: environment.clock)
        )
    }

    /// Der heutige Tag für Verse und Plan: der Tag der Debug-Uhr in der Zeitzone der Stadt, ohne Stadt in
    /// der des Geräts.
    nonisolated static func today(for environment: AppEnvironment, deviceTimeZone: TimeZone = .current) -> CalendarDay {
        let city = environment.launchOptions.effectiveCity
        let timeZone = city.flatMap { TimeZone(identifier: $0.timeZoneIdentifier) } ?? deviceTimeZone
        return CalendarDay(environment.clock.now, in: timeZone)
    }

    /// Auswahl und Kopfkarte der Anleitung zu den Debug-Argumenten: das Gebet, dem die Anleitung zu
    /// dieser Uhrzeit folgt, mit seinem Zeitfenster. Ohne Stadt gibt es `nil`; der Katalog zeigt dann
    /// seinen Standardzustand.
    nonisolated static func guide(for environment: AppEnvironment) -> GuideHeader? {
        guard let (timeline, now) = timeline(for: environment) else { return nil }
        let state = GuideState(phase: timeline.phase(at: now))
        return GuideHeader(
            state: state, window: Guide.window(of: state.prayer, in: timeline, at: now),
            timeZone: timeline.today.timeZone
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
    nonisolated static func phase(for environment: AppEnvironment) -> DayPhase? {
        guard let (timeline, now) = timeline(for: environment) else { return nil }
        return timeline.phase(at: now)
    }

    /// Zeitstrahl der Stadt aus den Debug-Argumenten und der Zeitpunkt, für den er gilt.
    private nonisolated static func timeline(for environment: AppEnvironment) -> (PrayerTimeline, Date)? {
        let options = environment.launchOptions
        guard let city = options.effectiveCity else { return nil }
        let source: any PrayerTimesSource = options.fixtureTimes
            ? FixtureTimesSource(highLatitude: options.highLatitude)
            : AdhanTimesSource()
        let now = environment.clock.now
        let place = city.place(named: city.localizedName)
        return source.timeline(at: now, place: place, settings: CalculationSettings()).map { ($0, now) }
    }
}

#endif
