import Foundation
import Testing
@testable import PrayerCore

/// Hohe Breiten, Regel „Manuelle Winkel“ (Spec § 9.12; entschieden am 15.11.2026: „Nur in hellen Nächten“).
@Suite("Manuelle Winkel")
struct ManualAnglesTests {

    private let source = AdhanTimesSource()
    private let summer = calendarDay("2026-06-21")
    private let winter = calendarDay("2026-11-10")

    private func settings(
        _ method: CalculationMethod = .mwl, rule: HighLatitudeRule = .manual, fajr: Int = 15, isha: Int = 15
    ) -> CalculationSettings {
        CalculationSettings(method: method, highLatitudeRule: rule, manualAngles: TwilightAngles(fajr: fajr, isha: isha))
    }

    private func times(on day: CalendarDay, at place: Place = .berlin, _ settings: CalculationSettings) throws -> DayTimes {
        try #require(source.times(on: day, at: place, settings: settings))
    }

    // MARK: - TwilightAngles

    @Test("Winkel: Start 15°, Stepper von 10 bis 20°, nur für Fadschr und Ischa")
    func angles() {
        var angles = TwilightAngles()
        #expect(angles.fajr == 15 && angles.isha == 15)
        #expect(TwilightAngles(fajr: 4, isha: 31) == TwilightAngles(fajr: 10, isha: 20))
        angles.step(.fajr, by: -5)
        #expect(angles.fajr == 10)
        #expect(!angles.canStep(.fajr, by: -1))
        #expect(angles.canStep(.isha, by: 5))
        angles.step(.isha, by: 6)
        #expect(angles.isha == 20)
        angles.step(.dhuhr, by: 1)
        #expect(angles == TwilightAngles(fajr: 10, isha: 20))
        #expect(angles[.asr] == nil)
        #expect(!angles.canStep(.asr, by: 1))
    }

    @Test("Gespeicherte Einstellungen von vor Phase 12 lesen sich mit den Startwinkeln")
    func decodesOldSettings() throws {
        let encoded = try JSONEncoder().encode(CalculationSettings(asr: .hanafi, highLatitudeRule: .seventh))
        var json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "manualAngles")
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(CalculationSettings.self, from: data)
        #expect(decoded.asr == .hanafi)
        #expect(decoded.highLatitudeRule == .seventh)
        #expect(decoded.manualAngles == TwilightAngles())

