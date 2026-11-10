import Foundation
import Testing
@testable import PrayerCore

@Suite("PrayerTimeline")
struct PrayerTimelineTests {

    private let source = AdhanTimesSource()
    private let day = calendarDay("2026-11-10")

    /// Sechs Zeiten eines Tages in Berlin aus Uhrzeiten; Ischa darf mit `ishaDayOffset` auf dem Folgetag liegen.
    private func times(
        on day: CalendarDay, _ clockTimes: [String] = ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"],
        ishaDayOffset: Int = 0
    ) -> DayTimes {
        DayTimes(
            day: day, timeZone: .berlin,
            fajr: day.at(clockTimes[0], in: .berlin), sunrise: day.at(clockTimes[1], in: .berlin),
            dhuhr: day.at(clockTimes[2], in: .berlin), asr: day.at(clockTimes[3], in: .berlin),
            maghrib: day.at(clockTimes[4], in: .berlin),
            isha: day.adding(days: ishaDayOffset).at(clockTimes[5], in: .berlin)
        )
    }

    private func timeline(around day: CalendarDay) -> PrayerTimeline {
        PrayerTimeline(
            yesterday: times(on: day.adding(days: -1)), today: times(on: day), tomorrow: times(on: day.adding(days: 1))
        )
    }

    // MARK: - Aufbau

    @Test("der Zeitstrahl hat 18 Ereignisse in der Folge der Tage")
    func events() {
        let events = timeline(around: day).events
        #expect(events.count == 18)
        #expect(events.map(\.dayOffset) == [-1, 0, 1].flatMap { Array(repeating: $0, count: 6) })
        #expect(events.map(\.prayer) == Prayer.allCases + Prayer.allCases + Prayer.allCases)
        #expect(events.map(\.date) == events.map(\.date).sorted())
        #expect(events[6].date == day.at("05:16", in: .berlin))
    }

    @Test("die Quelle baut den Zeitstrahl um einen Tag")
    func fromSource() throws {
        let timeline = try #require(source.timeline(around: day, at: .berlin, settings: CalculationSettings()))
        #expect(timeline.yesterday.day == calendarDay("2026-11-09"))
        #expect(timeline.today.day == day)
        #expect(timeline.tomorrow.day == calendarDay("2026-11-11"))
        #expect(timeline.today == source.times(on: day, at: .berlin, settings: CalculationSettings()))
    }

    @Test("der Zeitstrahl zu einem Zeitpunkt gilt für den Tag am Ort")
    func atInstant() throws {
        // 23:30 in Berlin ist in Jakarta schon der nächste Tag.
        let now = day.at("23:30", in: .berlin)
        let berlin = try #require(source.timeline(at: now, place: .berlin, settings: CalculationSettings()))
        #expect(berlin.today.day == day)
        #expect(berlin.covers(now))

        let jakarta = Place(
            name: "Jakarta", countryCode: "ID",
            coordinates: Coordinates(latitude: -6.2088, longitude: 106.8456), timeZoneIdentifier: "Asia/Jakarta"
        )
        let timeline = try #require(source.timeline(at: now, place: jakarta, settings: CalculationSettings()))
        #expect(timeline.today.day == calendarDay("2026-11-11"))
        #expect(timeline.covers(now))
    }

    @Test("ohne Zeiten für einen der drei Tage gibt es keinen Zeitstrahl")
    func missingDay() {
        // Utqiaġvik, Alaska: Anfang Januar geht die Sonne nicht auf.
        let place = Place(
            name: "Utqiaġvik", countryCode: "US",
            coordinates: Coordinates(latitude: 71.275009, longitude: -156.761368), timeZoneIdentifier: "America/Anchorage"
        )
        #expect(source.timeline(around: calendarDay("2018-01-01"), at: place, settings: CalculationSettings()) == nil)
    }

    // MARK: - Geltung

    @Test("ein Zeitstrahl gilt nur für seinen Tag")
    func covers() {
        let timeline = timeline(around: day)
        #expect(timeline.covers(day.at("00:00", in: .berlin)))
        #expect(timeline.covers(day.at("23:59:59", in: .berlin)))
        #expect(!timeline.covers(day.adding(days: -1).at("23:59:59", in: .berlin)))
        #expect(!timeline.covers(day.adding(days: 1).at("00:00", in: .berlin)))

        #expect(timeline.phase(at: day.at("12:00", in: .berlin)) != nil)
        #expect(timeline.phase(at: day.adding(days: 1).at("00:00", in: .berlin)) == nil)
        #expect(timeline.phase(at: day.adding(days: -1).at("23:59:59", in: .berlin)) == nil)
    }

