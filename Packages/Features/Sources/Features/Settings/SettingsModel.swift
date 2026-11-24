import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Was die Seiten der Einstellungen zeigen und tun – `PAGES` und die Aktionen `pick`, `step`,
/// `toggle-loc`, `toggle-kerahat`, `seg-notif` im Prototyp.
///
/// Jede Änderung wirkt sofort: Die Einstellungen liegen im `SettingsStore`, und was die Zeiten betrifft –
/// Methode, Asr, Regel für hohe Breiten, Minutenkorrektur, Kerahat –, baut die Zeiten-Seite gleich neu auf.
/// Bogen, Karten, Anleitung und Qibla lesen von dort.
@MainActor
@Observable
public final class SettingsModel {

    public let settings: SettingsStore
    /// Die Zeiten-Seite: Ort, Zeitstrahl und das Stadt-Sheet.
    public let today: TodayModel
    let navigation: AppNavigation

    @ObservationIgnored private let timesSource: any PrayerTimesSource
    @ObservationIgnored private let notificationAuthorizer: any NotificationAuthorizing
    @ObservationIgnored private let locale: Locale

    /// Adresse hinter „Quellcode“; `nil`, solange keine eingetragen ist.
    public let sourceCodeURL: URL?
    /// Adresse der App im App Store – was „App weiterempfehlen“ teilt; ohne Adresse fehlt der Knopf.
    public let appStoreURL: URL?
    /// „1.0 (1)“ – Version und Build der App.
    public let version: String

    /// Ob die App Mitteilungen senden darf, zuletzt gelesen in `refreshNotificationAuthorization()`.
    public private(set) var notificationAuthorization: NotificationAuthorization = .notDetermined
    /// Suchtext auf der Seite „Berechnungsmethode“ (`S.search.method`).
    public var methodQuery = ""

    init(
        settings: SettingsStore, today: TodayModel, navigation: AppNavigation,
        timesSource: any PrayerTimesSource, notificationAuthorizer: any NotificationAuthorizing,
        sourceCodeURL: URL?, appStoreURL: URL? = nil, version: String, locale: Locale = L10n.locale
    ) {
        self.settings = settings
        self.today = today
        self.navigation = navigation
        self.timesSource = timesSource
        self.notificationAuthorizer = notificationAuthorizer
        self.sourceCodeURL = sourceCodeURL
        self.appStoreURL = appStoreURL
        self.version = version
        self.locale = locale
    }

    private var location: PlaceModel { today.location }
    private var place: Place? { location.place }

    // MARK: - Standort

    /// Der Schalter „Aktuellen Standort verwenden“: an, solange der aktuelle Standort gilt
    /// (`S.autoLocation && !S.locDenied`).
    public var usesCurrentLocation: Bool {
        location.isAutomatic
    }

    /// Ohne Freigabe ist der Schalter gesperrt, und „iOS-Einstellungen öffnen“ erscheint.
    public var isLocationDenied: Bool {
        location.authorization == .denied
    }

    /// Wert der Zeile „Stadt“: der Ort, der gilt.
    public var cityValue: String {
        location.cityTitle
    }

    public var locationFooter: String {
        isLocationDenied ? L10n.locDeniedFooter : L10n.locFooter
    }

    /// Schaltet zwischen aktuellem Standort und gewählter Stadt (`toggle-loc`). Eingeschaltet fragt die
    /// App nach dem Standort, falls sie das noch nie getan hat. Ausgeschaltet bleibt die Stadt des
    /// Standorts als gewählte; gibt es keine, öffnet sich das Stadt-Sheet.
    public func setUsesCurrentLocation(_ isOn: Bool) async {
        guard !isLocationDenied, isOn != usesCurrentLocation else { return }
        if isOn {
            await today.useCurrentLocation()
        } else {
            settings.useChosenCity()
            today.refresh()
            if location.needsCity {
                openCitySheet()
            }
        }
    }

    public func openCitySheet() {
        today.isCitySheetPresented = true
    }

    // MARK: - Berechnung

    /// Die Methode, die ohne eigene Wahl gilt – die des Landes, mit Mock-Zeiten die der Fixture-Stadt.
    public var automaticMethod: CalculationMethod {
        place.map(timesSource.automaticMethod(for:)) ?? .automatic(forCountryCode: nil)
    }

