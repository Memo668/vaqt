import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Welcher Ort gilt – das Modell, das sich Zeiten-Seite und Qibla-Seite teilen. Was die Zeiten-Seite
/// daraus macht, prüft `TodayModelTests`.
@MainActor
@Suite("PlaceModel")
struct PlaceModelTests {

    private func make(
        location: any LocationSource = FixedLocationSource(place: .berlin, status: .authorized),
        settings change: (inout SettingsStore.Snapshot) -> Void = { _ in }
    ) -> (model: PlaceModel, settings: SettingsStore) {
        var snapshot = SettingsStore.Snapshot()
        change(&snapshot)
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        return (PlaceModel(settings: settings, locationSource: location), settings)
    }

    @Test("mit Freigabe gilt der aktuelle Standort")
    func currentLocation() async {
        let (model, settings) = make()
        #expect(model.authorization == .notDetermined)
        #expect(model.place == nil)

        #expect(await model.activate())

        #expect(model.authorization == .authorized)
        #expect(model.isAutomatic)
        #expect(model.place == .berlin)
        #expect(settings.devicePlace == .berlin)
        #expect(model.cityTitle == "Berlin")
        #expect(model.searchCenter == Place.berlin.coordinates)
        #expect(!model.needsCity)
    }

    @Test("beim Start gilt sofort der zuletzt bestimmte Ort")
    func knownPlace() {
        let (model, _) = make { $0.devicePlace = .munich }
        #expect(model.place == .munich)
        #expect(model.cityTitle == "München")
    }

    @Test("noch nicht gefragt: Das Modell fragt und meldet jeden Schritt")
    func asks() async {
        let source = ScriptedLocationSource(status: .notDetermined, afterRequest: .authorized, places: [.berlin])
        let (model, _) = make(location: source)
        var steps: [Place?] = []

        await model.activate { steps.append(model.place) }

        #expect(await source.requests == 1)
        #expect(await source.lookups == 1)
        // Freigabe gelesen, Abfrage beantwortet, Standort da.
        #expect(steps == [nil, nil, .berlin])
        #expect(model.authorization == .authorized)
    }

    @Test("verweigert und keine Stadt gewählt: kein Ort, eine Stadt fehlt")
    func deniedWithoutCity() async {
        let source = ScriptedLocationSource(status: .denied, places: [.berlin])
        let (model, _) = make(location: source)
        var steps = 0

        await model.activate { steps += 1 }

        #expect(model.authorization == .denied)
        #expect(!model.isAutomatic)
        #expect(model.place == nil)
        #expect(model.needsCity)
        #expect(model.cityTitle == L10n.citySheetTitle)
        #expect(model.searchCenter == nil)
        // Ohne Freigabe wird weder gefragt noch geortet.
        #expect(await source.requests == 0)
        #expect(await source.lookups == 0)
        #expect(steps == 1)
    }

    @Test("verweigert, Stadt gewählt: Die Stadt gilt, auch wenn die Automatik eingeschaltet ist")
    func deniedWithCity() async {
        let (model, settings) = make(location: FixedLocationSource(place: .berlin, status: .denied)) {
            $0.manualPlace = .istanbul
        }
        await model.activate()
        #expect(settings.autoLocation)
        #expect(!model.isAutomatic)
        #expect(model.place == .istanbul)
        #expect(!model.needsCity)
    }

    @Test("ist eine Stadt gewählt, wird der Standort nicht bestimmt")
    func manualCity() async {
        let source = ScriptedLocationSource(status: .notDetermined, afterRequest: .authorized, places: [.berlin])
        let (model, settings) = make(location: source) {
            $0.autoLocation = false
            $0.manualPlace = .istanbul
        }
        var steps = 0

        await model.activate { steps += 1 }

        #expect(model.place == .istanbul)
        #expect(settings.devicePlace == nil)
        #expect(await source.requests == 0)
        #expect(await source.lookups == 0)
        #expect(steps == 1)
    }

    @Test("die Wahl in den Einstellungen gilt sofort")
    func followsSettings() async {
        let (model, settings) = make()
        await model.activate()

        settings.select(.istanbul)
        #expect(!model.isAutomatic)
        #expect(model.place == .istanbul)

        settings.useCurrentLocation()
        #expect(model.isAutomatic)
        #expect(model.place == .berlin)
    }

    @Test("solange der Name des Standorts fehlt, steht „Aktueller Standort“ da")
    func unnamed() async {
        let here = Place.unnamed(latitude: 48.1351, longitude: 11.5820)
        let (model, _) = make(location: FixedLocationSource(place: here, status: .authorized))
        await model.activate()
        #expect(model.place == here)
        #expect(model.cityTitle == L10n.currentLocation)
    }

    @Test("ohne Netz gilt der Name des zuletzt bestimmten Ortes weiter, wenn der neue Standort in der Nähe liegt")
    func keepsName() async {
        // Berlin-Spandau, gut 13 km vom Stadtzentrum.
        let here = Place.unnamed(latitude: 52.5352, longitude: 13.2004)
        let (model, settings) = make(location: FixedLocationSource(place: here, status: .authorized)) {
            $0.devicePlace = .berlin
        }
        #expect(await model.updateDevicePlace())
        #expect(settings.devicePlace?.name == "Berlin")
        #expect(settings.devicePlace?.coordinates == here.coordinates)
    }

    @Test("kommt kein Standort, bleibt der zuletzt bestimmte Ort stehen")
    func noFix() async {
        let (model, settings) = make(location: FixedLocationSource(place: nil, status: .authorized)) {
            $0.devicePlace = .berlin
        }
        var steps = 0
        await model.activate { steps += 1 }
        #expect(await !model.updateDevicePlace())
        #expect(settings.devicePlace == .berlin)
        #expect(model.place == .berlin)
        // Nur die gelesene Freigabe wird gemeldet.
        #expect(steps == 1)
    }

    @Test("läuft schon ein Durchlauf, geschieht beim zweiten nichts")
    func onlyOnce() async {
        let source = ScriptedLocationSource(status: .authorized, places: [.berlin])
        let (model, _) = make(location: source)

        async let first = model.activate()
        async let second = model.activate()
        let results = await [first, second]

        #expect(results.sorted { !$0 && $1 } == [false, true])
        #expect(await source.lookups == 1)
        #expect(model.place == .berlin)
    }
}
