import Foundation
import Testing
@testable import PrayerCore

/// Die echte Berechnung gegen Referenzwerte: die Tabellen aus den Testdaten von Adhan Swift
/// (`Resources/AdhanTimes`) und einzelne Werte aus dessen Tests (`Tests/AdhanTests.swift`, MIT).
@Suite("AdhanTimesSource – Referenzwerte")
struct ReferenceTimesTests {

    private let source = AdhanTimesSource()

    // MARK: - Tabellen der veröffentlichenden Stellen

    @Test("rechnet die Tabelle nach", arguments: [
        ("Ankara-Turkey", CalculationMethod.diyanet, 24),
        ("Makkah-UmmAlQura", .ummAlQura, 12),
        ("Singapore-Singapore", .singapore, 366),
        ("Tehran-Tehran", .tehran, 12),
        ("London-MoonsightingCommittee", .moonsighting, 12),
    ])
    func table(name: String, method: CalculationMethod, days: Int) throws {
        let table = try ReferenceTable(named: name)
        #expect(try table.method == method)
        #expect(table.times.count == days)

        let place = table.place
        let settings = try CalculationSettings(method: method, asr: table.asr, highLatitudeRule: table.highLatitudeRule)
        for row in table.times {
            let day = try #require(CalendarDay(row.date))
            let times = try #require(source.times(on: day, at: place, settings: settings), "\(name) \(row.date)")
            for prayer in Prayer.allCases {
                let expected = day.date(at: try row.time(of: prayer), in: place.timeZone)
                let difference = abs(times[prayer].timeIntervalSince(expected))
                #expect(
                    difference <= minutes(table.variance ?? 0),
                    "\(name) \(row.date) \(prayer): gerechnet \(times.clockTime(of: prayer)), Tabelle \(row[prayer])"
                )
            }
        }
    }

    // MARK: - Einzelwerte aus den Tests von Adhan Swift

    /// Ein Tag an einem Ort mit den sechs erwarteten Uhrzeiten.
    struct Reference: Sendable, CustomTestStringConvertible {
        var label: String
        var latitude: Double
        var longitude: Double
        var zone: String
        var day: String
        var settings: CalculationSettings
        /// Fadschr, Sonnenaufgang, Dhuhr, Asr, Maghrib, Ischa.
        var expected: [String]

        var testDescription: String { label }

        var place: Place {
            Place(
                name: label, countryCode: nil,
                coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
            )
        }
    }

    private static let raleigh = (latitude: 35.7750, longitude: -78.6336, zone: "America/New_York")
    private static let tehran = (latitude: 35.715298, longitude: 51.404343, zone: "Asia/Tehran")
    private static let edinburgh = (latitude: 55.983226, longitude: -3.216649, zone: "Europe/London")

    static let references: [Reference] = [
        Reference(
            label: "ISNA, Raleigh, Asr hanafitisch",
            latitude: raleigh.latitude, longitude: raleigh.longitude, zone: raleigh.zone, day: "2015-07-12",
            settings: CalculationSettings(method: .isna, asr: .hanafi),
            expected: ["04:42", "06:08", "13:21", "18:22", "20:32", "21:57"]
        ),
        Reference(
            label: "MWL, Raleigh",
            latitude: raleigh.latitude, longitude: raleigh.longitude, zone: raleigh.zone, day: "2015-12-01",
            settings: CalculationSettings(method: .mwl),
            expected: ["05:35", "07:06", "12:05", "14:42", "17:01", "18:26"]
        ),
        Reference(
            label: "MWL, Raleigh, jede Zeit um 10 Minuten verschoben",
            latitude: raleigh.latitude, longitude: raleigh.longitude, zone: raleigh.zone, day: "2015-12-01",
            settings: CalculationSettings(
                method: .mwl,
                adjustments: MinuteAdjustments([.fajr: 10, .sunrise: 10, .dhuhr: 10, .asr: 10, .maghrib: 10, .isha: 10])
            ),
            expected: ["05:45", "07:16", "12:15", "14:52", "17:11", "18:36"]
        ),
        Reference(
            label: "Moonsighting, Raleigh",
            latitude: raleigh.latitude, longitude: raleigh.longitude, zone: raleigh.zone, day: "2016-01-31",
            settings: CalculationSettings(method: .moonsighting),
            expected: ["05:48", "07:16", "12:33", "15:20", "17:43", "19:05"]
        ),
        Reference(
            label: "Moonsighting, Oslo, Asr hanafitisch",
            latitude: 59.9094, longitude: 10.7349, zone: "Europe/Oslo", day: "2016-01-01",
            settings: CalculationSettings(method: .moonsighting, asr: .hanafi),
            expected: ["07:34", "09:19", "12:25", "13:36", "15:25", "17:02"]
        ),
        Reference(
            label: "Tehran, Winter",
            latitude: tehran.latitude, longitude: tehran.longitude, zone: tehran.zone, day: "2016-12-15",
            settings: CalculationSettings(method: .tehran),
            expected: ["05:37", "07:07", "12:00", "14:34", "17:13", "18:03"]
        ),
        Reference(
            label: "Tehran, Sommer",
            latitude: tehran.latitude, longitude: tehran.longitude, zone: tehran.zone, day: "2019-06-16",
            settings: CalculationSettings(method: .tehran),
            expected: ["04:01", "05:48", "13:05", "16:54", "20:43", "21:43"]
        ),
        Reference(
            label: "Diyanet, Istanbul",
            latitude: 41.005616, longitude: 28.976380, zone: "Europe/Istanbul", day: "2020-04-16",
            settings: CalculationSettings(method: .diyanet),
            expected: ["04:44", "06:16", "13:09", "16:53", "19:52", "21:19"]
        ),
        Reference(
            label: "Egyptian, Kairo",
            latitude: 30.028703, longitude: 31.249528, zone: "Africa/Cairo", day: "2020-01-01",
            settings: CalculationSettings(method: .egyptian),
            expected: ["05:18", "06:51", "11:59", "14:47", "17:06", "18:29"]
        ),
        // Hohe Breiten: Edinburgh im Juni, die Dämmerung endet nicht. Fadschr und Ischa hängen an der Regel.
        Reference(
            label: "MWL, Edinburgh, Nachtmitte",
            latitude: edinburgh.latitude, longitude: edinburgh.longitude, zone: edinburgh.zone, day: "2020-06-15",
            settings: CalculationSettings(method: .mwl, highLatitudeRule: .middle),
            expected: ["01:14", "04:26", "13:14", "17:46", "22:01", "01:14"]
        ),
        Reference(
            label: "MWL, Edinburgh, Siebtel der Nacht",
            latitude: edinburgh.latitude, longitude: edinburgh.longitude, zone: edinburgh.zone, day: "2020-06-15",
            settings: CalculationSettings(method: .mwl, highLatitudeRule: .seventh),
            expected: ["03:31", "04:26", "13:14", "17:46", "22:01", "22:56"]
        ),
        Reference(
            label: "MWL, Edinburgh, winkelbasiert",
            latitude: edinburgh.latitude, longitude: edinburgh.longitude, zone: edinburgh.zone, day: "2020-06-15",
            settings: CalculationSettings(method: .mwl, highLatitudeRule: .angle),
            expected: ["02:31", "04:26", "13:14", "17:46", "22:01", "23:50"]
        ),
    ]

    @Test("trifft die Werte aus den Tests von Adhan Swift", arguments: references)
    func reference(_ reference: Reference) throws {
        let day = try #require(CalendarDay(reference.day))
        let times = try #require(source.times(on: day, at: reference.place, settings: reference.settings))
        #expect(Prayer.allCases.map { times.clockTime(of: $0).description } == reference.expected)
        // Die Zeiten liegen in ihrer Reihenfolge, auch wenn Ischa erst nach Mitternacht kommt.
        #expect(Prayer.allCases.map { times[$0] } == Prayer.allCases.map { times[$0] }.sorted())
    }

    @Test("mit der Regel „Nachtmitte“ fällt Ischa auf den Folgetag")
    func ishaAfterMidnight() throws {
        let reference = try #require(Self.references.first { $0.label == "MWL, Edinburgh, Nachtmitte" })
        let day = try #require(CalendarDay(reference.day))
        let times = try #require(source.times(on: day, at: reference.place, settings: reference.settings))
        #expect(times.day == day)
        #expect(CalendarDay(times.maghrib, in: reference.place.timeZone) == day)
        #expect(CalendarDay(times.isha, in: reference.place.timeZone) == day.adding(days: 1))
    }

    // MARK: - Orte ohne Sonnenauf- oder -untergang

    @Test("wo die Sonne nicht aufgeht, gibt es keine Zeiten")
    func polarNight() throws {
        // Utqiaġvik, Alaska – Werte aus `testExtremeLocation` von Adhan Swift.
        let place = Place(
            name: "Utqiaġvik", countryCode: "US",
            coordinates: Coordinates(latitude: 71.275009, longitude: -156.761368), timeZoneIdentifier: "America/Anchorage"
        )
        #expect(source.times(on: calendarDay("2018-01-01"), at: place, settings: CalculationSettings()) == nil)
        #expect(source.times(on: calendarDay("2018-03-01"), at: place, settings: CalculationSettings()) != nil)
    }
}

