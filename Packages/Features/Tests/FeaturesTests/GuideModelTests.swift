#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Anleitung: welches Gebet sie zeigt, die manuelle Wahl und wann sie verfällt. Gerechnet wird mit
/// den Mock-Zeiten des Prototyps für Berlin – den Zahlen der Referenzbilder `iphone/40` bis `42`.
@MainActor
@Suite("GuideModel")
struct GuideModelTests {

    private struct Fixture {
        let guide: GuideModel
        let today: TodayModel
        let clock: TestClock
    }

    private func make(
        now: Date = instant("2026-11-10", "14:25"),
        location: any LocationSource = FixedLocationSource(place: .berlin, status: .authorized)
    ) async -> Fixture {
        let clock = TestClock(now)
        let today = TodayModel(
            clock: clock, timesSource: FixtureTimesSource(), locationSource: location,
            connectivity: FixedConnectivity(isOnline: true),
            settings: SettingsStore(storage: .ephemeral(SettingsStore.Snapshot())),
            toast: ToastCenter(duration: .seconds(60)), locale: Locale(identifier: "de_DE"), deviceTimeZone: .gmt
        )
        await today.activate()
        return Fixture(guide: GuideModel(today: today), today: today, clock: clock)
    }

    private let window = { (start: String, end: String) in "\(start)\u{2060}–\u{2060}\(end)" }

    // MARK: - Automatik

    @Test("iphone/40: die Anleitung öffnet bei Asr – „Jetzt“, 14:00–16:27")
    func opensOnCurrentPrayer() async {
        let fixture = await make()
        let guide = fixture.guide
        guide.refresh()

        #expect(guide.state.prayer == .asr)
        #expect(guide.header.status == L10n.now)
        #expect(guide.header.window == window("14:00", "16:27"))
        #expect(guide.header.automatic == .asr)
        #expect(guide.header.returnPrayer == nil)
    }

    @Test("schon vor dem ersten Abgleich steht das richtige Gebet da")
    func firstFrame() async {
        let fixture = await make()
        #expect(fixture.guide.state.prayer == .asr)
        #expect(fixture.guide.header.window == window("14:00", "16:27"))
    }

    @Test("vor Fadschr: noch Ischa – von gestern Abend bis Fadschr heute")
    func beforeFajr() async {
        let fixture = await make(now: instant("2026-11-10", "04:01"))
        fixture.guide.refresh()
        #expect(fixture.guide.state.prayer == .isha)
        #expect(fixture.guide.header.status == L10n.now)
        #expect(fixture.guide.header.window == window("18:17", "05:16"))
    }

    @Test("am Vormittag: Dhuhr als nächstes Gebet")
    func morning() async {
        let fixture = await make(now: instant("2026-11-10", "08:04"))
        fixture.guide.refresh()
        #expect(fixture.guide.state.prayer == .dhuhr)
        #expect(fixture.guide.header.status == L10n.guideNext)
        #expect(fixture.guide.header.automaticStatus == L10n.guideNext)
    }

    // MARK: - Manuelle Wahl

    @Test("iphone/42: Maghrib von Hand – ohne Status, 16:27–18:17, Knopf zurück zu Asr")
    func manualPick() async {
        let fixture = await make()
        let guide = fixture.guide
        guide.refresh()
        guide.choose(.maghrib)

        #expect(guide.state.prayer == .maghrib)
        #expect(guide.header.status == nil)
        #expect(guide.header.window == window("16:27", "18:17"))
        #expect(guide.header.returnPrayer == .asr)
        // Der Punkt bleibt beim aktuellen Gebet.
        #expect(guide.header.automatic == .asr)
    }

    @Test("„Zum aktuellen Gebet“ und das Verlassen der Seite heben die Wahl auf")
    func followTime() async {
        let fixture = await make()
        let guide = fixture.guide
        guide.refresh()
        guide.choose(.fajr)
        guide.followTime()
        #expect(guide.state.prayer == .asr)
        #expect(guide.header.returnPrayer == nil)
    }

    @Test("das aktuelle Gebet anzutippen ist keine Wahl")
    func chooseCurrent() async {
        let fixture = await make()
        let guide = fixture.guide
        guide.refresh()
        guide.choose(.maghrib)
        guide.choose(.asr)
        #expect(guide.selection.pick == nil)
    }

    // MARK: - Zeitwechsel

    @Test("die Wahl bleibt, solange Asr läuft, und verfällt mit Maghrib")
    func pickExpires() async {
        let fixture = await make()
        let guide = fixture.guide
        guide.refresh()
        guide.choose(.isha)

        fixture.clock.now = instant("2026-11-10", "16:26")
        guide.refresh()
        #expect(guide.state.prayer == .isha)

        fixture.clock.now = instant("2026-11-10", "16:27")
        guide.refresh()
        #expect(guide.selection.pick == nil)
        #expect(guide.state.prayer == .maghrib)
        #expect(guide.header.status == L10n.now)
        #expect(guide.header.window == window("16:27", "18:17"))
    }

    @Test("nach Mitternacht baut die Zeiten-Seite einen neuen Zeitstrahl; Ischa läuft weiter")
    func midnight() async {
        let fixture = await make(now: instant("2026-11-10", "23:30"))
        let guide = fixture.guide
        guide.refresh()
        let evening = fixture.today.timeline

        fixture.clock.now = instant("2026-11-11", "00:30")
        guide.refresh()
        #expect(fixture.today.timeline != evening)
        #expect(guide.phase != nil)
        #expect(guide.state.prayer == .isha)
        #expect(guide.header.window == window("18:17", "05:16"))
    }

    // MARK: - Ohne Zeiten

    @Test("ohne Ort: Fadschr ohne Status und Zeitfenster; wählen geht trotzdem")
    func withoutPlace() async {
        let fixture = await make(location: FixedLocationSource(place: nil, status: .denied))
        let guide = fixture.guide
        guide.refresh()

        #expect(fixture.today.timeline == nil)
        #expect(guide.phase == nil)
        #expect(guide.state.prayer == .fajr)
        #expect(guide.header.status == nil)
        #expect(guide.header.window == nil)
        #expect(guide.header.automatic == nil)

        guide.choose(.maghrib)
        #expect(guide.state.prayer == .maghrib)
        #expect(guide.header.returnPrayer == nil)
    }

    @Test("ohne Zeiten endet der Abgleich gleich")
    func runWithoutTimes() async {
        let fixture = await make(location: FixedLocationSource(place: nil, status: .denied))
        await fixture.guide.run()
        #expect(fixture.guide.phase == nil)
    }
}

#endif
