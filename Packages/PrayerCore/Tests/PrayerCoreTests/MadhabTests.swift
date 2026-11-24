#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Verbotszeiten nach Rechtsschule (Nachtrag zu Phase 18, Spec § 11.6) – `KERAHAT_MIN_BY`, `MADHABS` und
/// `kerahatWins()` im Prototyp. Gerechnet wird mit den Mock-Zeiten für Berlin: Sonnenaufgang 07:14,
/// Dhuhr 11:52, Maghrib 16:27. Der 10.11.2026 ist ein Dienstag, der 13.11.2026 ein Freitag.
@Suite("Verbotszeiten nach Rechtsschule")
struct MadhabTests {

    private let tuesday = FixtureTimes.referenceDay
    private let friday = CalendarDay(year: 2026, month: 11, day: 13)!

    private func times(_ madhab: Madhab, on day: CalendarDay? = nil) -> DayTimes {
        fixtureTimeline(on: day ?? tuesday, settings: CalculationSettings(madhab: madhab)).today
    }

    private func spans(_ madhab: Madhab, on day: CalendarDay? = nil) -> [String] {
        Kerahat.windows(for: times(madhab, on: day)).map {
            "\($0.id.rawValue) \(ClockTime($0.start, in: .berlin))–\(ClockTime($0.end, in: .berlin))"
        }
    }

    @Test("die Kennungen und die Reihenfolge sind die des Prototyps, Hanafi ist Standard")
    func identifiers() {
        #expect(Madhab.allCases.map(\.rawValue) == ["hanafi", "maliki", "shafii", "hanbali"])
        #expect(Madhab.standard == .hanafi)
        #expect(CalculationSettings().madhab == .hanafi)
    }

    @Test("die Dauer je Schule, wie am 24.11.2026 entschieden", arguments: [
        (Madhab.hanafi, 45, 10, 45),
        (.shafii, 25, 10, 25),
        (.hanbali, 20, 10, 20),
        (.maliki, 20, nil, 20),
    ] as [(Madhab, Int, Int?, Int)])
    func durations(madhab: Madhab, sunrise: Int, zenith: Int?, sunset: Int) {
        let minutes = Kerahat.durations(for: madhab)
        #expect(minutes.afterSunrise == sunrise)
        #expect(minutes.beforeDhuhr == zenith)
        #expect(minutes.beforeMaghrib == sunset)
    }

    @Test("Hanafi bleibt wie bisher: drei Fenster, 45 / 10 / 45")
    func hanafi() {
        #expect(spans(.hanafi) == ["sunrise 07:14–07:59", "zenith 11:42–11:52", "sunset 15:42–16:27"])
        #expect(spans(.hanafi, on: friday) == spans(.hanafi))
    }

    @Test("Maliki: kein Fenster vor Dhuhr, 20 Minuten nach Sonnenaufgang und vor Maghrib")
    func maliki() {
        #expect(spans(.maliki) == ["sunrise 07:14–07:34", "sunset 16:07–16:27"])
        #expect(Kerahat.windows(for: times(.maliki)).map(\.row) == [.sunrise, .asr])
    }

    @Test("Schafii: 25 / 10 / 25, freitags ohne das Fenster vor Dhuhr")
    func shafii() {
        #expect(spans(.shafii) == ["sunrise 07:14–07:39", "zenith 11:42–11:52", "sunset 16:02–16:27"])
        #expect(spans(.shafii, on: friday) == ["sunrise 07:14–07:39", "sunset 16:02–16:27"])
    }

    @Test("Hanbali: drei Fenster, 20 / 10 / 20, auch freitags")
    func hanbali() {
        #expect(spans(.hanbali) == ["sunrise 07:14–07:34", "zenith 11:42–11:52", "sunset 16:07–16:27"])
        #expect(spans(.hanbali, on: friday) == spans(.hanbali))
    }

