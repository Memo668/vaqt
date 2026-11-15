import CoreGraphics
import PrayerCore

// Texte und Symbole der Anleitung aus dem String Catalog – die Teile von `guidePage()` im Prototyp, die
// nicht in `PrayerCore` stehen.

extension GuideStep.Kind {

    /// Titel des Schritts (`s_takbir` …), z. B. „Verbeugung (Rukūʿ)“.
    public var localizedTitle: String {
        switch self {
        case .takbir: L10n.s_takbir
        case .qiyam: L10n.s_qiyam
        case .ruku: L10n.s_ruku
        case .itidal: L10n.s_itidal
        case .sujud: L10n.s_sujud
        case .tash: L10n.s_tash
        case .salam: L10n.s_salam
        }
    }

    /// Kurze Anweisung zum Schritt (`s_takbirD` …).
    public var localizedDescription: String {
        switch self {
        case .takbir: L10n.s_takbirD
        case .qiyam: L10n.s_qiyamD
        case .ruku: L10n.s_rukuD
        case .itidal: L10n.s_itidalD
        case .sujud: L10n.s_sujudD
        case .tash: L10n.s_tashD
        case .salam: L10n.s_salamD
        }
    }
}

extension Rakahs.Recitation {

    /// Wert der mittleren Fakten-Kachel: „laut“, „leise“ oder „1.–2. laut“ (`recAloud`, `recSilent`,
    /// `recMixed`).
    public var localizedName: String {
        switch self {
        case .aloud: L10n.recAloud
        case .mixed: L10n.recMixed
        case .silent: L10n.recSilent
        }
    }
}

extension Rakahs {

    /// Die Rakʿa-Folge für VoiceOver, wie `aria-label` von `.rak`: „Ablauf der Rakʿas: 1 leise, 2 leise, …“.
    public var accessibilityDescription: String {
        let units = aloud.enumerated().map { index, isAloud in
            "\(index + 1) \(isAloud ? L10n.recAloud : L10n.recSilent)"
        }
        return "\(L10n.rakSeq): \(units.joined(separator: ", "))"
    }
}

extension Prayer {

    /// Die Sunna-Gebete rund um das Fard, z. B. „4 vorher (freiwillig)“ (`sunna_<p>`). Der Sonnenaufgang
    /// ist kein Gebet und hat keine.
    public var localizedSunna: String {
        switch self {
        case .fajr: L10n.sunna_fajr
        case .sunrise: ""
        case .dhuhr: L10n.sunna_dhuhr
        case .asr: L10n.sunna_asr
        case .maghrib: L10n.sunna_maghrib
        case .isha: L10n.sunna_isha
        }
    }
}

/// Was vor dem Gebet steht – die vier Karten unter „Vorher“ in der Anleitung.
public enum GuidePreparation: String, CaseIterable, Identifiable, Sendable {
    /// Gebetswaschung (`b_wudu`).
    case wudu
    /// Reiner Ort und Kleidung (`b_clean`).
    case clean
    /// Richtung Qibla, mit dem Knopf zur Qibla-Seite (`b_qibla`).
    case qibla
    /// Absicht mit Gebetsname und Zahl der Rakʿas (`b_niyya`).
    case niyya

    public var id: Self { self }

    /// SF Symbol der Karte. Der Prototyp zeichnet eigene Linien (`drop`, `sparkle`, `compass`, `heart`);
    /// die App nimmt SF Symbols wie in den Phasen 2 bis 4 (entschieden mit dem Plan für Phase 5). Die
    /// Qibla trägt dasselbe Symbol wie ihr Chip.
    public var symbolName: String {
        switch self {
        case .wudu: "drop"
        case .clean: "sparkles"
        case .qibla: "safari"
        case .niyya: "heart"
        }
    }

    /// Schriftgröße des SF Symbols, so dass es so groß erscheint wie die Zeichnung des Prototyps in ihrem
    /// Feld von 22 pt: Tropfen 12 × 17 pt, Funkeln 15 × 15,5 pt, Kompass 18 pt, Herz 14,5 × 12,5 pt.
    public var symbolSize: CGFloat {
        switch self {
        case .wudu: 17
        case .clean: 14
        case .qibla: 18
        case .niyya: 14
        }
    }

    public var localizedTitle: String {
        switch self {
        case .wudu: L10n.b_wudu
        case .clean: L10n.b_clean
        case .qibla: L10n.b_qibla
        case .niyya: L10n.b_niyya
        }
    }

    /// Text der Karte. Die Absicht nennt das Gebet und die Zahl seiner Rakʿas („Asr, 4 Rakʿa“).
    public func localizedText(prayer: Prayer, rakahs: Rakahs) -> String {
        switch self {
        case .wudu: L10n.b_wuduD
        case .clean: L10n.b_cleanD
        case .qibla: L10n.b_qiblaD
        case .niyya: L10n.b_niyyaD(p: prayer.localizedName, n: rakahs.count)
        }
    }
}

/// Symbole der Anleitung außerhalb der Gebete.
public enum GuideSymbols {
    /// Knopf „Qibla öffnen“: dasselbe Symbol wie der Chip Qibla (`ic('compass', 18)`).
    public static let openQibla = "safari"
    /// Karte „Schritte 2–5 wiederholen“: dasselbe Symbol wie der Tab Nachholen (`ic('qada', 18)`).
    public static let repeatSteps = "clock.arrow.circlepath"
}
