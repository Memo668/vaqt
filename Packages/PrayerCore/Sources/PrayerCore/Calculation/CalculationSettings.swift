/// Alles, was die Zeiten eines Ortes bestimmt – die Rechen-Einstellungen aus `S` im Prototyp
/// (`method`, `asr`, `hlRule`, `hlDeg`, `adj`), seit dem Nachtrag zu Phase 18 dazu die Rechtsschule
/// (`madhab`) für die Verbotszeiten.
public struct CalculationSettings: Hashable, Codable, Sendable {
    /// Gewählte Methode; `nil` heißt automatisch nach dem Land des Ortes.
    public var method: CalculationMethod?
    public var asr: AsrRule
    public var highLatitudeRule: HighLatitudeRule
    /// Die Winkel der Regel „Manuelle Winkel“; sie bleiben erhalten, wenn eine andere Regel gewählt ist.
    public var manualAngles: TwilightAngles
    public var adjustments: MinuteAdjustments
    /// Die Rechtsschule für die Verbotszeiten (Spec § 11.6). Sie ändert keine Gebetszeit, nur die
    /// Kerahat-Fenster, die zu den Zeiten gehören (`DayTimes.madhab`).
    public var madhab: Madhab

    /// Standard wie im Prototyp: Methode automatisch, Asr Standard, hohe Breiten winkelbasiert, keine Korrektur,
    /// Rechtsschule Hanafi.
    public init(
        method: CalculationMethod? = nil,
        asr: AsrRule = .standard,
        highLatitudeRule: HighLatitudeRule = .angle,
        manualAngles: TwilightAngles = TwilightAngles(),
        adjustments: MinuteAdjustments = MinuteAdjustments(),
        madhab: Madhab = .standard
    ) {
        self.method = method
        self.asr = asr
        self.highLatitudeRule = highLatitudeRule
        self.manualAngles = manualAngles
        self.adjustments = adjustments
        self.madhab = madhab
    }

    /// Einstellungen, die vor Phase 12 gespeichert wurden, haben noch keine eigenen Winkel, solche vor dem
    /// Nachtrag zu Phase 18 keine Rechtsschule: Dann gelten die Startwerte.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        method = try container.decodeIfPresent(CalculationMethod.self, forKey: .method)
        asr = try container.decode(AsrRule.self, forKey: .asr)
        highLatitudeRule = try container.decode(HighLatitudeRule.self, forKey: .highLatitudeRule)
        manualAngles = try container.decodeIfPresent(TwilightAngles.self, forKey: .manualAngles) ?? TwilightAngles()
        adjustments = try container.decode(MinuteAdjustments.self, forKey: .adjustments)
        madhab = (try? container.decodeIfPresent(Madhab.self, forKey: .madhab)) ?? .standard
    }

    private enum CodingKeys: String, CodingKey {
        case method, asr, highLatitudeRule, manualAngles, adjustments, madhab
    }

    /// Die Methode, mit der für `place` gerechnet wird: die gewählte, sonst die automatische des Landes
    /// (`methodObj()` im Prototyp).
    public func effectiveMethod(for place: Place) -> CalculationMethod {
        method ?? .automatic(forCountryCode: place.countryCode)
    }
}