    @Test("Freitag hängt am Kalendertag der Zeiten", arguments: [
        ("2026-11-10", false), ("2026-11-13", true), ("2026-11-14", false), ("2027-01-01", true), ("2026-12-25", true),
    ])
    func friday(day: String, isFriday: Bool) throws {
        let times = fixtureTimeline(on: try #require(CalendarDay(day))).today
        #expect(times.isFriday == isFriday)
    }

    @Test("ein Fenster vor Dhuhr gibt es nicht bei Maliki und bei Schafii am Freitag")
    func zenithRule() {
        #expect(Kerahat.hasZenithWindow(.hanafi, onFriday: true))
        #expect(Kerahat.hasZenithWindow(.hanbali, onFriday: true))
        #expect(!Kerahat.hasZenithWindow(.maliki, onFriday: false))
        #expect(Kerahat.hasZenithWindow(.shafii, onFriday: false))
        #expect(!Kerahat.hasZenithWindow(.shafii, onFriday: true))
    }

    @Test("das laufende Fenster folgt der Schule", arguments: [
        (Madhab.hanafi, "07:45", "sunrise"),
        (.maliki, "07:45", nil),
        (.shafii, "07:45", nil),
        (.hanafi, "11:45", "zenith"),
        (.maliki, "11:45", nil),
        (.hanbali, "11:45", "zenith"),
        (.hanafi, "16:00", "sunset"),
        (.shafii, "16:00", nil),
        (.shafii, "16:05", "sunset"),
        (.maliki, "16:10", "sunset"),
    ] as [(Madhab, String, String?)])
    func active(madhab: Madhab, time: String, expected: String?) throws {
        let timeline = fixtureTimeline(settings: CalculationSettings(madhab: madhab))
        let phase = try #require(timeline.phase(at: tuesday.at(time, in: .berlin)))
        #expect(phase.activeKerahat?.id.rawValue == expected)
    }

    @Test("die Rechtsschule ändert keine Gebetszeit, auch nicht Asr")
    func timesUnchanged() throws {
        let source = AdhanTimesSource()
        let place = Place.berlin
        for asr in AsrRule.allCases {
            let hanafi = try #require(source.times(on: tuesday, at: place, settings: CalculationSettings(asr: asr)))
            for madhab in Madhab.allCases {
                let other = try #require(source.times(on: tuesday, at: place, settings: CalculationSettings(asr: asr, madhab: madhab)))
                #expect(other.madhab == madhab)
                #expect(other == hanafi.with(madhab: madhab))
            }
        }
    }

    @Test("Einstellungen von Build 4 ohne Rechtsschule lesen sich als Hanafi")
    func decodeOldSettings() throws {
        let encoded = try JSONEncoder().encode(CalculationSettings(asr: .hanafi))
        var object = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "madhab")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(CalculationSettings.self, from: data)
        #expect(decoded.madhab == .hanafi)
        #expect(decoded.asr == .hanafi)
    }

    @Test("die Rechtsschule bleibt beim Speichern erhalten")
    func roundTrip() throws {
        for madhab in Madhab.allCases {
            let settings = CalculationSettings(asr: .standard, madhab: madhab)
            let decoded = try JSONDecoder().decode(CalculationSettings.self, from: JSONEncoder().encode(settings))
            #expect(decoded == settings)
            let times = self.times(madhab)
            #expect(try JSONDecoder().decode(DayTimes.self, from: JSONEncoder().encode(times)) == times)
        }
    }

    @Test("Zeiten aus älteren Live-Aktivitäten ohne Rechtsschule gelten als Hanafi")
    func decodeOldTimes() throws {
        let encoded = try JSONEncoder().encode(times(.maliki))
        var object = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "madhab")
        let decoded = try JSONDecoder().decode(DayTimes.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.madhab == .hanafi)
        #expect(decoded == times(.hanafi))
    }

    @Test("Live-Aktivität bei Maliki: Dhuhr ohne Verbotszeit in einem Stück, Maghrib grün bis 16:07")
    func liveActivity() {
        let plans = LiveActivityPlanner(source: FixtureTimesSource()).plan(
            at: tuesday.at("14:25", in: .berlin), place: fixturePlace("berlin"),
            settings: CalculationSettings(madhab: .maliki),
            options: LiveActivityPlanner.Options(
                leadMinutes: 30, cityName: "Berlin", isCurrentLocation: true, showKerahat: true, clockOffset: 0
            )
        )
        let summary = plans.map {
            let kind = switch $0.content.kind {
            case .regular: ""
            case .beforeProhibited: " grün"
            case .prohibited: " orange"
            }
            return "\($0.prayer.rawValue) \(ClockTime($0.start, in: .berlin))–\(ClockTime($0.end, in: .berlin))\(kind)"
        }
        #expect(summary == [
            "maghrib 15:57–16:07 grün",
            "maghrib 16:07–16:27 orange",
            "isha 17:47–18:17",
            "fajr 04:46–05:16",
            "dhuhr 11:22–11:52",
        ])
    }
}

#endif
