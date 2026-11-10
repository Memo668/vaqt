/// Alles, was die Zeiten eines Ortes bestimmt – die Rechen-Einstellungen aus `S` im Prototyp
/// (`method`, `asr`, `hlRule`, `adj`).
public struct CalculationSettings: Hashable, Codable, Sendable {
    /// Gewählte Methode; `nil` heißt automatisch nach dem Land des Ortes.
    public var method: CalculationMethod?
    public var asr: AsrRule
    public var highLatitudeRule: HighLatitudeRule
    public var adjustments: MinuteAdjustments

    /// Standard wie im Prototyp: Methode automatisch, Asr Standard, hohe Breiten winkelbasiert, keine Korrektur.
    public init(
        method: CalculationMethod? = nil,
        asr: AsrRule = .standard,
        highLatitudeRule: HighLatitudeRule = .angle,
        adjustments: MinuteAdjustments = MinuteAdjustments()
    ) {
        self.method = method
        self.asr = asr
        self.highLatitudeRule = highLatitudeRule
        self.adjustments = adjustments
    }

    /// Die Methode, mit der für `place` gerechnet wird: die gewählte, sonst die automatische des Landes
    /// (`methodObj()` im Prototyp).
    public func effectiveMethod(for place: Place) -> CalculationMethod {
        method ?? .automatic(forCountryCode: place.countryCode)
    }
}
