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
}
