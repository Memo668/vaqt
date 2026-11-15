/// Alles, was die Zeiten eines Ortes bestimmt – die Rechen-Einstellungen aus `S` im Prototyp
/// (`method`, `asr`, `hlRule`, `hlDeg`, `adj`).
public struct CalculationSettings: Hashable, Codable, Sendable {
    /// Gewählte Methode; `nil` heißt automatisch nach dem Land des Ortes.
    public var method: CalculationMethod?
    public var asr: AsrRule
    public var highLatitudeRule: HighLatitudeRule
    /// Die Winkel der Regel „Manuelle Winkel“; sie bleiben erhalten, wenn eine andere Regel gewählt ist.
    public var manualAngles: TwilightAngles
    public var adjustments: MinuteAdjustments

    /// Standard wie im Prototyp: Methode automatisch, Asr Standard, hohe Breiten winkelbasiert, keine Korrektur.
    public init(
        method: CalculationMethod? = nil,
        asr: AsrRule = .standard,
        highLatitudeRule: HighLatitudeRule = .angle,
        manualAngles: TwilightAngles = TwilightAngles(),
        adjustments: MinuteAdjustments = MinuteAdjustments()
    ) {
        self.method = method
        self.asr = asr
        self.highLatitudeRule = highLatitudeRule
        self.manualAngles = manualAngles
        self.adjustments = adjustments
    }

    /// Einstellungen, die vor Phase 12 gespeichert wurden, haben noch keine eigenen Winkel: Dann gelten
    /// die Startwerte.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        method = try container.decodeIfPresent(CalculationMethod.self, forKey: .method)
        asr = try container.decode(AsrRule.self, forKey: .asr)
        highLatitudeRule = try container.decode(HighLatitudeRule.self, forKey: .highLatitudeRule)
        manualAngles = try container.decodeIfPresent(TwilightAngles.self, forKey: .manualAngles) ?? TwilightAngles()
        adjustments = try container.decode(MinuteAdjustments.self, forKey: .adjustments)
    }

    private enum CodingKeys: String, CodingKey {
        case method, asr, highLatitudeRule, manualAngles, adjustments
    }

    /// Die Methode, mit der für `place` gerechnet wird: die gewählte, sonst die automatische des Landes
    /// (`methodObj()` im Prototyp).
    public func effectiveMethod(for place: Place) -> CalculationMethod {
        method ?? .automatic(forCountryCode: place.countryCode)
    }
}