    /// Die Methode, mit der gerechnet wird (`methodObj()`).
    public var effectiveMethod: CalculationMethod {
        settings.calculation.method ?? automaticMethod
    }

    /// „Automatisch für Deutschland“; ohne Land nichts.
    public var automaticDetail: String? {
        guard let code = place?.countryCode, let country = locale.localizedString(forRegionCode: code) else { return nil }
        return L10n.autoFor(country: country)
    }

    /// Zeile „Methode“: Kurzname der Methode, darunter „Automatisch für …“, solange keine gewählt ist.
    public var methodValue: String { effectiveMethod.shortName }
    public var methodDetail: String? { settings.calculation.method == nil ? automaticDetail : nil }

    /// „Automatisch · MWL“ – die erste Zeile unter „Empfohlen“.
    public var automaticTitle: String {
        "\(L10n.auto) · \(automaticMethod.shortName)"
    }

    /// „Fadschr 18° · Ischa 17°“, „Fadschr 18,5° · Ischa 90 Min. nach Maghrib“, bei Moonsighting
    /// „… · saisonal“ (`methodSub()`).
    public func methodSubtitle(_ method: CalculationMethod) -> String {
        let isha: String
        switch method.isha {
        case .angle(let degrees): isha = number(degrees) + "°"
        case .minutesAfterMaghrib(let minutes): isha = L10n.minAfterMaghrib(n: minutes)
        }
        let text = "\(L10n.p_fajr) \(number(method.fajrAngle))° · \(L10n.p_isha) \(isha)"
        return method.isSeasonal ? text + " · " + L10n.seasonal : text
    }

    /// Ob „Empfohlen“ zu sehen ist: nur ohne Suchtext (`data-hide-on-filter`).
    public var showsRecommended: Bool {
        trimmedQuery.isEmpty
    }

