import BackgroundTasks
import DesignSystem
import Foundation
import PrayerCore

/// Die Hintergrundaktualisierung: iOS weckt die App etwa einmal am Tag kurz, und sie schiebt das
/// rollierende Fenster der Mitteilungen weiter – auch wenn man sie länger nicht öffnet (Spec § 6.4,
/// entschieden mit dem Plan für Phase 8). Den Zeitpunkt bestimmt iOS; die App bittet nur darum,
/// frühestens zwölf Stunden später geweckt zu werden.
///
/// Die Kennung steht in der Info.plist unter `BGTaskSchedulerPermittedIdentifiers`, dazu „Background
/// fetch“ unter `UIBackgroundModes` (beides in project.yml). Die App meldet die Aufgabe mit
/// `.backgroundTask(.appRefresh(…))` an (`GebetszeitenApp`).
public enum BackgroundRefresh {

    /// Kennung der Aufgabe: die Bundle-ID der App mit „.refresh“.
    public static var identifier: String {
        (Bundle.main.bundleIdentifier ?? "com.example.gebetszeiten") + ".refresh"
    }

    /// Frühestens so lange nach der Bitte darf iOS die App wecken.
    static let earliestDelay: TimeInterval = 12 * 60 * 60

    /// Bittet iOS um die nächste Hintergrundaktualisierung; sie ersetzt eine frühere Bitte. Gemessen an
    /// der Gerätezeit, denn danach weckt iOS.
    public static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliestDelay)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Im Simulator gibt es keine Hintergrundaktualisierung; dort schlägt das immer fehl.
            SystemNotificationScheduler.log.notice("Hintergrundaktualisierung nicht angemeldet: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Ein Lauf im Hintergrund: um den nächsten bitten, dann neu planen.
    @MainActor
    public static func run(environment: AppEnvironment) async {
        schedule()
        await reschedule(environment: environment)
    }

    /// Plant die Mitteilungen ohne Oberfläche: Einstellungen und Sprache aus der App Group, der Ort, der
    /// gilt – ohne nach dem Standort zu fragen und ohne ihn neu zu bestimmen; im Hintergrund gilt der
    /// zuletzt bestimmte.
    ///
    /// - Returns: was vorgemerkt wurde.
    @MainActor
    @discardableResult
    static func reschedule(environment: AppEnvironment) async -> [PrayerNotification] {
        let settings = SettingsStore(storage: environment.settings)
        L10n.chosenLanguage = settings.language
        let location = PlaceModel(settings: settings, locationSource: environment.locationSource)
        await location.readAuthorization()
        let model = NotificationModel(
            settings: settings, location: location, clock: environment.clock,
            timesSource: environment.timesSource, authorizer: environment.notificationAuthorizer,
            scheduler: environment.notificationScheduler
        )
        await model.reschedule()
        return model.planned
    }
}
