/// Quelle für die Zeiten eines Tages.
///
/// Die App rechnet echt (`AdhanTimesSource`). Mit `-debugFixtureTimes` liefert stattdessen
/// `FixtureTimesSource` die Mock-Zeiten des Prototyps, damit die Zahlen zu den Referenz-Screenshots passen.
public protocol PrayerTimesSource: Sendable {

    /// Zeiten des Kalendertags `day` am Ort `place`, Minutenkorrekturen eingerechnet.
    ///
    /// `nil`, wenn sich für den Tag keine Zeiten bestimmen lassen – etwa dort, wo die Sonne an dem Tag
    /// nicht auf- oder untergeht.
    func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes?

    /// Ob Fadschr oder Ischa des Tages aus der Regel für hohe Breiten kommen statt aus dem
    /// Dämmerungswinkel – dann sind sie geschätzt. Die Zeiten-Seite zeigt in dem Fall die Info-Marken an
    /// Fadschr und Ischa und den Hinweis mit der Regel (Design Spec § 5, „High latitude“).
    ///
    /// Der Prototyp hat dafür nur einen Schalter (`S.highLat`).
    func usesHighLatitudeRule(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> Bool

    /// Die Methode, die für `place` gilt, solange keine gewählt ist – „Automatisch · Diyanet“ in den
    /// Einstellungen (`CITIES[…].auto` im Prototyp).
    func automaticMethod(for place: Place) -> CalculationMethod
}

extension PrayerTimesSource {

    /// Ohne eigene Auskunft greift die Regel nicht.
    public func usesHighLatitudeRule(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> Bool {
        false
    }

    /// Ohne eigene Auskunft die Methode des Landes (`CalculationMethod.automatic(forCountryCode:)`).
    public func automaticMethod(for place: Place) -> CalculationMethod {
        .automatic(forCountryCode: place.countryCode)
    }
}
