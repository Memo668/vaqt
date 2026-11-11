import PrayerCore

// Symbole und Namen der Tagesereignisse und der Glocke. Die Symbole sind SF Symbols, wie die Design
// Spec sie nennt (§ 2, „Icons“); der Prototyp zeichnet an ihrer Stelle eigene Linien (`PICON`, `BELL_ICON`).

extension Prayer {

    /// SF Symbol des Ereignisses.
    public var symbolName: String {
        switch self {
        case .fajr: "sun.horizon"
        case .sunrise: "sunrise"
        case .dhuhr: "sun.max"
        case .asr: "sun.min"
        case .maghrib: "sunset"
        case .isha: "moon.stars"
        }
    }

    /// Name aus dem String Catalog (`p_fajr` …).
    public var localizedName: String {
        switch self {
        case .fajr: L10n.p_fajr
        case .sunrise: L10n.p_sunrise
        case .dhuhr: L10n.p_dhuhr
        case .asr: L10n.p_asr
        case .maghrib: L10n.p_maghrib
        case .isha: L10n.p_isha
        }
    }
}

extension HighLatitudeRule {

    /// Name der Regel aus dem String Catalog (`HL_KEY`: `hlAngle`, `hlSeventh`, `hlMiddle`).
    public var localizedName: String {
        switch self {
        case .angle: L10n.hlAngle
        case .seventh: L10n.hlSeventh
        case .middle: L10n.hlMiddle
        }
    }
}

extension BellState {

    /// SF Symbol der Glocke in diesem Stand.
    public var symbolName: String {
        switch self {
        case .sound: "bell.and.waves.left.and.right"
        case .silent: "bell"
        case .off: "bell.slash"
        }
    }

    /// Name des Standes aus dem String Catalog (`bellSound`, `bellSilent`, `bellOff`).
    public var localizedName: String {
        switch self {
        case .sound: L10n.bellSound
        case .silent: L10n.bellSilent
        case .off: L10n.bellOff
        }
    }
}
