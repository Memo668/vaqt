#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Die Tagesphase muss sich verhalten wie `phase()`, `phaseKey()` und `dayProgress()` im Prototyp.
/// Die Fälle stammen aus Spec § 4; gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026:
/// Fadschr 05:16, Sonnenaufgang 07:14, Dhuhr 11:52, Asr 14:00, Maghrib 16:27, Ischa 18:17.
@Suite("DayPhase")
struct DayPhaseTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixtureTimeline()

    /// Die Phase in Berlin am 10.11.2026 zur Uhrzeit `time` („HH:mm“ oder „HH:mm:ss“).
    private func phase(_ time: String) throws -> DayPhase {
        try #require(berlin.phase(at: day.at(time, in: .berlin)))
    }

    private func event(_ prayer: Prayer, _ dayOffset: Int, _ time: String) -> DayPhase.Event {
        DayPhase.Event(prayer: prayer, dayOffset: dayOffset, date: day.adding(days: dayOffset).at(time, in: .berlin))
    }

    private func passed(_ phase: DayPhase) -> [Prayer] {
        Prayer.allCases.filter { phase.hasPassed($0) }
    }

    // MARK: - Fälle aus Spec § 4

    @Test("14:25 – Asr läuft, Maghrib kommt in 2 h 02 min")
    func asrActive() throws {
        let phase = try phase("14:25")
        #expect(phase.previous == event(.asr, 0, "14:00"))
        #expect(phase.current == phase.previous)
        #expect(phase.highlighted == .asr)
        #expect(phase.next == event(.maghrib, 0, "16:27"))
        #expect(phase.following == event(.isha, 0, "18:17"))
        #expect(phase.remaining == minutes(122))
        #expect(phase.span == minutes(147))
        #expect(passed(phase) == [.fajr, .sunrise, .dhuhr, .asr])
        #expect(!phase.isNextTomorrow)
        #expect(phase.key(showKerahat: true) == "asr0|maghrib0|111100|-")
    }

    @Test("14:25 – der Tagesfortschritt ist 549 von 781 Minuten")
    func dayProgress() throws {
        let progress = try phase("14:25").dayProgress
        #expect(progress.fraction == 549.0 / 781.0)
        #expect(progress.isActive)
    }

    @Test("04:01 vor Fadschr – Ischa von gestern läuft, hervorgehoben ist nichts")
    func beforeFajr() throws {
        let phase = try phase("04:01")
        #expect(phase.previous == event(.isha, -1, "18:17"))
        #expect(phase.current == phase.previous)
        #expect(phase.highlighted == nil)
        #expect(phase.next == event(.fajr, 0, "05:16"))
        #expect(phase.following == event(.sunrise, 0, "07:14"))
        #expect(phase.remaining == minutes(75))
        #expect(passed(phase).isEmpty)
        #expect(!phase.isNextTomorrow)
        #expect(phase.dayProgress == DayPhase.Progress(fraction: 0, isActive: false))
        #expect(phase.key(showKerahat: true) == "isha-1|fajr0|000000|-")
    }

    @Test("05:14 kurz vor Fadschr – noch 2 Minuten")
    func rightBeforeFajr() throws {
        let phase = try phase("05:14")
        #expect(phase.highlighted == nil)
        #expect(phase.next.prayer == .fajr)
        #expect(phase.remaining == minutes(2))
    }

    @Test("08:04 nach Sonnenaufgang – kein Gebet läuft, Dhuhr ist das Nächste")
    func afterSunrise() throws {
        let phase = try phase("08:04")
        #expect(phase.previous == event(.sunrise, 0, "07:14"))
        #expect(phase.current == nil)
        #expect(phase.highlighted == nil)
        #expect(phase.next == event(.dhuhr, 0, "11:52"))
        #expect(phase.remaining == minutes(228))
        #expect(phase.span == minutes(278))
        #expect(passed(phase) == [.fajr, .sunrise])
        #expect(phase.dayProgress == DayPhase.Progress(fraction: 168.0 / 781.0, isActive: true))
        #expect(phase.key(showKerahat: true) == "-|dhuhr0|110000|-")
    }

    @Test("23:30 nach Ischa – Ischa ist hervorgehoben, Fadschr kommt morgen")
    func afterIsha() throws {
        let phase = try phase("23:30")
        #expect(phase.previous == event(.isha, 0, "18:17"))
        #expect(phase.highlighted == .isha)
        #expect(phase.next == event(.fajr, 1, "05:16"))
        #expect(phase.following == event(.sunrise, 1, "07:14"))
        #expect(phase.isNextTomorrow)
        #expect(phase.remaining == minutes(346))
        #expect(passed(phase) == Prayer.allCases)
        #expect(phase.dayProgress == DayPhase.Progress(fraction: 1, isActive: false))
        #expect(phase.key(showKerahat: true) == "isha0|fajr1|111111|-")
    }

    @Test("00:30 – der neue Tag hat begonnen, Ischa von gestern läuft weiter")
    func afterMidnight() throws {
        let phase = try phase("00:30")
        #expect(phase.previous == event(.isha, -1, "18:17"))
        #expect(phase.highlighted == nil)
        #expect(phase.next == event(.fajr, 0, "05:16"))
        #expect(!phase.isNextTomorrow)
        #expect(phase.remaining == minutes(286))
        #expect(phase.span == minutes(659))
        #expect(passed(phase).isEmpty)
        #expect(phase.key(showKerahat: true) == "isha-1|fajr0|000000|-")
    }

    @Test("die Grenze 13:59:59 / 14:00:00 – Asr beginnt auf die Sekunde")
    func boundary() throws {
        let before = try phase("13:59:59")
        #expect(before.highlighted == .dhuhr)
        #expect(before.next == event(.asr, 0, "14:00"))
        #expect(before.remaining == 1)
        #expect(!before.hasPassed(.asr))
        #expect(before.key(showKerahat: true) == "dhuhr0|asr0|111000|-")

        let at = try phase("14:00:00")
        #expect(at.highlighted == .asr)
        #expect(at.next == event(.maghrib, 0, "16:27"))
        #expect(at.remaining == minutes(147))
        #expect(at.hasPassed(.asr))
        #expect(at.key(showKerahat: true) == "asr0|maghrib0|111100|-")
    }

    @Test("der Sonnenaufgang beendet Fadschr")
    func sunriseEndsFajr() throws {
        let before = try phase("07:13:59")
        #expect(before.highlighted == .fajr)
        #expect(before.next.prayer == .sunrise)

        let at = try phase("07:14:00")
        #expect(at.current == nil)
        #expect(at.hasPassed(.sunrise))
        #expect(at.next.prayer == .dhuhr)
    }

    @Test("um Mitternacht wandert die Hervorhebung, und die Zeilen sind wieder offen")
    func midnight() throws {
        let lastSecond = try phase("23:59:59")
        #expect(lastSecond.highlighted == .isha)
        #expect(lastSecond.next.dayOffset == 1)
        #expect(passed(lastSecond) == Prayer.allCases)

        let nextDay = day.adding(days: 1)
        let firstSecond = try #require(fixtureTimeline(on: nextDay).phase(at: nextDay.at("00:00", in: .berlin)))
        #expect(firstSecond.highlighted == nil)
        #expect(firstSecond.current?.prayer == .isha)
        #expect(firstSecond.current?.dayOffset == -1)
        #expect(firstSecond.next.dayOffset == 0)
        #expect(passed(firstSecond).isEmpty)
        // Derselbe Augenblick, von beiden Tagen aus gesehen: gleich viel Zeit bis Fadschr.
        #expect(firstSecond.remaining == lastSecond.remaining - 1)
    }

    @Test("jede Phase des Tages nennt das laufende und das nächste Ereignis", arguments: [
        ("00:00", "isha-1|fajr0|000000|-"),
        ("05:15:59", "isha-1|fajr0|000000|-"),
        ("05:16", "fajr0|sunrise0|100000|-"),
        ("07:14", "-|dhuhr0|110000|sunrise"),
        ("11:52", "dhuhr0|asr0|111000|-"),
        ("14:00", "asr0|maghrib0|111100|-"),
        ("16:27", "maghrib0|isha0|111110|-"),
        ("18:17", "isha0|fajr1|111111|-"),
        ("23:59:59", "isha0|fajr1|111111|-"),
    ])
    func keys(time: String, key: String) throws {
        #expect(try phase(time).key(showKerahat: true) == key)
    }

    // MARK: - Andere Städte

    @Test("Jakarta um 17:57 – Maghrib läuft, bis Ischa sind es 72 Minuten")
    func jakarta() throws {
        let phase = try #require(fixtureTimeline(city: "jakarta").phase(at: day.at("17:57", in: .jakarta)))
        #expect(phase.highlighted == .maghrib)
        #expect(phase.next.prayer == .isha)
        #expect(phase.span == minutes(72))
        #expect(phase.remaining == minutes(64))
        #expect(phase.key(showKerahat: true) == "maghrib0|isha0|111110|-")
    }

    @Test("Istanbul um 16:01 – Asr läuft seit 15:36")
    func istanbul() throws {
        let phase = try #require(fixtureTimeline(city: "istanbul").phase(at: day.at("16:01", in: .istanbul)))
        #expect(phase.highlighted == .asr)
        #expect(phase.times.clockTime(of: .asr) == clockTime("15:36"))
        #expect(phase.next.prayer == .maghrib)
        #expect(phase.remaining == minutes(119))
    }

    // MARK: - Hohe Breiten: Ischa nach Mitternacht

    private let summerDay = FixtureTimes.berlinSummer.day

    private func summerPhase(_ time: String, rule: HighLatitudeRule) throws -> DayPhase {
        let timeline = fixtureTimeline(
            on: summerDay, settings: CalculationSettings(highLatitudeRule: rule), highLatitude: true
        )
        return try #require(timeline.phase(at: summerDay.at(time, in: .berlin)))
    }

    @Test("Nachtmitte um 01:08 – Ischa von gestern und Fadschr von heute beginnen zugleich, Fadschr gewinnt")
    func fajrWinsTie() throws {
        let phase = try summerPhase("01:08", rule: .middle)
        #expect(phase.previous.prayer == .fajr)
        #expect(phase.previous.dayOffset == 0)
        #expect(phase.highlighted == .fajr)
        #expect(phase.next.prayer == .sunrise)
        #expect(phase.remaining == minutes(215))
        #expect(phase.key(showKerahat: true) == "fajr0|sunrise0|100000|-")
    }

    @Test("Nachtmitte um 01:07:59 – Maghrib von gestern läuft noch, Ischa kommt in einer Sekunde")
    func beforeTie() throws {
        let phase = try summerPhase("01:07:59", rule: .middle)
        #expect(phase.previous.prayer == .maghrib)
        #expect(phase.previous.dayOffset == -1)
        #expect(phase.highlighted == nil)
        #expect(phase.next.prayer == .isha)
        #expect(phase.next.dayOffset == -1)
        #expect(phase.following.prayer == .fajr)
        #expect(phase.following.dayOffset == 0)
        #expect(phase.following.date == phase.next.date)
        #expect(phase.remaining == 1)
        #expect(phase.key(showKerahat: true) == "maghrib-1|isha-1|000000|-")
    }

    @Test("Nachtmitte um 23:00 – Ischa von heute liegt nach Mitternacht und ist das Nächste")
    func ishaAfterMidnight() throws {
        let phase = try summerPhase("23:00", rule: .middle)
        #expect(phase.highlighted == .maghrib)
        #expect(phase.next.prayer == .isha)
        #expect(phase.next.dayOffset == 0)
        #expect(phase.next.date == summerDay.adding(days: 1).at("01:08", in: .berlin))
        #expect(!phase.isNextTomorrow)
        #expect(phase.remaining == minutes(128))
        #expect(!phase.hasPassed(.isha))
        #expect(phase.key(showKerahat: true) == "maghrib0|isha0|111110|-")
        // Der Gebetstag reicht von 01:08 bis 01:08 am Folgetag.
        #expect(phase.dayProgress == DayPhase.Progress(fraction: 1312.0 / 1440.0, isActive: true))
    }

    @Test("winkelbasiert um 23:47 – Ischa läuft seit 23:35, Fadschr kommt morgen um 02:34")
    func summerAngle() throws {
        let phase = try summerPhase("23:47", rule: .angle)
        #expect(phase.highlighted == .isha)
        #expect(phase.next.prayer == .fajr)
        #expect(phase.isNextTomorrow)
        #expect(phase.remaining == minutes(167))
        #expect(phase.key(showKerahat: true) == "isha0|fajr1|111111|-")
    }

    // MARK: - Zeitumstellung

    @Test("Ende der Sommerzeit am 25.10.2026 – die Nacht ist eine Stunde länger")
    func clocksGoBack() throws {
        let changeDay = calendarDay("2026-10-25")
        let timeline = fixtureTimeline(on: changeDay)

        // 00:30 ist noch Sommerzeit, Fadschr um 05:16 schon Winterzeit: 5 h 46 min, nicht 4 h 46 min.
        let night = try #require(timeline.phase(at: changeDay.at("00:30", in: .berlin)))
        #expect(night.next.prayer == .fajr)
        #expect(night.remaining == minutes(346))
        #expect(night.span == minutes(719))

        let morning = try #require(timeline.phase(at: changeDay.at("03:30", in: .berlin)))
        #expect(morning.remaining == minutes(106))

        let noon = try #require(timeline.phase(at: changeDay.at("12:00", in: .berlin)))
        #expect(noon.highlighted == .dhuhr)
        #expect(noon.dayProgress.fraction == 404.0 / 781.0)

        // Am Vorabend zählt der Countdown die zusätzliche Stunde schon mit.
        let eve = changeDay.adding(days: -1)
        let evening = try #require(fixtureTimeline(on: eve).phase(at: eve.at("23:30", in: .berlin)))
        #expect(evening.isNextTomorrow)
        #expect(evening.remaining == minutes(406))
    }

    @Test("Beginn der Sommerzeit am 28.03.2027 – die Nacht ist eine Stunde kürzer")
    func clocksGoForward() throws {
        let changeDay = calendarDay("2027-03-28")
        let timeline = fixtureTimeline(on: changeDay)

        // 00:30 ist noch Winterzeit, Fadschr um 05:16 schon Sommerzeit: 3 h 46 min, nicht 4 h 46 min.
        let night = try #require(timeline.phase(at: changeDay.at("00:30", in: .berlin)))
        #expect(night.next.prayer == .fajr)
        #expect(night.remaining == minutes(226))
        #expect(night.span == minutes(599))

        let afternoon = try #require(timeline.phase(at: changeDay.at("14:25", in: .berlin)))
        #expect(afternoon.highlighted == .asr)
        #expect(afternoon.remaining == minutes(122))
        #expect(afternoon.dayProgress.fraction == 549.0 / 781.0)

        let eve = changeDay.adding(days: -1)
        let evening = try #require(fixtureTimeline(on: eve).phase(at: eve.at("23:30", in: .berlin)))
        #expect(evening.remaining == minutes(286))
    }

    // MARK: - Minutenkorrektur

    @Test("Minutenkorrekturen verschieben die Phase mit")
    func adjustments() throws {
        let settings = CalculationSettings(adjustments: MinuteAdjustments([.asr: 30]))
        let phase = try #require(fixtureTimeline(settings: settings).phase(at: day.at("14:25", in: .berlin)))
        #expect(phase.highlighted == .dhuhr)
        #expect(phase.next.prayer == .asr)
        #expect(phase.remaining == minutes(5))
    }
}

#endif
