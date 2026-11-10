import Foundation
import Testing
@testable import PrayerCore

@Suite("MinuteAdjustments")
struct MinuteAdjustmentsTests {

    @Test("ohne Korrektur steht jedes Ereignis auf 0")
    func empty() {
        let adjustments = MinuteAdjustments()
        #expect(Prayer.allCases.allSatisfy { adjustments[$0] == 0 })
        #expect(adjustments.changedCount == 0)
    }

    @Test("merkt sich die Korrektur je Ereignis")
    func stores() {
        var adjustments = MinuteAdjustments()
        adjustments[.fajr] = -2
        adjustments[.dhuhr] = 5
        #expect(adjustments[.fajr] == -2)
        #expect(adjustments[.dhuhr] == 5)
        #expect(adjustments[.asr] == 0)
        #expect(adjustments.changedCount == 2)
        #expect(adjustments == MinuteAdjustments([.dhuhr: 5, .fajr: -2]))
    }

    @Test("der Bereich ist ±30 Minuten")
    func range() {
        #expect(MinuteAdjustments.range == -30...30)
    }

    @Test("Werte außerhalb werden an den Rand gesetzt", arguments: [(31, 30), (-31, -30), (1000, 30), (.min, -30), (.max, 30)])
    func clamps(value: Int, expected: Int) {
        var adjustments = MinuteAdjustments()
        adjustments[.isha] = value
        #expect(adjustments[.isha] == expected)
        #expect(MinuteAdjustments([.isha: value])[.isha] == expected)
    }

    @Test("der Stepper zählt in Minuten und bleibt am Rand stehen")
    func steps() {
        var adjustments = MinuteAdjustments([.asr: 29])
        adjustments.step(.asr, by: 1)
        #expect(adjustments[.asr] == 30)
        adjustments.step(.asr, by: 1)
        #expect(adjustments[.asr] == 30)
        adjustments.step(.asr, by: -1)
        #expect(adjustments[.asr] == 29)

        adjustments[.fajr] = -30
        adjustments.step(.fajr, by: -1)
        #expect(adjustments[.fajr] == -30)
    }

    @Test("ein übergroßer Schritt läuft nicht über")
    func hugeSteps() {
        var adjustments = MinuteAdjustments([.maghrib: 30])
        adjustments.step(.maghrib, by: .max)
        #expect(adjustments[.maghrib] == 30)
        adjustments.step(.maghrib, by: .min)
        #expect(adjustments[.maghrib] == -30)
    }

    @Test("zurück auf 0 ist dasselbe wie nie geändert")
    func backToZero() {
        var adjustments = MinuteAdjustments()
        adjustments.step(.sunrise, by: 1)
        adjustments.step(.sunrise, by: -1)
        #expect(adjustments == MinuteAdjustments())
        #expect(adjustments.changedCount == 0)
    }

    @Test("Zurücksetzen löscht alle Korrekturen")
    func reset() {
        var adjustments = MinuteAdjustments([.fajr: 3, .isha: -7])
        adjustments.reset()
        #expect(adjustments == MinuteAdjustments())
    }

    @Test("wird als Objekt mit den Kennungen der Ereignisse gespeichert")
    func encodes() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(MinuteAdjustments([.fajr: -2, .dhuhr: 5]))
        #expect(String(decoding: data, as: UTF8.self) == #"{"dhuhr":5,"fajr":-2}"#)
        #expect(try JSONDecoder().decode(MinuteAdjustments.self, from: data) == MinuteAdjustments([.fajr: -2, .dhuhr: 5]))
    }

    @Test("beim Lesen werden unbekannte Kennungen übergangen und Werte begrenzt")
    func decodesDefensively() throws {
        let data = Data(#"{"fajr":99,"witr":4,"asr":0,"isha":-45}"#.utf8)
        let adjustments = try JSONDecoder().decode(MinuteAdjustments.self, from: data)
        #expect(adjustments == MinuteAdjustments([.fajr: 30, .isha: -30]))
    }

    @Test("etwas anderes als ein Objekt mit Zahlen wird abgelehnt")
    func rejectsOtherShapes() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MinuteAdjustments.self, from: Data(#"[1,2,3]"#.utf8))
        }
    }
}

@Suite("CalculationSettings")
struct CalculationSettingsTests {

    @Test("Standard wie im Prototyp: automatisch, Asr Standard, winkelbasiert, keine Korrektur")
    func defaults() {
        let settings = CalculationSettings()
        #expect(settings.method == nil)
        #expect(settings.asr == .standard)
        #expect(settings.highLatitudeRule == .angle)
        #expect(settings.adjustments == MinuteAdjustments())
    }

    @Test("ohne Wahl gilt die automatische Methode des Landes")
    func automaticMethod() {
        var place = Place.berlin
        #expect(CalculationSettings().effectiveMethod(for: place) == .diyanet)
        place.countryCode = "ID"
        #expect(CalculationSettings().effectiveMethod(for: place) == .kemenag)
        place.countryCode = "ES"
        #expect(CalculationSettings().effectiveMethod(for: place) == .mwl)
        place.countryCode = nil
        #expect(CalculationSettings().effectiveMethod(for: place) == .mwl)
    }

    @Test("eine gewählte Methode gilt in jedem Land")
    func chosenMethod() {
        let settings = CalculationSettings(method: .karachi)
        #expect(settings.effectiveMethod(for: .berlin) == .karachi)
    }

    @Test("die Kennungen von Asr sind die des Prototyps")
    func asrRawValues() {
        #expect(AsrRule.allCases.map(\.rawValue) == ["standard", "hanafi"])
    }

    @Test("übersteht Kodieren und Dekodieren")
    func codable() throws {
        let settings = CalculationSettings(
            method: .diyanet, asr: .hanafi, highLatitudeRule: .seventh, adjustments: MinuteAdjustments([.maghrib: 7])
        )
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(CalculationSettings.self, from: data) == settings)

        let automatic = try JSONEncoder().encode(CalculationSettings())
        #expect(try JSONDecoder().decode(CalculationSettings.self, from: automatic) == CalculationSettings())
    }
}
