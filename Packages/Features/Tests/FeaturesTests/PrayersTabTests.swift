import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die drei Seiten des Gebete-Tabs und ihre Chips.
@Suite("PrayersPage")
struct PrayersPageTests {

    @Test("drei Seiten in der Reihenfolge Zeiten, Qibla, Anleitung")
    func order() {
        #expect(PrayersPage.allCases == [.today, .qibla, .guide])
    }

    @Test("jede Seite hat einen eigenen Titel aus dem String Catalog")
    func titles() {
        #expect(PrayersPage.allCases.map(\.title) == [L10n.tabToday, L10n.tabQibla, L10n.guideChip])
        #expect(Set(PrayersPage.allCases.map(\.title)).count == 3)
    }

    @Test("Symbole: Uhr und Kompass aus den SF Symbols, für die Anleitung der Gebetsteppich des Prototyps")
    func symbols() {
        #expect(PrayersPage.allCases.map(\.symbol) == [.system("clock"), .system("safari"), .prayerRug])
    }

    #if DEBUG

    @Test("-debugTab wählt die Seite; alles andere beginnt bei den Zeiten", arguments: [
        (LaunchOptions.Page.today, PrayersPage.today),
        (.qibla, .qibla),
        (.guide, .guide),
        (.settings, .today),
        (.verses, .today),
        (.qada, .today),
    ])
    func debugTab(page: LaunchOptions.Page, expected: PrayersPage) {
        #expect(PrayersPage(page) == expected)
        #expect(PrayersPage(nil) == .today)
    }

    #endif
}

/// Die Ziele im Stapel der Einstellungen, soweit Phase 3 dorthin führt.
@Suite("SettingsRoute")
struct SettingsRouteTests {

    @Test("die Titel kommen aus dem String Catalog")
    func titles() {
        #expect(SettingsRoute.settings.title == L10n.settings)
        #expect(SettingsRoute.highLatitude.title == L10n.highLat)
    }
}

/// Der Toast steht kurz und verschwindet von selbst.
@MainActor
@Suite("ToastCenter")
struct ToastCenterTests {

    @Test("ein Toast erscheint mit Text und Symbol")
    func shows() {
        let center = ToastCenter(duration: .seconds(60))
        #expect(center.message == nil)
        center.show("Fadschr: Lautlos", systemImage: "bell")
        #expect(center.message?.text == "Fadschr: Lautlos")
        #expect(center.message?.systemImage == "bell")
    }

    @Test("nach seiner Frist verschwindet der Toast von selbst")
    func disappears() async throws {
        let center = ToastCenter(duration: .milliseconds(40))
        center.show("Kopiert")
        #expect(center.message != nil)
        try await Task.sleep(for: .milliseconds(400))
        #expect(center.message == nil)
    }

    @Test("ein neuer Toast ersetzt den alten und beginnt die Frist von vorn")
    func replaces() async throws {
        let center = ToastCenter(duration: .milliseconds(300))
        center.show("eins")
        let first = try #require(center.message)
        try await Task.sleep(for: .milliseconds(200))
        center.show("zwei")
        let second = try #require(center.message)
        #expect(second.text == "zwei")
        #expect(second.id != first.id)
        // 200 ms später wäre der erste Toast abgelaufen; der zweite steht noch.
        try await Task.sleep(for: .milliseconds(200))
        #expect(center.message == second)
    }

    @Test("ein Toast lässt sich sofort wegnehmen")
    func dismisses() {
        let center = ToastCenter(duration: .seconds(60))
        center.show("Kopiert")
        center.dismiss()
        #expect(center.message == nil)
    }

    @Test("ohne Angabe steht ein Toast 1,7 Sekunden, wie im Prototyp")
    func standardDuration() {
        #expect(Layout.toastDuration == 1.7)
        #expect(Layout.toastBottom == 100)
    }
}
