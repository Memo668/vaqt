import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Zustand der Zeiten-Seite: die Zeiten des Ortes, der gilt, die sechs Gebetskarten und die
/// Hinweise – der Rechenteil von `homePage()` im Prototyp.
///
/// Welcher Ort gilt, weiß `PlaceModel`; die Qibla-Seite fragt dasselbe Modell. Hier steht, was die
/// Zeiten-Seite daraus macht.
///
/// Das Modell baut sich nur bei einem Wechsel neu auf (`refresh()`): neuer Ort, neue Tagesphase, neuer
/// Tag. Dazwischen laufen nur Countdown und Bogen weiter; die rechnet `TodayHero` im Sekundentakt aus
/// `timeline` (Design Spec § 4).
@MainActor
@Observable
public final class TodayModel {

    public let settings: SettingsStore
    /// Welcher Ort gilt: aktueller Standort oder gewählte Stadt. Die Qibla-Seite teilt sich das Modell.
    public let location: PlaceModel
    /// Die Uhr der App. Der Bogen liest sie im Sekundentakt.
    public let clock: any AppClock
    /// Die Ortssuche für das Stadt-Sheet.
    public let citySearch: any CitySearching

    @ObservationIgnored private let timesSource: any PrayerTimesSource
    @ObservationIgnored private let connectivity: any ConnectivitySource
    @ObservationIgnored private let toast: ToastCenter
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let deviceTimeZone: TimeZone

    /// Ob das Gerät kein Netz hat. Dann steht der Hinweis unter dem Datum.
    public private(set) var isOffline = false
    /// Der Kalendertag am Ort; ohne Ort der des Geräts.
    public private(set) var day: CalendarDay
    /// Die Zeiten von gestern, heute und morgen am Ort. `nil` ohne Ort und dort, wo sich für den Tag
    /// keine Zeiten bestimmen lassen.
    public private(set) var timeline: PrayerTimeline?
    /// Die sechs Gebetskarten zur laufenden Tagesphase.
    public private(set) var rows: [PrayerRowModel] = []
    /// Ob Fadschr und Ischa heute aus der Regel für hohe Breiten kommen.
    public private(set) var isHighLatitude = false
    /// Ob das Stadt-Sheet offen ist.
    public var isCitySheetPresented = false
    /// Wie oft im Stadt-Sheet ein Ort gewählt wurde – eine Stadt oder „Aktueller Standort“. Daran erkennt
    /// das Onboarding, dass das Sheet mit einer Wahl geschlossen wurde und nicht mit „Abbrechen“.
    public private(set) var cityChoices = 0

    /// - Parameters:
    ///   - location: welcher Ort gilt; die Einstellungen sind die dieses Modells.
    ///   - locale: Sprache für Datum und Hijri-Datum; ohne Angabe die der Texte.
    ///   - deviceTimeZone: Zeitzone für das Datum, solange es keinen Ort gibt.
    public init(
        clock: any AppClock,
        timesSource: any PrayerTimesSource,
        location: PlaceModel,
        connectivity: any ConnectivitySource,
        citySearch: any CitySearching = NoCitySearch(),
        toast: ToastCenter,
        locale: Locale = L10n.locale,
        deviceTimeZone: TimeZone = .current
    ) {
        self.clock = clock
        self.timesSource = timesSource
        self.location = location
        self.connectivity = connectivity
        self.citySearch = citySearch
        settings = location.settings
        self.toast = toast
        self.locale = locale
        self.deviceTimeZone = deviceTimeZone
        day = CalendarDay(clock.now, in: deviceTimeZone)
    }

    /// Die Seite mit eigenem Ort-Modell, aus Einstellungen und Standortquelle.
    public convenience init(
        clock: any AppClock,
        timesSource: any PrayerTimesSource,
        locationSource: any LocationSource,
        connectivity: any ConnectivitySource,
        citySearch: any CitySearching = NoCitySearch(),
        settings: SettingsStore,
        toast: ToastCenter,
        locale: Locale = L10n.locale,
        deviceTimeZone: TimeZone = .current
    ) {
        self.init(
            clock: clock, timesSource: timesSource,
            location: PlaceModel(settings: settings, locationSource: locationSource),
            connectivity: connectivity, citySearch: citySearch, toast: toast,
            locale: locale, deviceTimeZone: deviceTimeZone
        )
    }

    // MARK: - Ort

    /// Stand der Standortfreigabe, zuletzt gelesen in `activate()`.
    public var authorization: LocationAuthorization {
        location.authorization
    }

    /// Ob der aktuelle Standort gilt. Ohne Freigabe gilt die von Hand gewählte Stadt, auch wenn die
    /// Automatik eingeschaltet ist.
    public var isAutomatic: Bool {
        location.isAutomatic
    }

    /// Der Ort, für den die Seite Zeiten zeigt: der aktuelle Standort oder die gewählte Stadt.
    public var place: Place? {
        location.place
    }

    /// Der Ort, in dessen Umgebung die Ortssuche zuerst sucht: der, für den die Seite Zeiten zeigt,
    /// sonst der zuletzt bestimmte Standort.
    public var searchCenter: Coordinates? {
        location.searchCenter
    }

    /// Die Zeile mit der Stadt. Solange der Name des aktuellen Standorts fehlt – noch nicht bestimmt
    /// oder ohne Netz –, steht dort „Aktueller Standort“; gibt es weder Freigabe noch Stadt,
    /// „Stadt wählen“.
    public var cityTitle: String {
        location.cityTitle
    }

