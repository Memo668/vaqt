/// Die Rechtsschule, nach der die App die Verbotszeiten zeigt und erklärt – `S.madhab` im Prototyp
/// (Nachtrag zu Phase 18, Spec § 11.6).
///
/// Sie bestimmt die Kerahat-Fenster und ihre Texte, nicht die Asr-Zeit: Die stellt `AsrRule` getrennt ein.
/// Die Rohwerte sind die Kennungen des Prototyps (`MADHABS`), in dieser Reihenfolge.
public enum Madhab: String, CaseIterable, Codable, Sendable {
    /// Hanafi – drei Fenster, 45 / 10 / 45 Minuten (Diyanet). Standard.
    case hanafi
    /// Maliki – kein Fenster vor Dhuhr, 20 / – / 20 Minuten.
    case maliki
    /// Schafii – freitags kein Fenster vor Dhuhr, 25 / 10 / 25 Minuten.
    case shafii
    /// Hanbali – drei Fenster, 20 / 10 / 20 Minuten.
    case hanbali

    /// Standard wie im Prototyp und im Onboarding vorgewählt.
    public static let standard = Madhab.hanafi
}
