import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Die Einstellungen der App – der Teil von `S` im Prototyp, den die App auf dem Gerät behält.
///
/// Sie liegen in den UserDefaults der App Group, damit Widgets und Live-Aktivität sie ab Phase 9 lesen
/// können. Nichts davon verlässt das Gerät: Glocke je Gebet, Standort oder Stadt, gespeicherte Städte,
/// Rechen-Einstellungen, Mitteilungen, Erscheinungsbild, Sprache, Kerahat-Schalter und ob das
/// Onboarding durchlaufen ist.
@MainActor
@Observable
public final class SettingsStore {

    /// Wo die Einstellungen liegen.
    public enum Storage: Equatable, Sendable {
        /// In den UserDefaults mit dieser Kennung – der App Group. Ohne Kennung in den Standard-Defaults.
        case userDefaults(suiteName: String?)
        /// Nur im Speicher, mit festen Startwerten: für `-debugFixtureTimes`, Tests und Previews. So
        /// sieht jede Aufnahme gleich aus, egal was vorher angetippt wurde.
        case ephemeral(Snapshot)
    }

    /// Alle Einstellungen auf einmal. Die Standardwerte sind die Startwerte von `S` im Prototyp.
    public struct Snapshot: Equatable, Sendable {
        /// Ob der aktuelle Standort gilt (`S.autoLocation`). Sonst gilt `manualPlace`.
        public var autoLocation = true
        /// Die von Hand gewählte Stadt (`S.city`).
        public var manualPlace: Place?
        /// Die Städte der Liste im Stadt-Sheet. Sie sind auch ohne Netz wählbar.
        public var savedPlaces: [Place] = []
        /// Der zuletzt bestimmte aktuelle Ort (`S.deviceCity`). Mit ihm zeigt die App beim Start sofort
        /// Zeiten, auch ohne Netz.
        public var devicePlace: Place?
        /// Stand der Mitteilung je Ereignis (`S.notif`).
        public var bells: [Prayer: BellState] = SettingsStore.standardBells
        /// Methode, Asr, Regel für hohe Breiten, Minutenkorrekturen (`S.method`, `S.asr`, `S.hlRule`, `S.adj`).
        public var calculation = CalculationSettings()
        /// Der Schalter „Kerahat-Zeiten zeigen“ (`S.kerahat`).
        public var showKerahat = true
        /// Vorab-Erinnerung, Live-Aktivität und Klang (`S.reminder`, `S.liveAct`, `S.sound`).
        public var notifications = NotificationPreferences()
        /// Der Wecker zu Fadschr (`S.alarmOn`, `S.alarmMode`, `S.alarmBefore`, `S.alarmTime`, `S.alarmSound`).
        public var fajrAlarm = FajrAlarmPreferences()
        /// Erscheinungsbild (`S.appearance`).
        public var appearance = Appearance.system
        /// Stil: Grundfarbe und Aussehen der Live-Aktivität (`S.accent`, `S.laStyle`, `S.laInv`; Spec § 11.7).
        public var style = AppStyle.standard
        /// Die in der App gewählte Sprache (`S.lang`); `nil` heißt: wie das Gerät.
        public var language: AppLanguage?
        /// Ob das Onboarding durchlaufen oder übersprungen ist (`S.onboarded`).
        public var onboardingCompleted = false

        public init() {}
    }

    /// Die Glocken wie im Prototyp: die Gebete mit Ton, Ischa lautlos, der Sonnenaufgang aus.
    public nonisolated static let standardBells: [Prayer: BellState] = Dictionary(
        uniqueKeysWithValues: Prayer.allCases.map { ($0, BellState.standard(for: $0)) }
    )

