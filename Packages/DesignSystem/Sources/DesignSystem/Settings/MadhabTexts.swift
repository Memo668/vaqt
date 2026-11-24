import PrayerCore

/// Die Texte je Rechtsschule (Nachtrag zu Phase 18, Spec § 11.6) – `madhab_*`, `madhabSub_*`, `madhabAdj_*` und die
/// Texte der Verbotszeiten im Prototyp. Hanafi behält die bisherigen Texte wörtlich (`kerahatFooter`,
/// `kerahatInfoP1`, `kerahatInfoFoot`); die übrigen Schulen haben eigene.
extension Madhab {

    /// Name der Schule, z. B. „Schafii“ (`madhab_<school>`).
    public var localizedName: String {
        switch self {
        case .hanafi: L10n.madhab_hanafi
        case .maliki: L10n.madhab_maliki
        case .shafii: L10n.madhab_shafii
        case .hanbali: L10n.madhab_hanbali
        }
    }

    /// Zeile unter dem Namen: welche Verbotszeiten gelten (`madhabSub_<school>`).
    public var localizedDetail: String {
        switch self {
        case .hanafi: L10n.madhabSub_hanafi
        case .maliki: L10n.madhabSub_maliki
        case .shafii: L10n.madhabSub_shafii
        case .hanbali: L10n.madhabSub_hanbali
        }
    }

    /// Eigenschaftswort für „nach {school} Lehre“, z. B. „schafiitischer“ (`madhabAdj_<school>`).
    public var localizedAdjective: String {
        switch self {
        case .hanafi: L10n.madhabAdj_hanafi
        case .maliki: L10n.madhabAdj_maliki
        case .shafii: L10n.madhabAdj_shafii
        case .hanbali: L10n.madhabAdj_hanbali
        }
    }

    /// Fußzeile der Gruppe „Darstellung“ in den Einstellungen.
    public var kerahatFooter: String {
        switch self {
        case .hanafi: L10n.kerahatFooter
        case .maliki: L10n.kerahatFooter_maliki
        case .shafii: L10n.kerahatFooter_shafii
        case .hanbali: L10n.kerahatFooter_hanbali
        }
    }

    /// Einleitung des Blatts „Was sind Verbotszeiten?“.
    public var kerahatInfoIntro: String {
        switch self {
        case .hanafi: L10n.kerahatInfoP1
        case .maliki: L10n.kerahatP1_maliki
        case .shafii: L10n.kerahatP1_shafii
        case .hanbali: L10n.kerahatP1_hanbali
        }
    }

    /// Fußnote des Blatts: Schule und Näherungen.
    public var kerahatInfoFootnote: String {
        switch self {
        case .hanafi: L10n.kerahatInfoFoot
        case .maliki: L10n.kerahatFoot_maliki
        case .shafii: L10n.kerahatFoot_shafii
        case .hanbali: L10n.kerahatFoot_hanbali
        }
    }

    /// Abschnitt „Versäumte Gebete nachholen“: hanafitisch nicht in den drei Fenstern, sonst erlaubt.
    public var kerahatQadaText: String {
        self == .hanafi ? L10n.kerahatQadaHanafi : L10n.kerahatQadaOther(school: localizedAdjective)
    }

    /// Ob das Blatt „Asr noch nicht gebetet?“ zeigt und die Anleitung zu Asr den Hinweis auf das Farḍ – nur
    /// hanafitisch.
    public var hasAsrNote: Bool {
        self == .hanafi
    }
}
