import Foundation
import Testing
@testable import PrayerCore

@Suite("AdhanTimesSource")
struct AdhanTimesSourceTests {

    private let source = AdhanTimesSource()
    private let day = calendarDay("2026-11-10")
    /// MWL fest gewählt. Ohne Wahl gilt in Berlin die Automatik für Deutschland, also Diyanet.
    private let mwl = CalculationSettings(method: .mwl)

    private func place(_ name: String, country: String?, latitude: Double, longitude: Double, zone: String) -> Place {
        Place(
            name: name, countryCode: country,
            coordinates: Coordinates(latitude: latitude, longitude: longitude), timeZoneIdentifier: zone
        )
    }

    private var istanbul: Place { place("Istanbul", country: "TR", latitude: 41.0082, longitude: 28.9784, zone: "Europe/Istanbul") }
    private var mecca: Place { place("Mekka", country: "SA", latitude: 21.4225, longitude: 39.8262, zone: "Asia/Riyadh") }
    private var jakarta: Place { place("Jakarta", country: "ID", latitude: -6.2088, longitude: 106.8456, zone: "Asia/Jakarta") }
    private var honolulu: Place { place("Honolulu", country: "US", latitude: 21.3069, longitude: -157.8583, zone: "Pacific/Honolulu") }

    private func times(
        on day: CalendarDay? = nil, at place: Place = .berlin, _ settings: CalculationSettings = CalculationSettings()
    ) throws -> DayTimes {
        try #require(source.times(on: day ?? self.day, at: place, settings: settings))
    }

    private func clockTimes(_ times: DayTimes) -> [String] {
        Prayer.allCases.map { times.clockTime(of: $0).description }
    }

    // MARK: - Berlin am Referenztag

    @Test("Berlin am 10.11.2026 mit MWL")
    func berlin() throws {
        let times = try times(mwl)
        #expect(clockTimes(times) == ["05:21", "07:19", "11:51", "13:55", "16:21", "18:13"])
        #expect(times.day == day)
        #expect(times.timeZone == .berlin)
    }

    @Test("Berlin am 10.11.2026 ohne Wahl: Für Deutschland gilt Diyanet")
    func berlinAutomatic() throws {
        let times = try times()
        #expect(times == (try self.times(CalculationSettings(method: .diyanet))))
        // Dieselben Winkel wie MWL (18°/17°), dazu die Minuten von Diyanet:
        // Sonnenaufgang −7, Dhuhr +5 statt +1, Asr +4, Maghrib +7.
        #expect(clockTimes(times) == ["05:21", "07:12", "11:55", "13:59", "16:28", "18:13"])
    }

    @Test("Asr hanafitisch beginnt später, alles andere bleibt")
    func hanafi() throws {
        let standard = try times(mwl)
        let hanafi = try times(CalculationSettings(method: .mwl, asr: .hanafi))
        #expect(hanafi.clockTime(of: .asr) == clockTime("14:31"))
        #expect(hanafi.asr > standard.asr)
        for prayer in Prayer.allCases where prayer != .asr {
            #expect(hanafi[prayer] == standard[prayer])
        }
    }

    @Test("jede Zeit steht auf einer vollen Minute")
    func wholeMinutes() throws {
        for method in CalculationMethod.allCases {
            let times = try times(CalculationSettings(method: method))
            for prayer in Prayer.allCases {
                #expect(times[prayer].timeIntervalSince1970.truncatingRemainder(dividingBy: 60) == 0, "\(method) \(prayer)")
            }
        }
    }

    // MARK: - Methode

    @Test("ohne Wahl gilt die Methode des Landes", arguments: [
        ("DE", CalculationMethod.diyanet), ("AT", .diyanet), ("TR", .diyanet), ("ES", .mwl), ("SA", .ummAlQura),
        ("ID", .kemenag),
        ("US", .isna), ("EG", .egyptian), ("PK", .karachi), ("MY", .jakim), ("SG", .singapore), ("IR", .tehran),
    ])
    func automaticMethod(country: String, method: CalculationMethod) throws {
        var place = Place.berlin
        place.countryCode = country
        #expect(try times(at: place) == times(at: place, CalculationSettings(method: method)))
        // Die Einstellungen nennen dieselbe Methode („Automatisch · Diyanet“).
        #expect(AdhanTimesSource().automaticMethod(for: place) == method)
    }

    @Test("ohne Land gilt MWL")
    func withoutCountry() throws {
        var place = Place.berlin
        place.countryCode = nil
        #expect(try times(at: place) == times(mwl))
    }

    @Test("eine gewählte Methode gilt unabhängig vom Land")
    func chosenMethod() throws {
        let diyanet = try times(at: istanbul)
        let mwl = try times(at: istanbul, CalculationSettings(method: .mwl))
        #expect(diyanet != mwl)
        // Diyanet schlägt auf Maghrib 7 Minuten auf, MWL nichts.
        #expect(diyanet.maghrib.timeIntervalSince(mwl.maghrib) == minutes(7))
    }

