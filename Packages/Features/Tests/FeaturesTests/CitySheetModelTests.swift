#if DEBUG

import CoreLocation
import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Eine Ortssuche mit vorgegebenen Antworten. Sie merkt sich, wonach und wo gesucht wurde.
actor StubCitySearch: CitySearching {
    private let results: [String: [CitySuggestion]]
    private let places: [String: Place]
    private(set) var queries: [String] = []
    private(set) var centers: [Coordinates?] = []

    /// - Parameters:
    ///   - results: Suchtext → Vorschläge.
    ///   - places: Kennung eines Vorschlags → sein Ort.
    init(results: [String: [CitySuggestion]] = [:], places: [String: Place] = [:]) {
        self.results = results
        self.places = places
    }

    func suggestions(for query: String, near center: Coordinates?) async -> AsyncStream<[CitySuggestion]> {
        queries.append(query)
        centers.append(center)
        let found = results[query] ?? []
        return AsyncStream { continuation in
            continuation.yield(found)
            continuation.finish()
        }
    }

    func place(for suggestion: CitySuggestion) async -> Place? {
        places[suggestion.id]
    }
}

/// Das Stadt-Sheet: aktueller Standort, gespeicherte Städte, Suche – iphone/85.
@MainActor
@Suite("CitySheetModel")
struct CitySheetModelTests {

    private struct Fixture {
        let sheet: CitySheetModel
        let today: TodayModel
        let settings: SettingsStore
    }

    private let munichSuggestion = CitySuggestion(id: "m", title: "München", subtitle: "Bayern, Deutschland")
    private let hamburgUS = CitySuggestion(id: "h", title: "Hamburg, PA", subtitle: "Vereinigte Staaten")

    /// Die fünf Städte des Prototyps als gespeicherte Städte, Berlin als Standort – wie mit
    /// `-debugFixtureTimes`.
    private func make(
        location: any LocationSource = FixedLocationSource(place: .berlin, status: .authorized),
        connectivity: any ConnectivitySource = FixedConnectivity(isOnline: true),
        search: any CitySearching = NoCitySearch(),
        settings change: (inout SettingsStore.Snapshot) -> Void = { _ in }
    ) async -> Fixture {
        var snapshot = SettingsStore.Snapshot.prototype(city: FixtureTimes.city("berlin"))
        // Feste Namen, unabhängig von der Sprache, in der die Tests laufen.
        snapshot.savedPlaces = zip(["Berlin", "Istanbul", "Madrid", "Mekka", "Jakarta"], FixtureTimes.cities).map { name, city in
            city.place(named: name)
        }
        snapshot.manualPlace = snapshot.savedPlaces.first
        snapshot.devicePlace = snapshot.savedPlaces.first
        change(&snapshot)
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let today = TodayModel(
            clock: FixedClock(instant("2026-11-10", "14:25")), timesSource: FixtureTimesSource(),
            locationSource: location, connectivity: connectivity, citySearch: search,
            settings: settings, toast: ToastCenter(duration: .seconds(60)),
            locale: Locale(identifier: "de_DE"), deviceTimeZone: .gmt
        )
        await today.activate()
        await today.observeConnectivity()
        let sheet = CitySheetModel(today: today, search: search, locale: Locale(identifier: "de_DE"), debounce: .zero)
        return Fixture(sheet: sheet, today: today, settings: settings)
    }

    private func names(_ places: [Place]) -> [String] {
        places.map(\.name)
    }

    // MARK: - Ohne Suchtext

    @Test("ohne Suchtext: aktueller Standort mit Häkchen, darunter die fünf Städte mit ihrem Land – iphone/85")
    func initial() async {
        let fixture = await make()
        let sheet = fixture.sheet
        #expect(sheet.showsCurrentLocation)
        #expect(sheet.isCurrentLocationSelected)
        #expect(!sheet.isLocationDenied)
        #expect(names(sheet.savedPlaces) == ["Berlin", "Istanbul", "Madrid", "Mekka", "Jakarta"])
        #expect(sheet.savedPlaces.map { sheet.countryName(of: $0) } == ["Deutschland", "Türkei", "Spanien", "Saudi-Arabien", "Indonesien"])
        // Beim aktuellen Standort trägt keine Stadt das Häkchen.
        #expect(!sheet.savedPlaces.contains { sheet.isSelected($0) })
        #expect(sheet.visibleSuggestions.isEmpty)
        #expect(!sheet.showsNoResults)
        #expect(sheet.showsCities)
        #expect(sheet.footer == nil)
    }

