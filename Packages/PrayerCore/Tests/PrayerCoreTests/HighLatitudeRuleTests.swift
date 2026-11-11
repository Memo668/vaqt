import Foundation
import Testing
@testable import PrayerCore

/// Wann Fadschr und Ischa als geschätzt gelten: `PrayerTimesSource.usesHighLatitudeRule`.
@Suite("Regel für hohe Breiten greift")
struct HighLatitudeRuleTests {

    private let source = AdhanTimesSource()
    private let summer = calendarDay("2027-06-21")
    private let autumn = calendarDay("2026-11-10")
    private let mwl = CalculationSettings(method: .mwl)

    private func place(_ name: String, country: String?, latitude: Double, longitude: Double, zone: String) -> Place {
        Place(
            name: name, countryCode: country,
            coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
        )
    }

    private var mecca: Place { place("Mekka", country: "SA", latitude: 21.4225, longitude: 39.8262, zone: "Asia/Riyadh") }
    private var jakarta: Place { place("Jakarta", country: "ID", latitude: -6.2088, longitude: 106.8456, zone: "Asia/Jakarta") }
    private var tromso: Place { place("Tromsø", country: "NO", latitude: 69.6492, longitude: 18.9553, zone: "Europe/Oslo") }

    private func uses(
        _ rule: HighLatitudeRule, on day: CalendarDay, at place: Place = .berlin, method: CalculationMethod? = .mwl,
        adjustments: MinuteAdjustments = MinuteAdjustments()
    ) -> Bool {
        let settings = CalculationSettings(method: method, highLatitudeRule: rule, adjustments: adjustments)
        return source.usesHighLatitudeRule(on: day, at: place, settings: settings)
    }

    // MARK: - Berlin

    @Test("Berlin am 21. Juni: Die Sonne erreicht den Winkel nicht, jede Regel greift", arguments: HighLatitudeRule.allCases)
    func berlinSummer(rule: HighLatitudeRule) {
        #expect(uses(rule, on: summer))
    }

    @Test("Berlin am 10. November: Winkelbasiert und Nachtmitte greifen nicht", arguments: [HighLatitudeRule.angle, .middle])
    func berlinAutumn(rule: HighLatitudeRule) {
        #expect(!uses(rule, on: autumn))
    }

    @Test("Berlin im Sommer mit der Automatik für Deutschland (Diyanet)")
    func berlinAutomatic() {
        #expect(uses(.angle, on: summer, method: nil))
        #expect(!uses(.angle, on: autumn, method: nil))
    }

    @Test("mit „Nachtmitte“ fallen Ischa und das Fadschr des Folgetags zusammen, wenn die Regel greift")
    func middleMeets() throws {
        let settings = CalculationSettings(method: .mwl, highLatitudeRule: .middle)
        let today = try #require(source.times(on: summer, at: .berlin, settings: settings))
        let tomorrow = try #require(source.times(on: summer.adding(days: 1), at: .berlin, settings: settings))
        #expect(abs(tomorrow.fajr.timeIntervalSince(today.isha)) <= minutes(2))
    }

    @Test("das Siebtel der Nacht greift schon, wenn die Dämmerung länger dauert als ein Siebtel der Nacht")
    func seventhInSpring() {
        // Am 20. April wird es in Berlin noch ganz dunkel; die Dämmerung dauert aber über zwei Stunden,
        // ein Siebtel der Nacht nur gut eine.
        let day = calendarDay("2027-04-20")
        #expect(uses(.seventh, on: day))
        #expect(!uses(.middle, on: day))
    }

    @Test("die Minutenkorrekturen ändern nichts daran, ob die Zeiten geschätzt sind", arguments: HighLatitudeRule.allCases)
    func adjustmentsDoNotMatter(rule: HighLatitudeRule) {
        var adjustments = MinuteAdjustments()
        adjustments[.fajr] = 25
        adjustments[.isha] = -25
        #expect(uses(rule, on: summer, adjustments: adjustments))
        #expect(uses(rule, on: autumn, adjustments: adjustments) == uses(rule, on: autumn))
    }

    // MARK: - Andere Orte und Methoden

    @Test("in Mekka und Jakarta greift die Regel auch im Sommer nicht", arguments: HighLatitudeRule.allCases)
    func lowLatitudes(rule: HighLatitudeRule) {
        #expect(!uses(rule, on: summer, at: mecca, method: nil))
        #expect(!uses(rule, on: summer, at: jakarta, method: nil))
    }

    @Test("Umm al-Qura: Ischa hängt an Maghrib, Fadschr kommt in Berlin im Sommer trotzdem aus der Regel")
    func ummAlQura() {
        #expect(uses(.angle, on: summer, method: .ummAlQura))
        #expect(!uses(.angle, on: autumn, method: .ummAlQura))
    }

    @Test("Moonsighting übergeht die Regel", arguments: HighLatitudeRule.allCases)
    func moonsighting(rule: HighLatitudeRule) {
        #expect(!uses(rule, on: summer, method: .moonsighting))
    }

    @Test("ohne Zeiten gibt es auch keine geschätzten: Tromsø in der Mitternachtssonne")
    func noTimes() {
        #expect(source.times(on: summer, at: tromso, settings: mwl) == nil)
        #expect(!uses(.angle, on: summer, at: tromso))
        #expect(!uses(.middle, on: summer, at: tromso))
    }

    // MARK: - Andere Quellen

    @Test("eine Quelle ohne eigene Auskunft meldet: greift nicht")
    func defaultAnswer() {
        struct Plain: PrayerTimesSource {
            func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? { nil }
        }
        #expect(!Plain().usesHighLatitudeRule(on: summer, at: .berlin, settings: mwl))
    }

    #if DEBUG

    @Test("die Mock-Quelle folgt dem Schalter -debugHighLatitude")
    func fixture() {
        #expect(FixtureTimesSource(highLatitude: true).usesHighLatitudeRule(on: autumn, at: .berlin, settings: mwl))
        #expect(!FixtureTimesSource().usesHighLatitudeRule(on: summer, at: .berlin, settings: mwl))
    }

    #endif
}