// MARK: - Tabellenformat

/// Eine Tabelle aus `Resources/AdhanTimes`, im Format der Testdaten von Adhan Swift.
private struct ReferenceTable: Decodable {

    struct Parameters: Decodable {
        let latitude: Double
        let longitude: Double
        let timezone: String
        let method: String
        let madhab: String
        let highLatitudeRule: String
    }

    struct Row: Decodable {
        let date: String
        let fajr: String
        let sunrise: String
        let dhuhr: String
        let asr: String
        let maghrib: String
        let isha: String

        /// Eintrag der Tabelle, z. B. „6:33 AM“.
        subscript(prayer: Prayer) -> String {
            switch prayer {
            case .fajr: fajr
            case .sunrise: sunrise
            case .dhuhr: dhuhr
            case .asr: asr
            case .maghrib: maghrib
            case .isha: isha
            }
        }

        /// „6:33 AM“ → 06:33, „7:05 PM“ → 19:05.
        func time(of prayer: Prayer) throws -> ClockTime {
            let parts = self[prayer].split(separator: " ")
            try #require(parts.count == 2, "Unerwarteter Eintrag: \(self[prayer])")
            let numbers = parts[0].split(separator: ":").compactMap { Int($0) }
            try #require(numbers.count == 2, "Unerwarteter Eintrag: \(self[prayer])")
            let hour = numbers[0] % 12 + (parts[1] == "PM" ? 12 : 0)
            return try #require(ClockTime(hour: hour, minute: numbers[1]))
        }
    }

