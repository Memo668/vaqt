#if DEBUG

import Foundation
import PrayerCore
import Testing
@testable import Features

/// Das Onboarding fragt Standort und Mitteilungen erst nach dem jeweiligen Vorab-Bildschirm – wie
/// `onboardingHTML()` und die Aktionen `ob-*` im Prototyp (Spec § 1).
@MainActor
@Suite("Onboarding")
struct OnboardingModelTests {

    struct Fixture {
        let settings: SettingsStore
        let today: TodayModel
        let navigation: AppNavigation
        let model: OnboardingModel
        let location: ScriptedLocationSource
        let notifications: CountingNotificationAuthorizer
        let scheduler: RecordingNotificationScheduler
    }

    private func fixture(
        status: LocationAuthorization = .notDetermined, afterRequest: LocationAuthorization = .authorized,
        step: OnboardingStep = .welcome
    ) -> Fixture {
        let settings = SettingsStore(storage: .ephemeral(SettingsStore.Snapshot()))
        let location = ScriptedLocationSource(status: status, afterRequest: afterRequest, places: [.berlin])
        let today = TodayModel(
            clock: TestClock(instant("2026-11-10", "14:25")), timesSource: FixtureTimesSource(),
            locationSource: location, connectivity: FixedConnectivity(isOnline: true),
            settings: settings, toast: ToastCenter()
        )
        let navigation = AppNavigation(onboardingStep: step)
        let notifications = CountingNotificationAuthorizer()
        let scheduler = RecordingNotificationScheduler()
        let notificationModel = NotificationModel(
            settings: settings, location: today.location, clock: today.clock, timesSource: FixtureTimesSource(),
            authorizer: notifications, scheduler: scheduler
        )
        let model = OnboardingModel(navigation: navigation, today: today, notifications: notificationModel)
        return Fixture(
            settings: settings, today: today, navigation: navigation, model: model, location: location,
            notifications: notifications, scheduler: scheduler
        )
    }

    @Test("Willkommen → Weiter führt zum Standort, ohne zu fragen")
    func welcome() async {
        let fixture = fixture()
        #expect(fixture.model.step == .welcome)
        #expect(fixture.model.showsSkip)
        fixture.model.next()
        #expect(fixture.model.step == .location)
        #expect(fixture.model.showsSkip)
        #expect(await fixture.location.requests == 0)
    }

    @Test("„Standort erlauben“ fragt erst jetzt; erlaubt → Mitteilungen, der Ort ist bestimmt")
    func allowLocation() async {
        let fixture = fixture(step: .location)
        await fixture.model.allowLocation()
        #expect(await fixture.location.requests == 1)
        #expect(fixture.model.step == .notifications)
        #expect(!fixture.model.showsSkip)
        #expect(fixture.settings.autoLocation)
        #expect(fixture.settings.devicePlace == .berlin)
        #expect(fixture.today.timeline != nil)
        #expect(!fixture.today.isCitySheetPresented)
    }

    @Test("abgelehnt → Stadt-Sheet; mit einer Stadt → Mitteilungen")
    func denyLocation() async {
        let fixture = fixture(afterRequest: .denied, step: .location)
        await fixture.model.allowLocation()
        #expect(fixture.today.isCitySheetPresented)
        #expect(fixture.model.step == .location)
        fixture.today.select(.istanbul)
        fixture.model.citySheetClosed()
        #expect(fixture.model.step == .notifications)
        #expect(fixture.settings.manualPlace == .istanbul)
    }

    @Test("schon verweigert: kein zweiter Dialog, gleich das Stadt-Sheet (iOS fragt nur einmal)")
    func alreadyDenied() async {
        let fixture = fixture(status: .denied, step: .location)
        await fixture.model.allowLocation()
        #expect(await fixture.location.requests == 0)
        #expect(fixture.today.isCitySheetPresented)
    }

    @Test("schon erlaubt: kein Dialog, gleich die Mitteilungen")
    func alreadyAuthorized() async {
        let fixture = fixture(status: .authorized, step: .location)
        await fixture.model.allowLocation()
        #expect(await fixture.location.requests == 0)
        #expect(fixture.model.step == .notifications)
    }

