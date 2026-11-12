#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Welche Mitteilungen die App vormerkt – je Ereignis nach seiner Glocke, dazu die Vorab-Erinnerung, im
/// rollierenden Fenster von höchstens 64 (Spec § 3 „Notifications“, § 4, § 6.4; Plan für Phase 8).
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: Fadschr 05:16, Sonnenaufgang 07:14,
/// Dhuhr 11:52, Asr 14:00, Maghrib 16:27, Ischa 18:17. Die Glocken und Einstellungen sind die Startwerte
/// von `S`: alle Gebete mit Ton, Ischa lautlos, Sonnenaufgang aus; Erinnerung 10 Minuten vorher, kurzer
/// Adhan, Stimme 1.
@Suite("Mitteilungen: Plan")
struct NotificationPlannerTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixturePlace("berlin")

    private func plan(
        at time: String, on day: CalendarDay? = nil, place: Place? = nil, zone: TimeZone = .berlin,
        source: any PrayerTimesSource = FixtureTimesSource(), limit: Int = NotificationPlanner.pendingLimit,
        settings: CalculationSettings = CalculationSettings(), bells: [Prayer: BellState] = [:],
        preferences: NotificationPreferences = NotificationPreferences()
    ) -> [PrayerNotification] {
        let planner = NotificationPlanner(source: source, wording: TestWording(), limit: limit)
        return planner.plan(
            at: (day ?? self.day).at(time, in: zone), place: place ?? berlin, cityName: "Berlin",
            settings: settings, bells: bells, preferences: preferences
        )
    }

    /// „reminder maghrib 2026-11-10 16:17“ – Art, Ereignis, Tag des Ereignisses und Uhrzeit in `zone`.
    private func summary(_ notifications: some Sequence<PrayerNotification>, in zone: TimeZone = .berlin) -> [String] {
        notifications.map { "\($0.kind.rawValue) \($0.prayer.rawValue) \($0.day) \(ClockTime($0.date, in: zone))" }
    }

    // MARK: - Startwerte

    @Test("14:25 – zuerst Maghrib mit Erinnerung, dann Ischa lautlos; Asr ist vorbei")
    func startValues() {
        let notifications = plan(at: "14:25")
        #expect(summary(notifications.prefix(14)) == [
            "reminder maghrib 2026-11-10 16:17", "prayer maghrib 2026-11-10 16:27",
            "reminder isha 2026-11-10 18:07", "prayer isha 2026-11-10 18:17",
            "reminder fajr 2026-11-11 05:06", "prayer fajr 2026-11-11 05:16",
            "reminder dhuhr 2026-11-11 11:42", "prayer dhuhr 2026-11-11 11:52",
            "reminder asr 2026-11-11 13:50", "prayer asr 2026-11-11 14:00",
            "reminder maghrib 2026-11-11 16:17", "prayer maghrib 2026-11-11 16:27",
            "reminder isha 2026-11-11 18:07", "prayer isha 2026-11-11 18:17",
        ])
        #expect(notifications.map(\.tone).prefix(6) == [
            .system, .clip("adhan-voice1.caf"), .silent, .silent, .system, .clip("adhan-voice1.caf"),
        ])
    }

    @Test("das Fenster hält 64 Mitteilungen: mit den Startwerten zehn am Tag, bis Ischa am 16.11.")
    func window() {
        let notifications = plan(at: "14:25")
        #expect(notifications.count == 64)
        #expect(summary([notifications[63]]) == ["prayer isha 2026-11-16 18:17"])
        #expect(Set(notifications.map(\.day)).count == 7)
        #expect(!notifications.contains { $0.prayer == .sunrise })
    }

    @Test("ohne Erinnerung fünf am Tag – das Fenster reicht knapp 13 Tage, bis Dhuhr am 23.11.")
    func withoutReminder() {
        let notifications = plan(at: "14:25", preferences: NotificationPreferences(reminderMinutes: 0))
        #expect(notifications.count == 64)
        #expect(notifications.allSatisfy { $0.kind == .prayer })
        #expect(summary([notifications[63]]) == ["prayer dhuhr 2026-11-23 11:52"])
    }

    @Test("alle sechs mit Erinnerung: zwölf am Tag, gut fünf Tage")
    func allSix() {
        let bells = Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, BellState.sound) })
        let notifications = plan(at: "00:00", bells: bells)
        #expect(notifications.count == 64)
        #expect(notifications.filter { $0.day == day }.count == 12)
        #expect(summary([notifications[63]]) == ["prayer sunrise 2026-11-15 07:14"])
    }

    @Test("die Mitteilungen stehen in zeitlicher Folge, jede Kennung gibt es einmal")
    func orderAndIdentifiers() {
        let notifications = plan(at: "14:25")
        #expect(notifications.map(\.date) == notifications.map(\.date).sorted())
        #expect(Set(notifications.map(\.id)).count == notifications.count)
        #expect(notifications[1].id == "prayer.2026-11-10.maghrib")
        #expect(notifications[0].id == "reminder.2026-11-10.maghrib")
    }

    @Test("die Kennung bleibt für dieselbe Mitteilung gleich, auch wenn später neu geplant wird")
    func stableIdentifiers() {
        let early = plan(at: "14:25")
        // Nach der Erinnerung an Maghrib: Am Ende kommt die Erinnerung an Fadschr am 17.11. nicht mit,
        // weil ihre Mitteilung nicht mehr ins Fenster passt.
        let later = plan(at: "16:20")
        #expect(later.map(\.id) == early.dropFirst().map(\.id))
        #expect(later.first?.id == "prayer.2026-11-10.maghrib")
    }

    // MARK: - Texte

    @Test("Titel und Text nennen Gebet, Uhrzeit am Ort, Stadt und Minuten")
    func texts() throws {
        let notifications = plan(at: "11:00")
        let reminder = try #require(notifications.first)
        let prayer = try #require(notifications.dropFirst().first)
        #expect(reminder.title == "dhuhr in 10")
        #expect(reminder.body == "dhuhr um 11:52")
        #expect(prayer.title == "dhuhr · 11:52")
        #expect(prayer.body == "dhuhr in Berlin")
        #expect(reminder.eventDate == prayer.date)
        #expect(prayer.eventDate == prayer.date)
    }

    @Test("die Erinnerung kommt so viele Minuten vorher, wie gewählt", arguments: [5, 15, 20, 30])
    func reminderLead(minutes: Int) throws {
        let notifications = plan(at: "11:00", preferences: NotificationPreferences(reminderMinutes: minutes))
        let reminder = try #require(notifications.first)
        #expect(reminder.kind == .reminder)
        #expect(reminder.date == day.at("11:52", in: .berlin).addingTimeInterval(-TimeInterval(minutes) * 60))
        #expect(reminder.title == "dhuhr in \(minutes)")
    }

    @Test("die Minutenkorrektur verschiebt Mitteilung und Erinnerung (Spec § 4)")
    func adjustments() {
        var settings = CalculationSettings()
        settings.adjustments.step(.dhuhr, by: 2)
        let notifications = plan(at: "11:00", settings: settings)
        #expect(summary(notifications.prefix(2)) == ["reminder dhuhr 2026-11-10 11:44", "prayer dhuhr 2026-11-10 11:54"])
        #expect(notifications[1].title == "dhuhr · 11:54")
        #expect(notifications[0].body == "dhuhr um 11:54")
    }

    @Test("Asr nach hanafitischer Rechnung")
    func hanafiAsr() {
        var settings = CalculationSettings()
        settings.asr = .hanafi
        #expect(summary(plan(at: "14:20", settings: settings).prefix(2)) == [
            "reminder asr 2026-11-10 14:26", "prayer asr 2026-11-10 14:36",
        ])
    }

    // MARK: - Glocken und Töne

    @Test("„Aus“ heißt keine Mitteilung und keine Erinnerung für das Ereignis")
    func offBell() {
        let notifications = plan(at: "14:25", bells: [.maghrib: .off])
        #expect(!notifications.contains { $0.prayer == .maghrib })
        #expect(summary(notifications.prefix(2)) == ["reminder isha 2026-11-10 18:07", "prayer isha 2026-11-10 18:17"])
    }

    @Test("alle Glocken aus – nichts geplant")
    func allOff() {
        let bells = Dictionary(uniqueKeysWithValues: Prayer.allCases.map { ($0, BellState.off) })
        #expect(plan(at: "14:25", bells: bells).isEmpty)
    }

    @Test("„Lautlos“ – Mitteilung und Erinnerung ohne Ton")
    func silentBell() {
        let notifications = plan(at: "14:25", bells: [.maghrib: .silent])
        #expect(notifications.prefix(2).map(\.tone) == [.silent, .silent])
    }

    @Test("der Sonnenaufgang bekommt eine Mitteilung, wenn seine Glocke an ist")
    func sunrise() {
        let notifications = plan(at: "06:00", bells: [.sunrise: .sound])
        #expect(summary(notifications.prefix(2)) == ["reminder sunrise 2026-11-10 07:04", "prayer sunrise 2026-11-10 07:14"])
        #expect(notifications[1].title == "sunrise · 07:14")
    }

    @Test("der Klang gilt für alle Gebete mit „Ton“")
    func sounds() {
        let system = plan(at: "14:25", preferences: NotificationPreferences(sound: .system))
        #expect(system.prefix(2).map(\.tone) == [.system, .system])
        let silent = plan(at: "14:25", preferences: NotificationPreferences(sound: .silent))
        #expect(silent.allSatisfy { $0.tone == .silent })
        let voice2 = plan(at: "14:25", preferences: NotificationPreferences(voice: .two))
        #expect(voice2[1].tone == .clip("adhan-voice2.caf"))
        let voice3 = plan(at: "14:25", preferences: NotificationPreferences(voice: .three))
        #expect(voice3[1].tone == .system)
    }

    @Test("Fadschr spielt den Ausschnitt der gewählten Stimme")
    func fajrTone() {
        let notifications = plan(at: "04:00", preferences: NotificationPreferences(voice: .two))
        #expect(summary([notifications[1]]) == ["prayer fajr 2026-11-10 05:16"])
        #expect(notifications[1].tone == .clip("adhan-voice2.caf"))
    }

    // MARK: - Grenze des Fensters

    @Test("eine Erinnerung ohne ihre Mitteilung bleibt am Ende draußen")
    func reminderNeedsItsPrayer() {
        #expect(summary(plan(at: "14:25", limit: 5)) == [
            "reminder maghrib 2026-11-10 16:17", "prayer maghrib 2026-11-10 16:27",
            "reminder isha 2026-11-10 18:07", "prayer isha 2026-11-10 18:17",
        ])
        #expect(plan(at: "14:25", limit: 6).count == 6)
        #expect(plan(at: "14:25", limit: 0).isEmpty)
    }

    @Test("was jetzt beginnt, ist schon vorbei: um 11:52 kommt als Nächstes Asr")
    func eventAtNow() {
        #expect(summary(plan(at: "11:52").prefix(2)) == ["reminder asr 2026-11-10 13:50", "prayer asr 2026-11-10 14:00"])
        #expect(summary(plan(at: "11:51:59").prefix(1)) == ["prayer dhuhr 2026-11-10 11:52"])
    }

    @Test("liegt die Erinnerung schon zurück, bleibt die Mitteilung")
    func reminderPassed() {
        #expect(summary(plan(at: "11:45").prefix(2)) == ["prayer dhuhr 2026-11-10 11:52", "reminder asr 2026-11-10 13:50"])
    }

    // MARK: - Zeitzonen

    @Test("Jakarta: Tage und Uhrzeiten gelten am Ort, nicht auf dem Gerät")
    func jakarta() {
        let jakarta = fixturePlace("jakarta")
        let local = plan(at: "14:25", place: jakarta, zone: .jakarta)
        #expect(summary(local.prefix(2), in: .jakarta) == ["reminder asr 2026-11-10 14:47", "prayer asr 2026-11-10 14:57"])
        #expect(local[1].title == "asr · 14:57")
        #expect(local[1].date == day.at("14:57", in: .jakarta))

        // 23:30 in Berlin ist in Jakarta schon 05:30 am 11.11.: Fadschr ist dort vorbei.
        let fromBerlin = plan(at: "23:30", place: jakarta, zone: .berlin)
        #expect(summary(fromBerlin.prefix(2), in: .jakarta) == ["reminder dhuhr 2026-11-11 11:29", "prayer dhuhr 2026-11-11 11:39"])
    }

    @Test("Beginn der Sommerzeit: Fadschr am 28.03.2027 kommt um 05:16 Sommerzeit")
    func daylightSavingStart() {
        let saturday = calendarDay("2027-03-27")
        let notifications = plan(at: "20:00", on: saturday)
        #expect(summary(notifications.prefix(2)) == ["reminder fajr 2027-03-28 05:06", "prayer fajr 2027-03-28 05:16"])
        let isha = saturday.at("18:17", in: .berlin)
        #expect(notifications[1].date.timeIntervalSince(isha) == minutes(10 * 60 - 1))
    }

    @Test("Ende der Sommerzeit: zwischen Ischa und Fadschr liegt eine Stunde mehr")
    func daylightSavingEnd() {
        let saturday = calendarDay("2026-10-24")
        let notifications = plan(at: "20:00", on: saturday)
        #expect(summary(notifications.prefix(2)) == ["reminder fajr 2026-10-25 05:06", "prayer fajr 2026-10-25 05:16"])
        let isha = saturday.at("18:17", in: .berlin)
        #expect(notifications[1].date.timeIntervalSince(isha) == minutes(12 * 60 - 1))
    }

    // MARK: - Hohe Breiten und Mitternacht

    @Test("Nachtmitte: Ischa von gestern und Fadschr von heute fallen auf 01:08 – beide kommen")
    func middleOfTheNight() {
        var settings = CalculationSettings()
        settings.highLatitudeRule = .middle
        let summer = FixtureTimes.berlinSummer.day
        let notifications = plan(at: "23:00", on: summer, source: FixtureTimesSource(highLatitude: true), settings: settings)
        #expect(summary(notifications.prefix(4)) == [
            "reminder isha 2027-06-21 00:58", "reminder fajr 2027-06-22 00:58",
            "prayer isha 2027-06-21 01:08", "prayer fajr 2027-06-22 01:08",
        ])
        #expect(notifications[2].id != notifications[3].id)
        #expect(notifications[2].title == "isha · 01:08")
    }

    @Test("nach Mitternacht kommt das Ischa von gestern noch")
    func ishaAfterMidnight() {
        var settings = CalculationSettings()
        settings.highLatitudeRule = .middle
        let next = FixtureTimes.berlinSummer.day.adding(days: 1)
        let notifications = plan(at: "00:30", on: next, source: FixtureTimesSource(highLatitude: true), settings: settings)
        #expect(summary(notifications.prefix(1)) == ["reminder isha 2027-06-21 00:58"])
    }

    @Test("eine Erinnerung vor Mitternacht für ein Fadschr nach Mitternacht")
    func reminderAcrossMidnight() {
        let source = StubTimesSource(times: ["00:05", "06:30", "12:00", "15:00", "18:00", "20:00"])
        #expect(summary(plan(at: "23:50", source: source).prefix(2)) == [
            "reminder fajr 2026-11-11 23:55", "prayer fajr 2026-11-11 00:05",
        ])
        #expect(summary(plan(at: "23:59:59", source: source).prefix(1)) == ["prayer fajr 2026-11-11 00:05"])
    }

    @Test("Tage ohne Zeiten fallen aus, der Plan geht am nächsten Tag weiter")
    func missingDays() {
        let missing: Set = [day.adding(days: 1), day.adding(days: 2)]
        let notifications = plan(at: "14:25", source: StubTimesSource(base: FixtureTimesSource(), missing: missing))
        #expect(notifications.count == 64)
        #expect(!notifications.contains { missing.contains($0.day) })
        #expect(summary(notifications[4...5]) == ["reminder fajr 2026-11-13 05:06", "prayer fajr 2026-11-13 05:16"])
    }

    @Test("Polarnacht in Utqiaġvik: nur Tage mit Zeiten, keine Mitteilung am 1. Januar")
    func polarNight() {
        let source = AdhanTimesSource()
        let place = Place(
            name: "Utqiaġvik", countryCode: "US",
            coordinates: Coordinates(latitude: 71.275009, longitude: -156.761368), timeZoneIdentifier: "America/Anchorage"
        )
        let newYear = calendarDay("2018-01-01")
        let zone = place.timeZone
        #expect(source.times(on: newYear, at: place, settings: CalculationSettings()) == nil)
        let notifications = plan(at: "12:00", on: newYear, place: place, zone: zone, source: source)
        #expect(notifications.allSatisfy { source.times(on: $0.day, at: place, settings: CalculationSettings()) != nil })
        #expect(!notifications.contains { $0.day == newYear })
    }

    @Test("in einer Gegend ohne Zeiten bleibt der Plan leer")
    func noTimesAtAll() {
        let source = StubTimesSource(base: FixtureTimesSource(), missingAll: true)
        #expect(plan(at: "14:25", source: source).isEmpty)
    }
}