    public private(set) var autoLocation: Bool
    public private(set) var manualPlace: Place?
    public private(set) var savedPlaces: [Place]
    public private(set) var devicePlace: Place?
    public private(set) var bells: [Prayer: BellState]
    public private(set) var calculation: CalculationSettings
    public private(set) var showKerahat: Bool
    public private(set) var notifications: NotificationPreferences
    public private(set) var fajrAlarm: FajrAlarmPreferences
    public private(set) var appearance: Appearance
    public private(set) var style: AppStyle
    public private(set) var language: AppLanguage?
    public private(set) var onboardingCompleted: Bool

    @ObservationIgnored private let defaults: UserDefaults?
    /// Wo die Grundfarbe gilt – in der App der gemeinsame Speicher, in Tests ein eigener.
    @ObservationIgnored private let accentStore: AccentStore

    public init(storage: Storage, accentStore: AccentStore = .shared) {
        self.accentStore = accentStore
        let snapshot: Snapshot
        switch storage {
        case .userDefaults(let suiteName):
            // Lässt sich die App Group nicht öffnen, bleiben die Standard-Defaults.
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
            self.defaults = defaults
            snapshot = Self.load(from: defaults)
        case .ephemeral(let start):
            defaults = nil
            snapshot = start
        }
        autoLocation = snapshot.autoLocation
        manualPlace = snapshot.manualPlace
        savedPlaces = snapshot.savedPlaces
        devicePlace = snapshot.devicePlace
        bells = snapshot.bells
        calculation = snapshot.calculation
        showKerahat = snapshot.showKerahat
        notifications = snapshot.notifications
        fajrAlarm = snapshot.fajrAlarm
        appearance = snapshot.appearance
        style = snapshot.style
        language = snapshot.language
        onboardingCompleted = snapshot.onboardingCompleted
        // Die Grundfarbe gilt vom ersten Bild an (Spec § 11.7).
        accentStore.apply(snapshot.style)
    }

    /// Der Stand aller Einstellungen.
    public var snapshot: Snapshot {
        var snapshot = Snapshot()
        snapshot.autoLocation = autoLocation
        snapshot.manualPlace = manualPlace
        snapshot.savedPlaces = savedPlaces
        snapshot.devicePlace = devicePlace
        snapshot.bells = bells
        snapshot.calculation = calculation
        snapshot.showKerahat = showKerahat
        snapshot.notifications = notifications
        snapshot.fajrAlarm = fajrAlarm
        snapshot.appearance = appearance
        snapshot.style = style
        snapshot.language = language
        snapshot.onboardingCompleted = onboardingCompleted
        return snapshot
    }

    // MARK: - Glocke

    /// Stand der Mitteilung für ein Ereignis.
    public func bell(for prayer: Prayer) -> BellState {
        bells[prayer] ?? BellState.standard(for: prayer)
    }

    public func setBell(_ state: BellState, for prayer: Prayer) {
        bells[prayer] = state
        defaults?.set(state.rawValue, forKey: Key.bell(prayer))
    }

    /// Ein Tippen auf die Glocke: Ton → Lautlos → Aus → Ton. Liefert den neuen Stand.
    @discardableResult
    public func cycleBell(for prayer: Prayer) -> BellState {
        let next = bell(for: prayer).next
        setBell(next, for: prayer)
        return next
    }

    // MARK: - Ort

    /// Eine Stadt wählen: Sie gilt ab jetzt statt des aktuellen Standorts und steht in der Liste der
    /// gespeicherten Städte (`select-city` im Prototyp).
    public func select(_ place: Place) {
        manualPlace = place
        autoLocation = false
        if let index = savedPlaces.firstIndex(where: { Self.isSameCity($0, place) }) {
            // Schon in der Liste: an ihrem Platz lassen, aber mit den neuen Angaben.
            savedPlaces[index] = place
        } else {
            savedPlaces.append(place)
        }
        save(manualPlace, forKey: Key.manualPlace)
        save(savedPlaces, forKey: Key.savedPlaces)
        defaults?.set(autoLocation, forKey: Key.autoLocation)
    }