    /// Text des Stadt-Buttons für VoiceOver: „Stadt: Berlin. Ändern“. Ohne Stadt sagt der Titel schon,
    /// was der Button tut: „Stadt wählen“.
    public var cityAccessibilityLabel: String {
        guard place != nil || isAutomatic else { return cityTitle }
        return "\(L10n.city): \(cityTitle). \(L10n.change)"
    }

    /// Das Symbol `location.fill` vor der Stadt: nur beim aktuellen Standort.
    public var showsLocationSymbol: Bool {
        isAutomatic
    }

    /// Die Marke „manuell“ hinter der Stadt: bei gewählter Stadt, solange der Standort nicht verweigert
    /// ist – dann sagt es schon das Banner.
    public var showsManualTag: Bool {
        !isAutomatic && authorization != .denied && place != nil
    }

    /// Das Banner „Standortzugriff aus – Stadt manuell gewählt“.
    public var showsLocationDeniedBanner: Bool {
        authorization == .denied
    }

    /// Ob es für den Ort heute keine Zeiten gibt, weil die Sonne nicht auf- oder untergeht.
    public var hasNoTimes: Bool {
        place != nil && timeline == nil
    }

    // MARK: - Datum und Hinweise

    /// „Dienstag, 10. November“ – Wochentag, Tag und Monat in der Sprache der App (`gregDate()`).
    public var gregorianDateText: String {
        Self.gregorianDateText(for: day, locale: locale)
    }

    /// „30. Dschumada I 1448“ (`hijriDate()`).
    public var hijriDateText: String {
        HijriDate(day).formatted(locale: locale)
    }

    /// Der Hinweis zu hohen Breiten mit Stadt und Regel.
    public var highLatitudeNote: String {
        L10n.highLatNote(city: cityTitle, rule: settings.calculation.highLatitudeRule.localizedName)
    }

    static func gregorianDateText(for day: CalendarDay, locale: Locale) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = .gmt
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        // Mittags in GMT liegt jeder Kalendertag eindeutig auf sich selbst.
        return formatter.string(from: day.date(at: ClockTime(minutesSinceMidnight: 12 * 60), in: .gmt))
    }

    // MARK: - Ablauf

    /// Beim Erscheinen der Seite und immer, wenn die App wieder nach vorn kommt: Freigabe lesen, mit dem
    /// bekannten Ort sofort Zeiten zeigen, dann den aktuellen Standort neu bestimmen.
    ///
    /// Nach dem Onboarding ist der Standort schon erfragt oder eine Stadt gewählt. Wurde es übersprungen,
    /// fragt die Seite hier selbst nach dem Standort, weil sie ohne Ort nichts zeigen kann (Annahme mit dem
    /// Plan für Phase 7). Wird er verweigert und ist noch keine Stadt gewählt, öffnet sich das
    /// Stadt-Sheet – wie im Ablauf des Prototyps nach „Nicht erlauben“.
    public func activate() async {
        // Nach jedem Schritt, der den Ort ändern kann, baut sich die Seite neu auf.
        guard await location.activate(onChange: { [self] in refresh() }) else { return }
        if settings.autoLocation, authorization == .denied, settings.manualPlace == nil {
            isCitySheetPresented = true
        }
    }

    /// Hört auf das Netz, solange die Seite lebt. Kommt es zurück, holt die Seite den Namen des
    /// aktuellen Standorts nach, falls er noch fehlt.
    public func observeConnectivity() async {
        for await isOnline in connectivity.updates() {
            isOffline = !isOnline
            if isOnline, isAutomatic, authorization == .authorized, settings.devicePlace?.hasName == false,
               await location.updateDevicePlace() {
                refresh()
            }
        }
    }

    /// Baut den Stand der Seite neu auf: Tag, Zeiten, Karten und der Hinweis zu hohen Breiten.
    ///
    /// Wird gerufen, wenn sich etwas ändert – nicht im Sekundentakt.
    public func refresh() {
        let now = clock.now
        let place = place
        day = CalendarDay(now, in: place?.timeZone ?? deviceTimeZone)
        guard let place, let timeline = timesSource.timeline(at: now, place: place, settings: settings.calculation) else {
            timeline = nil
            rows = []
            isHighLatitude = false
            return
        }
        self.timeline = timeline
        isHighLatitude = timesSource.usesHighLatitudeRule(on: day, at: place, settings: settings.calculation)
        rows = timeline.phase(at: now).map {
            PrayerRowModel.rows(for: $0, showKerahat: settings.showKerahat, isHighLatitude: isHighLatitude)
        } ?? []
    }

    // MARK: - Aktionen

    /// Stand der Mitteilung für ein Ereignis.
    public func bell(for prayer: Prayer) -> BellState {
        settings.bell(for: prayer)
    }

    /// Tippen auf eine Glocke: zum nächsten Stand wechseln und ihn im Toast nennen (`bell` im Prototyp).
    public func cycleBell(for prayer: Prayer) {
        let state = settings.cycleBell(for: prayer)
        toast.show(L10n.bellToast(p: prayer.localizedName, s: state.localizedName), systemImage: state.symbolName)
    }

    /// Eine Stadt im Stadt-Sheet wählen: Sie gilt ab jetzt statt des aktuellen Standorts.
    public func select(_ place: Place) {
        settings.select(place)
        cityChoices += 1
        isCitySheetPresented = false
        refresh()
    }

    /// „Aktueller Standort“ im Stadt-Sheet. Ohne Freigabe bewirkt die Zeile nichts.
    public func useCurrentLocation() async {
        guard authorization != .denied else { return }
        settings.useCurrentLocation()
        cityChoices += 1
        isCitySheetPresented = false
        refresh()
        await activate()
    }
}
