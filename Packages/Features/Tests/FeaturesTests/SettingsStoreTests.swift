import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Einstellungen starten wie `S` im Prototyp und bleiben auf dem Gerät.
@MainActor
@Suite("SettingsStore")
struct SettingsStoreTests {

    /// Eigene UserDefaults je Test, danach wieder gelöscht.
    private func withSuite(_ body: (String) throws -> Void) rethrows {
        let name = "FeaturesTests." + UUID().uuidString
        defer { UserDefaults().removePersistentDomain(forName: name) }
        try body(name)
    }

    private func ephemeral(_ change: (inout SettingsStore.Snapshot) -> Void = { _ in }) -> SettingsStore {
        var snapshot = SettingsStore.Snapshot()
        change(&snapshot)
        return SettingsStore(storage: .ephemeral(snapshot))
    }

    // MARK: - Startwerte

    @Test("die Startwerte sind die von S im Prototyp")
    func defaults() {
        let store = ephemeral()
        #expect(store.autoLocation)
        #expect(store.manualPlace == nil)
        #expect(store.savedPlaces.isEmpty)
        #expect(store.devicePlace == nil)
        #expect(store.showKerahat)
        #expect(store.calculation == CalculationSettings())
        // `S.notif`: fajr sound, sunrise off, dhuhr sound, asr sound, maghrib sound, isha silent.
        #expect(Prayer.allCases.map { store.bell(for: $0) } == [.sound, .off, .sound, .sound, .sound, .silent])
    }

    @Test("leere UserDefaults ergeben dieselben Startwerte")
    func emptyDefaults() {
        withSuite { name in
            let store = SettingsStore(storage: .userDefaults(suiteName: name))
            #expect(store.snapshot == SettingsStore.Snapshot())
        }
    }

    // MARK: - Glocke

    @Test("die Glocke wechselt Ton → Lautlos → Aus → Ton")
    func bellCycle() {
        let store = ephemeral()
        #expect(store.cycleBell(for: .fajr) == .silent)
        #expect(store.cycleBell(for: .fajr) == .off)
        #expect(store.cycleBell(for: .fajr) == .sound)
        // Der Sonnenaufgang beginnt bei „Aus“.
        #expect(store.cycleBell(for: .sunrise) == .sound)
        // Die anderen Ereignisse bleiben, wie sie waren.
        #expect(store.bell(for: .isha) == .silent)
        #expect(store.bell(for: .dhuhr) == .sound)
    }

    // MARK: - Ort

    @Test("eine gewählte Stadt gilt statt des Standorts und steht in der Liste")
    func select() {
        let store = ephemeral()
        store.select(.istanbul)
        #expect(store.manualPlace == .istanbul)
        #expect(!store.autoLocation)
        #expect(store.savedPlaces == [.istanbul])

        store.select(.berlin)
        #expect(store.manualPlace == .berlin)
        #expect(store.savedPlaces == [.istanbul, .berlin])
    }

    @Test("dieselbe Stadt steht nur einmal in der Liste und behält ihren Platz")
    func selectTwice() {
        let store = ephemeral()
        store.select(.istanbul)
        store.select(.berlin)
        // Dieselbe Stadt noch einmal aus der Suche, mit leicht anderen Koordinaten und anderer Schreibweise.
        let again = Place(
            name: "ISTANBUL", countryCode: "TR",
            coordinates: Coordinates(latitude: 41.01, longitude: 28.96), timeZoneIdentifier: "Europe/Istanbul"
        )
        store.select(again)
        #expect(store.savedPlaces == [again, .berlin])
        #expect(store.manualPlace == again)
    }

    @Test("gleicher Name in einem anderen Land ist eine andere Stadt")
    func sameNameOtherCountry() {
        let store = ephemeral()
        let berlinUS = Place(
            name: "Berlin", countryCode: "US",
            coordinates: Coordinates(latitude: 44.4687, longitude: -71.1851), timeZoneIdentifier: "America/New_York"
        )
        store.select(.berlin)
        store.select(berlinUS)
        #expect(store.savedPlaces == [.berlin, berlinUS])
    }

    @Test("zurück zum aktuellen Standort: Die gewählte Stadt bleibt gemerkt")
    func useCurrentLocation() {
        let store = ephemeral()
        store.select(.istanbul)
        store.useCurrentLocation()
        #expect(store.autoLocation)
        #expect(store.manualPlace == .istanbul)
        #expect(store.savedPlaces == [.istanbul])
    }