    /// Zurück zum aktuellen Standort (`use-current` im Prototyp). Die gewählte Stadt bleibt gemerkt,
    /// falls der Standort später nicht mehr freigegeben ist.
    public func useCurrentLocation() {
        autoLocation = true
        defaults?.set(autoLocation, forKey: Key.autoLocation)
    }

    /// Der Schalter „Aktuellen Standort verwenden“ aus (`toggle-loc` im Prototyp): Die Stadt des
    /// aktuellen Standorts bleibt als gewählte Stadt stehen – im Prototyp ist `S.city` dann die
    /// `S.deviceCity`. Fehlt ihr Name (ohne Netz bestimmt), bleibt die zuletzt gewählte Stadt.
    public func useChosenCity() {
        if let devicePlace, devicePlace.hasName {
            select(devicePlace)
        } else {
            autoLocation = false
            defaults?.set(autoLocation, forKey: Key.autoLocation)
        }
    }

    /// Merkt sich den zuletzt bestimmten aktuellen Ort.
    public func setDevicePlace(_ place: Place?) {
        guard devicePlace != place else { return }
        devicePlace = place
        save(devicePlace, forKey: Key.devicePlace)
    }

    /// Entfernt eine Stadt aus der Liste der gespeicherten. War sie die gemerkte Wahl, ist auch die
    /// vergessen. Dass die Stadt, die gerade gilt, in der Liste bleibt, regelt das Stadt-Sheet.
    public func removeSavedPlace(_ place: Place) {
        savedPlaces.removeAll { Self.isSameCity($0, place) }
        save(savedPlaces, forKey: Key.savedPlaces)
        if let chosen = manualPlace, Self.isSameCity(chosen, place) {
            manualPlace = nil
            save(manualPlace, forKey: Key.manualPlace)
        }
    }

