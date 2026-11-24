import Observation
import PrayerCore
import Synchronization

/// Die Werte der 24 Grundfarben (Nachtrag zu Phase 18, Spec § 11.7) – die Liste `ACCENTS` im Prototyp, wörtlich:
/// hell (`--accent-l`), dunkel (`--accent-d`) und die Schrift auf der dunklen Akzentfläche (`--on-accent-d`). Hell
/// ist die Schrift auf der Akzentfläche immer Weiß.
///
/// Kontrast und Abstände prüfen die Tests (`AccentPaletteTests`), wie das Bauskript des Vorschlags.
extension AccentColorID {

    /// `--accent-l`.
    public var light: RGBA {
        RGBA(hex: Self.values[self]?.light ?? 0x1F7A6D)
    }

    /// `--accent-d`.
    public var dark: RGBA {
        RGBA(hex: Self.values[self]?.dark ?? 0x4CC2AE)
    }

    /// `--on-accent-d`: Schrift und Symbole auf der Akzentfläche im dunklen Erscheinungsbild.
    public var onDark: RGBA {
        RGBA(hex: Self.values[self]?.onDark ?? 0x04221D)
    }

    /// Name für VoiceOver und als Wert der Zeile „Stil“ (`col_<id>`).
    public var localizedName: String {
        switch self {
        case .teal: L10n.col_teal
        case .green: L10n.col_green
        case .blue: L10n.col_blue
        case .violet: L10n.col_violet
        case .berry: L10n.col_berry
        case .graphite: L10n.col_graphite
        case .cyan: L10n.col_cyan
        case .grass: L10n.col_grass
        case .indigo: L10n.col_indigo
        case .orchid: L10n.col_orchid
        case .orange: L10n.col_orange
        case .gold: L10n.col_gold
        case .ocean: L10n.col_ocean
        case .forest: L10n.col_forest
        case .navy: L10n.col_navy
        case .plum: L10n.col_plum
        case .wine: L10n.col_wine
        case .mono: L10n.col_mono
        case .mint: L10n.col_mint
        case .sage: L10n.col_sage
        case .ice: L10n.col_ice
        case .lavender: L10n.col_lavender
        case .mauve: L10n.col_mauve
        case .sand: L10n.col_sand
        }
    }

    private static let values: [AccentColorID: (light: UInt32, dark: UInt32, onDark: UInt32)] = [
        // Standard
        .teal: (0x1F7A6D, 0x4CC2AE, 0x04221D),
        .green: (0x2E7D4F, 0x5FCB8A, 0x04220F),
        .blue: (0x1E6BB8, 0x6DB5FF, 0x031B33),
        .violet: (0x7A4CB5, 0xC4A2FF, 0x1B0B33),
        .berry: (0xA93466, 0xFF8FBA, 0x33081B),
        .graphite: (0x48484D, 0xD6D6DC, 0x111113),
        // kräftig
        .cyan: (0x026E89, 0x28D1FE, 0x001F28),
        .grass: (0x3C6603, 0x98D75E, 0x111F05),
        .indigo: (0x4646CB, 0x8997FF, 0x151831),
        .orchid: (0x941C95, 0xE585E2, 0x271126),
        .orange: (0xA44C03, 0xFE904D, 0x2C1204),
        .gold: (0x876204, 0xF5C25F, 0x251801),
        // tief
        .ocean: (0x024153, 0x43A9CB, 0x011E28),
        .forest: (0x03472A, 0x5FA77F, 0x032112),
        .navy: (0x182D6A, 0x728DCD, 0x101932),
        .plum: (0x50205A, 0xB47EBE, 0x251228),
        .wine: (0x6D1733, 0xC37586, 0x2D0F17),
        .mono: (0x1C1C1E, 0xF2F2F7, 0x1C1C1E),
        // gedeckt
        .mint: (0x015D54, 0x9AE9DD, 0x01201C),
        .sage: (0x556345, 0xBDD4A3, 0x161E0B),
        .ice: (0x455A74, 0x9FC1EB, 0x131B27),
        .lavender: (0x69639D, 0xCBC6FF, 0x1A172C),
        .mauve: (0x714967, 0xCBB7C5, 0x1F181D),
        .sand: (0x6F4D27, 0xECCAA7, 0x24180B),
    ]
}

/// Die Farbe der Verbotszeiten je Grundfarbe (Spec § 11.7): orange wie bisher, bei den warmen Grundfarben violett.
///
/// Jeder Orangeton des Prototyps ist dafür auf OKLCH-Ton 300 gedreht, bei gleicher Helligkeit und Buntheit
/// (`kerahat_violet()` im Bauskript des Vorschlags); die Paare stehen hier wörtlich. Die Tests rechnen sie nach.
public enum KerahatTone {

    /// Orange → Violett, für alle Orangetöne, die je in einer Verbotszeit erscheinen.
    public static let violet: [UInt32: UInt32] = [
        0xC7862A: 0xA282D9, 0x9A6212: 0x7B5FA8, 0xD9A04E: 0xB89AED, 0xE3B36B: 0xC6ADF6,
        0xF3C979: 0xD8C4FF, 0xEC8530: 0xB38AF6, 0xD9772B: 0xA37DE1, 0xC4661F: 0x916CCB,
        0xFFE2BF: 0xEBE2FF, 0x8A4409: 0x644990, 0xB85C12: 0x8762BF, 0xF1DCCB: 0xE3DCF3,
        0xEDA35C: 0xC2A3F9, 0xF0A257: 0xC3A2FC, 0x3A1D05: 0x2A1E3D, 0xF8B877: 0xD0B8FF,
        0x9A4D0E: 0x7152A0, 0xE0A84F: 0xC0A1F7,
    ]

    /// Der Ton für die Verbotszeit: bei warmen Grundfarben violett, sonst `hex` selbst.
    public static func rgba(_ hex: UInt32, accent: AccentColorID) -> RGBA {
        RGBA(hex: accent.isWarm ? (violet[hex] ?? hex) : hex)
    }
}

/// Die Grundfarbe, die gerade gilt – eine für die ganze App, die Widgets und die Erweiterung.
///
/// Alle Farben, die von der Grundfarbe abhängen (`Palette.accent` und was daraus gemischt ist), lesen sie hier.
/// Der Speicher ist beobachtbar: Liest eine Ansicht beim Aufbau eine dieser Farben, baut sie sich nach einem
/// Wechsel neu auf – ohne dass jede Ansicht die Farbe durchreichen muss. Die App setzt sie aus den Einstellungen
/// (`SettingsStore`), die Widget-Erweiterung aus der App Group, bevor sie zeichnet.
public final class AccentStore: Observable, Sendable {

    public static let shared = AccentStore()

    private let registrar = ObservationRegistrar()
    private let storage = Mutex(AccentColorID.standard)

    public init() {}

    /// Die Grundfarbe; der Standard ist Petrol.
    public var accent: AccentColorID {
        get {
            registrar.access(self, keyPath: \.accent)
            return storage.withLock { $0 }
        }
        set {
            guard storage.withLock({ $0 }) != newValue else { return }
            registrar.withMutation(of: self, keyPath: \.accent) {
                storage.withLock { $0 = newValue }
            }
        }
    }
}
