#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Kerahat-Fenster müssen sich verhalten wie `KERAHAT_MIN`, `kerahatWins()` und `activeKerahat()`
/// im Prototyp. Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026:
/// Sonnenaufgang 07:14, Dhuhr 11:52, Maghrib 16:27.
@Suite("Kerahat")
struct KerahatTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixtureTimeline()

    private func span(_ window: KerahatWindow, in zone: TimeZone = .berlin) -> String {
        "\(ClockTime(window.start, in: zone))–\(ClockTime(window.end, in: zone))"
    }

    @Test("die Dauern sind 45, 10 und 45 Minuten")
    func durations() {
        #expect(Kerahat.minutesAfterSunrise == 45)
        #expect(Kerahat.minutesBeforeDhuhr == 10)
        #expect(Kerahat.minutesBeforeMaghrib == 45)
    }

    @Test("die Kennungen sind die des Prototyps")
    func kinds() {
        #expect(KerahatWindow.Kind.allCases.map(\.rawValue) == ["sunrise", "zenith", "sunset"])
    }

    @Test("drei Fenster: nach Sonnenaufgang, vor Dhuhr, vor Maghrib")
    func windows() {
        let windows = Kerahat.windows(for: berlin.today)
        #expect(windows.map(\.id) == [.sunrise, .zenith, .sunset])
        #expect(windows.map { span($0) } == ["07:14–07:59", "11:42–11:52", "15:42–16:27"])
        #expect(windows.map { $0.end.timeIntervalSince($0.start) } == [minutes(45), minutes(10), minutes(45)])
    }

    @Test("jedes Fenster steht bei seiner Zeile: Sonnenaufgang, Dhuhr und – am Ende der Asr-Zeit – Asr")
    func rows() {
        #expect(Kerahat.windows(for: berlin.today).map(\.row) == [.sunrise, .dhuhr, .asr])
    }

    @Test("an den Rändern: Der Beginn gehört zum Fenster, das Ende nicht", arguments: [
        ("07:13:59", nil),
        ("07:14:00", "sunrise"),
        ("07:30:00", "sunrise"),
        ("07:58:59", "sunrise"),
        ("07:59:00", nil),
        ("11:41:59", nil),
        ("11:42:00", "zenith"),
        ("11:51:59", "zenith"),
        ("11:52:00", nil),
        ("15:41:59", nil),
        ("15:42:00", "sunset"),
        ("16:05:00", "sunset"),
        ("16:26:59", "sunset"),
        ("16:27:00", nil),
        ("14:25:00", nil),
        ("00:00:00", nil),
        ("23:59:59", nil),
    ] as [(String, String?)])
    func edges(time: String, expected: String?) throws {
        let now = day.at(time, in: .berlin)
        #expect(Kerahat.activeWindow(at: now, in: berlin.today)?.id.rawValue == expected)
        #expect(try #require(berlin.phase(at: now)).activeKerahat?.id.rawValue == expected)
    }

    @Test("ein Fenster enthält seinen Beginn, aber nicht sein Ende")
    func contains() throws {
        let window = try #require(Kerahat.windows(for: berlin.today).first)
        #expect(window.contains(window.start))
        #expect(window.contains(window.end.addingTimeInterval(-0.001)))
        #expect(!window.contains(window.end))
        #expect(!window.contains(window.start.addingTimeInterval(-0.001)))
    }

    @Test("die Fenster folgen den Zeiten samt Minutenkorrektur")
    func adjusted() {
        let settings = CalculationSettings(adjustments: MinuteAdjustments([.sunrise: 5, .dhuhr: -3, .maghrib: 2]))
        let windows = Kerahat.windows(for: fixtureTimeline(settings: settings).today)
        #expect(windows.map { span($0) } == ["07:19–08:04", "11:39–11:49", "15:44–16:29"])
    }

    @Test("Jakarta: die Fenster liegen an den Zeiten der Stadt")
    func jakarta() {
        let windows = Kerahat.windows(for: fixtureTimeline(city: "jakarta").today)
        #expect(windows.map { span($0, in: .jakarta) } == ["05:24–06:09", "11:29–11:39", "17:04–17:49"])
    }

    // MARK: - Schlüssel der Phase

    @Test("ein laufendes Fenster steht im Schlüssel der Phase – aber nur, wenn die App Kerahat zeigt")
    func phaseKey() throws {
        let morning = try #require(berlin.phase(at: day.at("07:30", in: .berlin)))
        #expect(morning.key(showKerahat: true) == "-|dhuhr0|110000|sunrise")
        #expect(morning.key(showKerahat: false) == "-|dhuhr0|110000|-")
        // Ausgerechnet wird das Fenster immer; der Schalter entscheidet nur über die Anzeige.
        #expect(morning.activeKerahat?.id == .sunrise)

        let afternoon = try #require(berlin.phase(at: day.at("16:05", in: .berlin)))
        #expect(afternoon.key(showKerahat: true) == "asr0|maghrib0|111100|sunset")
        #expect(afternoon.key(showKerahat: false) == "asr0|maghrib0|111100|-")
    }

    @Test("Beginn und Ende eines Fensters ändern den Schlüssel", arguments: [
        ("15:41:59", "asr0|maghrib0|111100|-"),
        ("15:42:00", "asr0|maghrib0|111100|sunset"),
        ("16:26:59", "asr0|maghrib0|111100|sunset"),
        ("16:27:00", "maghrib0|isha0|111110|-"),
        ("11:41:59", "-|dhuhr0|110000|-"),
        ("11:42:00", "-|dhuhr0|110000|zenith"),
        ("11:52:00", "dhuhr0|asr0|111000|-"),
    ])
    func keyChanges(time: String, key: String) throws {
        #expect(try #require(berlin.phase(at: day.at(time, in: .berlin))).key(showKerahat: true) == key)
    }
}

#endif