    @Test("bei gewählter Stadt trägt sie das Häkchen, der aktuelle Standort nicht")
    func manualSelection() async {
        let fixture = await make { $0.autoLocation = false; $0.manualPlace = .istanbul }
        #expect(!fixture.sheet.isCurrentLocationSelected)
        #expect(names(fixture.sheet.savedPlaces.filter { fixture.sheet.isSelected($0) }) == ["Istanbul"])
    }

    @Test("ohne Freigabe ist „Aktueller Standort“ gesperrt und die gemerkte Stadt gilt")
    func denied() async {
        let fixture = await make(location: FixedLocationSource(place: nil, status: .denied))
        #expect(fixture.sheet.isLocationDenied)
        #expect(!fixture.sheet.isCurrentLocationSelected)
        #expect(names(fixture.sheet.savedPlaces.filter { fixture.sheet.isSelected($0) }) == ["Berlin"])
    }

    @Test("ohne gespeicherte Stadt und ohne Suchtext gibt es keine zweite Gruppe")
    func emptyList() async {
        let fixture = await make { $0.savedPlaces = [] }
        #expect(fixture.sheet.showsCurrentLocation)
        #expect(!fixture.sheet.showsCities)
    }

    // MARK: - Suche in den gespeicherten Städten

    @Test("der Suchtext filtert nach Name oder Land, ohne auf Schreibweise und Akzente zu achten", arguments: [
        ("ist", ["Istanbul"]),
        ("MEKKA", ["Mekka"]),
        ("turkei", ["Istanbul"]),
        ("Spanien", ["Madrid"]),
        // „an“ steht in Deutschland, Istanbul und Spanien.
        ("an", ["Berlin", "Istanbul", "Madrid"]),
        ("  berlin  ", ["Berlin"]),
        ("xq", []),
    ])
    func filter(query: String, expected: [String]) async {
        let fixture = await make()
        fixture.sheet.query = query
        #expect(names(fixture.sheet.savedPlaces) == expected)
        // Mit Suchtext steht die Zeile „Aktueller Standort“ nicht da.
        #expect(!fixture.sheet.showsCurrentLocation)
    }

    @Test("nur Leerzeichen sind kein Suchtext")
    func blankQuery() async {
        let fixture = await make()
        fixture.sheet.query = "   "
        #expect(fixture.sheet.showsCurrentLocation)
        #expect(fixture.sheet.savedPlaces.count == 5)
    }

    @Test("„Keine Ergebnisse“, wenn weder eine gespeicherte Stadt noch ein Vorschlag passt")
    func noResults() async {
        let fixture = await make()
        fixture.sheet.query = "xq"
        await fixture.sheet.runSearch()
        #expect(fixture.sheet.showsNoResults)
        #expect(fixture.sheet.showsCities)

        fixture.sheet.query = "ist"
        await fixture.sheet.runSearch()
        #expect(!fixture.sheet.showsNoResults)
    }

    // MARK: - Ortssuche

    @Test("mit Netz kommen unter den gespeicherten Städten die Vorschläge der Ortssuche")
    func suggestions() async {
        let search = StubCitySearch(results: ["mün": [munichSuggestion]])
        let fixture = await make(search: search)
        fixture.sheet.query = "mün"
        await fixture.sheet.runSearch()
        #expect(fixture.sheet.savedPlaces.isEmpty)
        #expect(fixture.sheet.visibleSuggestions == [munichSuggestion])
        #expect(!fixture.sheet.showsNoResults)
        #expect(!fixture.sheet.isSearching)
        #expect(await search.queries == ["mün"])
    }