    @Test("schließen die Zeiten den Zeitpunkt nicht ein, gibt es keine Phase")
    func timesDoNotBracketNow() {
        // Drei Tage mit Zeiten, die alle in der Zukunft liegen: Kein Ereignis hat begonnen.
        let later = day.adding(days: 10)
        let future = PrayerTimeline(
            yesterday: DayTimes(
                day: day.adding(days: -1), timeZone: .berlin,
                fajr: later.at("05:16", in: .berlin), sunrise: later.at("07:14", in: .berlin),
                dhuhr: later.at("11:52", in: .berlin), asr: later.at("14:00", in: .berlin),
                maghrib: later.at("16:27", in: .berlin), isha: later.at("18:17", in: .berlin)
            ),
            today: DayTimes(
                day: day, timeZone: .berlin,
                fajr: later.at("05:16", in: .berlin), sunrise: later.at("07:14", in: .berlin),
                dhuhr: later.at("11:52", in: .berlin), asr: later.at("14:00", in: .berlin),
                maghrib: later.at("16:27", in: .berlin), isha: later.at("18:17", in: .berlin)
            ),
            tomorrow: times(on: later.adding(days: 1))
        )
        #expect(future.covers(day.at("12:00", in: .berlin)))
        #expect(future.phase(at: day.at("12:00", in: .berlin)) == nil)

        // Drei Tage mit Zeiten, die alle vorbei sind: Es gibt kein nächstes Ereignis.
        let past = PrayerTimeline(
            yesterday: times(on: day.adding(days: -12)), today: times(on: day.adding(days: -11)),
            tomorrow: times(on: day.adding(days: -10))
        )
        #expect(past.phase(at: day.adding(days: -11).at("12:00", in: .berlin)) != nil)
        let stale = PrayerTimeline(
            yesterday: times(on: day.adding(days: -12)),
            today: DayTimes(
                day: day, timeZone: .berlin,
                fajr: day.adding(days: -11).at("05:16", in: .berlin), sunrise: day.adding(days: -11).at("07:14", in: .berlin),
                dhuhr: day.adding(days: -11).at("11:52", in: .berlin), asr: day.adding(days: -11).at("14:00", in: .berlin),
                maghrib: day.adding(days: -11).at("16:27", in: .berlin), isha: day.adding(days: -11).at("18:17", in: .berlin)
            ),
            tomorrow: times(on: day.adding(days: -10))
        )
        #expect(stale.covers(day.at("12:00", in: .berlin)))
        #expect(stale.phase(at: day.at("12:00", in: .berlin)) == nil)
    }

    // MARK: - Reihenfolge der Ereignisse

    @Test("liegt Ischa von gestern hinter Fadschr von heute, läuft trotzdem Fadschr")
    func ishaAfterNextFajr() throws {
        // Wie bei „Nachtmitte“ nach der Sonnenwende: Ischa 01:12 (am Folgetag), Fadschr 01:11.
        let summer = calendarDay("2027-07-11")
        let clockTimes = ["01:11", "04:56", "13:15", "17:33", "21:27", "01:12"]
        let timeline = PrayerTimeline(
            yesterday: times(on: summer.adding(days: -1), clockTimes, ishaDayOffset: 1),
            today: times(on: summer, clockTimes, ishaDayOffset: 1),
            tomorrow: times(on: summer.adding(days: 1), clockTimes, ishaDayOffset: 1)
        )
        #expect(timeline.yesterday.isha > timeline.today.fajr)

        let before = try #require(timeline.phase(at: summer.at("01:10", in: .berlin)))
        #expect(before.previous.prayer == .maghrib)
        #expect(before.previous.dayOffset == -1)
        #expect(before.next.prayer == .isha)
        #expect(before.next.dayOffset == -1)
        #expect(before.remaining == minutes(2))

        // Fadschr hat begonnen, Ischa von gestern noch nicht: Fadschr läuft, das Nächste ist der Sonnenaufgang.
        let between = try #require(timeline.phase(at: summer.at("01:11:30", in: .berlin)))
        #expect(between.highlighted == .fajr)
        #expect(between.next.prayer == .sunrise)
        #expect(between.remaining > 0)
        #expect(between.span > 0)

        // Beide haben begonnen: Es bleibt bei Fadschr, Ischa von gestern übernimmt nicht.
        for time in ["01:12", "01:12:30", "03:00", "04:55:59"] {
            let phase = try #require(timeline.phase(at: summer.at(time, in: .berlin)))
            #expect(phase.highlighted == .fajr, "\(time)")
            #expect(phase.next.prayer == .sunrise, "\(time)")
            #expect(phase.key(showKerahat: true) == "fajr0|sunrise0|100000|-", "\(time)")
        }
    }

