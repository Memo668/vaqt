/// Minutenkorrektur je Ereignis – `S.adj` im Prototyp.
///
/// Jeder Wert liegt zwischen −30 und +30 Minuten (Spec § 4). Werte außerhalb werden an den Rand gesetzt.
public struct MinuteAdjustments: Hashable, Sendable {
    /// Erlaubter Bereich je Ereignis in Minuten. An den Rändern sperren die Stepper ihre Knöpfe.
    public static let range = -30...30

    /// Nur Werte ungleich null. So sind zwei Sätze mit denselben Korrekturen auch als Wert gleich.
    private var minutes: [Prayer: Int] = [:]

    /// Keine Korrektur.
    public init() {}

    public init(_ minutes: [Prayer: Int]) {
        for (prayer, value) in minutes {
            self[prayer] = value
        }
    }

    /// Korrektur eines Ereignisses in Minuten; ohne Korrektur 0.
    public subscript(prayer: Prayer) -> Int {
        get { minutes[prayer] ?? 0 }
        set {
            let value = min(max(newValue, Self.range.lowerBound), Self.range.upperBound)
            minutes[prayer] = value == 0 ? nil : value
        }
    }

    /// Verschiebt ein Ereignis um `delta` Minuten, höchstens bis an den Rand des Bereichs – Aktion `step`.
    public mutating func step(_ prayer: Prayer, by delta: Int) {
        // Mehr als die Breite des Bereichs bewirkt nichts; so läuft die Summe nie über.
        let width = Self.range.upperBound - Self.range.lowerBound
        self[prayer] += min(max(delta, -width), width)
    }

    /// Setzt alle Korrekturen auf 0 – Aktion `adj-reset`.
    public mutating func reset() {
        minutes.removeAll()
    }

    /// Zahl der Ereignisse mit Korrektur – „{n} geändert“ in den Einstellungen.
    public var changedCount: Int {
        minutes.count
    }
}

/// Gespeichert wird ein Objekt mit den Kennungen der Ereignisse, z. B. `{"dhuhr": 5, "fajr": -2}`.
extension MinuteAdjustments: Codable {

    public init(from decoder: any Decoder) throws {
        let stored = try decoder.singleValueContainer().decode([String: Int].self)
        for (key, value) in stored {
            // Unbekannte Kennungen werden übergangen, Werte außerhalb des Bereichs an den Rand gesetzt.
            guard let prayer = Prayer(rawValue: key) else { continue }
            self[prayer] = value
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Dictionary(uniqueKeysWithValues: minutes.map { ($0.key.rawValue, $0.value) }))
    }
}
