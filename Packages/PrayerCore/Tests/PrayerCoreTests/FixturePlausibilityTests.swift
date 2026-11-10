#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Mock-Zeiten des Prototyps sind keine Referenz für die Berechnung – sie sind „plausible,
/// internally consistent“ (Kommentar im Prototyp). Hier steht nur, wie weit die echte Rechnung von ihnen
/// entfernt liegt: höchstens 5 Minuten, mit einer benannten Ausnahme.
///
/// Verglichen wird mit der Methode, die der Prototyp für die Stadt nennt (`auto`). Für Berlin ist das
/// MWL; die App rechnet in Deutschland ohne eigene Wahl mit Diyanet (Entscheidung vom 10.11.2026).
@Suite("Mock-Zeiten gegen die echte Rechnung")
struct FixturePlausibilityTests {

    private let real = AdhanTimesSource()
    private let mock = FixtureTimesSource()
    private let summerMock = FixtureTimesSource(highLatitude: true)

    /// Erlaubte Abweichung in Minuten.
    private let tolerance = 5.0

    /// Bekannte Ausnahme: Berlin, Maghrib mit MWL. Gerechnet 16:21, im Mock 16:27. Die Berliner
    /// Mock-Zeiten passen eher zum 6./7. November als zum 10. (docs/OPEN-QUESTIONS.md).
    private func tolerance(city: String, prayer: Prayer) -> Double {
        city == "berlin" && prayer == .maghrib ? 6 : tolerance
    }

    /// Größte Abweichung in Minuten zwischen Rechnung und Mock, je Ereignis.
    private func differences(_ computed: DayTimes, _ expected: DayTimes) -> [Prayer: Double] {
        Dictionary(uniqueKeysWithValues: Prayer.allCases.map {
            ($0, computed[$0].timeIntervalSince(expected[$0]) / 60)
        })
    }

    @Test("am 10.11.2026 liegt jede Zeit höchstens 5 Minuten neben dem Mock", arguments: FixtureTimes.cities.map(\.id))
    func cities(id: String) throws {
        let city = try #require(FixtureTimes.city(id))
        let place = city.place(named: id)
        let day = FixtureTimes.referenceDay
        let method = try #require(CalculationMethod(rawValue: city.automaticMethodID))

        for asr in AsrRule.allCases {
            let settings = CalculationSettings(method: method, asr: asr)
            let computed = try #require(real.times(on: day, at: place, settings: settings))
            let expected = try #require(mock.times(on: day, at: place, settings: settings))
            for (prayer, difference) in differences(computed, expected) {
                #expect(
                    abs(difference) <= tolerance(city: id, prayer: prayer),
                    "\(id) \(prayer) (\(asr)): gerechnet \(computed.clockTime(of: prayer)), Mock \(expected.clockTime(of: prayer))"
                )
            }
        }
    }

    @Test("die Ausnahme Berlin-Maghrib mit MWL ist genau 6 Minuten groß")
    func berlinMaghrib() throws {
        let day = FixtureTimes.referenceDay
        let settings = CalculationSettings(method: .mwl)
        let computed = try #require(real.times(on: day, at: .berlin, settings: settings))
        let expected = try #require(mock.times(on: day, at: .berlin, settings: settings))
        #expect(computed.clockTime(of: .maghrib) == clockTime("16:21"))
        #expect(expected.clockTime(of: .maghrib) == clockTime("16:27"))
    }

    @Test("Berlin mit der Automatik der App (Diyanet): jede Zeit höchstens 5 Minuten neben dem Mock, ohne Ausnahme")
    func berlinAutomatic() throws {
        let day = FixtureTimes.referenceDay
        for asr in AsrRule.allCases {
            let settings = CalculationSettings(asr: asr)
            #expect(settings.effectiveMethod(for: .berlin) == .diyanet)
            let computed = try #require(real.times(on: day, at: .berlin, settings: settings))
            let expected = try #require(mock.times(on: day, at: .berlin, settings: settings))
            for (prayer, difference) in differences(computed, expected) {
                #expect(
                    abs(difference) <= tolerance,
                    "\(prayer) (\(asr)): gerechnet \(computed.clockTime(of: prayer)), Mock \(expected.clockTime(of: prayer))"
                )
            }
        }
    }

    @Test("Berlin am 21.06.2027 mit MWL: jede Regel für hohe Breiten liegt höchstens 5 Minuten neben dem Mock", arguments: HighLatitudeRule.allCases)
    func berlinSummer(rule: HighLatitudeRule) throws {
        let day = FixtureTimes.berlinSummer.day
        for asr in AsrRule.allCases {
            let settings = CalculationSettings(method: .mwl, asr: asr, highLatitudeRule: rule)
            let computed = try #require(real.times(on: day, at: .berlin, settings: settings))
            let expected = try #require(summerMock.times(on: day, at: .berlin, settings: settings))
            for (prayer, difference) in differences(computed, expected) {
                #expect(
                    abs(difference) <= tolerance,
                    "\(rule) \(prayer) (\(asr)): gerechnet \(computed.clockTime(of: prayer)), Mock \(expected.clockTime(of: prayer))"
                )
            }
        }
    }

    @Test("Berlin am 21.06.2027 mit MWL: Fadschr und Ischa treffen den Mock fast auf die Minute", arguments: [
        (HighLatitudeRule.angle, "02:34", "23:35"),
        (.seventh, "03:42", "22:35"),
        (.middle, "01:08", "01:08"),
    ])
    func berlinSummerRules(rule: HighLatitudeRule, fajr: String, isha: String) throws {
        let day = FixtureTimes.berlinSummer.day
        let settings = CalculationSettings(method: .mwl, highLatitudeRule: rule)
        let computed = try #require(real.times(on: day, at: .berlin, settings: settings))
        #expect(computed.clockTime(of: .fajr) == clockTime(fajr))
        #expect(computed.clockTime(of: .isha) == clockTime(isha))
    }
}

#endif
