import Foundation
import Observation
import PrayerCore

/// Der Ablauf des Onboardings – `onboardingHTML()` und die Aktionen `ob-next`, `ob-loc`, `ob-manual`,
/// `ob-notif`, `ob-finish` im Prototyp (Spec § 1):
///
/// 1. Willkommen → „Weiter“.
/// 2. Standort: „Standort erlauben“ fragt erst jetzt mit dem Dialog des Systems. Erlaubt → Schritt 3;
///    abgelehnt → Stadt-Sheet, mit einer Wahl → Schritt 3. „Stadt manuell wählen“ → Stadt-Sheet → Schritt 3.
/// 3. Mitteilungen: „Mitteilungen erlauben“ fragt erst jetzt; danach wie „Später“ in die App.
///
/// „Überspringen“ auf Schritt 1 und 2 führt sofort in die App, ohne zu fragen. Das Onboarding erscheint
/// danach nicht wieder.
@MainActor
@Observable
final class OnboardingModel {

    let navigation: AppNavigation
    let today: TodayModel
    /// Erlaubnis und Planen der Mitteilungen; nach der Antwort plant es gleich.
    let notifications: NotificationModel

    /// Stand von `today.cityChoices`, als das Stadt-Sheet aus dem Onboarding aufging; `nil`, solange es
    /// nicht offen ist.
    @ObservationIgnored private var cityChoicesWhenOpened: Int?

    init(navigation: AppNavigation, today: TodayModel, notifications: NotificationModel) {
        self.navigation = navigation
        self.today = today
        self.notifications = notifications
    }

    /// Der Schritt, der zu sehen ist.
    var step: OnboardingStep {
        navigation.onboardingStep ?? .welcome
    }

    /// „Überspringen“ gibt es auf Schritt 1 und 2 (`s < 2`).
    var showsSkip: Bool {
        step != .notifications
    }

    private var location: PlaceModel { today.location }

    // MARK: - Aktionen

    /// „Weiter“ (`ob-next`).
    func next() {
        navigation.onboardingStep = .location
    }

    /// „Standort erlauben“ (`ob-loc`). Ist der Standort schon verweigert, fragt iOS nicht noch einmal;
    /// dann öffnet sich gleich das Stadt-Sheet.
    func allowLocation() async {
        switch await location.requestAuthorization() {
        case .authorized:
            today.settings.useCurrentLocation()
            navigation.onboardingStep = .notifications
            // Den Ort schon jetzt bestimmen, damit die Zeiten-Seite gleich Zeiten zeigt.
            if await location.updateDevicePlace() {
                today.refresh()
            }
        case .denied:
            openCitySheet()
        case .notDetermined:
            break
        }
    }

    /// „Stadt manuell wählen“ (`ob-manual`).
    func chooseCityManually() {
        openCitySheet()
    }

    private func openCitySheet() {
        cityChoicesWhenOpened = today.cityChoices
        today.isCitySheetPresented = true
    }

    /// Das Stadt-Sheet ist zu. Mit einer Wahl geht es zu den Mitteilungen; mit „Abbrechen“ bleibt
    /// Schritt 2 stehen (`select-city`, `use-current`, `close-sheet`).
    func citySheetClosed() {
        guard let before = cityChoicesWhenOpened else { return }
        cityChoicesWhenOpened = nil
        if today.cityChoices > before, navigation.onboardingStep == .location {
            navigation.onboardingStep = .notifications
        }
    }

    /// „Mitteilungen erlauben“ (`ob-notif`): fragt mit dem Dialog des Systems, dann in die App – wie die
    /// Antwort auch ausfällt. Erlaubt, sind die Mitteilungen schon geplant.
    func allowNotifications() async {
        await notifications.requestAuthorization()
        finish()
    }

    /// „Später“ und „Überspringen“ (`ob-finish`): in die App, ohne zu fragen.
    func finish() {
        today.settings.completeOnboarding()
        navigation.onboardingStep = nil
    }
}
