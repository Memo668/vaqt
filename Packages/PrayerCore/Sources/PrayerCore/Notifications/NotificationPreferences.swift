/// Klang einer Mitteilung mit Ton – `S.sound` im Prototyp (`SOUND_KEY`).
///
/// Die Rohwerte sind die Kennungen des Prototyps. Welche Mitteilung überhaupt einen Ton hat, sagt die
/// Glocke je Gebet (`BellState`).
public enum NotificationSound: String, CaseIterable, Codable, Sendable {
    /// Der Ton des Systems.
    case system
    /// Der kurze Adhan, höchstens 30 Sekunden – die eine Aufnahme der App (`AdhanRecording`).
    case adhan
    /// Kein Ton, auch bei Gebeten mit „Ton“.
    case silent
}

/// Was neben der Glocke je Gebet zu den Mitteilungen gehört – `S.reminder`, `S.liveAct` und `S.sound`.
///
/// Mitteilungen plant `NotificationPlanner` damit, Live-Aktivitäten `LiveActivityPlanner`. Werte, die
/// keine der Wahlmöglichkeiten sind, gelten als nicht gesetzt: Es bleibt der Startwert des Prototyps.
public struct NotificationPreferences: Hashable, Sendable {
    /// Vorab-Erinnerung in Minuten, 0 heißt aus (`REMINDERS`).
    public static let reminderChoices = [0, 5, 10, 15, 20, 30]
    /// Vorlauf der Live-Aktivität in Minuten, 0 heißt aus. Der Prototyp bietet Aus, 30 und 60 (`LIVE_OPTS`);
    /// die längere Liste ist entschieden mit dem Plan für Phase 9 („Vorlauf beliebig einstellbar“).
    public static let liveActivityChoices = [0, 10, 15, 20, 30, 45, 60, 90, 120]

    public static let standardReminderMinutes = 10
    public static let standardLiveActivityMinutes = 30

    /// Minuten vor dem Gebet, zu denen eine Erinnerung kommt; 0 heißt keine.
    public var reminderMinutes: Int {
        didSet { if !Self.reminderChoices.contains(reminderMinutes) { reminderMinutes = Self.standardReminderMinutes } }
    }
    /// Minuten vor dem Gebet, ab denen die Live-Aktivität läuft; 0 heißt keine.
    public var liveActivityMinutes: Int {
        didSet { if !Self.liveActivityChoices.contains(liveActivityMinutes) { liveActivityMinutes = Self.standardLiveActivityMinutes } }
    }
    public var sound: NotificationSound

    /// Startwerte wie `S` im Prototyp: Erinnerung 10 Minuten vorher, Live-Aktivität 30 Minuten vorher,
    /// kurzer Adhan.
    public init(
        reminderMinutes: Int = NotificationPreferences.standardReminderMinutes,
        liveActivityMinutes: Int = NotificationPreferences.standardLiveActivityMinutes,
        sound: NotificationSound = .adhan
    ) {
        self.reminderMinutes = Self.reminderChoices.contains(reminderMinutes) ? reminderMinutes : Self.standardReminderMinutes
        self.liveActivityMinutes = Self.liveActivityChoices.contains(liveActivityMinutes)
            ? liveActivityMinutes : Self.standardLiveActivityMinutes
        self.sound = sound
    }
}

/// Gespeichert wird ein Objekt mit den Kennungen des Prototyps, z. B.
/// `{"reminder": 10, "liveAct": 30, "sound": "adhan"}`. Fehlt ein Wert oder passt er nicht, gilt sein
/// Startwert. Stände aus der Zeit vor Phase 18 enthalten noch `"voice"`, die damals gewählte Stimme
/// (Spec § 11.2); der Wert wird überlesen und beim nächsten Speichern nicht mehr geschrieben.
extension NotificationPreferences: Codable {

    private enum CodingKeys: String, CodingKey {
        case reminderMinutes = "reminder"
        case liveActivityMinutes = "liveAct"
        case sound
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            reminderMinutes: (try? container.decode(Int.self, forKey: .reminderMinutes)) ?? Self.standardReminderMinutes,
            liveActivityMinutes: (try? container.decode(Int.self, forKey: .liveActivityMinutes))
                ?? Self.standardLiveActivityMinutes,
            sound: (try? container.decode(NotificationSound.self, forKey: .sound)) ?? .adhan
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reminderMinutes, forKey: .reminderMinutes)
        try container.encode(liveActivityMinutes, forKey: .liveActivityMinutes)
        try container.encode(sound, forKey: .sound)
    }
}
