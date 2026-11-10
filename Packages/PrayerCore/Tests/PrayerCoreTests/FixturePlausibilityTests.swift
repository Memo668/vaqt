#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Mock-Zeiten des Prototyps sind keine Referenz für die Berechnung – sie sind „plausible,
/// internally consistent“ (Kommentar im Prototyp). Hier steht nur, wie weit die echte Rechnung von ihnen
/// entfernt liegt: höchstens 5 Minuten, mit einer benannten Ausnahme.
@Suite("Mock-Zeiten gegen die echte Rechnung")
struct FixturePlausibilityTests {

    private let real = AdhanTimesSource()
    private let mock = FixtureTimesSource()
    private let summerMock = FixtureTimesSource(highLatitude: true)

    /// Erlaubte Abweichung in Minuten.
    private let tolerance = 5.0

    /// Bekannte Ausnahme: Berlin, Maghrib. Gerechnet 16:21, im Mock 16:27. Die Berliner Mock-Zeiten
    /// passen eher zum 6./7. November als zum 10. (docs/OPEN-QUESTIONS.md).
    private func tolerance(city: String, prayer: Prayer) -> Double {
        city == "berlin" && prayer == .maghrib ? 6 : tolerance
    }

    @Test("am 10.11.2026 liegt jede Zeit höchstens 5 Minuten neben dem Mock", arguments: FixtureTimes.cities.map(\.id))
    func cities(id: String) throws {
        let city = try #require(FixtureTimes.city(id))
        let place = city.place(named: id)
        let day = FixtureTimes.referenceDay

        for asr in AsrRule.allCases {
            let settings = CalculationSettings(asr: asr)
            #expect(settings.effectiveMethod(for: place).rawValue == city.automaticMethodID)
            let computed = try #require(real.times(on: day, at: place, settings: settings))
            let expected = try #require(mock.times(on: day, at: place, settings: settings))
            for prayer in Prayer.allCases {
                let difference = computed[prayer].timeIntervalSince(expected[prayer]) / 60
                #expect(
                    abs(difference) <= tolerance(city: id, prayer: prayer),
                    "\(id) \(prayer) (\(asr)): gerechnet \(computed.clockTime(of: prayer)), Mock \(expected.clockTime(of: prayer))"
                )
            }
        }
    }

    @Test("die Ausnahme Berlin-Maghrib ist genau 6 Minuten groß")
    func berlinMaghrib() throws {
        let day = FixtureTimes.referenceDay
        let computed = try #require(real.times(on: day, at: .berlin, settings: CalculationSettings()))
        let expected = try #require(mock.times(on: day, at: .berlin, settings: CalculationSettings()))
        #expect(computed.clockTime(of: .maghrib) == clockTime("16:21"))
        #expect(expected.clockTime(of: .maghrib) == clockTime("16:27"))
    }

    @Test("Berlin am 21.06.2027: jede Regel für hohe Breiten liegt höchstens 5 Minuten neben dem Mock", arguments: HighLatitudeRule.allCases)
    func berlinSummer(rule: HighLatitudeRule) throws {
        let day = FixtureTimes.berlinSummer.day
        for asr in AsrRule.allCases {
            let settings = CalculationSettings(asr: asr, highLatitudeRule: rule)
            let computed = try #require(real.times(on: day, at: .berlin, settings: settings))
            let expected = try #require(summerMock.times(on: day, at: .berlin, settings: settings))
            for prayer in Prayer.allCases {
                let difference = computed[prayer].timeIntervalSince(expected[prayer]) / 60
                #expect(
                    abs(difference) <= tolerance,
                    "\(rule) \(prayer) (\(asr)): gerechnet \(computed.clockTime(of: prayer)), Mock \(expected.clockTime(of: prayer))"
                )
            }
        }
    }

    @Test("Berlin am 21.06.2027: Fadschr und Ischa treffen den Mock fast auf die Minute", arguments: [
        (HighLatitudeRule.angle, "02:34", "23:35"),
        (.seventh, "03:42", "22:35"),
        (.middle, "01:08", "01:08"),
    ])
    func berlinSummerRules(rule: HighLatitudeRule, fajr: String, isha: String) throws {
        let day = FixtureTimes.berlinSummer.day
        let computed = try #require(real.times(on: day, at: .berlin, settings: CalculationSettings(highLatitudeRule: rule)))
        #expect(computed.clockTime(of: .fajr) == clockTime(fajr))
        #expect(computed.clockTime(of: .isha) == clockTime(isha))
    }
}

#endif
