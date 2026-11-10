/// Regel für den Beginn von Asr.
///
/// Die Rohwerte sind die Kennungen des Prototyps (`S.asr`).
public enum AsrRule: String, CaseIterable, Codable, Sendable {
    /// Schatten = Objektlänge (Schafiʿi, Maliki, Hanbali) – Standard.
    case standard
    /// Schatten = doppelte Objektlänge.
    case hanafi
}