    @Test("gespeicherte Städte lassen sich entfernen")
    func remove() {
        let store = ephemeral()
        store.select(.istanbul)
        store.select(.berlin)
        store.removeSavedPlace(.istanbul)
        #expect(store.savedPlaces == [.berlin])
        // Die gewählte Stadt ist davon nicht berührt.
        #expect(store.manualPlace == .berlin)
    }

    @Test("mit der gemerkten Wahl verschwindet auch die Erinnerung an sie")
    func removeChosen() {
        let store = ephemeral()
        store.select(.istanbul)
        store.useCurrentLocation()
        store.removeSavedPlace(.istanbul)
        #expect(store.savedPlaces.isEmpty)
        #expect(store.manualPlace == nil)
        #expect(store.autoLocation)
    }

    // MARK: - Speichern

    @Test("alles, was sich ändert, steht nach dem nächsten Start wieder da")
    func persistence() {
        withSuite { name in
            let store = SettingsStore(storage: .userDefaults(suiteName: name))
            store.select(.istanbul)
            store.select(.berlin)
            store.useCurrentLocation()
            store.setDevicePlace(.munich)
            store.cycleBell(for: .fajr)
            store.setBell(.sound, for: .sunrise)
            store.setShowKerahat(false)
            store.setCalculation(CalculationSettings(method: .diyanet, asr: .hanafi, highLatitudeRule: .seventh))

            let next = SettingsStore(storage: .userDefaults(suiteName: name))
            #expect(next.snapshot == store.snapshot)
            #expect(next.autoLocation)
            #expect(next.manualPlace == .berlin)
            #expect(next.savedPlaces == [.istanbul, .berlin])
            #expect(next.devicePlace == .munich)
            #expect(next.bell(for: .fajr) == .silent)
            #expect(next.bell(for: .sunrise) == .sound)
            #expect(!next.showKerahat)
            #expect(next.calculation.method == .diyanet)
            #expect(next.calculation.asr == .hanafi)
            #expect(next.calculation.highLatitudeRule == .seventh)
        }
    }

    @Test("die Wahl „Stadt statt Standort“ bleibt über den Neustart")
    func persistsManual() {
        withSuite { name in
            SettingsStore(storage: .userDefaults(suiteName: name)).select(.istanbul)
            let next = SettingsStore(storage: .userDefaults(suiteName: name))
            #expect(!next.autoLocation)
            #expect(next.manualPlace == .istanbul)
        }
    }

    @Test("ein gelöschter aktueller Ort ist auch nach dem Neustart weg")
    func clearsDevicePlace() {
        withSuite { name in
            let store = SettingsStore(storage: .userDefaults(suiteName: name))
            store.setDevicePlace(.berlin)
            store.setDevicePlace(nil)
            #expect(SettingsStore(storage: .userDefaults(suiteName: name)).devicePlace == nil)
        }
    }

    @Test("unlesbare Einträge zählen nicht: Es gelten die Startwerte")
    func unreadable() throws {
        try withSuite { name in
            let defaults = try #require(UserDefaults(suiteName: name))
            defaults.set(Data("kein JSON".utf8), forKey: SettingsStore.Key.manualPlace)
            defaults.set("laut", forKey: SettingsStore.Key.bell(.fajr))
            let store = SettingsStore(storage: .userDefaults(suiteName: name))
            #expect(store.manualPlace == nil)
            #expect(store.bell(for: .fajr) == .sound)
        }
    }

    @Test("flüchtige Einstellungen schreiben nichts in die UserDefaults")
    func ephemeralWritesNothing() {
        let before = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("settings.") }
        let store = ephemeral()
        store.select(.istanbul)
        store.cycleBell(for: .fajr)
        store.setDevicePlace(.berlin)
        store.setShowKerahat(false)
        let after = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("settings.") }
        #expect(Set(before) == Set(after))
    }

    #if DEBUG

    @Test("mit -debugFixtureTimes: die Stadt der Fixture und die fünf Städte des Prototyps")
    func prototypeSnapshot() throws {
        let jakarta = try #require(FixtureTimes.city("jakarta"))
        let snapshot = SettingsStore.Snapshot.prototype(city: jakarta)
        #expect(snapshot.autoLocation)
        #expect(snapshot.manualPlace?.countryCode == "ID")
        #expect(snapshot.devicePlace == snapshot.manualPlace)
        #expect(snapshot.savedPlaces.map(\.countryCode) == ["DE", "TR", "ES", "SA", "ID"])
        #expect(snapshot.savedPlaces.map(\.coordinates) == FixtureTimes.cities.map(\.coordinates))
        #expect(snapshot.bells == SettingsStore.standardBells)
    }

    #endif
}
