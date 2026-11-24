/// Eine der 24 Grundfarben der App (Nachtrag zu Phase 18, Spec § 11.7) – die Kennungen von `ACCENTS` im Prototyp,
/// in der Reihenfolge des Rasters 4 × 6: Standard, kräftig, tief, gedeckt. In jeder Reihe folgen die Töne derselben
/// Ordnung (Petrol/Türkis, Grün, Blau, Violett, Rosa/Rot bzw. warm, Neutral).
///
/// Nur die Kennung: Die Farbwerte und Namen stehen im DesignSystem. Hier, weil die Live-Aktivität ihren Stil im
/// Inhalt mitträgt (`LiveActivityContent.style`).
public enum AccentColorID: String, CaseIterable, Codable, Sendable {
    // Standard – immer sichtbar
    case teal, green, blue, violet, berry, graphite
    // kräftig
    case cyan, grass, indigo, orchid, orange, gold
    // tief
    case ocean, forest, navy, plum, wine, mono
    // gedeckt
    case mint, sage, ice, lavender, mauve, sand

    /// Petrol, wie bisher.
    public static let standard = AccentColorID.teal
    /// Farben je Reihe des Rasters.
    public static let rowLength = 6

    /// Die sechs Standardfarben – zugeklappt die einzigen sichtbaren.
    public static var standardRow: [AccentColorID] {
        Array(allCases.prefix(rowLength))
    }

    /// Ob die Farbe in der Standardreihe steht.
    public var isInStandardRow: Bool {
        Self.standardRow.contains(self)
    }

    /// Orange, Gold und Sand: Bei ihnen ist die Verbotszeit violett statt orange (`WARM` im Prototyp).
    public var isWarm: Bool {
        self == .orange || self == .gold || self == .sand
    }
}

/// Wie die Live-Aktivität aussieht (`LA_STYLES` im Prototyp): farbig, nur der Bogen farbig, schwarz-weiß. Jede
/// Stufe gibt es auch invertiert (`AppStyle.isInverted`). Die Deckkraft ist immer 30 %.
public enum LiveActivityStyle: String, CaseIterable, Codable, Sendable {
    /// Verlauf der Grundfarbe, wie bisher (Spec § 10.3).
    case full
    /// Grund ohne Farbe, nur Bogen und begonnene Gebete in der Grundfarbe.
    case arc
    /// Ganz ohne Farbe; Verbotszeiten gestreift.
    case mono
}

/// Der Stil der App: Grundfarbe und Aussehen der Live-Aktivität (Einstellungen › Stil, Spec § 11.7). Gilt für
/// App, Widgets, Live-Aktivität und Dynamic Island.
public struct AppStyle: Hashable, Codable, Sendable {
    public var accent: AccentColorID
    public var liveActivity: LiveActivityStyle
    /// „Invertiert“: heller Grund, dunkle Schrift – für helle Hintergrundbilder.
    public var isInverted: Bool

    public init(accent: AccentColorID = .standard, liveActivity: LiveActivityStyle = .full, isInverted: Bool = false) {
        self.accent = accent
        self.liveActivity = liveActivity
        self.isInverted = isInverted
    }

    /// Petrol, farbig, nicht invertiert – wie vor dem Nachtrag zu Phase 18.
    public static let standard = AppStyle()

    /// Ob etwas vom Standard abweicht; dann gibt es „Standard wiederherstellen“.
    public var isStandard: Bool {
        self == .standard
    }

    /// Unbekannte Werte – etwa aus einer späteren Fassung – gelten als Standard, statt das Ganze zu verwerfen.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accent = (try? container.decodeIfPresent(AccentColorID.self, forKey: .accent)) ?? .standard
        liveActivity = (try? container.decodeIfPresent(LiveActivityStyle.self, forKey: .liveActivity)) ?? .full
        isInverted = (try? container.decodeIfPresent(Bool.self, forKey: .isInverted)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case accent, liveActivity, isInverted
    }
}
