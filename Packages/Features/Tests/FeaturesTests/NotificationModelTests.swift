#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
import UserNotifications
@testable import Features

/// Die App plant ihre Mitteilungen nach Glocken, Erinnerung, Klang und Ort – nur mit Erlaubnis – und
/// plant neu, wenn sich etwas davon ändert (Plan für Phase 8).
///
/// Gerechnet wird mit den Mock-Zeiten am 10.11.2026 um 14:25 in Berlin, mit den Startwerten von `S`.
@MainActor
@Suite("Mitteilungen planen")
struct NotificationModelTests {

    struct Fixture {
        let settings: SettingsStore
        let model: NotificationModel
        let scheduler: RecordingNotificationScheduler
        let authorizer: ScriptedNotificationAuthorizer
        let clock: TestClock
    }

    private func fixture(
        authorization: NotificationAuthorization = .authorized, answer: NotificationAuthorization = .authorized,
        place: Place? = .berlin, timesSource: any PrayerTimesSource = FixtureTimesSource(),
        time: String = "14:25", language: AppLanguage? = nil
    ) -> Fixture {
        var snapshot = SettingsStore.Snapshot()
        snapshot.autoLocation = false
        snapshot.manualPlace = place
        snapshot.language = language
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let location = PlaceModel(settings: settings, locationSource: FixedLocationSource(place: nil, status: .notDetermined))
        let clock = TestClock(instant("2026-11-10", time))
        let scheduler = RecordingNotificationScheduler()
        let authorizer = ScriptedNotificationAuthorizer(status: authorization, answer: answer)
        let model = NotificationModel(
            settings: settings, location: location, clock: clock, timesSource: timesSource,
            authorizer: authorizer, scheduler: scheduler
        )
        return Fixture(settings: settings, model: model, scheduler: scheduler, authorizer: authorizer, clock: clock)
    }

    // MARK: - Erlaubnis

    @Test("erlaubt: 64 Mitteilungen, die erste ist die Erinnerung an Maghrib")
    func authorized() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        let planned = try #require(fixture.scheduler.calls.last)
        #expect(fixture.scheduler.calls.count == 1)
        #expect(fixture.scheduler.nows == [fixture.clock.now])
        #expect(planned.count == 64)
        #expect(planned == fixture.model.planned)
        #expect(fixture.model.authorization == .authorized)

