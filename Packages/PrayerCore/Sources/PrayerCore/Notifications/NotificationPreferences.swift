/// Klang einer Mitteilung mit Ton – `S.sound` im Prototyp (`SOUND_KEY`).
///
/// Die Rohwerte sind die Kennungen des Prototyps. Welche Mitteilung überhaupt einen Ton hat, sagt die
/// Glocke je Gebet (`BellState`).
public enum NotificationSound: String, CaseIterable, Codable, Sendable {
    /// Der Ton des Systems.
    case system
    /// Der kurze Adhan der gewählten Stimme, höchstens 30 Sekunden.
    case adhan
    /// Kein Ton, auch bei Gebeten mit „Ton“.
    case silent
}

/// Eine Stimme des Adhan – `VOICES` im Prototyp.
///
/// TODO(placeholder): Die drei Stimmen und ihre Orte sind Platzhalter des Prototyps; die endgültigen
/// Aufnahmen stehen noch nicht fest (Spec § 6.5). Bis dahin spielen Stimme 1 und 2 freie Aufnahmen von
/// Wikimedia Commons, Stimme 3 hat keine (docs/OPEN-QUESTIONS.md, „Entschieden mit dem Plan für Phase 7“).
public enum AdhanVoice: Int, CaseIterable, Codable, Sendable {
    case one = 1
    case two = 2
    case three = 3

    /// Nummer der Stimme, wie sie in „Stimme {n}“ erscheint.
    public var number: Int { rawValue }

    /// Ort der Aufnahme (`VOICES[].place`). In allen Sprachen gleich, wie im Prototyp.
    public var place: String {
        switch self {
        case .one: "Makkah"
        case .two: "Madinah"
        case .three: "Istanbul"
        }
    }
}

/// Was neben der Glocke je Gebet zu den Mitteilungen gehört – `S.reminder`, `S.liveAct`, `S.sound` und
/// die Stimme des Adhan (`S.adhan.voice`).
///
/// Phase 7 speichert nur die Wahl; Mitteilungen plant Phase 8, die Live-Aktivität Phase 9. Werte, die
/// keine der Wahlmöglichkeiten sind, gelten als nicht gesetzt: Es bleibt der Startwert des Prototyps.
public struct NotificationPreferences: Hashable, Sendable {
    /// Vorab-Erinnerung in Minuten, 0 heißt aus (`REMINDERS`).
    public static let reminderChoices = [0, 5, 10, 15, 20, 30]
    /// Vorlauf der Live-Aktivität in Minuten, 0 heißt aus (`LIVE_OPTS`).
    public static let liveActivityChoices = [0, 30, 60]

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
    public var voice: AdhanVoice

    /// Startwerte wie `S` im Prototyp: Erinnerung 10 Minuten vorher, Live-Aktivität 30 Minuten vorher,
    /// kurzer Adhan, Stimme 1.
    public init(
        reminderMinutes: Int = NotificationPreferences.standardReminderMinutes,
        liveActivityMinutes: Int = NotificationPreferences.standardLiveActivityMinutes,
        sound: NotificationSound = .adhan,
        voice: AdhanVoice = .one
    ) {
        self.reminderMinutes = Self.reminderChoices.contains(reminderMinutes) ? reminderMinutes : Self.standardReminderMinutes
        self.liveActivityMinutes = Self.liveActivityChoices.contains(liveActivityMinutes)
            ? liveActivityMinutes : Self.standardLiveActivityMinutes
        self.sound = sound
        self.voice = voice
    }
}

/// Gespeichert wird ein Objekt mit den Kennungen des Prototyps, z. B.
/// `{"reminder": 10, "liveAct": 30, "sound": "adhan", "voice": 1}`. Fehlt ein Wert oder passt er nicht,
/// gilt sein Startwert.
extension NotificationPreferences: Codable {

    private enum CodingKeys: String, CodingKey {
        case reminderMinutes = "reminder"
        case liveActivityMinutes = "liveAct"
        case sound
        case voice
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            reminderMinutes: (try? container.decode(Int.self, forKey: .reminderMinutes)) ?? Self.standardReminderMinutes,
            liveActivityMinutes: (try? container.decode(Int.self, forKey: .liveActivityMinutes))
                ?? Self.standardLiveActivityMinutes,
            sound: (try? container.decode(NotificationSound.self, forKey: .sound)) ?? .adhan,
            voice: (try? container.decode(AdhanVoice.self, forKey: .voice)) ?? .one
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reminderMinutes, forKey: .reminderMinutes)
        try container.encode(liveActivityMinutes, forKey: .liveActivityMinutes)
        try container.encode(sound, forKey: .sound)
        try container.encode(voice, forKey: .voice)
    }
}
