#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Fixture-Daten müssen Zeile für Zeile den Mock-Daten des Prototyps entsprechen
/// (`CITIES`, `BERLIN_SUMMER` in design/prayer-times-prototype.html).
@Suite("FixtureTimes")
struct FixtureTimesTests {

    @Test("die fünf Städte stehen in der Reihenfolge des Prototyps")
    func cityOrder() {
        #expect(FixtureTimes.cities.map(\.id) == ["berlin", "istanbul", "madrid", "mecca", "jakarta"])
    }

    @Test("Berlin zeigt die Zeiten des Haupt-Screenshots")
    func berlin() throws {
        let berlin = try #require(FixtureTimes.city("berlin"))
        #expect(Prayer.allCases.map { berlin.times[$0].description } == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(berlin.times.asrHanafi.description == "14:36")
        #expect(berlin.countryCode == "DE")
        #expect(berlin.qiblaDegrees == 137)
        #expect(berlin.distanceKm == 4130)
        #expect(berlin.automaticMethodID == "mwl")
    }

    @Test("Land, Qibla, Entfernung und Methode je Stadt", arguments: [
        ("istanbul", "TR", 152, 2410, "diyanet"),
        ("madrid", "ES", 104, 4600, "mwl"),
        ("jakarta", "ID", 295, 7920, "kemenag"),
    ])
    func cityFacts(id: String, country: String, qibla: Int, km: Int, method: String) throws {
        let city = try #require(FixtureTimes.city(id))
        #expect(city.countryCode == country)
        #expect(city.qiblaDegrees == qibla)
        #expect(city.distanceKm == km)
        #expect(city.automaticMethodID == method)
    }

    @Test("Zeiten je Stadt", arguments: [
        ("istanbul", ["06:09", "07:36", "12:53", "15:36", "16:13", "18:00", "19:23"]),
        ("madrid", ["06:18", "07:51", "13:00", "15:43", "16:25", "18:06", "19:33"]),
        ("mecca", ["05:08", "06:27", "12:05", "15:17", "16:05", "17:41", "19:11"]),
        ("jakarta", ["04:06", "05:24", "11:39", "14:57", "16:02", "17:49", "19:01"]),
    ])
    func cityTimes(id: String, expected: [String]) throws {
        let times = try #require(FixtureTimes.city(id)).times
        let actual = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.asrHanafi, times.maghrib, times.isha]
        #expect(actual.map(\.description) == expected)
    }

    @Test("in Mekka gibt es keine Richtung und keine Entfernung")
    func mecca() throws {
        let mecca = try #require(FixtureTimes.city("mecca"))
        #expect(mecca.qiblaDegrees == nil)
        #expect(mecca.distanceKm == 0)
        #expect(mecca.automaticMethodID == "ummalqura")
    }

    @Test("in jeder Stadt liegen die Zeiten in aufsteigender Reihenfolge")
    func ascending() {
        for city in FixtureTimes.cities {
            let times = city.times
            let ordered = [times.fajr, times.sunrise, times.dhuhr, times.asr, times.asrHanafi, times.maghrib, times.isha]
            #expect(ordered == ordered.sorted(), "\(city.id)")
            #expect(Set(ordered).count == ordered.count, "\(city.id)")
        }
    }

    @Test("jede Stadt hat eine gültige Zeitzone und plausible Koordinaten")
    func placeData() {
        for city in FixtureTimes.cities {
            #expect(TimeZone(identifier: city.timeZoneIdentifier) != nil, "\(city.id)")
            #expect((-90...90).contains(city.coordinates.latitude), "\(city.id)")
            #expect((-180...180).contains(city.coordinates.longitude), "\(city.id)")
        }
    }

    @Test("eine Stadt wird zum Ort mit Anzeigenamen")
    func place() throws {
        let place = try #require(FixtureTimes.city("jakarta")).place(named: "Jakarta")
        #expect(place.name == "Jakarta")
        #expect(place.countryCode == "ID")
        #expect(place.timeZone.identifier == "Asia/Jakarta")
        #expect(place.coordinates.latitude < 0)
    }

    @Test("eine unbekannte Kennung ergibt keine Stadt")
    func unknownCity() {
        #expect(FixtureTimes.city("paris") == nil)
        #expect(FixtureTimes.city("Berlin") == nil)
    }

    @Test("Referenztag und -uhrzeit sind der 10.11.2026, 14:25")
    func reference() {
        #expect(FixtureTimes.referenceDay.description == "2026-11-10")
        #expect(FixtureTimes.referenceTime.description == "14:25")
    }

    @Test("Berlin im Sommer: 21. Juni 2027 mit den festen Zeiten")
    func berlinSummer() {
        let summer = FixtureTimes.berlinSummer
        #expect(summer.day.description == "2027-06-21")
        #expect(summer.sunrise.description == "04:43")
        #expect(summer.dhuhr.description == "13:12")
        #expect(summer.asr.description == "17:33")
        #expect(summer.asrHanafi.description == "18:48")
        #expect(summer.maghrib.description == "21:33")
    }

    @Test("Berlin im Sommer: Fadschr und Ischa je Regel", arguments: [
        (HighLatitudeRule.angle, "02:34", "23:35"),
        (.seventh, "03:42", "22:34"),
        (.middle, "01:08", "01:08"),
    ])
    func berlinSummerRules(rule: HighLatitudeRule, fajr: String, isha: String) {
        #expect(FixtureTimes.berlinSummer.fajr[rule]?.description == fajr)
        #expect(FixtureTimes.berlinSummer.isha[rule]?.description == isha)
    }

    @Test("Berlin im Sommer: jede Regel hat Fadschr und Ischa")
    func berlinSummerComplete() {
        for rule in HighLatitudeRule.allCases {
            #expect(FixtureTimes.berlinSummer.fajr[rule] != nil)
            #expect(FixtureTimes.berlinSummer.isha[rule] != nil)
        }
    }
}

#endif
