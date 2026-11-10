import Adhan
import Foundation
import Testing

/// Phase 0 prüft nur, dass Adhan Swift eingebunden ist und rechnet.
/// Die eigentliche Berechnung samt Referenzwerten kommt in Phase 1.
@Suite("Adhan Swift ist eingebunden")
struct AdhanIntegrationTests {

    @Test("liefert für Mekka sechs Zeiten in aufsteigender Reihenfolge")
    func makkah() throws {
        let coordinates = Adhan.Coordinates(latitude: 21.4225, longitude: 39.8262)
        let day = DateComponents(year: 2026, month: 11, day: 10)
        let parameters = CalculationMethod.ummAlQura.params

        let times = try #require(PrayerTimes(coordinates: coordinates, date: day, calculationParameters: parameters))
        let ordered = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.maghrib, times.isha]

        #expect(ordered == ordered.sorted())
        #expect(Set(ordered).count == 6)
    }

    @Test("Umm al-Qura legt Ischa 90 Minuten nach Maghrib")
    func ummAlQuraInterval() throws {
        let coordinates = Adhan.Coordinates(latitude: 21.4225, longitude: 39.8262)
        let day = DateComponents(year: 2026, month: 11, day: 10)
        let times = try #require(
            PrayerTimes(coordinates: coordinates, date: day, calculationParameters: CalculationMethod.ummAlQura.params)
        )
        #expect(times.isha.timeIntervalSince(times.maghrib) == 90 * 60)
    }
}
