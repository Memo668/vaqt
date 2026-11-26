#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import SwiftUI
import Testing
@testable import Features

/// Das App-Icon in der Grundfarbe (Phase 20, Spec § 13.2): Wechsel nur bei einer Änderung, `nil` für Petrol und
/// ausgeschalteten Schalter, Schalter nur mit alternativen Icons.
@MainActor
@Suite("App-Icon in der Grundfarbe")
struct AppIconTests {

    /// Ein Icon, dessen Wechsel wartet, bis der Test ihn freigibt – wie iOS, das erst nach dem Hinweis fertig ist.
    final class GatedIcons: AlternateIconSetting {
        let supportsAlternateIcons = true
        private(set) var alternateIconName: String?
        private(set) var requests: [String?] = []
        var gate: CheckedContinuation<Void, Never>?

        func setAlternateIconName(_ alternateIconName: String?) async throws {
            requests.append(alternateIconName)
            await withCheckedContinuation { gate = $0 }
            self.alternateIconName = alternateIconName
        }
    }

    /// Ein Icon, das iOS ablehnt – etwa im Hintergrund.
    final class RefusingIcons: AlternateIconSetting {
        struct Refused: Error {}
        let supportsAlternateIcons = true
        let alternateIconName: String? = nil
        private(set) var attempts = 0

        func setAlternateIconName(_ alternateIconName: String?) async throws {
            attempts += 1
            throw Refused()
        }
    }

    @Test("Petrol ruft iOS nicht; eine andere Farbe setzt AppIcon-<id>, einmal")
    func switchesOnlyOnChange() async {
        let icons = FixedAlternateIcons()
        let switcher = AppIconSwitcher(target: icons)
        #expect(switcher.isAvailable)
        #expect(await !switcher.apply(.standard))
        #expect(icons.requests.isEmpty)
        #expect(await switcher.apply(AppStyle(accent: .ocean)))
        #expect(icons.alternateIconName == "AppIcon-ocean")
        // Dasselbe Icon, auch mit anderem Stil der Live-Aktivität: kein zweiter Hinweis.
        #expect(await !switcher.apply(AppStyle(accent: .ocean, liveActivity: .mono, isInverted: true)))
        #expect(await switcher.apply(AppStyle(accent: .sand)))
        #expect(icons.requests == ["AppIcon-ocean", "AppIcon-sand"])
    }

    @Test("Schalter aus oder zurück zu Petrol: das Haupt-Icon (nil)")
    func backToPrimary() async {
        let icons = FixedAlternateIcons(alternateIconName: "AppIcon-ocean")
        let switcher = AppIconSwitcher(target: icons)
        #expect(await switcher.apply(AppStyle(accent: .ocean, tintsAppIcon: false)))
        #expect(icons.alternateIconName == nil)
        #expect(await !switcher.apply(AppStyle(accent: .gold, tintsAppIcon: false)))
        #expect(await switcher.apply(AppStyle(accent: .gold)))
        #expect(await switcher.apply(.standard))
        #expect(icons.requests == [nil, "AppIcon-gold", nil])
    }

    @Test("ohne alternative Icons: kein Schalter, kein Aufruf")
    func unsupported() async {
        let icons = FixedAlternateIcons(supportsAlternateIcons: false)
        let switcher = AppIconSwitcher(target: icons)
        #expect(!switcher.isAvailable)
        #expect(await !switcher.apply(AppStyle(accent: .ocean)))
        #expect(icons.requests.isEmpty)
    }

    @Test("ein zweiter Anlass während des Wechsels (Seite verlassen, dann Hintergrund) ruft nicht noch einmal")
    func pendingChange() async throws {
        let icons = GatedIcons()
        let switcher = AppIconSwitcher(target: icons)
        let first = Task { await switcher.apply(AppStyle(accent: .ocean)) }
        while icons.gate == nil { await Task.yield() }
        #expect(await !switcher.apply(AppStyle(accent: .ocean)))
        let gate = try #require(icons.gate)
        gate.resume()
        #expect(await first.value)
        #expect(icons.requests == ["AppIcon-ocean"])
        #expect(await !switcher.apply(AppStyle(accent: .ocean)))
    }

