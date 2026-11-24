import Foundation
import PrayerCore

/// Was die App für Widgets und Live-Aktivität in die App Group schreibt (Spec § 1, „Outside the app“).
///
/// Die Extension rechnet daraus mit PrayerCore selbst: Ort, Name des Ortes, Rechen-Einstellungen samt
/// Minutenkorrektur, Kerahat-Schalter und Sprache – alles so, wie es in der App gilt. Den Ort entscheidet
/// die App (aktueller Standort oder gewählte Stadt, je nach Freigabe); die Extension fragt nie nach dem
/// Standort. Nichts davon verlässt das Gerät.
public struct WidgetState: Codable, Hashable, Sendable {

    /// Nur in DEBUG-Builds gesetzt: Mock-Zeiten und Debug-Uhr der App (`-debugFixtureTimes`, `-debugTime`),
    /// damit die Widgets dieselben Zahlen zeigen wie die App und die Referenzbilder.
    public struct Debug: Codable, Hashable, Sendable {
        /// Mock-Zeiten des Prototyps statt echter Rechnung.
        public var fixtureTimes: Bool
        /// `-debugHighLatitude`: die Mock-Zeiten von Berlin am 21. Juni.
        public var highLatitude: Bool
        /// Uhr der App minus Gerätezeit in Sekunden.
        public var clockOffset: TimeInterval

        public init(fixtureTimes: Bool, highLatitude: Bool, clockOffset: TimeInterval) {
            self.fixtureTimes = fixtureTimes
            self.highLatitude = highLatitude
            self.clockOffset = clockOffset
        }
    }

    /// Der Ort, der in der App gilt; `nil`, solange es keinen gibt – dann zeigen die Widgets „Stadt wählen“.
    public var place: Place?
    /// Name des Ortes wie auf der Zeiten-Seite, z. B. „Berlin“ oder „Aktueller Standort“.
    public var cityName: String
    /// Ob der Ort der aktuelle Standort ist; dann steht der Pfeil vor dem Namen.
    public var isCurrentLocation: Bool
    /// Methode, Asr, Regel für hohe Breiten, Minutenkorrekturen.
    public var calculation: CalculationSettings
    /// Der Schalter „Kerahat-Zeiten zeigen“.
    public var showKerahat: Bool
    /// Die Sprache, in der die App ihre Texte zeigt, auch ohne eigene Wahl. Die Extension läuft in der
    /// Sprache des Geräts; so stimmen ihre Texte mit denen der App überein.
    public var language: AppLanguage
    /// Stil der App (Spec § 11.7): Grundfarbe und Aussehen des Widgets mit dem Bogen; `nil` in Ständen vor dem
    /// Nachtrag zu Phase 18, dann gilt der Standard.
    public var style: AppStyle?
    public var debug: Debug?

    public init(
        place: Place?, cityName: String, isCurrentLocation: Bool, calculation: CalculationSettings,
        showKerahat: Bool, language: AppLanguage, style: AppStyle = .standard, debug: Debug? = nil
    ) {
        self.place = place
        self.cityName = cityName
        self.isCurrentLocation = isCurrentLocation
        self.calculation = calculation
        self.showKerahat = showKerahat
        self.language = language
        self.style = style
        self.debug = debug
    }

    /// Der Stil, der gilt.
    public var effectiveStyle: AppStyle {
        style ?? .standard
    }

    /// Uhr der App minus Gerätezeit; ohne Debug-Uhr 0.
    public var clockOffset: TimeInterval {
        debug?.clockOffset ?? 0
    }

    // MARK: - App Group

    /// Schlüssel in den UserDefaults der App Group.
    public static let key = "widgets.state"

    /// Die App Group aus der Info.plist (`AppGroupIdentifier`, gefüllt aus `APP_GROUP_ID` in project.yml) –
    /// App und Extension tragen sie beide.
    public static var appGroupIdentifier: String? {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
              !identifier.isEmpty
        else { return nil }
        return identifier
    }

    /// Die UserDefaults der App Group; ohne Eintrag in der Info.plist – etwa in Tests – keine.
    public static var sharedDefaults: UserDefaults? {
        appGroupIdentifier.flatMap { UserDefaults(suiteName: $0) }
    }

    /// Liest den Stand; `nil`, solange die App noch keinen geschrieben hat.
    public static func load(from defaults: UserDefaults) -> WidgetState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetState.self, from: data)
    }

    /// Schreibt den Stand. Gibt zurück, ob er sich geändert hat – nur dann müssen die Widgets neu laden.
    @discardableResult
    public func save(to defaults: UserDefaults) -> Bool {
        guard Self.load(from: defaults) != self, let data = try? JSONEncoder().encode(self) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }
}
