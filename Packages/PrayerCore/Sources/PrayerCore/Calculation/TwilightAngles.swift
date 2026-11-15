/// Eigene Dämmerungswinkel für Fadschr und Ischa – die Regel „Manuelle Winkel“ für hohe Breiten
/// (Spec § 9.12, `S.hlDeg` im Prototyp). Ganze Grad von 10 bis 20, zu Beginn je 15.
public struct TwilightAngles: Hashable, Codable, Sendable {
    /// Der Bereich der Stepper (`hldeg`: 10 bis 20).
    public static let range = 10...20
    /// Startwert beider Winkel.
    public static let standard = 15

    public private(set) var fajr: Int
    public private(set) var isha: Int

    /// Werte außerhalb von `range` werden auf den Rand gesetzt.
    public init(fajr: Int = standard, isha: Int = standard) {
        self.fajr = Self.clamped(fajr)
        self.isha = Self.clamped(isha)
    }

    /// Der Winkel für Fadschr oder Ischa; für die übrigen Ereignisse `nil`.
    public subscript(prayer: Prayer) -> Int? {
        switch prayer {
        case .fajr: fajr
        case .isha: isha
        default: nil
        }
    }

    /// Ein Schritt des Steppers, innerhalb von `range` (`hldeg` im Prototyp). Für andere Ereignisse als
    /// Fadschr und Ischa geschieht nichts.
    public mutating func step(_ prayer: Prayer, by delta: Int) {
        switch prayer {
        case .fajr: fajr = Self.clamped(fajr + delta)
        case .isha: isha = Self.clamped(isha + delta)
        default: break
        }
    }

    /// Ob sich der Winkel noch verringern bzw. erhöhen lässt.
    public func canStep(_ prayer: Prayer, by delta: Int) -> Bool {
        guard let value = self[prayer] else { return false }
        return Self.range.contains(value + delta)
    }

    // Auch beim Lesen gespeicherter Werte begrenzen.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            fajr: try container.decodeIfPresent(Int.self, forKey: .fajr) ?? Self.standard,
            isha: try container.decodeIfPresent(Int.self, forKey: .isha) ?? Self.standard
        )
    }

    private enum CodingKeys: String, CodingKey {
        case fajr, isha
    }

    private static func clamped(_ value: Int) -> Int {
        min(range.upperBound, max(range.lowerBound, value))
    }
}