    @Test("Umm al-Qura legt Ischa 90 Minuten nach Maghrib")
    func ummAlQura() throws {
        let times = try times(at: mecca)
        #expect(times.isha.timeIntervalSince(times.maghrib) == minutes(90))
        #expect(clockTimes(times) == ["05:10", "06:29", "12:05", "15:17", "17:40", "19:10"])
    }

    @Test("JAKIM und Kemenag rechnen gleich: Fadschr bei 20°, Ischa bei 18°")
    func jakimAndKemenag() throws {
        let kemenag = try times(at: jakarta)
        let jakim = try times(at: jakarta, CalculationSettings(method: .jakim))
        let mwl = try times(at: jakarta, CalculationSettings(method: .mwl))
        #expect(kemenag == jakim)
        #expect(clockTimes(kemenag) == ["04:04", "05:25", "11:36", "14:56", "17:48", "19:01"])
        // Gegen MWL (18°/17°) beginnt Fadschr früher und Ischa später.
        #expect(kemenag.fajr < mwl.fajr)
        #expect(kemenag.isha > mwl.isha)
        #expect(kemenag.sunrise == mwl.sunrise)
        #expect(kemenag.maghrib == mwl.maghrib)
    }

    @Test("Karachi rechnet Fadschr wie MWL und Ischa später (18° statt 17°)")
    func karachi() throws {
        let karachi = try times(CalculationSettings(method: .karachi))
        let mwl = try times(self.mwl)
        #expect(karachi.fajr == mwl.fajr)
        #expect(karachi.isha > mwl.isha)
        #expect(karachi.isha.timeIntervalSince(mwl.isha) < minutes(15))
    }

    // MARK: - Minutenkorrektur

    @Test("eine Korrektur verschiebt genau ihr Ereignis")
    func adjustment() throws {
        let plain = try times(mwl)
        let adjusted = try times(CalculationSettings(method: .mwl, adjustments: MinuteAdjustments([.maghrib: 7, .fajr: -30])))
        #expect(adjusted.maghrib.timeIntervalSince(plain.maghrib) == minutes(7))
        #expect(adjusted.fajr.timeIntervalSince(plain.fajr) == minutes(-30))
        for prayer in [Prayer.sunrise, .dhuhr, .asr, .isha] {
            #expect(adjusted[prayer] == plain[prayer])
        }
    }

    // MARK: - Tag und Zeitzone

    @Test("alle Zeiten liegen auf dem Kalendertag des Ortes", arguments: ["Berlin", "Jakarta", "Honolulu", "Mekka"])
    func localDay(name: String) throws {
        // Jakarta: Fadschr um 04:04 ist in UTC noch der Vortag. Honolulu: Ischa ist in UTC schon der Folgetag.
        let place = try #require([Place.berlin, jakarta, honolulu, mecca].first { $0.name == name })
        let times = try times(at: place)
        for prayer in Prayer.allCases {
            #expect(CalendarDay(times[prayer], in: place.timeZone) == day, "\(name) \(prayer)")
        }
        #expect(Prayer.allCases.map { times[$0] } == Prayer.allCases.map { times[$0] }.sorted())
    }

    // MARK: - Zeitumstellung

    @Test("Ende der Sommerzeit am 25.10.2026: Die Uhrzeiten springen eine Stunde zurück, die Zeitpunkte nicht")
    func clocksGoBack() throws {
        let before = try times(on: calendarDay("2026-10-24"), mwl)
        let changeDay = try times(on: calendarDay("2026-10-25"), mwl)
        #expect(clockTimes(before) == ["05:53", "07:48", "12:52", "15:20", "17:52", "19:40"])
        #expect(clockTimes(changeDay) == ["04:55", "06:50", "11:51", "14:18", "16:50", "18:38"])
        for prayer in Prayer.allCases {
            // Von Tag zu Tag wandert die Sonne nur um Minuten; ein Tag sind hier 24 Stunden.
            let drift = changeDay[prayer].timeIntervalSince(before[prayer]) - 24 * 3600
            #expect(abs(drift) <= minutes(3), "\(prayer)")
            #expect(CalendarDay(changeDay[prayer], in: .berlin) == calendarDay("2026-10-25"), "\(prayer)")
        }
    }

    @Test("Beginn der Sommerzeit am 28.03.2027: Die Uhrzeiten springen eine Stunde vor, die Zeitpunkte nicht")
    func clocksGoForward() throws {
        let before = try times(on: calendarDay("2027-03-27"), mwl)
        let changeDay = try times(on: calendarDay("2027-03-28"), mwl)
        #expect(clockTimes(before) == ["03:54", "05:53", "12:13", "15:38", "18:31", "20:23"])
        #expect(clockTimes(changeDay) == ["04:52", "06:51", "13:13", "16:39", "19:33", "21:26"])
        for prayer in Prayer.allCases {
            let drift = changeDay[prayer].timeIntervalSince(before[prayer]) - 24 * 3600
            #expect(abs(drift) <= minutes(3), "\(prayer)")
            #expect(CalendarDay(changeDay[prayer], in: .berlin) == calendarDay("2027-03-28"), "\(prayer)")
        }
    }
}