    @Test("lehnt iOS ab, versucht es der nächste Anlass wieder")
    func retriesAfterRefusal() async {
        let icons = RefusingIcons()
        let switcher = AppIconSwitcher(target: icons)
        #expect(await !switcher.apply(AppStyle(accent: .ocean)))
        #expect(await !switcher.apply(AppStyle(accent: .ocean)))
        #expect(icons.attempts == 2)
    }

    @Test("Modell: Schalter, Standard wiederherstellen, Wechsel beim Verlassen der Seite")
    func model() async {
        let settings = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()), accentStore: AccentStore())
        let icons = FixedAlternateIcons()
        let model = SettingsModel(
            settings: settings, today: TodayModel(
                clock: TestClock(instant("2026-11-10", "14:25")), timesSource: FixtureTimesSource(),
                locationSource: FixedLocationSource(place: .berlin, status: .authorized),
                connectivity: FixedConnectivity(isOnline: true), settings: settings, toast: ToastCenter(),
                locale: Locale(identifier: "de_DE")
            ),
            navigation: AppNavigation(), timesSource: FixtureTimesSource(),
            notificationAuthorizer: FixedNotificationAuthorizer(), sourceCodeURL: nil, version: "1.0 (1)",
            locale: Locale(identifier: "de_DE"), appIcons: AppIconSwitcher(target: icons)
        )
        #expect(model.offersAppIconSwitch)
        #expect(settings.style.tintsAppIcon)
        model.setAccent(.orange)
        model.setAccent(.ocean)
        // Antippen allein wechselt nichts; erst das Verlassen der Seite.
        #expect(icons.requests.isEmpty)
        await model.applyAppIcon()
        #expect(icons.requests == ["AppIcon-ocean"])
        model.setTintsAppIcon(false)
        #expect(!settings.style.isStandard)
        await model.applyAppIcon()
        #expect(icons.alternateIconName == nil)
        model.resetStyle()
        #expect(settings.style == .standard && settings.style.tintsAppIcon)
        await model.applyAppIcon()
        #expect(icons.requests == ["AppIcon-ocean", nil])
    }

    @Test("zweiter Anlass: nur vorn und nicht auf der Seite Stil – beim Start und wenn die App zurückkommt")
    func planning() {
        #expect(AppIconPlanning.applies(in: .active, isStylePageShown: false))
        #expect(!AppIconPlanning.applies(in: .active, isStylePageShown: true))
        // Im Hintergrund lehnt iOS ab; dann versucht die App es gar nicht erst.
        #expect(!AppIconPlanning.applies(in: .inactive, isStylePageShown: false))
        #expect(!AppIconPlanning.applies(in: .background, isStylePageShown: false))
    }

    @Test("Umgebung: die App wechselt über das System, Tests und Aufnahmen mit Mock-Zeiten nur im Speicher")
    func environment() {
        #expect(AppEnvironment.live.appIcons == .system)
        #expect(AppEnvironment(options: LaunchOptions(arguments: ["-debugFixtureTimes"])).appIcons == .memory())
        #expect(AppEnvironment(options: LaunchOptions(arguments: [])).appIcons == .system)
        #expect(AppEnvironment(clock: TestClock(instant("2026-11-10", "14:25")), locationSource: FixedLocationSource(
            place: nil, status: .notDetermined
        )).appIcons == .memory())
    }

    @Test("Einstellungen: der Speicher der Grundfarbe folgt dem Schalter")
    func accentStore() {
        let accents = AccentStore()
        let store = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()), accentStore: accents)
        store.updateStyle { $0.accent = .wine }
        #expect(accents.iconAccent == .wine)
        store.updateStyle { $0.tintsAppIcon = false }
        #expect(accents.accent == .wine && accents.iconAccent == .teal)
    }
}

#endif
