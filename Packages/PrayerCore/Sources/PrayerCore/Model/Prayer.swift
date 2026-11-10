/// Die sechs Tagesereignisse in zeitlicher Reihenfolge – `PRAYERS` im Prototyp.
///
/// Der Sonnenaufgang ist kein Gebet, steht aber in der Liste, weil er Fadschr beendet.
public enum Prayer: String, CaseIterable, Codable, Sendable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    /// Die fünf Pflichtgebete ohne Sonnenaufgang – `FIVE` im Prototyp.
    public static let five: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
}
