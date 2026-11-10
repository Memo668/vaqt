import Foundation
import Testing
@testable import PrayerCore

@Suite("DayTimes")
struct DayTimesTests {

    private let day = calendarDay("2026-11-10")

    /// Berlin am 10.11.2026 mit den Zeiten des Haupt-Screenshots.
    private var berlin: DayTimes {
        DayTimes(
            day: day, timeZone: .berlin,
            fajr: day.at("05:16", in: .berlin), sunrise: day.at("07:14", in: .berlin),
            dhuhr: day.at("11:52", in: .berlin), asr: day.at("14:00", in: .berlin),
            maghrib: day.at("16:27", in: .berlin), isha: day.at("18:17", in: .berlin)
        )
    }

    @Test("liefert den Zeitpunkt je Ereignis")
    func subscripts() {
        let times = berlin
        #expect(times[.fajr] == times.fajr)
        #expect(times[.sunrise] == times.sunrise)
        #expect(times[.dhuhr] == times.dhuhr)
        #expect(times[.asr] == times.asr)
        #expect(times[.maghrib] == times.maghrib)
        #expect(times[.isha] == times.isha)
        #expect(Prayer.allCases.map { times[$0] } == Prayer.allCases.map { times[$0] }.sorted())
    }

    @Test("zeigt die Uhrzeit am Ort")
    func clockTimes() {
        #expect(Prayer.allCases.map { berlin.clockTime(of: $0).description } == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
    }

    @Test("ein Ischa nach Mitternacht gehört zum Tag und zeigt die Uhrzeit des Folgetags")
    func ishaAfterMidnight() {
        let summer = calendarDay("2027-06-21")
        let times = DayTimes(
            day: summer, timeZone: .berlin,
            fajr: summer.at("01:08", in: .berlin), sunrise: summer.at("04:43", in: .berlin),
            dhuhr: summer.at("13:12", in: .berlin), asr: summer.at("17:33", in: .berlin),
            maghrib: summer.at("21:33", in: .berlin), isha: summer.adding(days: 1).at("01:08", in: .berlin)
        )
        #expect(times.day == summer)
        #expect(times.clockTime(of: .isha) == clockTime("01:08"))
        #expect(times.clockTime(of: .fajr) == clockTime("01:08"))
        #expect(times.isha.timeIntervalSince(times.fajr) == 24 * 3600)
    }

    @Test("derselbe Zeitpunkt zeigt in einer anderen Zeitzone eine andere Uhrzeit")
    func dependsOnTimeZone() {
        let times = berlin
        let elsewhere = DayTimes(
            day: day, timeZone: .jakarta,
            fajr: times.fajr, sunrise: times.sunrise, dhuhr: times.dhuhr, asr: times.asr, maghrib: times.maghrib, isha: times.isha
        )
        #expect(elsewhere.clockTime(of: .asr) == clockTime("20:00"))
        #expect(elsewhere != times)
    }
}