    @Test("echte Rechnung, Berlin im Juli mit Nachtmitte: Fadschr läuft bis zum Sonnenaufgang")
    func ishaAfterNextFajrComputed() throws {
        let summer = calendarDay("2027-07-11")
        let settings = CalculationSettings(highLatitudeRule: .middle)
        let timeline = try #require(source.timeline(around: summer, at: .berlin, settings: settings))
        #expect(timeline.today.clockTime(of: .fajr) == clockTime("01:11"))
        #expect(timeline.yesterday.clockTime(of: .isha) == clockTime("01:12"))
        #expect(timeline.yesterday.isha.timeIntervalSince(timeline.today.fajr) == minutes(1))

        let phase = try #require(timeline.phase(at: summer.at("03:00", in: .berlin)))
        #expect(phase.highlighted == .fajr)
        #expect(phase.next.prayer == .sunrise)
        #expect(phase.next.dayOffset == 0)
    }

    // MARK: - Echte Rechnung

    @Test("echte Rechnung, Berlin am 10.11.2026 um 14:25: Asr läuft seit 13:55")
    func computedPhase() throws {
        let now = day.at("14:25", in: .berlin)
        let timeline = try #require(source.timeline(at: now, place: .berlin, settings: CalculationSettings()))
        let phase = try #require(timeline.phase(at: now))
        #expect(phase.highlighted == .asr)
        #expect(phase.next.prayer == .maghrib)
        #expect(phase.remaining == minutes(116))
        #expect(phase.dayProgress.fraction == 544.0 / 772.0)
        #expect(phase.key(showKerahat: true) == "asr0|maghrib0|111100|-")
    }

    @Test("echte Rechnung am Tag der Zeitumstellung: Der Countdown zählt echte Zeit")
    func computedClockChange() throws {
        let changeDay = calendarDay("2026-10-25")
        let timeline = try #require(source.timeline(around: changeDay, at: .berlin, settings: CalculationSettings()))
        // 00:30 Sommerzeit bis Fadschr um 04:55 Winterzeit: 5 h 25 min.
        let night = try #require(timeline.phase(at: changeDay.at("00:30", in: .berlin)))
        #expect(night.next.prayer == .fajr)
        #expect(night.remaining == minutes(325))

        let noon = try #require(timeline.phase(at: changeDay.at("12:00", in: .berlin)))
        #expect(noon.highlighted == .dhuhr)
        #expect(noon.times.clockTime(of: .dhuhr) == clockTime("11:51"))
    }

    // MARK: - Tagesfortschritt

    @Test("fallen Fadschr und Ischa zusammen, gibt es keinen Fortschritt")
    func degenerateDay() throws {
        let odd = DayTimes(
            day: day, timeZone: .berlin,
            fajr: day.at("05:16", in: .berlin), sunrise: day.at("07:14", in: .berlin),
            dhuhr: day.at("11:52", in: .berlin), asr: day.at("14:00", in: .berlin),
            maghrib: day.at("16:27", in: .berlin), isha: day.at("05:16", in: .berlin)
        )
        let timeline = PrayerTimeline(yesterday: times(on: day.adding(days: -1)), today: odd, tomorrow: times(on: day.adding(days: 1)))
        let phase = try #require(timeline.phase(at: day.at("12:00", in: .berlin)))
        #expect(phase.dayProgress == DayPhase.Progress(fraction: 0, isActive: false))
    }

    @Test("der Fortschritt läuft von Fadschr bis Ischa und bleibt an den Enden stehen", arguments: [
        ("05:15:59", 0.0, false),
        ("05:16:00", 0.0, false),
        ("05:16:01", 1.0 / 46860.0, true),
        ("11:46:30", 0.5, true),
        ("18:16:59", 46859.0 / 46860.0, true),
        ("18:17:00", 1.0, false),
        ("22:00:00", 1.0, false),
    ])
    func progress(time: String, fraction: Double, isActive: Bool) throws {
        let phase = try #require(timeline(around: day).phase(at: day.at(time, in: .berlin)))
        #expect(phase.dayProgress == DayPhase.Progress(fraction: fraction, isActive: isActive))
    }
}