        let reminder = planned[0]
        let prayer = planned[1]
        #expect(reminder.title == L10n.notifReminderTitle(p: L10n.p_maghrib, n: "10"))
        #expect(reminder.body == L10n.notifReminderBody(p: L10n.p_maghrib, time: "16:27"))
        #expect(prayer.title == L10n.notifPrayerTitle(p: L10n.p_maghrib, time: "16:27"))
        #expect(prayer.body == L10n.notifPrayerBody(p: L10n.p_maghrib, city: "Berlin"))
        #expect(prayer.date == instant("2026-11-10", "16:27"))
    }

    @Test("verweigert oder nicht gefragt: nichts geplant, Ausstehendes gelöscht", arguments: [
        NotificationAuthorization.denied, .notDetermined,
    ])
    func notAuthorized(status: NotificationAuthorization) async {
        let fixture = fixture(authorization: status)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.calls == [[]])
        #expect(fixture.model.planned.isEmpty)
        #expect(fixture.model.authorization == status)
    }

    @Test("ohne Ort nichts geplant")
    func withoutPlace() async {
        let fixture = fixture(place: nil)
        await fixture.model.reschedule()
        #expect(fixture.scheduler.calls == [[]])
    }

    @Test("„Mitteilungen erlauben“: fragt einmal und plant gleich")
    func requestAuthorization() async {
        let fixture = fixture(authorization: .notDetermined)
        #expect(await fixture.model.requestAuthorization() == .authorized)
        #expect(await fixture.authorizer.requests == 1)
        #expect(fixture.scheduler.calls.last?.count == 64)
    }

    @Test("nach „Später“: Die erste Änderung fragt; ist schon geantwortet, fragt sie nicht", arguments: [
        (NotificationAuthorization.notDetermined, 1), (.denied, 0), (.authorized, 0),
    ])
    func requestIfNeverAsked(status: NotificationAuthorization, requests: Int) async {
        let fixture = fixture(authorization: status)
        await fixture.model.requestIfNeverAsked()
        #expect(await fixture.authorizer.requests == requests)
        #expect(fixture.scheduler.calls.count == requests)
    }

    @Test("-debugNotifications beim Start: Zugestelltes abräumen, dann fragen und planen")
    func debugRun() async {
        let fixture = fixture(authorization: .notDetermined)
        await fixture.model.prepareDebugRun()
        #expect(fixture.scheduler.removals == 1)
        #expect(await fixture.authorizer.requests == 1)
        #expect(fixture.scheduler.calls.last?.count == 64)
    }

    @Test("abgelehnt beim Fragen: nichts geplant")
    func requestDenied() async {
        let fixture = fixture(authorization: .notDetermined, answer: .denied)
        await fixture.model.requestIfNeverAsked()
        #expect(fixture.scheduler.calls == [[]])
        #expect(fixture.model.authorization == .denied)
    }

    // MARK: - Glocken und Klang

    @Test("„Aus“ – keine Mitteilung und keine Erinnerung für Maghrib")
    func off() async {
        let fixture = fixture()
        fixture.settings.setBell(.off, for: .maghrib)
        await fixture.model.reschedule()
        #expect(!fixture.model.planned.contains { $0.prayer == .maghrib })
        #expect(fixture.model.planned.first?.id == "reminder.2026-11-10.isha")
    }

    @Test("„Lautlos“ – Ischa ohne Ton, auch bei iOS")
    func silent() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        let isha = try #require(fixture.model.planned.first { $0.id == "prayer.2026-11-10.isha" })
        #expect(isha.tone == .silent)
        let request = try #require(SystemNotificationScheduler.request(for: isha, now: fixture.clock.now))
        #expect(request.content.sound == nil)
    }

    @Test("Klang und Stimme wirken auf den Ton")
    func sound() async {
        let fixture = fixture()
        fixture.settings.updateNotifications { $0.voice = .two }
        await fixture.model.reschedule()
        #expect(fixture.model.planned[1].tone == .clip("adhan-voice2.caf"))
        fixture.settings.updateNotifications { $0.sound = .system }
        await fixture.model.reschedule()
        #expect(fixture.model.planned[1].tone == .system)
    }

    // MARK: - Neu planen

    @Test("Wechsel der Stadt: neu geplant, mit Zeiten und Namen von Istanbul")
    func cityChange() async throws {
        let fixture = fixture()
        await fixture.model.reschedule()
        let before = fixture.model.inputs
        fixture.settings.select(.istanbul)
        #expect(fixture.model.inputs != before)
        await fixture.model.reschedule()
        // 14:25 in Berlin ist 16:25 in Istanbul: Asr (15:36) ist vorbei, Maghrib kommt um 18:00.
        let prayer = try #require(fixture.model.planned.dropFirst().first)
        #expect(prayer.title == L10n.notifPrayerTitle(p: L10n.p_maghrib, time: "18:00"))
        #expect(prayer.body == L10n.notifPrayerBody(p: L10n.p_maghrib, city: "Istanbul"))
        #expect(fixture.scheduler.calls.count == 2)
    }

    @Test("Wechsel der Methode: neu geplant mit den neuen Zeiten (Dhuhr 11:55 Diyanet, 11:51 MWL)")
    func methodChange() async throws {
        let fixture = fixture(timesSource: AdhanTimesSource(), time: "10:00")
        await fixture.model.reschedule()
        let diyanet = try #require(fixture.model.planned.first { $0.kind == .prayer })
        #expect(diyanet.title == L10n.notifPrayerTitle(p: L10n.p_dhuhr, time: "11:55"))

        let before = fixture.model.inputs
        fixture.settings.updateCalculation { $0.method = .mwl }
        #expect(fixture.model.inputs != before)
        await fixture.model.reschedule()
        let mwl = try #require(fixture.model.planned.first { $0.kind == .prayer })
        #expect(mwl.title == L10n.notifPrayerTitle(p: L10n.p_dhuhr, time: "11:51"))
    }

    @Test("die Minutenkorrektur gilt auch für die Mitteilungen")
    func adjustment() async {
        let fixture = fixture()
        fixture.settings.updateCalculation { $0.adjustments.step(.maghrib, by: -3) }
        await fixture.model.reschedule()
        #expect(fixture.model.planned[1].title == L10n.notifPrayerTitle(p: L10n.p_maghrib, time: "16:24"))
    }

    @Test("was eingeht: Ort, Rechnung, Glocken, Erinnerung, Klang, Stimme und Sprache")
    func inputs() {
        let fixture = fixture()
        var last = fixture.model.inputs
        func changed() -> Bool {
            defer { last = fixture.model.inputs }
            return fixture.model.inputs != last
        }
        fixture.settings.setBell(.silent, for: .fajr)
        #expect(changed())
        fixture.settings.updateNotifications { $0.reminderMinutes = 5 }
        #expect(changed())
        fixture.settings.updateNotifications { $0.sound = .silent }
        #expect(changed())
        fixture.settings.updateNotifications { $0.voice = .three }
        #expect(changed())
        fixture.settings.updateCalculation { $0.asr = .hanafi }
        #expect(changed())
        fixture.settings.updateCalculation { $0.highLatitudeRule = .seventh }
        #expect(changed())
        fixture.settings.select(.istanbul)
        #expect(changed())
        fixture.settings.setShowKerahat(false)
        #expect(!changed())

        // Die Sprache: zwei sonst gleiche Einstellungen, eine auf Türkisch.
        #expect(self.fixture(language: .tr).model.inputs != self.fixture().model.inputs)
    }

    @Test("nach einer Änderung an Glocke, Erinnerung, Live-Aktivität oder Klang fragt die App – nicht nach der Stimme")
    func choices() {
        let fixture = fixture()
        var last = fixture.model.choices
        func changed() -> Bool {
            defer { last = fixture.model.choices }
            return fixture.model.choices != last
        }
        fixture.settings.cycleBell(for: .dhuhr)
        #expect(changed())
        fixture.settings.updateNotifications { $0.reminderMinutes = 15 }
        #expect(changed())
        fixture.settings.updateNotifications { $0.liveActivityMinutes = 60 }
        #expect(changed())
        fixture.settings.updateNotifications { $0.sound = .system }
        #expect(changed())
        fixture.settings.updateNotifications { $0.voice = .two }
        #expect(!changed())
    }

    // MARK: - Anfrage an iOS

    @Test("die Anfrage an iOS: Kennung, Texte, Ton und Abstand von der App-Uhr")
    func systemRequest() throws {
        let now = instant("2026-11-10", "14:25")
        let notification = PrayerNotification(
            kind: .prayer, prayer: .dhuhr, day: day("2026-11-10"), date: now.addingTimeInterval(600), eventDate: now.addingTimeInterval(600),
            title: "Dhuhr · 11:52", body: "Zeit für Dhuhr in Berlin.", tone: .clip("adhan-voice1.caf")
        )
        let request = try #require(SystemNotificationScheduler.request(for: notification, now: now))
        #expect(request.identifier == "prayer.2026-11-10.dhuhr")
        #expect(request.content.title == "Dhuhr · 11:52")
        #expect(request.content.body == "Zeit für Dhuhr in Berlin.")
        #expect(request.content.interruptionLevel == .active)
        #expect(request.content.sound != nil)
        let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(trigger.timeInterval == 600)
        #expect(!trigger.repeats)
    }

    @Test("was nicht mehr in der Zukunft liegt, geht nicht an iOS")
    func requestTooLate() {
        let now = instant("2026-11-10", "14:25")
        for lead in [-60.0, 0, 0.5] {
            let notification = PrayerNotification(
                kind: .reminder, prayer: .asr, day: day("2026-11-10"), date: now.addingTimeInterval(lead), eventDate: now,
                title: "", body: "", tone: .system
            )
            #expect(SystemNotificationScheduler.request(for: notification, now: now) == nil)
        }
    }

    @Test("die Töne für iOS: keiner, der des Systems, eine Aufnahme")
    func sounds() {
        #expect(SystemNotificationScheduler.sound(for: .silent) == nil)
        #expect(SystemNotificationScheduler.sound(for: .system) == .default)
        #expect(SystemNotificationScheduler.sound(for: .clip("adhan-voice1.caf")) == UNNotificationSound(named: UNNotificationSoundName("adhan-voice1.caf")))
    }

    // MARK: - Hintergrund

    @Test("die Hintergrundaktualisierung plant ohne Oberfläche, mit dem Ort aus den Einstellungen")
    func backgroundRefresh() async {
        var snapshot = SettingsStore.Snapshot()
        snapshot.autoLocation = false
        snapshot.manualPlace = .berlin
        // Dieselbe Sprache wie gerade, damit der Lauf die Texte anderer Tests nicht umstellt.
        snapshot.language = L10n.chosenLanguage
        let scheduler = RecordingNotificationScheduler()
        let environment = AppEnvironment(
            clock: FixedClock(instant("2026-11-10", "14:25")),
            locationSource: FixedLocationSource(place: nil, status: .denied),
            timesSource: FixtureTimesSource(), settings: .ephemeral(snapshot),
            notificationAuthorizer: FixedNotificationAuthorizer(status: .authorized),
            notificationScheduler: scheduler
        )
        let planned = await BackgroundRefresh.reschedule(environment: environment)
        #expect(planned.count == 64)
        #expect(planned.first?.id == "reminder.2026-11-10.maghrib")
        #expect(scheduler.calls == [planned])
    }

    @Test("die Kennung der Hintergrundaktualisierung ist die Bundle-ID mit „.refresh“")
    func backgroundIdentifier() {
        #expect(BackgroundRefresh.identifier.hasSuffix(".refresh"))
        #expect(BackgroundRefresh.earliestDelay == 12 * 60 * 60)
    }
}

#endif
