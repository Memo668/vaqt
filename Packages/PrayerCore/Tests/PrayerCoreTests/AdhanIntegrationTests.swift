import Adhan
import Foundation
import Testing
@testable import PrayerCore

// Diese Datei sieht beide Module. Gleichnamige Typen (`CalculationMethod`, `Coordinates`, `Prayer`,
// `HighLatitudeRule`) brauchen deshalb den Modulnamen davor. Für die Methoden gibt es zwei Kurznamen,
// weil `#require` und `#expect` mit einem Modulnamen im Ausdruck nicht umgehen können.
typealias CoreMethod = PrayerCore.CalculationMethod
typealias AdhanMethod = Adhan.CalculationMethod

/// Adhan Swift ist eingebunden und rechnet.
@Suite("Adhan Swift ist eingebunden")
struct AdhanIntegrationTests {

    @Test("liefert für Mekka sechs Zeiten in aufsteigender Reihenfolge")
    func makkah() throws {
        let coordinates = Adhan.Coordinates(latitude: 21.4225, longitude: 39.8262)
        let day = DateComponents(year: 2026, month: 11, day: 10)
        let parameters = AdhanMethod.ummAlQura.params

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
            PrayerTimes(coordinates: coordinates, date: day, calculationParameters: AdhanMethod.ummAlQura.params)
        )
        #expect(times.isha.timeIntervalSince(times.maghrib) == 90 * 60)
    }
}

/// Wie `AdhanTimesSource` Methode und Einstellungen in die Parameter von Adhan Swift übersetzt.
@Suite("AdhanTimesSource – Parameter")
struct AdhanParametersTests {

    /// Die Parameter mit den Standard-Einstellungen der App: Asr Standard, hohe Breiten winkelbasiert.
    private func parameters(for method: CoreMethod) -> CalculationParameters {
        AdhanTimesSource.parameters(for: method, settings: CalculationSettings())
    }

    @Test("neun Methoden nutzen die Voreinstellung von Adhan Swift, samt deren Minuten", arguments: [
        ("mwl", "muslimWorldLeague"),
        ("isna", "northAmerica"),
        ("egyptian", "egyptian"),
        ("ummalqura", "ummAlQura"),
        ("karachi", "karachi"),
        ("diyanet", "turkey"),
        ("singapore", "singapore"),
        ("tehran", "tehran"),
        ("moonsighting", "moonsightingCommittee"),
    ])
    func presets(id: String, adhanID: String) throws {
        let method = try #require(CoreMethod(rawValue: id))
        let preset = try #require(AdhanMethod(rawValue: adhanID))

        // Asr-Regel und Regel für hohe Breiten setzt die App immer selbst; alles andere bleibt die Voreinstellung.
        var expected = preset.params
        expected.madhab = .shafi
        expected.highLatitudeRule = .twilightAngle
        #expect(parameters(for: method) == expected)
        #expect(parameters(for: method).method == preset)
    }

    @Test("JAKIM und Kemenag rechnen mit reinen Winkeln 20°/18°", arguments: ["jakim", "kemenag"])
    func customAngles(id: String) throws {
        let method = try #require(CoreMethod(rawValue: id))

        var expected = AdhanMethod.other.params
        expected.fajrAngle = 20
        expected.ishaAngle = 18
        expected.madhab = .shafi
        expected.highLatitudeRule = .twilightAngle
        #expect(parameters(for: method) == expected)
        #expect(parameters(for: method).ishaInterval == 0)
        #expect(parameters(for: method).rounding == .nearest)
    }

    @Test("die Winkel jeder Methode sind die aus METHODS", arguments: CoreMethod.allCases)
    func angles(method: CoreMethod) {
        let parameters = parameters(for: method)
        #expect(parameters.fajrAngle == method.fajrAngle)
        switch method.isha {
        case .angle(let angle):
            #expect(parameters.ishaAngle == angle)
            #expect(parameters.ishaInterval == 0)
        case .minutesAfterMaghrib(let minutes):
            #expect(parameters.ishaInterval == minutes)
        }
    }

    @Test("Besonderheiten der Voreinstellungen bleiben erhalten")
    func presetDetails() {
        #expect(parameters(for: .tehran).maghribAngle == 4.5)
        #expect(parameters(for: .singapore).rounding == .up)
        #expect(parameters(for: .mwl).rounding == .nearest)
        #expect(parameters(for: .mwl).maghribAngle == nil)
    }

    @Test("Asr Standard rechnet schafiitisch, Hanafi hanafitisch")
    func asr() {
        #expect(AdhanTimesSource.parameters(for: .mwl, settings: CalculationSettings(asr: .standard)).madhab == .shafi)
        #expect(AdhanTimesSource.parameters(for: .mwl, settings: CalculationSettings(asr: .hanafi)).madhab == .hanafi)
    }

    @Test("die Regel für hohe Breiten wird immer gesetzt, nie die Empfehlung von Adhan Swift")
    func highLatitude() {
        func rule(_ rule: PrayerCore.HighLatitudeRule) -> Adhan.HighLatitudeRule? {
            AdhanTimesSource.parameters(for: .mwl, settings: CalculationSettings(highLatitudeRule: rule)).highLatitudeRule
        }
        #expect(rule(.angle) == .twilightAngle)
        #expect(rule(.seventh) == .seventhOfTheNight)
        #expect(rule(.middle) == .middleOfTheNight)
    }

    @Test("die Minutenkorrekturen landen beim richtigen Ereignis")
    func adjustments() {
        let settings = CalculationSettings(
            adjustments: MinuteAdjustments([.fajr: 1, .sunrise: -2, .dhuhr: 3, .asr: -4, .maghrib: 5, .isha: -6])
        )
        let parameters = AdhanTimesSource.parameters(for: .diyanet, settings: settings)
        #expect(parameters.adjustments == PrayerAdjustments(fajr: 1, sunrise: -2, dhuhr: 3, asr: -4, maghrib: 5, isha: -6))
        #expect(self.parameters(for: .diyanet).adjustments == PrayerAdjustments())
    }
}
