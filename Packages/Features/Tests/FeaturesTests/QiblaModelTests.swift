import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Qibla-Seite: Richtung und Entfernung vom Ort aus, der gilt, Kursanzeige, Statuszeile und die
/// Zustände ohne Ort, ohne Kompass und in Mekka.
///
/// Die Texte kommen aus dem String Catalog und erscheinen in der Sprache des Simulators; verglichen
/// wird deshalb mit `L10n`, nicht mit deutschen Literalen.
@MainActor
@Suite("QiblaModel")
struct QiblaModelTests {

    private struct Fixture {
        let model: QiblaModel
        let location: PlaceModel
        let settings: SettingsStore
    }

    private let german = Locale(identifier: "de_DE")

    /// - Parameters:
    ///   - heading: der feste Kurs; `nil` für ein Gerät ohne Kompass.
    ///   - settings: Änderungen an den Einstellungen vor dem Start.
    private func make(
        place: Place? = .berlin,
        status: LocationAuthorization = .authorized,
        heading: Heading? = Heading(degrees: 98),
        locale: Locale? = nil,
        settings change: (inout SettingsStore.Snapshot) -> Void = { _ in }
    ) async -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        change(&snapshot)
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let location = PlaceModel(
            settings: settings, locationSource: FixedLocationSource(place: place, status: status)
        )
        let model = QiblaModel(
            location: location, headingSource: FixedHeadingSource(heading: heading), locale: locale ?? german
        )
        await location.activate()
        await model.run()
        return Fixture(model: model, location: location, settings: settings)
    }

    private func abbreviation(_ point: CompassPoint) -> String {
        point.localizedAbbreviation
    }

    // MARK: - Referenzbilder

    @Test("iphone/30: Berlin, Kurs 98° – „Nach rechts drehen 39°“")
    func turnRight() async throws {
        let model = await make().model

        #expect(model.title == "\(L10n.qibla) · Berlin")
        #expect(model.hasCompass == true)
        #expect(model.showsHeading)
        #expect(model.dialHeading == 98)
        let readout = try #require(model.readout)
        #expect(readout.degrees == "98°")
        #expect(readout.direction == abbreviation(.east))

        let bearing = try #require(model.bearing)
        #expect(abs(bearing - 136.68) < 0.01)
        #expect(model.status == .turn(.right, degrees: 39))
        #expect(model.statusText == "\(L10n.turnRight) 39°")
        #expect(!model.isAligned)

        let direction = L10n.qiblaAt(deg: "137", dir: abbreviation(.southEast))
        #expect(model.info == "\(direction) · \(L10n.distance(km: "4.130"))")
        #expect(!model.showsCalibration)
        #expect(!model.needsCity)
    }

    @Test("iphone/31: Kurs 137° – „Du blickst Richtung Qibla“")
    func aligned() async throws {
        let model = await make(heading: Heading(degrees: 137)).model

        let readout = try #require(model.readout)
        #expect(readout.degrees == "137°")
        #expect(readout.direction == abbreviation(.southEast))
        #expect(model.status == .facing)
        #expect(model.statusText == L10n.facing)
        #expect(model.isAligned)
        #expect(model.alignment?.turn == nil)
    }

    @Test("iphone/32: in Mekka steht die Meldung statt der Nadel, die Statuszeile bleibt leer")
    func mecca() async throws {
        let model = await make(place: .mecca, heading: Heading(degrees: 138)).model

        #expect(model.title == "\(L10n.qibla) · Mekka")
        #expect(model.qibla?.isInMecca == true)
        #expect(model.bearing == nil)
        #expect(model.alignment == nil)
        #expect(model.status == nil)
        #expect(model.statusText == nil)
        #expect(!model.isAligned)
        #expect(model.info == L10n.inMecca)
        // Die Skala dreht sich weiter mit dem Kurs.
        #expect(model.dialHeading == 138)
        let readout = try #require(model.readout)
        #expect(readout.degrees == "138°")
        #expect(readout.direction == abbreviation(.southEast))
    }

    // MARK: - Statuszeile

    @Test("liegt die Qibla links vom Kurs, steht „Nach links drehen“ da")
    func turnLeft() async {
        let model = await make(heading: Heading(degrees: 180)).model
        #expect(model.status == .turn(.left, degrees: 43))
        #expect(model.statusText == "\(L10n.turnLeft) 43°")
        #expect(!model.isAligned)
    }

    @Test("ausgerichtet gilt bis 3° nach beiden Seiten", arguments: [
        (133.0, false), (134.0, true), (136.68, true), (139.0, true), (140.0, false),
    ])
    func tolerance(heading: Double, expected: Bool) async {
        let model = await make(heading: Heading(degrees: heading)).model
        #expect(model.isAligned == expected)
        #expect((model.status == .facing) == expected)
    }

    @Test("der Startwert des Prototyps, Kurs 99°: 38° nach rechts")
    func prototypeStart() async {
        let model = await make(heading: Heading(degrees: 99)).model
        #expect(model.statusText == "\(L10n.turnRight) 38°")
    }

    @Test("die Kursanzeige nennt ganze Grad von 0 bis 359", arguments: [
        (359.6, "0°", CompassPoint.north), (0.4, "0°", .north), (247.4, "247°", .southWest),
        (247.5, "248°", .west),
    ])
    func readoutRounds(heading: Double, degrees: String, point: CompassPoint) async throws {
        let model = await make(heading: Heading(degrees: heading)).model
        let readout = try #require(model.readout)
        #expect(readout.degrees == degrees)
        #expect(readout.direction == abbreviation(point))
    }

    // MARK: - Info-Zeile

    @Test("die Kilometer stehen in der Schreibweise der Sprache", arguments: [
        ("de_DE", "4.130"), ("tr_TR", "4.130"), ("en_GB", "4,130"), ("es_ES", "4130"),
    ])
    func distanceFormat(identifier: String, expected: String) async {
        let model = await make(locale: Locale(identifier: identifier)).model
        #expect(model.info?.hasSuffix(L10n.distance(km: expected)) == true)
    }

    @Test("Istanbul: 152° SO, 2.410 km")
    func istanbul() async {
        let model = await make(place: .istanbul).model
        let direction = L10n.qiblaAt(deg: "152", dir: abbreviation(.southEast))
        #expect(model.info == "\(direction) · \(L10n.distance(km: "2.410"))")
        #expect(model.title == "\(L10n.qibla) · Istanbul")
    }

    @Test("wenige Kilometer vor der Kaaba nennt die Zeile ganze Kilometer und zeigt wieder die Nadel")
    func nearTheKaaba() async throws {
        // 4,89 km nördlich der Kaaba: nicht mehr „in Mekka“, die Kaaba liegt genau im Süden.
        let place = Place(
            name: "Mekka", countryCode: "SA",
            coordinates: Coordinates(latitude: Qibla.kaaba.latitude + 0.044, longitude: Qibla.kaaba.longitude),
            timeZoneIdentifier: "Asia/Riyadh"
        )
        let model = await make(place: place, heading: Heading(degrees: 180)).model
        let bearing = try #require(model.bearing)
        #expect(abs(bearing - 180) < 0.001)
        #expect(model.isAligned)
        let direction = L10n.qiblaAt(deg: "180", dir: abbreviation(.south))
        #expect(model.info == "\(direction) · \(L10n.distance(km: "5"))")
    }

    // MARK: - Ohne Kompass

    @Test("ohne Kompass: Skala fest mit Norden oben, keine Kursanzeige, „Kein Kompass verfügbar“")
    func noCompass() async throws {
        let model = await make(heading: nil).model

        #expect(model.hasCompass == false)
        #expect(!model.showsHeading)
        #expect(model.dialHeading == nil)
        #expect(model.readout == nil)
        #expect(model.status == .noCompass)
        #expect(model.statusText == L10n.noCompass)
        #expect(!model.isAligned)
        #expect(!model.showsCalibration)
        // Nadel und Info-Zeile bleiben: Die Richtung steht auf der Skala und in Zahlen da.
        let bearing = try #require(model.bearing)
        #expect(abs(bearing - 136.68) < 0.01)
        #expect(model.info?.hasPrefix(L10n.qiblaAt(deg: "137", dir: abbreviation(.southEast))) == true)
    }

    @Test("ohne Kompass in Mekka: der Hinweis auf den Kompass und die Meldung")
    func noCompassInMecca() async {
        let model = await make(place: .mecca, heading: nil).model
        #expect(model.status == .noCompass)
        #expect(model.bearing == nil)
        #expect(model.info == L10n.inMecca)
    }

    @Test("solange noch nichts feststeht, steht Norden oben und die Zeilen bleiben leer")
    func beforeRunning() {
        let settings = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()))
        let location = PlaceModel(
            settings: settings, locationSource: FixedLocationSource(place: .berlin, status: .authorized)
        )
        let model = QiblaModel(location: location, headingSource: FixedHeadingSource(heading: Heading(degrees: 98)))

        #expect(model.hasCompass == nil)
        #expect(model.heading == nil)
        // Der Platz der Kursanzeige bleibt frei, die Peilmarke steht schon.
        #expect(model.showsHeading)
        #expect(model.dialHeading == 0)
        #expect(model.readout == nil)
        #expect(model.status == nil)
        #expect(!model.isAligned)
        #expect(!model.showsCalibration)
    }

    // MARK: - Genauigkeit

    @Test("die Kalibrierungskarte erscheint nur bei schlechter Genauigkeit", arguments: [
        (0.0, false), (10.0, false), (25.0, false), (26.0, true), (40.0, true),
    ])
    func calibration(accuracy: Double, expected: Bool) async {
        let model = await make(heading: Heading(degrees: 98, accuracy: accuracy)).model
        #expect(model.showsCalibration == expected)
        // Der Kurs gilt weiter, auch wenn er ungenau ist.
        #expect(model.status == .turn(.right, degrees: 39))
    }

    @Test("ein ungültiger Kurs meldet keine Ausrichtung, die Karte erscheint")
    func invalidHeading() async throws {
        let model = await make(heading: Heading(degrees: 137, accuracy: -1)).model
        #expect(model.showsCalibration)
        #expect(model.alignment == nil)
        #expect(model.status == nil)
        #expect(!model.isAligned)
        // Die Skala zeigt, was der Kompass meldet – so sieht man, dass er auf die Acht reagiert.
        #expect(model.dialHeading == 137)
        #expect(try #require(model.readout).degrees == "137°")
    }

    @Test("ohne Standortfreigabe gilt magnetisch Nord wie jeder andere Kurs")
    func magneticNorth() async {
        let heading = Heading(degrees: 137, accuracy: 10, reference: .magneticNorth)
        let model = await make(heading: heading).model
        #expect(model.heading?.reference == .magneticNorth)
        #expect(model.status == .facing)
        #expect(!model.showsCalibration)
    }

    // MARK: - Ohne Ort

    @Test("Standort verweigert und keine Stadt gewählt: keine Nadel, „Stadt wählen“ statt der Info-Zeile")
    func withoutPlace() async throws {
        let fixture = await make(status: .denied)
        let model = fixture.model

        #expect(fixture.location.place == nil)
        #expect(model.needsCity)
        #expect(model.title == L10n.qibla)
        #expect(model.qibla == nil)
        #expect(model.bearing == nil)
        #expect(model.info == nil)
        #expect(model.status == nil)
        #expect(!model.isAligned)
        // Der Kompass selbst läuft: Die Skala dreht sich, die Kursanzeige steht da.
        #expect(model.dialHeading == 98)
        #expect(try #require(model.readout).degrees == "98°")
    }

    @Test("Standort verweigert, Stadt gewählt: Die Stadt gilt")
    func deniedWithCity() async {
        let model = await make(status: .denied) { $0.manualPlace = .istanbul }.model
        #expect(!model.needsCity)
        #expect(model.title == "\(L10n.qibla) · Istanbul")
        #expect(model.info?.hasSuffix(L10n.distance(km: "2.410")) == true)
        #expect(model.bearing != nil)
    }

    @Test("der Standort ist noch nicht bestimmt: „Aktueller Standort“, keine Nadel, kein Knopf")
    func pendingPlace() async {
        let model = await make(place: nil).model
        #expect(!model.needsCity)
        #expect(model.title == "\(L10n.qibla) · \(L10n.currentLocation)")
        #expect(model.bearing == nil)
        #expect(model.info == nil)
        #expect(model.status == nil)
    }

    @Test("ohne Netz kommt der Standort ohne Namen: Richtung und Entfernung stehen trotzdem da")
    func unnamedPlace() async {
        let model = await make(place: .unnamed(latitude: 52.52, longitude: 13.405)).model
        #expect(model.title == "\(L10n.qibla) · \(L10n.currentLocation)")
        #expect(model.info?.hasSuffix(L10n.distance(km: "4.130")) == true)
        #expect(model.status == .turn(.right, degrees: 39))
    }

    @Test("wird eine andere Stadt gewählt, folgt die Seite")
    func placeChanges() async throws {
        let fixture = await make(heading: Heading(degrees: 137))
        #expect(fixture.model.isAligned)

        fixture.settings.select(.istanbul)

        #expect(fixture.model.title == "\(L10n.qibla) · Istanbul")
        let bearing = try #require(fixture.model.bearing)
        #expect(Int(bearing.rounded()) == 152)
        // Istanbul: 152°. Mit Kurs 137° sind es 15° nach rechts.
        #expect(fixture.model.status == .turn(.right, degrees: 15))
        #expect(!fixture.model.isAligned)
    }

    // MARK: - Ablauf

    @Test("es gilt der zuletzt gemeldete Kurs")
    func followsHeadings() async {
        let settings = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()))
        let location = PlaceModel(
            settings: settings, locationSource: FixedLocationSource(place: .berlin, status: .authorized)
        )
        let source = ScriptedHeadingSource(headings: [98, 110, 125, 137].map { Heading(degrees: $0) })
        let model = QiblaModel(location: location, headingSource: source, locale: german)
        await location.activate()

        await model.run()

        #expect(model.heading == Heading(degrees: 137))
        #expect(model.isAligned)
    }

    @Test("der Kompass läuft nur, solange die Seite zuhört")
    func stopsListening() async throws {
        let settings = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()))
        let location = PlaceModel(
            settings: settings, locationSource: FixedLocationSource(place: .berlin, status: .authorized)
        )
        let source = LiveHeadingSource()
        let model = QiblaModel(location: location, headingSource: source, locale: german)
        await location.activate()

        // Die Seite erscheint: Der Kompass beginnt.
        let listening = Task { await model.run() }
        try await waitUntil { await source.starts == 1 }
        await source.send(Heading(degrees: 98))
        try await waitUntil { model.heading != nil }
        #expect(model.statusText == "\(L10n.turnRight) 39°")
        #expect(await source.stops == 0)

        // Die Seite verschwindet: Der Kompass hört auf, der letzte Kurs bleibt stehen.
        listening.cancel()
        await listening.value
        try await waitUntil { await source.stops == 1 }
        #expect(model.heading == Heading(degrees: 98))

        // Sie erscheint wieder: Der Kompass beginnt von vorn.
        let again = Task { await model.run() }
        try await waitUntil { await source.starts == 2 }
        await source.send(Heading(degrees: 137))
        try await waitUntil { model.isAligned }
        again.cancel()
        await again.value
    }

    /// Wartet, bis die Bedingung gilt – höchstens zwei Sekunden.
    private func waitUntil(_ condition: () async -> Bool) async throws {
        for _ in 0..<200 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Die Bedingung ist nach zwei Sekunden nicht eingetreten")
    }
}
