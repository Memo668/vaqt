import Foundation
import Testing
@testable import PrayerCore

/// Die Verse müssen `VERSES` im Prototyp entsprechen, und die Seite „Verse“ muss am 10.11.2026 dieselbe
/// Folge zeigen wie `versesPage()` (design/screenshots/iphone/50-verses.png).
@Suite("Verse")
struct VerseTests {

    @Test("sechs Verse in der Reihenfolge des Prototyps")
    func list() {
        #expect(Verse.all.map { "\($0.surah):\($0.ayah)" } == ["2:45", "94:5", "13:28", "2:152", "20:14", "2:286"])
        #expect(Set(Verse.all).count == Verse.all.count)
        #expect(Verse.all.allSatisfy { !$0.arabic.isEmpty })
    }

    @Test("der erste Vers auf Arabisch, wie im Prototyp")
    func arabic() {
        #expect(Verse.all[0].arabic == "وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ")
        #expect(Verse.all[1].arabic == "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا")
    }

    @Test("am 10.11.2026 und an den fünf Tagen davor die Folge des Prototyps")
    func referenceDay() {
        let today = calendarDay("2026-11-10")
        let days = Verse.recentDays(endingAt: today)
        #expect(days.map(\.description) == [
            "2026-11-10", "2026-11-09", "2026-11-08", "2026-11-07", "2026-11-06", "2026-11-05",
        ])
        #expect(days.map(Verse.ofDay) == Verse.all)
    }

    @Test("jeden Tag ein anderer Vers; nach dem letzten kommt wieder der erste", arguments: [
        ("2026-11-10", 0), ("2026-11-09", 1), ("2026-11-05", 5), ("2026-11-04", 0),
        ("2026-11-11", 5), ("2026-11-12", 4), ("2026-11-16", 0), ("2026-11-17", 5),
        // 52 Tage nach dem 10.11.2026: 52 = 8 × 6 + 4, also vier Schritte vom Ende her.
        ("2027-01-01", 2), ("2025-11-10", 5),
    ])
    func rotation(day: String, index: Int) {
        #expect(Verse.index(of: calendarDay(day), count: 6) == index)
        #expect(Verse.ofDay(calendarDay(day)) == Verse.all[index])
    }

    @Test("zwei aufeinanderfolgende Tage haben nie denselben Vers")
    func consecutiveDaysDiffer() {
        var day = calendarDay("2026-01-01")
        for _ in 0..<800 {
            let next = day.adding(days: 1)
            #expect(Verse.ofDay(day) != Verse.ofDay(next))
            day = next
        }
    }

    @Test("die Liste „Letzte Tage“ zeigt jeden Vers genau einmal, an jedem Tag")
    func recentDaysShowEveryVerse() {
        var day = calendarDay("2026-12-24")
        for _ in 0..<12 {
            #expect(Set(Verse.recentDays(endingAt: day).map(Verse.ofDay)) == Set(Verse.all))
            day = day.adding(days: 1)
        }
    }

    @Test("die Liste „Letzte Tage“ geht über Monats- und Jahresgrenzen zurück")
    func recentDaysAcrossYears() {
        #expect(Verse.recentDays(endingAt: calendarDay("2027-01-02")).map(\.description) == [
            "2027-01-02", "2027-01-01", "2026-12-31", "2026-12-30", "2026-12-29", "2026-12-28",
        ])
    }
}
