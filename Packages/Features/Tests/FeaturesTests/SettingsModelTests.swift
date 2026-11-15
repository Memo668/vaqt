#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Seiten der Einstellungen zeigen und tun, was `PAGES` und die Aktionen des Prototyps tun – mit den
/// Mock-Zeiten für Berlin am 10.11.2026, 14:25.
@MainActor
@Suite("Einstellungen: Modell")
struct SettingsModelTests {

    struct Fixture {
        let settings: SettingsStore
        let today: TodayModel
        let navigation: AppNavigation
        let model: SettingsModel
    }

    private func fixture(
        place: Place = .berlin,
        status: LocationAuthorization = .authorized,
        notifications: NotificationAuthorization = .notDetermined,
        _ change: (inout SettingsStore.Snapshot) -> Void = { _ in }
    ) -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        snapshot.devicePlace = place
        change(&snapshot)
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let source = FixtureTimesSource()
        let today = TodayModel(
            clock: TestClock(instant("2026-11-10", "14:25")), timesSource: source,
            locationSource: FixedLocationSource(place: place, status: status),
            connectivity: FixedConnectivity(isOnline: true), settings: settings, toast: ToastCenter(),
            locale: Locale(identifier: "de_DE")
        )
        let navigation = AppNavigation()
        let model = SettingsModel(
            settings: settings, today: today, navigation: navigation, timesSource: source,
            notificationAuthorizer: FixedNotificationAuthorizer(status: notifications),
            sourceCodeURL: nil, version: "1.0 (1)", locale: Locale(identifier: "de_DE")
        )
        today.refresh()
        return Fixture(settings: settings, today: today, navigation: navigation, model: model)
    }

    // MARK: - Startseite

    @Test("die Werte der Startseite sind die von iphone/70")
    func rootValues() throws {
        let model = fixture().model
        let germany = try #require(Locale(identifier: "de_DE").localizedString(forRegionCode: "DE"))
        #expect(model.cityValue == "Berlin")
        #expect(model.usesCurrentLocation)
        #expect(!model.isLocationDenied)
        #expect(model.locationFooter == L10n.locFooter)
        #expect(model.methodValue == "MWL")
        #expect(model.methodDetail == L10n.autoFor(country: germany))
        #expect(model.asrValue == L10n.asrStd)
        #expect(model.highLatitudeValue == L10n.hlAngle)
        #expect(model.adjustmentsValue == L10n.adjNone)
        #expect(model.perPrayerValue == L10n.ofN(n: "5"))
        #expect(model.reminderValue == L10n.minBefore(n: 10))
        #expect(model.liveActivityValue == L10n.minBefore(n: 30))
        #expect(model.soundValue == L10n.soundAdhan)
        #expect(model.appearanceValue == L10n.apSystem)
        #expect(model.showsKerahat)
        #expect(model.notificationsFooter == nil)
        #expect(model.version == "1.0 (1)")
    }

    // MARK: - Methode

    @Test("die Zusätze der Methoden sind die von methodSub(), mit Zahlen wie num()")
    func methodSubtitles() {
        let model = fixture().model
        func degrees(_ fajr: String, _ isha: String) -> String { "\(L10n.p_fajr) \(fajr)° · \(L10n.p_isha) \(isha)" }
        #expect(model.methodSubtitle(.mwl) == degrees("18", "17°"))
        #expect(model.methodSubtitle(.egyptian) == degrees("19,5", "17,5°"))
        #expect(model.methodSubtitle(.tehran) == degrees("17,7", "14°"))
        #expect(model.methodSubtitle(.ummAlQura) == degrees("18,5", L10n.minAfterMaghrib(n: 90)))
        #expect(model.methodSubtitle(.moonsighting) == degrees("18", "18°") + " · " + L10n.seasonal)
    }

    @Test("die Suche filtert nach Name und Kurzname, ohne auf Schreibweise und Akzente zu achten", arguments: [
        ("isna", [CalculationMethod.isna]),
        ("Diyanet", [.diyanet]),
        ("türk", [.diyanet]),
        ("TURKIYE", [.diyanet]),
        ("makkah", [.ummAlQura]),
        ("  JAKIM ", [.jakim]),
        ("xyz", []),
    ])
    func search(query: String, expected: [CalculationMethod]) {
        let model = fixture().model
        model.methodQuery = query
        #expect(model.filteredMethods == expected)
        #expect(!model.showsRecommended)
    }

    @Test("ohne Suchtext stehen alle elf Methoden da und „Empfohlen“ darüber")
    func noQuery() {
        let model = fixture().model
        model.methodQuery = "   "
        #expect(model.filteredMethods == CalculationMethod.allCases)
        #expect(model.showsRecommended)
        #expect(model.automaticTitle == "\(L10n.auto) · MWL")
    }

    @Test("eine gewählte Methode gilt statt der Automatik, „Automatisch“ hebt die Wahl auf")
    func selectMethod() {
        let model = fixture().model
        model.selectMethod(.diyanet)
        #expect(model.settings.calculation.method == .diyanet)
        #expect(model.methodValue == "Diyanet")
        #expect(model.methodDetail == nil)
        model.selectMethod(nil)
        #expect(model.settings.calculation.method == nil)
        #expect(model.methodValue == "MWL")
    }

    // MARK: - Asr, hohe Breiten, Korrektur

    @Test("Asr hanafitisch verschiebt die Zeit von Asr sofort")
    func hanafi() throws {
        let fixture = fixture()
        let hanafi = try #require(FixtureTimes.city("berlin")).times.asrHanafi
        fixture.model.setAsr(.hanafi)
        #expect(fixture.model.asrValue == L10n.asrHanafi)
        #expect(fixture.model.todayTime(of: .asr) == hanafi.description)
        #expect(fixture.today.timeline?.today.clockTime(of: .asr) == hanafi)
    }

    @Test("bei Moonsighting sagt die Seite „Hohe Breitengrade“, dass die Regel nicht wirkt")
    func moonsightingHint() {
        let model = fixture().model
        #expect(model.highLatitudeFooter == L10n.hlFooter)
        model.setHighLatitudeRule(.seventh)
        #expect(model.highLatitudeValue == L10n.hlSeventh)
        model.selectMethod(.moonsighting)
        #expect(model.highLatitudeFooter == L10n.hlFooter + " " + L10n.hlMoonsighting)
    }

    @Test("die Minutenkorrektur verschiebt die Zeit sofort, höchstens ±30, „Zurücksetzen“ hebt alles auf")
    func adjustments() {
        let fixture = fixture()
        let model = fixture.model
        #expect(model.todayTime(of: .fajr) == "05:16")
        model.stepAdjustment(of: .fajr, by: 1)
        model.stepAdjustment(of: .fajr, by: 1)
        #expect(model.adjustment(of: .fajr) == 2)
        #expect(model.adjustmentText(of: .fajr) == "+" + L10n.min(n: 2))
        #expect(model.todayTime(of: .fajr) == "05:18")
        #expect(model.adjustmentsValue == L10n.adjChanged(n: 1))
        #expect(model.hasAdjustments)

        for _ in 0..<40 {
            model.stepAdjustment(of: .isha, by: -1)
        }
        #expect(model.adjustment(of: .isha) == -30)
        #expect(model.adjustmentText(of: .isha) == "\u{2212}" + L10n.min(n: 30))
        #expect(model.adjustmentsValue == L10n.adjChanged(n: 2))

        model.resetAdjustments()
        #expect(!model.hasAdjustments)
        #expect(model.adjustmentText(of: .fajr) == L10n.min(n: 0))
        #expect(model.todayTime(of: .fajr) == "05:16")
    }

    @Test("ohne Zeiten rechnet die Seite „Minutenkorrektur“ sie selbst")
    func prepareTimes() {
        var snapshot = SettingsStore.Snapshot()
        snapshot.devicePlace = .berlin
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let source = FixtureTimesSource()
        let today = TodayModel(
            clock: TestClock(instant("2026-11-10", "14:25")), timesSource: source,
            locationSource: FixedLocationSource(place: .berlin, status: .authorized),
            connectivity: FixedConnectivity(isOnline: true), settings: settings, toast: ToastCenter()
        )
        let model = SettingsModel(
            settings: settings, today: today, navigation: AppNavigation(), timesSource: source,
            notificationAuthorizer: FixedNotificationAuthorizer(), sourceCodeURL: nil, version: ""
        )
        #expect(model.todayTime(of: .dhuhr) == "")
        model.prepareTimes()
        #expect(model.todayTime(of: .dhuhr) == "11:52")
    }

    // MARK: - Kerahat

    @Test("der Kerahat-Schalter wirkt sofort auf die Karten")
    func kerahat() {
        let fixture = fixture()
        #expect(fixture.today.rows.contains { $0.kerahat != nil })
        fixture.model.setShowsKerahat(false)
        #expect(!fixture.settings.showKerahat)
        #expect(fixture.today.rows.allSatisfy { $0.kerahat == nil })
    }

    // MARK: - Mitteilungen

    @Test("Erinnerung, Live-Aktivität und Klang zeigen die Wahl; 0 heißt „Aus“")
    func notifications() {
        let model = fixture().model
        model.setReminder(5)
        #expect(model.reminderValue == L10n.minBefore(n: 5))
        model.setReminder(0)
        #expect(model.reminderValue == L10n.off)
        model.setLiveActivity(60)
        #expect(model.liveActivityValue == L10n.minBefore(n: 60))
        model.setSound(.system)
        #expect(model.soundValue == L10n.soundSystem)
        #expect(model.settings.notifications == NotificationPreferences(
            reminderMinutes: 0, liveActivityMinutes: 60, sound: .system, voice: .one
        ))
    }

    @Test("„Pro Gebet“ ist dieselbe Wahl wie die Glocke der Zeiten-Seite")
    func perPrayer() {
        let fixture = fixture()
        fixture.model.setBell(.off, for: .fajr)
        #expect(fixture.model.perPrayerValue == L10n.ofN(n: "4"))
        #expect(fixture.today.bell(for: .fajr) == .off)
        fixture.model.setBell(.sound, for: .sunrise)
        #expect(fixture.model.perPrayerValue == L10n.ofN(n: "5"))
    }

    @Test("verweigert iOS die Mitteilungen, steht der Hinweis unter der Gruppe")
    func notificationsDenied() async {
        let model = fixture(notifications: .denied).model
        #expect(model.notificationsFooter == nil)
        await model.refreshNotificationAuthorization()
        #expect(model.notificationsFooter == L10n.notifDeniedFooter)
    }

    @Test("„Adhan anhören“ öffnet das Adhan-Sheet")
    func openAdhan() {
        let fixture = fixture()
        fixture.model.openAdhan()
        #expect(fixture.navigation.isAdhanSheetPresented)
    }

    // MARK: - Standort

    @Test("Standort aus: Berlin bleibt als gewählte Stadt; an: wieder der aktuelle Standort")
    func locationToggle() async {
        let fixture = fixture()
        await fixture.model.setUsesCurrentLocation(false)
        #expect(!fixture.model.usesCurrentLocation)
        #expect(fixture.settings.manualPlace == .berlin)
        #expect(fixture.model.cityValue == "Berlin")
        #expect(!fixture.today.isCitySheetPresented)
        await fixture.model.setUsesCurrentLocation(true)
        #expect(fixture.model.usesCurrentLocation)
        #expect(fixture.settings.autoLocation)
    }

    @Test("Standort aus ohne bekannte Stadt öffnet das Stadt-Sheet")
    func locationToggleWithoutCity() async {
        let fixture = fixture(place: .unnamed(latitude: 52.5, longitude: 13.4))
        await fixture.model.setUsesCurrentLocation(false)
        #expect(fixture.today.isCitySheetPresented)
    }

    @Test("ohne Freigabe ist der Schalter gesperrt und die Fußzeile sagt, was zu tun ist")
    func locationDenied() async {
        let fixture = fixture(status: .denied) { $0.manualPlace = .istanbul }
        await fixture.today.location.activate()
        #expect(fixture.model.isLocationDenied)
        #expect(!fixture.model.usesCurrentLocation)
        #expect(fixture.model.locationFooter == L10n.locDeniedFooter)
        await fixture.model.setUsesCurrentLocation(true)
        #expect(!fixture.model.usesCurrentLocation)
    }

    // MARK: - Texte

    @Test("Vorlauf 0 heißt „Aus“, sonst „… Min. vorher“")
    func leadText() {
        #expect(SettingsModel.leadText(0) == L10n.off)
        #expect(SettingsModel.leadText(15) == L10n.minBefore(n: 15))
    }

    @Test("die Korrektur schreibt + und das echte Minuszeichen wie adjText()", arguments: [
        (3, "+"), (-3, "\u{2212}"), (0, ""),
    ])
    func adjustmentText(minutes: Int, sign: String) {
        #expect(SettingsModel.adjustmentText(minutes) == sign + L10n.min(n: abs(minutes)))
    }
}

#endif
