import BackgroundTasks
import DesignSystem
import Foundation
import PrayerCore
import Synchronization

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

    /// Das Ende der nächsten Live-Aktivität in Gerätezeit, gesetzt von `LiveActivityModel`. Liegt es vor
    /// den zwölf Stunden, bittet die App, schon dann geweckt zu werden: Läuft sie nicht, beendet sonst
    /// niemand die Aktivität (Phase 9). Wann iOS weckt, entscheidet iOS.
    static var liveActivityCheck: Date? {
        get { pendingLiveActivityCheck.withLock { $0 } }
        set { pendingLiveActivityCheck.withLock { $0 = newValue } }
    }

    private static let pendingLiveActivityCheck = Mutex<Date?>(nil)

    /// Wann die App frühestens geweckt werden soll: in zwölf Stunden oder zum Ende der nächsten
    /// Live-Aktivität, wenn das früher ist.
    static func earliestBeginDate(now: Date = Date(), liveActivityCheck: Date? = liveActivityCheck) -> Date {
        let regular = now.addingTimeInterval(earliestDelay)
        guard let check = liveActivityCheck, check > now else { return regular }
        return min(regular, check)
    }

    /// Bittet iOS um die nächste Hintergrundaktualisierung; sie ersetzt eine frühere Bitte. Gemessen an
    /// der Gerätezeit, denn danach weckt iOS.
    public static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = earliestBeginDate()
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Im Simulator gibt es keine Hintergrundaktualisierung; dort schlägt das immer fehl.
            SystemNotificationScheduler.log.notice("Hintergrundaktualisierung nicht angemeldet: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Ein Lauf im Hintergrund: neu planen – Mitteilungen, Widgets und Live-Aktivitäten, dabei enden alte
    /// Aktivitäten (Spec § 4) –, dann um den nächsten Lauf bitten.
    @MainActor
    public static func run(environment: AppEnvironment) async {
        await reschedule(environment: environment)
        await refreshOutsideApp(environment: environment)
        schedule()
    }

    /// Widgets und Live-Aktivitäten ohne Oberfläche: Stand schreiben, Aktivitäten planen und alte beenden.
    /// Einstellungen, Sprache und Ort wie bei den Mitteilungen.
    @MainActor
    static func refreshOutsideApp(environment: AppEnvironment) async {
        let settings = SettingsStore(storage: environment.settings)
        L10n.chosenLanguage = settings.language
        let location = PlaceModel(settings: settings, locationSource: environment.locationSource)
        await location.readAuthorization()
        WidgetSync(
            settings: settings, location: location, clock: environment.clock,
            publisher: environment.widgetPublisher, debug: environment.widgetDebug
        ).publish()
        await LiveActivityModel(
            settings: settings, location: location, clock: environment.clock,
            timesSource: environment.timesSource, scheduler: environment.liveActivityScheduler,
            isPlanning: environment.plansLiveActivities, debugStart: environment.liveActivityDebugStart
        ).reschedule()
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