    /// Zwei Einträge meinen dieselbe Stadt, wenn Name und Land übereinstimmen – auch wenn die Suche
    /// beim zweiten Mal leicht andere Koordinaten liefert.
    nonisolated static func isSameCity(_ lhs: Place, _ rhs: Place) -> Bool {
        lhs.countryCode == rhs.countryCode && lhs.name.compare(rhs.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    // MARK: - Berechnung und Darstellung

    public func setCalculation(_ calculation: CalculationSettings) {
        self.calculation = calculation
        save(calculation, forKey: Key.calculation)
    }

    public func setShowKerahat(_ showKerahat: Bool) {
        self.showKerahat = showKerahat
        defaults?.set(showKerahat, forKey: Key.showKerahat)
    }

    /// Ändert einen Teil der Rechen-Einstellungen, z. B. `{ $0.asr = .hanafi }`.
    public func updateCalculation(_ change: (inout CalculationSettings) -> Void) {
        var calculation = calculation
        change(&calculation)
        setCalculation(calculation)
    }

    // MARK: - Mitteilungen

    public func setNotifications(_ notifications: NotificationPreferences) {
        self.notifications = notifications
        save(notifications, forKey: Key.notifications)
    }

    /// Ändert einen Teil der Mitteilungs-Einstellungen, z. B. `{ $0.reminderMinutes = 5 }`.
    public func updateNotifications(_ change: (inout NotificationPreferences) -> Void) {
        var notifications = notifications
        change(&notifications)
        setNotifications(notifications)
    }

    // MARK: - Wecker zu Fadschr

    /// Ändert den Wecker, z. B. `{ $0.mode = .fixedTime }`.
    public func updateFajrAlarm(_ change: (inout FajrAlarmPreferences) -> Void) {
        var fajrAlarm = fajrAlarm
        change(&fajrAlarm)
        self.fajrAlarm = fajrAlarm
        save(fajrAlarm, forKey: Key.fajrAlarm)
    }

    // MARK: - Darstellung und Sprache

    public func setAppearance(_ appearance: Appearance) {
        self.appearance = appearance
        defaults?.set(appearance.rawValue, forKey: Key.appearance)
    }

    /// Der Stil der App (Spec § 11.7). Die Grundfarbe gilt sofort überall (`AccentStore`); Widgets und
    /// Live-Aktivitäten bekommen den Stil, wenn die App neu plant.
    public func setStyle(_ style: AppStyle) {
        self.style = style
        accentStore.apply(style)
        save(style, forKey: Key.style)
    }

    /// Ändert einen Teil des Stils, z. B. `{ $0.accent = .ocean }`.
    public func updateStyle(_ change: (inout AppStyle) -> Void) {
        var style = style
        change(&style)
        setStyle(style)
    }

    /// Wählt die Sprache der App. Die Texte folgen sofort (`L10n.chosenLanguage`); die Seiten bauen sich
    /// dafür neu auf (`RootView`).
    public func setLanguage(_ language: AppLanguage?) {
        L10n.chosenLanguage = language
        self.language = language
        if let language {
            defaults?.set(language.rawValue, forKey: Key.language)
        } else {
            defaults?.removeObject(forKey: Key.language)
        }
    }

    // MARK: - Onboarding

    /// Das Onboarding ist durchlaufen oder übersprungen; es erscheint nicht wieder.
    public func completeOnboarding() {
        onboardingCompleted = true
        defaults?.set(onboardingCompleted, forKey: Key.onboardingCompleted)
    }

    // MARK: - Lesen und Schreiben

    /// Die Schlüssel in den UserDefaults.
    enum Key {
        static let autoLocation = "settings.autoLocation"
        static let manualPlace = "settings.city"
        static let savedPlaces = "settings.savedCities"
        static let devicePlace = "settings.deviceCity"
        static let calculation = "settings.calculation"
        static let showKerahat = "settings.showKerahat"
        static let notifications = "settings.notifications"
        static let fajrAlarm = "settings.fajrAlarm"
        static let appearance = "settings.appearance"
        static let style = "settings.style"
        static let language = "settings.language"
        static let onboardingCompleted = "settings.onboarded"

        static func bell(_ prayer: Prayer) -> String {
            "settings.notification." + prayer.rawValue
        }
    }

    private static func load(from defaults: UserDefaults) -> Snapshot {
        var snapshot = Snapshot()
        if defaults.object(forKey: Key.autoLocation) != nil {
            snapshot.autoLocation = defaults.bool(forKey: Key.autoLocation)
        }
        snapshot.manualPlace = decode(Place.self, from: defaults, forKey: Key.manualPlace)
        snapshot.savedPlaces = decode([Place].self, from: defaults, forKey: Key.savedPlaces) ?? []
        snapshot.devicePlace = decode(Place.self, from: defaults, forKey: Key.devicePlace)
        for prayer in Prayer.allCases {
            if let state = defaults.string(forKey: Key.bell(prayer)).flatMap(BellState.init(rawValue:)) {
                snapshot.bells[prayer] = state
            }
        }
        if let calculation = decode(CalculationSettings.self, from: defaults, forKey: Key.calculation) {
            snapshot.calculation = calculation
        }
        if defaults.object(forKey: Key.showKerahat) != nil {
            snapshot.showKerahat = defaults.bool(forKey: Key.showKerahat)
        }
        if let notifications = decode(NotificationPreferences.self, from: defaults, forKey: Key.notifications) {
            snapshot.notifications = notifications
        }
        if let fajrAlarm = decode(FajrAlarmPreferences.self, from: defaults, forKey: Key.fajrAlarm) {
            snapshot.fajrAlarm = fajrAlarm
        }
        if let appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) {
            snapshot.appearance = appearance
        }
        if let style = decode(AppStyle.self, from: defaults, forKey: Key.style) {
            snapshot.style = style
        }
        snapshot.language = defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:))
        snapshot.onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        return snapshot
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from defaults: UserDefaults, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    /// Schreibt einen Wert als JSON; `nil` entfernt den Eintrag.
    private func save<Value: Encodable>(_ value: Value?, forKey key: String) {
        guard let defaults else { return }
        guard let value, let data = try? JSONEncoder().encode(value) else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(data, forKey: key)
    }
}