    @Test("„Stadt manuell wählen“ öffnet das Stadt-Sheet ohne Standortabfrage; „Abbrechen“ bleibt bei Schritt 2")
    func manualCityCancelled() async {
        let fixture = fixture(step: .location)
        fixture.model.chooseCityManually()
        #expect(fixture.today.isCitySheetPresented)
        fixture.today.isCitySheetPresented = false
        fixture.model.citySheetClosed()
        #expect(fixture.model.step == .location)
        #expect(await fixture.location.requests == 0)
    }

    @Test("„Stadt manuell wählen“ mit einer Wahl führt zu den Mitteilungen")
    func manualCityChosen() {
        let fixture = fixture(step: .location)
        fixture.model.chooseCityManually()
        fixture.today.select(.munich)
        fixture.model.citySheetClosed()
        #expect(fixture.model.step == .notifications)
        #expect(!fixture.settings.autoLocation)
    }

    @Test("ein Sheet, das nicht das Onboarding geöffnet hat, ändert den Schritt nicht")
    func foreignSheet() {
        let fixture = fixture(step: .location)
        fixture.today.select(.munich)
        fixture.model.citySheetClosed()
        #expect(fixture.model.step == .location)
    }

    @Test("„Mitteilungen erlauben“ fragt erst jetzt, plant gleich und führt zu „Kostenlos“, dann „Los geht’s“ in die App")
    func allowNotifications() async throws {
        let fixture = fixture(step: .location)
        await fixture.model.allowLocation()
        await fixture.model.allowNotifications()
        #expect(await fixture.notifications.requests == 1)
        #expect(fixture.model.step == .free)
        #expect(!fixture.model.showsSkip)
        #expect(!fixture.settings.onboardingCompleted)
        fixture.model.finish()
        #expect(fixture.navigation.onboardingStep == nil)
        #expect(fixture.settings.onboardingCompleted)
        // Erlaubt: Die Mitteilungen für Berlin sind schon vorgemerkt, die erste ist die Erinnerung an Maghrib.
        let planned = try #require(fixture.scheduler.calls.last)
        #expect(planned.count == NotificationPlanner.pendingLimit)
        #expect(planned.first?.id == "reminder.2026-11-10.maghrib")
    }

    @Test("„Später“ führt zu „Kostenlos. Ohne Werbung.“, ohne zu fragen und ohne zu planen")
    func later() async {
        let fixture = fixture(step: .notifications)
        fixture.model.showFree()
        #expect(fixture.model.step == .free)
        #expect(await fixture.notifications.requests == 0)
        #expect(fixture.scheduler.calls.isEmpty)
        fixture.model.finish()
        #expect(fixture.navigation.onboardingStep == nil)
        #expect(fixture.settings.onboardingCompleted)
    }

    @Test("„Überspringen“ auf Schritt 1 und 2 führt zu „Kostenlos“, ohne nach etwas zu fragen", arguments: [
        OnboardingStep.welcome, .location,
    ])
    func skip(step: OnboardingStep) async {
        let fixture = fixture(step: step)
        #expect(fixture.model.showsSkip)
        fixture.model.showFree()
        #expect(fixture.model.step == .free)
        #expect(!fixture.settings.onboardingCompleted)
        fixture.model.finish()
        #expect(fixture.navigation.onboardingStep == nil)
        #expect(fixture.settings.onboardingCompleted)
        #expect(await fixture.location.requests == 0)
        #expect(await fixture.notifications.requests == 0)
    }

    @Test("vier Schritte, der letzte ist „Kostenlos. Ohne Werbung.“")
    func steps() {
        #expect(OnboardingStep.allCases == [.welcome, .location, .notifications, .free])
        #expect(OnboardingStep(rawValue: 3) == .free)
    }

    @Test("nach „Überspringen“ fragt die Zeiten-Seite selbst nach dem Standort")
    func todayAsksAfterSkip() async {
        let fixture = fixture()
        fixture.model.showFree()
        fixture.model.finish()
        await fixture.today.activate()
        #expect(await fixture.location.requests == 1)
        #expect(fixture.today.place == .berlin)
    }
}

/// Zählt, wie oft nach der Erlaubnis für Mitteilungen gefragt wurde.
actor CountingNotificationAuthorizer: NotificationAuthorizing {
    private(set) var requests = 0

    func authorization() async -> NotificationAuthorization {
        requests == 0 ? .notDetermined : .authorized
    }

    func requestAuthorization() async -> NotificationAuthorization {
        requests += 1
        return .authorized
    }
}

#endif