    struct UnknownValue: Error {
        let value: String
    }

    let params: Parameters
    /// Erlaubte Abweichung in Minuten; ohne Angabe 0.
    let variance: Double?
    let times: [Row]

    init(named name: String) throws {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "AdhanTimes"),
            "Tabelle \(name).json fehlt in den Test-Ressourcen"
        )
        self = try JSONDecoder().decode(ReferenceTable.self, from: Data(contentsOf: url))
    }

    var place: Place {
        Place(
            name: params.method, countryCode: nil,
            coordinates: Coordinates(latitude: params.latitude, longitude: params.longitude),
            timeZoneIdentifier: params.timezone
        )
    }

    var method: CalculationMethod {
        get throws {
            switch params.method {
            case "Turkey": .diyanet
            case "UmmAlQura": .ummAlQura
            case "Singapore": .singapore
            case "Tehran": .tehran
            case "MoonsightingCommittee": .moonsighting
            default: throw UnknownValue(value: params.method)
            }
        }
    }

    var asr: AsrRule {
        get throws {
            switch params.madhab {
            case "Shafi": .standard
            case "Hanafi": .hanafi
            default: throw UnknownValue(value: params.madhab)
            }
        }
    }

    var highLatitudeRule: HighLatitudeRule {
        get throws {
            switch params.highLatitudeRule {
            case "MiddleOfTheNight": .middle
            case "SeventhOfTheNight": .seventh
            case "TwilightAngle": .angle
            default: throw UnknownValue(value: params.highLatitudeRule)
            }
        }
    }
}
