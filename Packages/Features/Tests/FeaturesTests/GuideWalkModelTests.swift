#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// „Gebet Schritt für Schritt“ in der Anleitung (Spec § 9.6): Start für das gezeigte Gebet, Weiter und
/// Zurück, Schließen – `walk-start`, `walk-next`, `walk-prev` und `walk-close` im Prototyp. Dazu die
/// Debug-Argumente `-debugWalk` und `-debugWalkStep`.
@MainActor
@Suite("GuideModel – Schritt für Schritt")
struct GuideWalkModelTests {

    private func make(now: Date = instant("2026-11-10", "14:25")) async -> (guide: GuideModel, clock: TestClock) {
        let clock = TestClock(now)
        let today = TodayModel(
            clock: clock, timesSource: FixtureTimesSource(),
            locationSource: FixedLocationSource(place: .berlin, status: .authorized),
            connectivity: FixedConnectivity(isOnline: true),
            settings: SettingsStore(storage: .ephemeral(SettingsStore.Snapshot())),
            toast: ToastCenter(duration: .seconds(60)), locale: Locale(identifier: "de_DE"), deviceTimeZone: .gmt
        )
        await today.activate()
        return (GuideModel(today: today), clock)
    }

    @Test("der Knopf öffnet den Durchlauf für das gezeigte Gebet, auf der Startseite")
    func startForShownPrayer() async throws {
        let (guide, _) = await make()
        guide.refresh()
        #expect(guide.walk == nil)

        guide.startWalk()
        let session = try #require(guide.walk)
        #expect(session.walk.prayer == .asr)
        #expect(session.index == 0)
        #expect(session.direction == .forward)
        #expect(session.walk.stepCount == 28)
    }

    @Test("nach einer Wahl von Hand gilt das gewählte Gebet (Maghrib: 22 Schritte)")
    func startForPick() async throws {
        let (guide, _) = await make()
        guide.refresh()
        guide.choose(.maghrib)
        guide.startWalk()
        let session = try #require(guide.walk)
        #expect(session.walk.prayer == .maghrib)
        #expect(session.walk.stepCount == 22)
    }

    @Test("Weiter und Zurück blättern, bleiben an den Enden stehen und merken die Richtung")
    func navigate() async throws {
        let (guide, _) = await make()
        guide.startWalk(prayer: .fajr)
        guide.previousWalkStep()
        #expect(guide.walk?.index == 0)

        guide.nextWalkStep()
        guide.nextWalkStep()
        #expect(guide.walk?.index == 2)
        #expect(guide.walk?.direction == .forward)

        guide.previousWalkStep()
        #expect(guide.walk?.index == 1)
        #expect(guide.walk?.direction == .backward)

        let last = try #require(guide.walk?.walk.lastIndex)
        for _ in 0..<40 { guide.nextWalkStep() }
        #expect(guide.walk?.index == last)
        #expect(guide.walk?.walk.step(at: last).kind == .done)
    }

    @Test("Schließen beendet den Durchlauf; die Wahl der Anleitung bleibt")
    func close() async {
        let (guide, _) = await make()
        guide.refresh()
        guide.choose(.isha)
        guide.startWalk()
        guide.nextWalkStep()
        guide.closeWalk()
        #expect(guide.walk == nil)
        #expect(guide.state.prayer == .isha)
    }

    @Test("wechselt währenddessen das aktuelle Gebet, bleibt der Durchlauf bei seinem Gebet")
    func keepsPrayerAcrossPhaseChange() async throws {
        let (guide, clock) = await make()
        guide.refresh()
        guide.startWalk()
        guide.nextWalkStep()
        // 16:27 beginnt Maghrib; die Anleitung folgt der Zeit.
        clock.now = instant("2026-11-10", "16:30")
        guide.refresh()
        #expect(guide.state.prayer == .maghrib)
        #expect(guide.walk?.walk.prayer == .asr)
        #expect(guide.walk?.index == 1)
    }

    @Test("ohne Zeiten öffnet der Knopf Fadschr, wie die Anleitung ohne Zeiten")
    func startWithoutTimes() async throws {
        let clock = TestClock(instant("2026-11-10", "14:25"))
        let today = TodayModel(
            clock: clock, timesSource: FixtureTimesSource(),
            locationSource: FixedLocationSource(place: nil, status: .denied),
            connectivity: FixedConnectivity(isOnline: true),
            settings: SettingsStore(storage: .ephemeral(SettingsStore.Snapshot())),
            toast: ToastCenter(duration: .seconds(60)), locale: Locale(identifier: "de_DE"), deviceTimeZone: .gmt
        )
        let guide = GuideModel(today: today)
        guide.startWalk()
        #expect(guide.walk?.walk.prayer == .fajr)
    }

    @Test("ein Durchlauf ab einer Seite: zu große Seiten zeigen die letzte; der Sonnenaufgang hat keinen")
    func startAtIndex() async {
        let (guide, _) = await make()
        guide.startWalk(prayer: .dhuhr, at: 9)
        #expect(guide.walk?.index == 9)
        guide.startWalk(prayer: .dhuhr, at: 99)
        #expect(guide.walk?.index == 29)
        guide.closeWalk()
        guide.startWalk(prayer: .sunrise)
        #expect(guide.walk == nil)
    }

    // MARK: - Debug-Argumente

    @Test("-debugWalk dhuhr -debugWalkStep 9 öffnet den Durchlauf über der Anleitung")
    func launchOptions() throws {
        let options = LaunchOptions(arguments: ["-debugSkipOnboarding", "-debugWalk", "dhuhr", "-debugWalkStep", "9"])
        #expect(options.problems.isEmpty)
        #expect(options.walkPrayer == .dhuhr)
        #expect(options.walkStep == 9)
        let environment = AppEnvironment(options: options)
        #expect(environment.initialPage == .guide)
        let walk = try #require(environment.initialWalk)
        #expect(walk.prayer == .dhuhr)
        #expect(walk.index == 9)
    }

    @Test("-debugWalk ohne -debugWalkStep beginnt auf der Startseite; -debugTab bleibt die Seite darunter")
    func launchOptionsDefaults() {
        let options = LaunchOptions(arguments: ["-debugWalk", "fajr", "-debugTab", "today"])
        #expect(options.walkStep == 0)
        let environment = AppEnvironment(options: options)
        #expect(environment.initialPage == .today)
        #expect(environment.initialWalk?.index == 0)
        #expect(AppEnvironment(options: LaunchOptions(arguments: [])).initialWalk == nil)
    }

    @Test("falsche Werte werden gemeldet", arguments: [
        ["-debugWalk", "sunrise"],
        ["-debugWalk", "mittag"],
        ["-debugWalk", "dhuhr", "-debugWalkStep", "-1"],
        ["-debugWalk", "dhuhr", "-debugWalkStep", "neun"],
        ["-debugWalkStep", "3"],
    ])
    func invalidLaunchOptions(arguments: [String]) {
        #expect(LaunchOptions(arguments: arguments).problems.count == 1)
    }
}

#endif
