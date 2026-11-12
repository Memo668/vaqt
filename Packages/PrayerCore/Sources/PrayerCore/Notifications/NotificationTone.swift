/// Der Ton einer geplanten Mitteilung.
public enum NotificationTone: Hashable, Sendable {
    /// Ohne Ton: Die Mitteilung erscheint nur (Glocke „Lautlos“ oder Klang „Lautlos“).
    case silent
    /// Der Ton des Systems.
    case system
    /// Eine Aufnahme im Bundle der App, mit Endung – z. B. „adhan-voice1.caf“. iOS spielt für Mitteilungen
    /// höchstens 30 Sekunden (Spec § 4).
    case clip(String)

    /// Ton der Mitteilung zur Gebetszeit; `nil` bei der Glocke „Aus“ – dann gibt es keine Mitteilung.
    ///
    /// „Ton“ spielt den gewählten Klang, „Lautlos“ zeigt nur die Mitteilung (`perPrayerFooter`). Der kurze
    /// Adhan ist die Aufnahme der gewählten Stimme; zu Fadschr ihre Fadschr-Variante, sobald es dafür eine
    /// Aufnahme gibt, bis dahin der normale Ausschnitt. Hat die Stimme keine Aufnahme, spielt der Ton des
    /// Systems (entschieden mit dem Plan für Phase 8). Der Sonnenaufgang ist kein Gebet und hat keinen
    /// Adhan: Er spielt den Ton des Systems (entschieden mit der Abnahme von Phase 8).
    public static func prayer(_ prayer: Prayer, bell: BellState, preferences: NotificationPreferences) -> NotificationTone? {
        switch bell {
        case .off:
            return nil
        case .silent:
            return .silent
        case .sound:
            switch preferences.sound {
            case .silent:
                return .silent
            case .system:
                return .system
            case .adhan where prayer == .sunrise:
                return .system
            case .adhan:
                let voice = preferences.voice
                let resource = (prayer == .fajr ? voice.clipResource(fajrVariant: true) : nil)
                    ?? voice.clipResource(fajrVariant: false)
                return resource.map { .clip($0 + "." + AdhanVoice.clipExtension) } ?? .system
            }
        }
    }

    /// Ton der Vorab-Erinnerung; `nil` bei der Glocke „Aus“ – dann gibt es auch keine Erinnerung.
    ///
    /// Die Erinnerung spielt nie den Adhan, der kommt erst zur Gebetszeit: bei „Ton“ der Ton des Systems,
    /// beim Klang „Lautlos“ und bei der Glocke „Lautlos“ keiner (Annahme mit dem Plan für Phase 8).
    public static func reminder(bell: BellState, preferences: NotificationPreferences) -> NotificationTone? {
        switch bell {
        case .off: nil
        case .silent: .silent
        case .sound: preferences.sound == .silent ? .silent : .system
        }
    }
}

extension AdhanVoice {

    /// Endung der Aufnahmen: IMA4 in CAF, ein Format, das iOS auch für Mitteilungstöne annimmt.
    public static let clipExtension = "caf"

    /// Name der Aufnahme im Bundle der App, ohne Endung; `nil`, wenn es keine gibt.
    ///
    /// TODO(placeholder): Stimme 1 und 2 spielen freie Aufnahmen von Wikimedia Commons (App/Sounds,
    /// scripts/adhan-clip.swift). Stimme 3 und die Fadschr-Varianten haben noch keine; der Player läuft
    /// dann stumm, eine Mitteilung spielt den Ton des Systems. Spec § 6.5 ist offen.
    public func clipResource(fajrVariant: Bool) -> String? {
        guard !fajrVariant else { return nil }
        switch self {
        case .one: return "adhan-voice1"
        case .two: return "adhan-voice2"
        case .three: return nil
        }
    }
}
