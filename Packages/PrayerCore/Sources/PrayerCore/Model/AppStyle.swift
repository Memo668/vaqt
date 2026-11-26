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

/// Der Stil der App: Grundfarbe, App-Icon und Aussehen der Live-Aktivität (Einstellungen › Stil, Spec § 11.7 und
/// § 13.2). Gilt für App, Widgets, Live-Aktivität und Dynamic Island.
public struct AppStyle: Hashable, Codable, Sendable {
    public var accent: AccentColorID
    /// „App-Icon in der Grundfarbe“ (seit Phase 20): Das Icon auf dem Home-Bildschirm und das Zeichen der App
    /// (`AppMark`) folgen der Grundfarbe; aus heißt immer Petrol.
    public var tintsAppIcon: Bool
    public var liveActivity: LiveActivityStyle
    /// „Invertiert“: heller Grund, dunkle Schrift – für helle Hintergrundbilder.
    public var isInverted: Bool

    public init(
        accent: AccentColorID = .standard, tintsAppIcon: Bool = true, liveActivity: LiveActivityStyle = .full,
        isInverted: Bool = false
    ) {
        self.accent = accent
        self.tintsAppIcon = tintsAppIcon
        self.liveActivity = liveActivity
        self.isInverted = isInverted
    }

    /// Petrol, Icon in der Grundfarbe, farbig, nicht invertiert.
    public static let standard = AppStyle()

    /// Die Grundfarbe des App-Icons und des Zeichens `AppMark`: die Grundfarbe, bei ausgeschaltetem Schalter Petrol.
    public var appIconAccent: AccentColorID {
        tintsAppIcon ? accent : .standard
    }

    /// Der Name für `setAlternateIconName`: `nil` ist das Haupt-Icon in Petrol, sonst `AppIcon-<id>`.
    public var alternateIconName: String? {
        AppIconName.alternate(for: appIconAccent)
    }

    /// Ob etwas vom Standard abweicht; dann gibt es „Standard wiederherstellen“.
    public var isStandard: Bool {
        self == .standard
    }

    /// Unbekannte Werte – etwa aus einer späteren Fassung – gelten als Standard, statt das Ganze zu verwerfen.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accent = (try? container.decodeIfPresent(AccentColorID.self, forKey: .accent)) ?? .standard
        // Gespeichert vor Phase 20: an, wie der Standard.
        tintsAppIcon = (try? container.decodeIfPresent(Bool.self, forKey: .tintsAppIcon)) ?? true
        liveActivity = (try? container.decodeIfPresent(LiveActivityStyle.self, forKey: .liveActivity)) ?? .full
        isInverted = (try? container.decodeIfPresent(Bool.self, forKey: .isInverted)) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case accent, tintsAppIcon, liveActivity, isInverted
    }
}

/// Die Namen der App-Icons (Phase 20, Spec § 13.2). iOS kann ein Icon nicht umfärben; die App bringt je Grundfarbe
/// ein fertiges Icon mit: das Haupt-Icon `AppIcon` in Petrol (`App/AppIcon.icon`) und 23 alternative Icons
/// `AppIcon-<id>` (`App/AlternateIcons/`, eingetragen in `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`).
public enum AppIconName {
    /// Das Haupt-Icon; App Store und TestFlight zeigen immer dieses.
    public static let primary = "AppIcon"

    /// Das alternative Icon einer Grundfarbe; `nil` für Petrol, das Haupt-Icon.
    public static func alternate(for accent: AccentColorID) -> String? {
        accent == .standard ? nil : "\(primary)-\(accent.rawValue)"
    }

    /// Alle alternativen Icons in der Reihenfolge der Grundfarben.
    public static var alternates: [String] {
        AccentColorID.allCases.compactMap(alternate(for:))
    }
}