    /// Die Methoden, deren Name oder Kurzname den Suchtext enthält, ohne auf Groß- und Kleinschreibung und
    /// Akzente zu achten (`applyFilter('method')`).
    public var filteredMethods: [CalculationMethod] {
        let query = trimmedQuery
        guard !query.isEmpty else { return CalculationMethod.allCases }
        return CalculationMethod.allCases.filter {
            "\($0.name) \($0.shortName)".range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    private var trimmedQuery: String {
        methodQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Wählt eine Methode; `nil` heißt automatisch.
    public func selectMethod(_ method: CalculationMethod?) {
        updateCalculation { $0.method = method }
    }

    public var asrValue: String { settings.calculation.asr.localizedName }

    public func setAsr(_ asr: AsrRule) {
        updateCalculation { $0.asr = asr }
    }

    /// Die Rechtsschule für die Verbotszeiten, als Wert der Zeile (Spec § 11.6).
    public var madhabValue: String { settings.calculation.madhab.localizedName }

    /// Wählt die Rechtsschule. Sie ändert keine Gebetszeit, nur die Verbotszeiten und ihre Texte; Zeiten-Seite,
    /// Widgets und Live-Aktivitäten rechnen neu.
    public func setMadhab(_ madhab: Madhab) {
        updateCalculation { $0.madhab = madhab }
    }

    // MARK: - Stil

    /// Der Name der Grundfarbe als Wert der Zeile „Stil“ (Spec § 11.7).
    public var styleValue: String { settings.style.accent.localizedName }

    /// Wählt die Grundfarbe; sie gilt sofort in der App, Widgets und Live-Aktivitäten folgen, sobald die App neu
    /// plant.
    public func setAccent(_ accent: AccentColorID) {
        settings.updateStyle { $0.accent = accent }
    }

    /// Wählt den Stil der Live-Aktivität: farbig, nur Bogen, schwarz-weiß.
    public func setLiveActivityStyle(_ style: LiveActivityStyle) {
        settings.updateStyle { $0.liveActivity = style }
    }

    /// „Invertiert“: heller Grund, dunkle Schrift.
    public func setInverted(_ isInverted: Bool) {
        settings.updateStyle { $0.isInverted = isInverted }
    }

    /// „Standard wiederherstellen“: Petrol, farbig, nicht invertiert.
    public func resetStyle() {
        settings.setStyle(.standard)
    }

    /// Die Live-Aktivität, wie sie jetzt aussähe – die zum nächsten Gebet, im gewählten Stil – für die Vorschau
    /// der Seite „Stil“ (`laBanner(phase(nowSec()))`); `nil` ohne Ort oder Zeiten.
    public func stylePreview(at now: Date) -> LiveActivityContent? {
        guard let place else { return nil }
        let planner = LiveActivityPlanner(source: timesSource)
        let options = LiveActivityPlanner.Options(
            leadMinutes: settings.notifications.liveActivityMinutes, cityName: location.cityTitle,
            isCurrentLocation: location.isAutomatic, showKerahat: settings.showKerahat,
            clockOffset: WidgetSync.clockOffset(of: today.clock), style: settings.style
        )
        return planner.plan(at: now, place: place, settings: settings.calculation, options: options, debugStart: now)
            .first?.content
    }

    /// Fußzeile der Gruppe „Darstellung“: die Verbotszeiten der gewählten Schule.
    public var kerahatFooter: String { settings.calculation.madhab.kerahatFooter }

    public var highLatitudeValue: String { settings.calculation.highLatitudeRule.localizedName }

    public func setHighLatitudeRule(_ rule: HighLatitudeRule) {
        updateCalculation { $0.highLatitudeRule = rule }
    }

    /// Der eigene Dämmerungswinkel für Fadschr oder Ischa als Text: „15°“.
    public func manualAngleText(of prayer: Prayer) -> String {
        "\(settings.calculation.manualAngles[prayer] ?? TwilightAngles.standard)°"
    }

    public func canStepManualAngle(of prayer: Prayer, by delta: Int) -> Bool {
        settings.calculation.manualAngles.canStep(prayer, by: delta)
    }

    /// Ein Schritt der Stepper unter „Dämmerungswinkel“ (`hldeg`), 10 bis 20°.
    public func stepManualAngle(of prayer: Prayer, by delta: Int) {
        updateCalculation { $0.manualAngles.step(prayer, by: delta) }
    }

    /// Fußzeile der Seite „Hohe Breitengrade“; bei Moonsighting mit dem Hinweis, dass die Regel nicht
    /// wirkt (entschieden mit dem Plan für Phase 7).
    public var highLatitudeFooter: String {
        effectiveMethod == .moonsighting ? L10n.hlFooter + " " + L10n.hlMoonsighting : L10n.hlFooter
    }

    /// „Keine“ oder „2 geändert“.
    public var adjustmentsValue: String {
        let count = settings.calculation.adjustments.changedCount
        return count == 0 ? L10n.adjNone : L10n.adjChanged(n: count)
    }

    public func adjustment(of prayer: Prayer) -> Int {
        settings.calculation.adjustments[prayer]
    }

    /// „+2 Min.“, „−3 Min.“, „0 Min.“ (`adjText()`).
    public func adjustmentText(of prayer: Prayer) -> String {
        Self.adjustmentText(adjustment(of: prayer))
    }

    static func adjustmentText(_ minutes: Int) -> String {
        if minutes > 0 { return "+" + L10n.min(n: minutes) }
        if minutes < 0 { return "\u{2212}" + L10n.min(n: -minutes) }
        return L10n.min(n: 0)
    }

    /// Die Uhrzeit des Ereignisses heute, mit Korrektur, z. B. „05:16“; ohne Zeiten leer.
    public func todayTime(of prayer: Prayer) -> String {
        today.timeline.map { L10n.time($0.today.clockTime(of: prayer)) } ?? ""
    }

    /// Rechnet die Zeiten, falls die Zeiten-Seite das noch nicht getan hat – etwa wenn die Einstellungen
    /// in einem anderen Tab offen sind, bevor die Zeiten-Seite zu sehen war.
    public func prepareTimes() {
        if today.timeline == nil {
            today.refresh()
        }
    }

    public var hasAdjustments: Bool {
        settings.calculation.adjustments.changedCount > 0
    }

    /// Eine Minute früher oder später (`step`), höchstens ±30.
    public func stepAdjustment(of prayer: Prayer, by delta: Int) {
        updateCalculation { $0.adjustments.step(prayer, by: delta) }
    }

    /// Alle Korrekturen auf 0 (`adj-reset`).
    public func resetAdjustments() {
        updateCalculation { $0.adjustments.reset() }
    }

    private func updateCalculation(_ change: (inout CalculationSettings) -> Void) {
        settings.updateCalculation(change)
        today.refresh()
    }

    // MARK: - Mitteilungen

    /// „5 von 6“: wie viele Ereignisse eine Mitteilung bekommen.
    public var perPrayerValue: String {
        let count = Prayer.allCases.filter { settings.bell(for: $0) != .off }.count
        return L10n.ofN(n: String(count))
    }

    public func bell(for prayer: Prayer) -> BellState {
        settings.bell(for: prayer)
    }

    public func setBell(_ state: BellState, for prayer: Prayer) {
        settings.setBell(state, for: prayer)
    }

    /// „10 Min. vorher“ oder „Aus“.
    public static func leadText(_ minutes: Int) -> String {
        minutes == 0 ? L10n.off : L10n.minBefore(n: minutes)
    }

    public var reminderValue: String { Self.leadText(settings.notifications.reminderMinutes) }
    public var liveActivityValue: String { Self.leadText(settings.notifications.liveActivityMinutes) }
    public var soundValue: String { settings.notifications.sound.localizedName }

    public func setReminder(_ minutes: Int) {
        settings.updateNotifications { $0.reminderMinutes = minutes }
    }

    public func setLiveActivity(_ minutes: Int) {
        settings.updateNotifications { $0.liveActivityMinutes = minutes }
    }

    public func setSound(_ sound: NotificationSound) {
        settings.updateNotifications { $0.sound = sound }
    }

    /// Fußtext unter „Mitteilungen“, wenn iOS sie nicht erlaubt.
    public var notificationsFooter: String? {
        notificationAuthorization == .denied ? L10n.notifDeniedFooter : nil
    }

    public func refreshNotificationAuthorization() async {
        notificationAuthorization = await notificationAuthorizer.authorization()
    }

    /// „Adhan anhören“ öffnet das Adhan-Sheet (`open-adhan`).
    public func openAdhan() {
        navigation.isAdhanSheetPresented = true
    }

    // MARK: - Darstellung

    public var appearanceValue: String { settings.appearance.title }

    public func setAppearance(_ appearance: Appearance) {
        settings.setAppearance(appearance)
    }

    /// Die Sprache, in der die App gerade erscheint.
    public var language: AppLanguage { settings.language ?? L10n.systemLanguage }
    public var languageValue: String { language.name }

    /// Wählt die Sprache der App; die Seiten bauen sich dafür neu auf (`RootView`).
    public func setLanguage(_ language: AppLanguage) {
        settings.setLanguage(language)
    }

    public var showsKerahat: Bool { settings.showKerahat }

    public func setShowsKerahat(_ isOn: Bool) {
        settings.setShowKerahat(isOn)
        today.refresh()
    }

    // MARK: - Hilfen

    /// Zahl wie `num()` im Prototyp: „18,5“ deutsch, „18.5“ englisch.
    private func number(_ value: Double) -> String {
        value.formatted(.number.locale(locale))
    }
}

extension NotificationSound {

    /// Name aus dem String Catalog (`SOUND_KEY`).
    public var localizedName: String {
        switch self {
        case .system: L10n.soundSystem
        case .adhan: L10n.soundAdhan
        case .silent: L10n.soundSilent
        }
    }
}

extension AsrRule {

    /// Name aus dem String Catalog (`asrStd`, `asrHanafi`).
    public var localizedName: String {
        switch self {
        case .standard: L10n.asrStd
        case .hanafi: L10n.asrHanafi
        }
    }

    /// Zusatz unter dem Namen (`asrStdSub`, `asrHanafiSub`).
    public var localizedDetail: String {
        switch self {
        case .standard: L10n.asrStdSub
        case .hanafi: L10n.asrHanafiSub
        }
    }
}

extension HighLatitudeRule {

    /// Zusatz unter dem Namen (`hlAngleSub` …).
    public var localizedDetail: String {
        switch self {
        case .angle: L10n.hlAngleSub
        case .seventh: L10n.hlSeventhSub
        case .middle: L10n.hlMiddleSub
        case .manual: L10n.hlManualSub
        }
    }
}