        let manual = settings(fajr: 12, isha: 18)
        #expect(try JSONDecoder().decode(CalculationSettings.self, from: JSONEncoder().encode(manual)) == manual)
    }

    // MARK: - Rechnung

    @Test("Winter in Berlin: Die Sonne erreicht 18°/17°, die eigenen Winkel ändern nichts")
    func winterUnchanged() throws {
        let byAngle = try times(on: winter, settings(rule: .angle))
        for (fajr, isha) in [(10, 10), (15, 15), (20, 20)] {
            #expect(try times(on: winter, settings(fajr: fajr, isha: isha)) == byAngle)
        }
        #expect(!source.usesHighLatitudeRule(on: winter, at: .berlin, settings: settings()))
    }

    @Test("Sommer in Berlin: 15° erreicht die Sonne nicht – es gilt ein Viertel der Nacht (15 ÷ 60)")
    func summerNightPortion() throws {
        let manual = try times(on: summer, settings())
        let byAngle = try times(on: summer, settings(rule: .angle))
        let night = manual.sunrise.timeIntervalSince(manual.maghrib) + 24 * 3600
        // Die Nacht von Maghrib bis zum Sonnenaufgang des Folgetags rechnet Adhan selbst; auf zwei Minuten.
        #expect(abs(manual.sunrise.timeIntervalSince(manual.fajr) - night * 15 / 60) < 120)
        #expect(abs(manual.isha.timeIntervalSince(manual.maghrib) - night * 15 / 60) < 120)
        // Weniger Nachtanteil als bei 18°/17°: Fadschr später, Ischa früher.
        #expect(manual.fajr > byAngle.fajr)
        #expect(manual.isha < byAngle.isha)
        for prayer in [Prayer.sunrise, .dhuhr, .asr, .maghrib] {
            #expect(manual[prayer] == byAngle[prayer])
        }
        #expect(source.usesHighLatitudeRule(on: summer, at: .berlin, settings: settings()))
    }

    @Test("Sommer in Berlin: 12° erreicht die Sonne (tiefster Stand etwa 14°) – die Zeit aus dem Winkel, mit 12 ÷ 60 als Grenze")
    func summerReachedAngle() throws {
        let twelve = try times(on: summer, settings(fajr: 12, isha: 12))
        let fifteen = try times(on: summer, settings())
        let night = twelve.sunrise.timeIntervalSince(twelve.maghrib) + 24 * 3600
        // Kleinerer Winkel, kürzere Dämmerung.
        #expect(twelve.fajr > fifteen.fajr)
        #expect(twelve.isha < fifteen.isha)
        // Nie früher als die Grenze.
        #expect(twelve.sunrise.timeIntervalSince(twelve.fajr) <= night * 12 / 60 + 60)
        #expect(twelve.isha.timeIntervalSince(twelve.maghrib) <= night * 12 / 60 + 60)
    }

    @Test("Fadschr und Ischa eigens: Die Winkel wirken je Zeit")
    func separateAngles() throws {
        let both = try times(on: summer, settings(fajr: 15, isha: 15))
        let laterFajr = try times(on: summer, settings(fajr: 10, isha: 15))
        #expect(laterFajr.fajr > both.fajr)
        #expect(laterFajr.isha == both.isha)
    }

    @Test("Minutenkorrekturen gelten auch mit eigenen Winkeln")
    func adjustments() throws {
        var adjusted = settings()
        adjusted.adjustments[.fajr] = 5
        let base = try times(on: summer, settings())
        #expect(try times(on: summer, adjusted).fajr.timeIntervalSince(base.fajr) == 5 * 60)
    }

    @Test("Moonsighting übergeht die Regel, auch die eigenen Winkel")
    func moonsighting() throws {
        let manual = try times(on: summer, settings(.moonsighting))
        #expect(manual == (try times(on: summer, settings(.moonsighting, rule: .angle))))
        #expect(!source.usesHighLatitudeRule(on: summer, at: .berlin, settings: settings(.moonsighting)))
    }

    @Test("Umm al-Qura: Ischa bleibt 90 Minuten nach Maghrib, die Regel greift dort nicht")
    func ishaInterval() throws {
        let manual = try times(on: summer, settings(.ummAlQura))
        #expect(manual.isha.timeIntervalSince(manual.maghrib) == 90 * 60)
    }

    // MARK: - Mock-Zeiten

    @Test("Mock-Zeiten mit -debugHighLatitude: Fadschr und Ischa wie `manualHL()` im Prototyp", arguments: [
        (10, 10, "03:31", "22:45"),
        (12, 18, "03:17", "23:42"),
        (15, 15, "02:56", "23:21"),
        (16, 14, "02:48", "23:13"),
        (20, 20, "02:20", "23:56"),
    ])
    func fixtureManual(fajr: Int, isha: Int, expectedFajr: String, expectedIsha: String) throws {
        let source = FixtureTimesSource(highLatitude: true)
        let day = FixtureTimes.berlinSummer.day
        let times = try #require(source.times(on: day, at: fixturePlace("berlin"), settings: settings(fajr: fajr, isha: isha)))
        #expect(times.clockTime(of: .fajr) == clockTime(expectedFajr))
        #expect(times.clockTime(of: .isha) == clockTime(expectedIsha))
        #expect(times.clockTime(of: .sunrise) == clockTime("04:43"))
        #expect(times.clockTime(of: .maghrib) == clockTime("21:33"))
    }

    @Test("Mock-Zeiten ohne -debugHighLatitude: Die Regel ändert nichts, wie im Prototyp")
    func fixtureWithoutHighLatitude() throws {
        let source = FixtureTimesSource()
        let place = fixturePlace("berlin")
        let plain = try #require(source.times(on: winter, at: place, settings: CalculationSettings()))
        #expect(source.times(on: winter, at: place, settings: settings()) == plain)
    }
}