// MARK: - Hilfen

/// Texte mit den eingesetzten Werten, ohne String Catalog.
private struct TestWording: NotificationWording {
    func prayerTitle(_ prayer: Prayer, time: ClockTime) -> String { "\(prayer.rawValue) · \(time)" }
    func prayerBody(_ prayer: Prayer, city: String) -> String { "\(prayer.rawValue) in \(city)" }
    func reminderTitle(_ prayer: Prayer, minutes: Int) -> String { "\(prayer.rawValue) in \(minutes)" }
    func reminderBody(_ prayer: Prayer, time: ClockTime) -> String { "\(prayer.rawValue) um \(time)" }
}

/// Feste Uhrzeiten an jedem Tag oder die einer anderen Quelle – an den Tagen in `missing` keine.
private struct StubTimesSource: PrayerTimesSource {
    var base: (any PrayerTimesSource)?
    var times: [String] = []
    var missing: Set<CalendarDay> = []
    var missingAll = false

    init(times: [String]) {
        self.times = times
    }

    init(base: any PrayerTimesSource, missing: Set<CalendarDay> = [], missingAll: Bool = false) {
        self.base = base
        self.missing = missing
        self.missingAll = missingAll
    }

    func times(on day: CalendarDay, at place: Place, settings: CalculationSettings) -> DayTimes? {
        guard !missingAll, !missing.contains(day) else { return nil }
        if let base {
            return base.times(on: day, at: place, settings: settings)
        }
        let dates = times.map { day.at($0, in: place.timeZone) }
        return DayTimes(
            day: day, timeZone: place.timeZone,
            fajr: dates[0], sunrise: dates[1], dhuhr: dates[2], asr: dates[3], maghrib: dates[4], isha: dates[5]
        )
    }
}

#endif
