#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Zeiten-Seite: welcher Ort gilt, was die Karten zeigen, wann Banner und Hinweise erscheinen.
/// Gerechnet wird mit den Mock-Zeiten des Prototyps – den Zahlen der Referenzbilder.
@MainActor
@Suite("TodayModel")
struct TodayModelTests {

    private struct Fixture {
        let model: TodayModel
        let clock: TestClock
        let settings: SettingsStore
        let toast: ToastCenter
    }

    private let german = Locale(identifier: "de_DE")

    private func make(
        now: Date = instant("2026-11-10", "14:25"),
        times: any PrayerTimesSource = FixtureTimesSource(),
        location: any LocationSource = FixedLocationSource(place: .berlin, status: .authorized),
        connectivity: any ConnectivitySource = FixedConnectivity(isOnline: true),
        locale: Locale? = nil,
        settings change: (inout SettingsStore.Snapshot) -> Void = { _ in }
    ) -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        change(&snapshot)
        let clock = TestClock(now)
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let toast = ToastCenter(duration: .seconds(60))
        let model = TodayModel(
            clock: clock, timesSource: times, locationSource: location, connectivity: connectivity,
            settings: settings, toast: toast, locale: locale ?? german, deviceTimeZone: .gmt
        )
        return Fixture(model: model, clock: clock, settings: settings, toast: toast)
    }

    private func times(_ model: TodayModel) -> [String] {
        model.rows.map(\.time.description)
    }

    // MARK: - Aktueller Standort

    @Test("mit Freigabe gilt der aktuelle Standort: iphone/10")
    func currentLocation() async {
        let fixture = make()
        await fixture.model.activate()
        let model = fixture.model

        #expect(model.authorization == .authorized)
        #expect(model.isAutomatic)
        #expect(model.place == .berlin)
        #expect(fixture.settings.devicePlace == .berlin)
        #expect(model.cityTitle == "Berlin")
        #expect(model.showsLocationSymbol)
        #expect(!model.showsManualTag)
        #expect(!model.showsLocationDeniedBanner)
        #expect(!model.isCitySheetPresented)

        #expect(model.day == day("2026-11-10"))
        #expect(model.timeline != nil)
        #expect(!model.hasNoTimes)
        #expect(!model.isHighLatitude)
        #expect(times(model) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(model.rows.map(\.status) == [.passed, .passed, .passed, .current, .upcoming, .upcoming])
    }

    @Test("der Text des Stadt-Buttons für VoiceOver nennt Stadt und Aktion")
    func cityLabel() async {
        let fixture = make()
        await fixture.model.activate()
        #expect(fixture.model.cityAccessibilityLabel == "\(L10n.city): Berlin. \(L10n.change)")
    }

    @Test("noch nicht gefragt: Die Seite fragt selbst und zeigt dann den Standort")
    func asksForPermission() async {
        let source = ScriptedLocationSource(status: .notDetermined, afterRequest: .authorized, places: [.berlin])
        let fixture = make(location: source)
        // Vor der Antwort: Automatik, aber noch kein Ort.
        #expect(fixture.model.isAutomatic)
        #expect(fixture.model.cityTitle == L10n.currentLocation)

        await fixture.model.activate()
        #expect(await source.requests == 1)
        #expect(fixture.model.authorization == .authorized)
        #expect(fixture.model.place == .berlin)
        #expect(fixture.model.rows.count == 6)
    }

    @Test("ist die Freigabe schon erteilt, fragt die Seite nicht noch einmal")
    func doesNotAskTwice() async {
        let source = ScriptedLocationSource(status: .authorized, places: [.berlin])
        let fixture = make(location: source)
        await fixture.model.activate()
        await fixture.model.activate()
        #expect(await source.requests == 0)
        #expect(await source.lookups == 2)
    }

    @Test("lässt sich der Standort nicht bestimmen, bleibt der zuletzt bekannte Ort")
    func keepsKnownPlace() async {
        let source = ScriptedLocationSource(status: .authorized, places: [nil])
        let fixture = make(location: source) { $0.devicePlace = .munich }
        await fixture.model.activate()
        #expect(fixture.model.place == .munich)
        #expect(fixture.model.cityTitle == "München")
        #expect(fixture.model.rows.count == 6)
    }

    @Test("ohne bekannten Ort steht „Aktueller Standort“ da, ohne Bogen und Karten")
    func noPlaceYet() async {
        let source = ScriptedLocationSource(status: .authorized, places: [nil])
        let fixture = make(location: source)
        await fixture.model.activate()
        #expect(fixture.model.place == nil)
        #expect(fixture.model.cityTitle == L10n.currentLocation)
        #expect(fixture.model.showsLocationSymbol)
        #expect(fixture.model.timeline == nil)
        #expect(fixture.model.rows.isEmpty)
        // Kein Ort ist etwas anderes als ein Ort ohne Zeiten.
        #expect(!fixture.model.hasNoTimes)
    }

    // MARK: - Ohne Netz

    @Test("ohne Netz kommt der Standort ohne Namen: Die Seite rechnet trotzdem und zeigt „Aktueller Standort“")
    func unnamedPlace() async {
        let here = Place.unnamed(latitude: 48.1351, longitude: 11.5820)
        let fixture = make(location: ScriptedLocationSource(status: .authorized, places: [here]))
        await fixture.model.activate()
        #expect(fixture.model.place == here)
        #expect(fixture.model.cityTitle == L10n.currentLocation)
        #expect(fixture.model.rows.count == 6)
    }

    @Test("ohne Netz gilt der zuletzt bestimmte Ort weiter, wenn der Standort in seiner Nähe liegt")
    func unnamedPlaceNearKnown() async {
        // Berlin-Spandau, gut 13 km vom Stadtzentrum.
        let here = Place.unnamed(latitude: 52.5352, longitude: 13.2004, zone: "Europe/Paris")
        let fixture = make(location: ScriptedLocationSource(status: .authorized, places: [here])) {
            $0.devicePlace = .berlin
        }
        await fixture.model.activate()
        #expect(fixture.model.cityTitle == "Berlin")
        #expect(fixture.model.place?.countryCode == "DE")
        #expect(fixture.model.place?.timeZoneIdentifier == "Europe/Berlin")
        #expect(fixture.model.place?.coordinates == here.coordinates)
    }

    @Test("der Hinweis „Offline“ folgt dem Netz")
    func offline() async {
        let fixture = make(connectivity: FixedConnectivity(isOnline: false))
        #expect(!fixture.model.isOffline)
        await fixture.model.observeConnectivity()
        #expect(fixture.model.isOffline)

        let online = make(connectivity: ScriptedConnectivity(states: [false, true]))
        await online.model.observeConnectivity()
        #expect(!online.model.isOffline)
    }

    @Test("kommt das Netz zurück, holt die Seite den fehlenden Namen nach")
    func namesPlaceWhenOnline() async {
        let here = Place.unnamed(latitude: 48.1351, longitude: 11.5820)
        let source = ScriptedLocationSource(status: .authorized, places: [here, .munich])
        let fixture = make(location: source, connectivity: ScriptedConnectivity(states: [false, true]))
        await fixture.model.activate()
        #expect(fixture.model.cityTitle == L10n.currentLocation)

        await fixture.model.observeConnectivity()
        #expect(fixture.model.cityTitle == "München")
        #expect(await source.lookups == 2)
    }

    @Test("hat der Ort schon einen Namen, fragt die Seite bei wiederkehrendem Netz nicht erneut")
    func doesNotLookUpNamedPlaceAgain() async {
        let source = ScriptedLocationSource(status: .authorized, places: [.berlin])
        let fixture = make(location: source, connectivity: ScriptedConnectivity(states: [false, true]))
        await fixture.model.activate()
        await fixture.model.observeConnectivity()
        #expect(await source.lookups == 1)
    }

    // MARK: - Standort verweigert

    @Test("Standort verweigert, Stadt gewählt: Banner, kein Symbol, keine Marke – iphone/17")
    func denied() async {
        let fixture = make(location: FixedLocationSource(place: .berlin, status: .denied)) {
            $0.manualPlace = .berlin
            $0.devicePlace = .berlin
        }
        await fixture.model.activate()
        let model = fixture.model
        #expect(model.authorization == .denied)
        #expect(!model.isAutomatic)
        #expect(model.place == .berlin)
        #expect(model.showsLocationDeniedBanner)
        #expect(!model.showsLocationSymbol)
        #expect(!model.showsManualTag)
        #expect(!model.isCitySheetPresented)
        #expect(times(model) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        // Die Automatik bleibt gemerkt: Wird der Standort wieder erlaubt, gilt er wieder.
        #expect(fixture.settings.autoLocation)
    }

    @Test("Standort verweigert, noch keine Stadt: „Stadt wählen“ und das Stadt-Sheet öffnet sich")
    func deniedWithoutCity() async {
        let fixture = make(location: FixedLocationSource(place: nil, status: .denied))
        await fixture.model.activate()
        #expect(fixture.model.cityTitle == L10n.citySheetTitle)
        // Für VoiceOver sagt der Titel schon, was der Button tut.
        #expect(fixture.model.cityAccessibilityLabel == L10n.citySheetTitle)
        #expect(fixture.model.showsLocationDeniedBanner)
        #expect(fixture.model.isCitySheetPresented)
        #expect(fixture.model.rows.isEmpty)
        #expect(fixture.model.searchCenter == nil)
    }

    @Test("wird die Abfrage abgelehnt, öffnet sich das Stadt-Sheet")
    func refusesPermission() async {
        let source = ScriptedLocationSource(status: .notDetermined, afterRequest: .denied)
        let fixture = make(location: source)
        await fixture.model.activate()
        #expect(await source.requests == 1)
        #expect(fixture.model.showsLocationDeniedBanner)
        #expect(fixture.model.isCitySheetPresented)
    }

    // MARK: - Gewählte Stadt

    @Test("eine gewählte Stadt gilt statt des Standorts und trägt die Marke „manuell“")
    func manual() async {
        let source = ScriptedLocationSource(status: .authorized, places: [.berlin])
        let fixture = make(location: source) {
            $0.autoLocation = false
            $0.manualPlace = .istanbul
        }
        await fixture.model.activate()
        let model = fixture.model
        #expect(!model.isAutomatic)
        #expect(model.place == .istanbul)
        #expect(model.cityTitle == "Istanbul")
        #expect(model.showsManualTag)
        #expect(!model.showsLocationSymbol)
        #expect(!model.showsLocationDeniedBanner)
        // 14:25 in Berlin ist 16:25 in Istanbul: Asr läuft seit 15:36.
        #expect(times(model) == ["06:09", "07:36", "12:53", "15:36", "18:00", "19:23"])
        #expect(model.rows.map(\.status) == [.passed, .passed, .passed, .current, .upcoming, .upcoming])
        // Der Standort wird dann gar nicht erst bestimmt.
        #expect(await source.lookups == 0)
    }

    @Test("Stadt im Sheet wählen: gilt sofort, wird gespeichert, das Sheet schließt")
    func select() async {
        let fixture = make()
        await fixture.model.activate()
        fixture.model.isCitySheetPresented = true

        fixture.model.select(.istanbul)
        #expect(fixture.model.place == .istanbul)
        #expect(fixture.model.showsManualTag)
        #expect(!fixture.model.isCitySheetPresented)
        #expect(fixture.settings.savedPlaces == [.istanbul])
        #expect(!fixture.settings.autoLocation)
        #expect(times(fixture.model).first == "06:09")
    }

    @Test("„Aktueller Standort“ im Sheet: zurück zum Standort")
    func backToCurrentLocation() async {
        let fixture = make { $0.autoLocation = false; $0.manualPlace = .istanbul }
        await fixture.model.activate()
        fixture.model.isCitySheetPresented = true

        await fixture.model.useCurrentLocation()
        #expect(fixture.model.isAutomatic)
        #expect(fixture.model.place == .berlin)
        #expect(!fixture.model.isCitySheetPresented)
        #expect(times(fixture.model).first == "05:16")
    }

    @Test("ohne Freigabe bewirkt „Aktueller Standort“ nichts")
    func currentLocationWhileDenied() async {
        let fixture = make(location: FixedLocationSource(place: nil, status: .denied)) {
            $0.autoLocation = false
            $0.manualPlace = .istanbul
        }
        await fixture.model.activate()
        fixture.model.isCitySheetPresented = true
        await fixture.model.useCurrentLocation()
        #expect(!fixture.settings.autoLocation)
        #expect(fixture.model.isCitySheetPresented)
        #expect(fixture.model.place == .istanbul)
    }

    // MARK: - Datum

    @Test("gregorianisches und Hijri-Datum in der Sprache der App", arguments: [
        ("de_DE", "Dienstag, 10. November", "30. Dschumada I 1448"),
        ("tr_TR", "10 Kasım Salı", "30 Cemaziyelevvel 1448"),
        ("en_GB", "Tuesday 10 November", "30 Jumada I 1448"),
        ("es_ES", "martes, 10 de noviembre", "30 de jumada I de 1448"),
    ])
    func dates(locale: String, gregorian: String, hijri: String) async {
        let fixture = make(locale: Locale(identifier: locale))
        await fixture.model.activate()
        #expect(fixture.model.gregorianDateText == gregorian)
        #expect(fixture.model.hijriDateText == hijri)
    }

    @Test("das Datum ist das am Ort, nicht das des Geräts")
    func dateAtPlace() async {
        // 23:30 in Berlin ist in Jakarta schon der nächste Tag, 05:30.
        let jakarta = Place(
            name: "Jakarta", countryCode: "ID",
            coordinates: Coordinates(latitude: -6.2088, longitude: 106.8456), timeZoneIdentifier: "Asia/Jakarta"
        )
        let fixture = make(now: instant("2026-11-10", "23:30")) {
            $0.autoLocation = false
            $0.manualPlace = jakarta
        }
        await fixture.model.activate()
        #expect(fixture.model.day == day("2026-11-11"))
        #expect(fixture.model.gregorianDateText == "Mittwoch, 11. November")
    }

    // MARK: - Wechsel der Phase

    @Test("mit der nächsten Phase bauen sich die Karten neu auf")
    func phaseChange() async {
        let fixture = make()
        await fixture.model.activate()
        #expect(fixture.model.rows.first { $0.status == .current }?.prayer == .asr)

        fixture.clock.now = instant("2026-11-10", "16:27")
        fixture.model.refresh()
        #expect(fixture.model.rows.first { $0.status == .current }?.prayer == .maghrib)
        #expect(fixture.model.rows.map(\.status) == [.passed, .passed, .passed, .passed, .current, .upcoming])
    }

    @Test("ein laufendes Kerahat-Fenster steht in der Karte: iphone/15")
    func kerahat() async throws {
        let fixture = make(now: instant("2026-11-10", "16:05"))
        await fixture.model.activate()
        let asr = try #require(fixture.model.rows.first { $0.prayer == .asr })
        #expect(asr.kerahat?.isActive == true)
        #expect(asr.kerahat?.end.description == "16:27")
    }

    @Test("nach Mitternacht gilt der neue Tag mit einem neuen Zeitstrahl")
    func midnight() async throws {
        let fixture = make(now: instant("2026-11-10", "23:30"))
        await fixture.model.activate()
        #expect(fixture.model.day == day("2026-11-10"))
        #expect(fixture.model.rows.first { $0.status == .current }?.prayer == .isha)

        fixture.clock.now = instant("2026-11-11", "00:05")
        fixture.model.refresh()
        #expect(fixture.model.day == day("2026-11-11"))
        #expect(try #require(fixture.model.timeline).covers(fixture.clock.now))
        // Vor Fadschr ist nichts hervorgehoben.
        #expect(fixture.model.rows.allSatisfy { $0.status == .upcoming })
        #expect(fixture.model.gregorianDateText == "Mittwoch, 11. November")
    }

    // MARK: - Hinweise

    @Test("hohe Breiten: Info-Marken an Fadschr und Ischa und der Hinweis mit Stadt und Regel – iphone/18")
    func highLatitude() async {
        let fixture = make(now: instant("2027-06-21", "23:47"), times: FixtureTimesSource(highLatitude: true))
        await fixture.model.activate()
        let model = fixture.model
        #expect(model.isHighLatitude)
        #expect(times(model) == ["02:34", "04:43", "13:12", "17:33", "21:33", "23:35"])
        #expect(model.rows.filter(\.showsHighLatitudeMark).map(\.prayer) == [.fajr, .isha])
        #expect(model.highLatitudeNote == L10n.highLatNote(city: "Berlin", rule: L10n.hlAngle))
        #expect(model.gregorianDateText == "Montag, 21. Juni")
        #expect(model.hijriDateText == "16. Muharram 1449")
    }

    @Test("der Hinweis nennt die gewählte Regel")
    func highLatitudeRule() async {
        let fixture = make(now: instant("2027-06-21", "23:47"), times: FixtureTimesSource(highLatitude: true)) {
            $0.calculation.highLatitudeRule = .middle
        }
        await fixture.model.activate()
        #expect(fixture.model.highLatitudeNote == L10n.highLatNote(city: "Berlin", rule: L10n.hlMiddle))
        // Mit „Nachtmitte“ fallen Fadschr und Ischa auf 01:08.
        #expect(times(fixture.model).first == "01:08")
        #expect(times(fixture.model).last == "01:08")
    }

    @Test("ohne Zeiten – die Sonne geht nicht auf oder unter – steht der Hinweis statt Bogen und Karten")
    func noTimes() async {
        let fixture = make(times: NoTimesSource())
        await fixture.model.activate()
        #expect(fixture.model.place == .berlin)
        #expect(fixture.model.hasNoTimes)
        #expect(fixture.model.timeline == nil)
        #expect(fixture.model.rows.isEmpty)
        #expect(!fixture.model.isHighLatitude)
    }

    @Test("die echte Rechnung: Berlin am 10.11.2026 mit der Automatik für Deutschland")
    func realCalculation() async {
        let fixture = make(times: AdhanTimesSource())
        await fixture.model.activate()
        #expect(times(fixture.model) == ["05:21", "07:12", "11:55", "13:59", "16:28", "18:13"])
        #expect(!fixture.model.isHighLatitude)
    }

    @Test("die echte Rechnung erkennt die hellen Nächte in Berlin am 21. Juni")
    func realHighLatitude() async {
        let fixture = make(now: instant("2027-06-21", "12:00"), times: AdhanTimesSource())
        await fixture.model.activate()
        #expect(fixture.model.isHighLatitude)
        #expect(fixture.model.rows.filter(\.showsHighLatitudeMark).map(\.prayer) == [.fajr, .isha])
    }

    // MARK: - Tage vor und zurück (Spec § 9.4)

    @Test("Morgen (iphone/23): die Zeiten des Tages wie im Prototyp, keine Karte läuft oder ist vorbei")
    func nextDay() async {
        let fixture = make()
        await fixture.model.activate()
        let model = fixture.model
        #expect(!model.isShowingOtherDay)

        model.showNextDay()
        #expect(model.dayOffset == 1)
        #expect(model.isShowingOtherDay)
        #expect(model.shownDay == day("2026-11-11"))
        #expect(model.gregorianDateText == "Mittwoch, 11. November")
        #expect(model.hijriDateText == "1. Dschumada II 1448")
        #expect(model.relativeDayText == "Morgen")
        #expect(model.otherDayTimes != nil)
        #expect(times(model) == ["05:18", "07:16", "11:52", "13:59", "16:25", "18:16"])
        #expect(model.rows.allSatisfy { $0.status == .upcoming })
        #expect(model.rows.compactMap(\.kerahat).allSatisfy { !$0.isActive })
        #expect(model.rows.compactMap(\.kerahat).map(\.range) == ["07:16\u{2060}–\u{2060}08:01", "11:42\u{2060}–\u{2060}11:52", "15:40\u{2060}–\u{2060}16:25"])
        // Der Zeitstrahl bleibt der von heute – für Countdown und Anleitung.
        #expect(model.timeline?.today.day == day("2026-11-10"))

        model.backToToday()
        #expect(model.dayOffset == 0)
        #expect(model.otherDayTimes == nil)
        #expect(times(model) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(model.rows.map(\.status) == [.passed, .passed, .passed, .current, .upcoming, .upcoming])
    }

    @Test("Der Tag relativ zu heute, mit großem Anfangsbuchstaben", arguments: [
        (1, "Morgen"), (2, "Übermorgen"), (3, "In 3 Tagen"), (-1, "Gestern"), (-2, "Vorgestern"), (-10, "Vor 10 Tagen"),
    ])
    func relativeDay(offset: Int, expected: String) {
        #expect(TodayModel.relativeDayText(offset: offset, locale: german) == expected)
    }

    @Test("Die Navigation reicht ein Jahr in jede Richtung")
    func range() async {
        let fixture = make()
        await fixture.model.activate()
        let model = fixture.model
        model.show(dayOffset: 400)
        #expect(model.dayOffset == 365)
        #expect(!model.canShowNextDay)
        model.showNextDay()
        #expect(model.dayOffset == 365)
        #expect(model.shownDay == day("2027-11-10"))
        #expect(model.canShowPreviousDay)

        model.show(dayOffset: -365)
        #expect(!model.canShowPreviousDay)
        model.showPreviousDay()
        #expect(model.dayOffset == -365)
        #expect(model.shownDay == day("2025-11-10"))
        #expect(!model.rows.isEmpty)
    }

    @Test("Der gewählte Tag bleibt relativ zu heute: nach Mitternacht rückt er mit")
    func dayOffsetAcrossMidnight() async {
        let fixture = make(now: instant("2026-11-10", "23:59"))
        await fixture.model.activate()
        fixture.model.show(dayOffset: 2)
        #expect(fixture.model.shownDay == day("2026-11-12"))
        fixture.clock.now = instant("2026-11-11", "00:01")
        fixture.model.refresh()
        #expect(fixture.model.shownDay == day("2026-11-13"))
    }

    @Test("Echt gerechnet: ein Tag in Tromsø ohne Sonnenuntergang zeigt den Hinweis statt der Karten")
    func otherDayWithoutTimes() async {
        let tromso = Place(
            name: "Tromsø", countryCode: "NO",
            coordinates: Coordinates(latitude: 69.6492, longitude: 18.9553), timeZoneIdentifier: "Europe/Oslo"
        )
        let fixture = make(
            now: instant("2027-05-01", "12:00"), times: AdhanTimesSource(),
            location: FixedLocationSource(place: tromso, status: .authorized)
        )
        await fixture.model.activate()
        let model = fixture.model
        #expect(!model.hasNoTimes)
        model.show(dayOffset: 51)   // 21.06.2027
        #expect(model.otherDayTimes == nil)
        #expect(model.hasNoTimes)
        #expect(model.rows.isEmpty)
        model.backToToday()
        #expect(!model.hasNoTimes)
    }

    @Test("Hohe Breiten an einem anderen Tag: Info-Marken wie heute")
    func otherDayHighLatitude() async {
        let fixture = make(now: instant("2027-06-21", "23:47"), times: FixtureTimesSource(highLatitude: true))
        await fixture.model.activate()
        fixture.model.showNextDay()
        #expect(fixture.model.isHighLatitude)
        #expect(fixture.model.rows.filter(\.showsHighLatitudeMark).map(\.prayer) == [.fajr, .isha])
    }

    // MARK: - Glocke

    @Test("Tippen auf die Glocke wechselt den Stand und nennt ihn im Toast")
    func bell() async {
        let fixture = make()
        await fixture.model.activate()
        #expect(fixture.model.bell(for: .fajr) == .sound)

        fixture.model.cycleBell(for: .fajr)
        #expect(fixture.model.bell(for: .fajr) == .silent)
        #expect(fixture.settings.bell(for: .fajr) == .silent)
        #expect(fixture.toast.message?.text == L10n.bellToast(p: Prayer.fajr.localizedName, s: BellState.silent.localizedName))
        #expect(fixture.toast.message?.systemImage == "bell")

        fixture.model.cycleBell(for: .fajr)
        #expect(fixture.toast.message?.text == L10n.bellToast(p: Prayer.fajr.localizedName, s: BellState.off.localizedName))
        #expect(fixture.toast.message?.systemImage == "bell.slash")

        // Der Sonnenaufgang beginnt bei „Aus“ und springt auf „Ton“.
        fixture.model.cycleBell(for: .sunrise)
        #expect(fixture.toast.message?.systemImage == "bell.and.waves.left.and.right")
    }
}

#endif