    @Test("die Suche beginnt beim Ort, für den die Seite Zeiten zeigt")
    func searchCenter() async {
        let search = StubCitySearch()
        let fixture = await make(search: search)
        fixture.sheet.query = "ham"
        await fixture.sheet.runSearch()
        #expect(await search.centers == [Place.berlin.coordinates])
        #expect(fixture.today.searchCenter == Place.berlin.coordinates)
    }

    @Test("ein Vorschlag, der schon als gespeicherte Stadt dasteht, erscheint nicht doppelt")
    func deduplicates() async {
        let berlin = CitySuggestion(id: "b", title: "Berlin", subtitle: "Deutschland")
        let berlinUS = CitySuggestion(id: "b2", title: "Berlin, NH", subtitle: "Vereinigte Staaten")
        let istanbul = CitySuggestion(id: "i", title: "Istanbul, Istanbul, Türkei", subtitle: "")
        let search = StubCitySearch(results: ["berlin": [berlin, berlinUS], "ist": [istanbul]])
        let fixture = await make(search: search)

        fixture.sheet.query = "berlin"
        await fixture.sheet.runSearch()
        #expect(names(fixture.sheet.savedPlaces) == ["Berlin"])
        // Berlin in Deutschland steht schon da; Berlin in New Hampshire ist eine andere Stadt.
        #expect(fixture.sheet.visibleSuggestions == [berlinUS])

        fixture.sheet.query = "ist"
        await fixture.sheet.runSearch()
        #expect(fixture.sheet.visibleSuggestions.isEmpty)
    }

    @Test("ohne Netz fragt die Ortssuche nicht: nur gespeicherte Städte und der Hinweis darunter")
    func offline() async {
        let search = StubCitySearch(results: ["mün": [munichSuggestion]])
        let fixture = await make(connectivity: FixedConnectivity(isOnline: false), search: search)
        #expect(fixture.sheet.footer == L10n.offlineCities)

        fixture.sheet.query = "mün"
        await fixture.sheet.runSearch()
        #expect(await search.queries.isEmpty)
        #expect(fixture.sheet.visibleSuggestions.isEmpty)
        #expect(fixture.sheet.showsNoResults)

        fixture.sheet.query = "ma"
        #expect(names(fixture.sheet.savedPlaces) == ["Madrid"])
    }

    @Test("ein leerer Suchtext fragt die Ortssuche nicht und leert die Vorschläge")
    func clearingQuery() async {
        let search = StubCitySearch(results: ["mün": [munichSuggestion]])
        let fixture = await make(search: search)
        fixture.sheet.query = "mün"
        await fixture.sheet.runSearch()
        fixture.sheet.query = ""
        await fixture.sheet.runSearch()
        #expect(fixture.sheet.visibleSuggestions.isEmpty)
        #expect(await search.queries == ["mün"])
    }

    // MARK: - Wählen

    @Test("eine gespeicherte Stadt wählen: Sie gilt, das Sheet schließt")
    func chooseSaved() async {
        let fixture = await make()
        fixture.today.isCitySheetPresented = true
        fixture.sheet.choose(.istanbul)
        #expect(fixture.today.place == .istanbul)
        #expect(!fixture.today.isCitySheetPresented)
        #expect(fixture.settings.savedPlaces.count == 5)
    }

    @Test("einen Vorschlag wählen: Der Ort wird bestimmt, gilt und bleibt gespeichert")
    func chooseSuggestion() async {
        let search = StubCitySearch(results: ["mün": [munichSuggestion]], places: ["m": .munich])
        let fixture = await make(search: search)
        fixture.today.isCitySheetPresented = true
        await fixture.sheet.choose(munichSuggestion)
        #expect(fixture.today.place == .munich)
        #expect(fixture.today.showsManualTag)
        #expect(!fixture.today.isCitySheetPresented)
        #expect(fixture.settings.savedPlaces.last == .munich)
        #expect(fixture.sheet.resolving == nil)
    }

