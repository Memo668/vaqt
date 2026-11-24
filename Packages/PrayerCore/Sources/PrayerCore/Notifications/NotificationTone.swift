/// Der Ton einer geplanten Mitteilung.
public enum NotificationTone: Hashable, Sendable {
    /// Ohne Ton: Die Mitteilung erscheint nur (Glocke „Lautlos“ oder Klang „Lautlos“).
    case silent
    /// Der Ton des Systems.
    case system
    /// Eine Aufnahme im Bundle der App, mit Endung – „adhan.caf“ (`AdhanRecording.clipFile`). iOS spielt
    /// für Mitteilungen höchstens 30 Sekunden (Spec § 4).
    case clip(String)

    /// Ton der Mitteilung zur Gebetszeit; `nil` bei der Glocke „Aus“ – dann gibt es keine Mitteilung.
    ///
    /// „Ton“ spielt den gewählten Klang, „Lautlos“ zeigt nur die Mitteilung (`perPrayerFooter`). Der kurze
    /// Adhan ist die eine Aufnahme der App (`AdhanRecording`), zu allen fünf Gebeten dieselbe, auch zu
    /// Fadschr (Spec § 11.2). Der Sonnenaufgang ist kein Gebet und hat keinen Adhan: Er spielt den Ton des
    /// Systems (entschieden mit der Abnahme von Phase 8).
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
                return .clip(AdhanRecording.clipFile)
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
