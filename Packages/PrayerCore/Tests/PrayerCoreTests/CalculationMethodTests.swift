import Foundation
import Testing
@testable import PrayerCore

/// Der Katalog muss Zeile für Zeile `METHODS` im Prototyp entsprechen
/// (design/prayer-times-prototype.html).
@Suite("CalculationMethod")
struct CalculationMethodTests {

    @Test("die elf Methoden stehen in der Reihenfolge des Prototyps")
    func order() {
        #expect(CalculationMethod.allCases.map(\.rawValue) == [
            "mwl", "isna", "egyptian", "ummalqura", "karachi", "diyanet", "jakim", "kemenag", "singapore", "tehran",
            "moonsighting",
        ])
        #expect(CalculationMethod.allCases.map(\.id) == CalculationMethod.allCases.map(\.rawValue))
    }

    @Test("Kurzname, Name, Fadschr-Winkel und Ischa-Winkel je Methode", arguments: [
        ("mwl", "MWL", "Muslim World League", 18.0, 17.0),
        ("isna", "ISNA", "Islamic Society of North America", 15.0, 15.0),
        ("egyptian", "Egyptian", "Egyptian General Authority of Survey", 19.5, 17.5),
        ("karachi", "Karachi", "University of Islamic Sciences, Karachi", 18.0, 18.0),
        ("diyanet", "Diyanet", "Diyanet İşleri Başkanlığı (Türkiye)", 18.0, 17.0),
        ("jakim", "JAKIM", "JAKIM (Malaysia)", 20.0, 18.0),
        ("kemenag", "Kemenag", "Kemenag (Indonesia)", 20.0, 18.0),
        ("singapore", "Singapore", "MUIS (Singapore)", 20.0, 18.0),
        ("tehran", "Tehran", "Institute of Geophysics, Tehran", 17.7, 14.0),
        ("moonsighting", "Moonsighting", "Moonsighting Committee Worldwide", 18.0, 18.0),
    ])
    func angleMethods(id: String, short: String, name: String, fajr: Double, isha: Double) throws {
        let method = try #require(CalculationMethod(rawValue: id))
        #expect(method.shortName == short)
        #expect(method.name == name)
        #expect(method.fajrAngle == fajr)
        #expect(method.isha == .angle(isha))
    }

    @Test("Umm al-Qura legt Ischa 90 Minuten nach Maghrib")
    func ummAlQura() {
        let method = CalculationMethod.ummAlQura
        #expect(method.shortName == "Umm al-Qura")
        #expect(method.name == "Umm al-Qura University, Makkah")
        #expect(method.fajrAngle == 18.5)
        #expect(method.isha == .minutesAfterMaghrib(90))
    }

    @Test("nur Moonsighting ist saisonal")
    func seasonal() {
        #expect(CalculationMethod.allCases.filter(\.isSeasonal) == [.moonsighting])
    }

    @Test("automatische Methode je Land", arguments: [
        ("DE", CalculationMethod.mwl),
        ("TR", .diyanet),
        ("ES", .mwl),
        ("SA", .ummAlQura),
        ("ID", .kemenag),
    ])
    func automatic(country: String, expected: CalculationMethod) {
        #expect(CalculationMethod.automatic(forCountryCode: country) == expected)
        #expect(CalculationMethod.automatic(forCountryCode: country.lowercased()) == expected)
    }

    @Test("ohne Land und für alle anderen Länder gilt MWL", arguments: [nil, "", "US", "MY", "GB", "XX"] as [String?])
    func automaticFallback(country: String?) {
        #expect(CalculationMethod.automatic(forCountryCode: country) == .mwl)
    }

    #if DEBUG
    @Test("die automatische Methode passt zu den Städten des Prototyps")
    func automaticMatchesFixtureCities() {
        for city in FixtureTimes.cities {
            #expect(CalculationMethod.automatic(forCountryCode: city.countryCode).rawValue == city.automaticMethodID, "\(city.id)")
        }
    }
    #endif

    @Test("wird unter der Kennung des Prototyps gespeichert")
    func codable() throws {
        let data = try JSONEncoder().encode([CalculationMethod.ummAlQura, .mwl])
        #expect(String(decoding: data, as: UTF8.self) == #"["ummalqura","mwl"]"#)
        #expect(try JSONDecoder().decode([CalculationMethod].self, from: data) == [.ummAlQura, .mwl])
    }
}