    @Test("lässt sich der Ort eines Vorschlags nicht bestimmen, bleibt alles, wie es war")
    func chooseUnresolvable() async {
        let fixture = await make(search: StubCitySearch())
        fixture.today.isCitySheetPresented = true
        await fixture.sheet.choose(munichSuggestion)
        #expect(fixture.today.place == .berlin)
        #expect(fixture.today.isCitySheetPresented)
        #expect(fixture.settings.savedPlaces.count == 5)
    }

    @Test("„Aktueller Standort“ wählen: zurück zum Standort, das Sheet schließt")
    func chooseCurrentLocation() async {
        let fixture = await make { $0.autoLocation = false; $0.manualPlace = .istanbul }
        fixture.today.isCitySheetPresented = true
        await fixture.sheet.useCurrentLocation()
        #expect(fixture.today.isAutomatic)
        #expect(fixture.sheet.isCurrentLocationSelected)
        #expect(!fixture.today.isCitySheetPresented)
    }

    // MARK: - Entfernen

    @Test("die Stadt, die gerade gilt, lässt sich nicht entfernen – alle anderen schon")
    func remove() async {
        let fixture = await make { $0.autoLocation = false; $0.manualPlace = .istanbul }
        let istanbul = fixture.sheet.savedPlaces[1]
        let madrid = fixture.sheet.savedPlaces[2]
        #expect(!fixture.sheet.canRemove(istanbul))
        #expect(fixture.sheet.canRemove(madrid))

        fixture.sheet.remove(istanbul)
        #expect(fixture.settings.savedPlaces.count == 5)
        fixture.sheet.remove(madrid)
        #expect(names(fixture.settings.savedPlaces) == ["Berlin", "Istanbul", "Mekka", "Jakarta"])
    }

    @Test("beim aktuellen Standort lässt sich auch die gemerkte Stadt entfernen; sie ist dann vergessen")
    func removeRemembered() async {
        let fixture = await make()
        let berlin = fixture.sheet.savedPlaces[0]
        #expect(fixture.sheet.canRemove(berlin))
        fixture.sheet.remove(berlin)
        #expect(names(fixture.settings.savedPlaces) == ["Istanbul", "Madrid", "Mekka", "Jakarta"])
        #expect(fixture.settings.manualPlace == nil)
        // Der aktuelle Standort gilt weiter.
        #expect(fixture.today.place?.name == "Berlin")
    }
}

/// Bausteine der Ortssuche und der Standortquelle, die sich ohne Netz und ohne Gerät prüfen lassen.
@Suite("Ortssuche und Standort")
struct LocationPiecesTests {

    @Test("der Name der Stadt steht im Titel vor dem ersten Komma", arguments: [
        ("München", "München"),
        ("Hamburg, PA", "Hamburg"),
        ("Istanbul, Istanbul, Türkiye", "Istanbul"),
        (" Wien ", "Wien"),
        ("", ""),
    ])
    func cityName(title: String, expected: String) {
        #expect(CitySuggestion(id: "x", title: title, subtitle: "").cityName == expected)
    }

    @Test("eine Suche ohne Vorschläge liefert nichts und endet sofort")
    func noCitySearch() async {
        let search = NoCitySearch()
        var updates = 0
        for await _ in await search.suggestions(for: "berlin", near: nil) {
            updates += 1
        }
        #expect(updates == 0)
        #expect(await search.place(for: CitySuggestion(id: "x", title: "Berlin", subtitle: "")) == nil)
    }

    @Test("die Freigabe von Core Location, auf das reduziert, was die App unterscheidet", arguments: [
        (CLAuthorizationStatus.notDetermined, LocationAuthorization.notDetermined),
        (.authorizedWhenInUse, .authorized),
        (.authorizedAlways, .authorized),
        (.denied, .denied),
        (.restricted, .denied),
    ])
    func authorization(status: CLAuthorizationStatus, expected: LocationAuthorization) {
        #expect(CoreLocationSource.authorization(for: status) == expected)
    }

    @Test("feste Antworten zum Netz: eine Meldung, dann Schluss")
    func fixedConnectivity() async {
        var states: [Bool] = []
        for await state in FixedConnectivity(isOnline: false).updates() {
            states.append(state)
        }
        #expect(states == [false])
    }
}

#endif
