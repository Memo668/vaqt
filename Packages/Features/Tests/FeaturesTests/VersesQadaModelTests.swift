#if DEBUG

import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Die Seite „Verse“: welcher Tag heute ist, welcher Vers oben steht, Kopieren und der Wechsel um
/// Mitternacht am Ort.
@MainActor
@Suite("VersesModel")
struct VersesModelTests {

    private struct Fixture {
        let model: VersesModel
        let clock: TestClock
        let toast: ToastCenter
        let copied: Copied
        let settings: SettingsStore
    }

    /// Was in die Zwischenablage gelegt wurde.
    @MainActor
    final class Copied {
        var texts: [String] = []
    }

    private func make(now: Date = instant("2026-11-10", "14:25"), place: Place? = .berlin) -> Fixture {
        let clock = TestClock(now)
        var snapshot = SettingsStore.Snapshot()
        snapshot.devicePlace = place
        let settings = SettingsStore(storage: .ephemeral(snapshot))
        let location = PlaceModel(
            settings: settings, locationSource: FixedLocationSource(place: place, status: .authorized)
        )
        let toast = ToastCenter(duration: .seconds(60))
        let copied = Copied()
        let model = VersesModel(
            clock: clock, location: location, toast: toast, locale: Locale(identifier: "de_DE"),
            deviceTimeZone: .gmt, copyToPasteboard: { copied.texts.append($0) }
        )
        return Fixture(model: model, clock: clock, toast: toast, copied: copied, settings: settings)
    }

    @Test("iphone/50: am 10.11.2026 steht oben der Vers des Tages, darunter sechs Tage")
    func referenceDay() {
        let model = make().model
        #expect(model.today == day("2026-11-10"))
        #expect(model.shownDay == day("2026-11-10"))
        #expect(model.shown.cardTitle == L10n.verseToday)
        #expect(model.shown.shortDate == "10. Nov.")
        #expect(model.shown.verse == Verse.all[0])
        #expect(model.recent.map(\.day) == Verse.recentDays(endingAt: day("2026-11-10")))
        #expect(model.recent.map(\.verse) == Verse.all)
    }

    @Test("Antippen eines Eintrags zeigt seinen Vers oben; heute antippen zeigt wieder den Vers des Tages")
    func select() {
        let model = make().model
        model.select(day("2026-11-08"))
        #expect(model.shownDay == day("2026-11-08"))
        #expect(model.shown.verse == Verse.all[2])
        #expect(model.shown.cardTitle == "Sonntag")
        model.select(day("2026-11-10"))
        #expect(model.pickedDay == nil)
        #expect(model.shown.cardTitle == L10n.verseToday)
    }

    @Test("Kopieren legt Arabisch, Übersetzung und Quelle in die Zwischenablage und zeigt „Kopiert“")
    func copy() {
        let fixture = make()
        fixture.model.select(day("2026-11-09"))
        fixture.model.copyShownVerse()
        #expect(fixture.copied.texts == [Verse.all[1].shareText])
        #expect(fixture.toast.message?.text == L10n.copied)
        #expect(fixture.toast.message?.systemImage == "square.on.square")
    }

    @Test("der Tag ist der am Ort: 23:30 in Berlin ist in Jakarta schon morgen")
    func dayAtPlace() {
        let berlin = make(now: instant("2026-11-10", "23:30")).model
        #expect(berlin.today == day("2026-11-10"))
        let jakartaPlace = Place(
            name: "Jakarta", countryCode: "ID",
            coordinates: Coordinates(latitude: -6.2088, longitude: 106.8456), timeZoneIdentifier: "Asia/Jakarta"
        )
        let jakarta = make(now: instant("2026-11-10", "23:30"), place: jakartaPlace).model
        #expect(jakarta.today == day("2026-11-11"))
    }

    @Test("ohne Ort gilt die Zeitzone des Geräts")
    func dayWithoutPlace() {
        let model = make(now: instant("2026-11-10", "00:30"), place: nil).model
        // 00:30 in Berlin ist 23:30 GMT am Vortag.
        #expect(model.today == day("2026-11-09"))
    }

    @Test("um Mitternacht kommt der nächste Vers; ein angetippter Tag bleibt gewählt")
    func midnight() {
        let fixture = make(now: instant("2026-11-10", "23:59"))
        let model = fixture.model
        model.select(day("2026-11-09"))
        fixture.clock.now = instant("2026-11-11", "00:01")
        model.refresh()
        #expect(model.today == day("2026-11-11"))
        #expect(model.recent.first?.verse == Verse.ofDay(day("2026-11-11")))
        #expect(model.shownDay == day("2026-11-09"))
        #expect(model.shown.cardTitle == "Montag")
    }

    @Test("fällt der angetippte Tag aus der Liste, steht wieder der Vers des Tages oben")
    func pickedDayExpires() {
        let fixture = make()
        let model = fixture.model
        model.select(day("2026-11-05"))
        fixture.clock.now = instant("2026-11-11", "08:00")
        model.refresh()
        #expect(model.pickedDay == nil)
        #expect(model.shownDay == day("2026-11-11"))
    }

    @Test("run() wacht kurz nach Mitternacht auf und liest den neuen Tag")
    func runWakesAtMidnight() async {
        let midnight = instant("2026-11-11", "00:00")
        let fixture = make(now: midnight.addingTimeInterval(-0.3))
        let task = Task { await fixture.model.run() }
        try? await Task.sleep(for: .seconds(0.1))
        #expect(fixture.model.today == day("2026-11-10"))
        // Die Aufgabe schläft bis 0,5 s nach Mitternacht; bis dahin ist es auf der Uhr schon der 11.
        fixture.clock.now = midnight.addingTimeInterval(0.1)
        try? await Task.sleep(for: .seconds(1.2))
        task.cancel()
        #expect(fixture.model.today == day("2026-11-11"))
    }
}

/// Die Seite „Nachholen“: Speichern, Aktionen, Toast und der Tag für den Plan.
@MainActor
@Suite("QadaModel")
struct QadaModelTests {

    private func make(
        storage: QadaModel.Storage = .ephemeral(QadaLedger()), now: Date = instant("2026-11-10", "14:25")
    ) -> (model: QadaModel, toast: ToastCenter) {
        var snapshot = SettingsStore.Snapshot()
        snapshot.devicePlace = .berlin
        let location = PlaceModel(
            settings: SettingsStore(storage: .ephemeral(snapshot)),
            locationSource: FixedLocationSource(place: .berlin, status: .authorized)
        )
        let toast = ToastCenter(duration: .seconds(60))
        let model = QadaModel(
            storage: storage, clock: TestClock(now), location: location, toast: toast,
            locale: Locale(identifier: "de_DE"), deviceTimeZone: .gmt
        )
        return (model, toast)
    }

    /// Eine eigene Ablage für jeden Test, damit sich die Tests nicht in die Quere kommen.
    private func withDefaults(_ body: (String) -> Void) {
        let suite = "QadaModelTests." + UUID().uuidString
        body(suite)
        UserDefaults().removePersistentDomain(forName: suite)
    }

    @Test("die App startet leer: ohne Einträge keine Zusammenfassung")
    func startsEmpty() {
        withDefaults { suite in
            let model = make(storage: .userDefaults(suiteName: suite)).model
            #expect(model.ledger == QadaLedger())
            #expect(!model.ledger.hasEntries)
        }
    }

    @Test("mit -debugFixtureTimes die Zahlen des Prototyps (iphone/60)")
    func sample() {
        let model = make(storage: .ephemeral(.prototypeSample)).model
        #expect(model.ledger.totalCount == 2725)
        #expect(model.ledger.openCount == 2592)
        #expect(model.today == day("2026-11-10"))
    }

    @Test("jede Änderung wird gespeichert und ist beim nächsten Start wieder da")
    func persists() {
        withDefaults { suite in
            let first = make(storage: .userDefaults(suiteName: suite)).model
            first.perform(.step(.years, by: 1))
            first.perform(.setWitr(true))
            first.perform(.applyPeriod)
            first.perform(.markMadeUp(.fajr))
            first.perform(.step(.perDay, by: 2))

            let second = make(storage: .userDefaults(suiteName: suite)).model
            #expect(second.ledger == first.ledger)
            #expect(second.ledger.openCount(of: .fajr) == 364)
            #expect(second.ledger.totalCount(of: .witr) == 365)
            #expect(second.ledger[.perDay] == 7)
        }
    }

    @Test("ein beschädigter Eintrag ergibt einen leeren Stand")
    func damagedEntry() {
        withDefaults { suite in
            UserDefaults(suiteName: suite)?.set(Data("kein JSON".utf8), forKey: QadaModel.key)
            #expect(make(storage: .userDefaults(suiteName: suite)).model.ledger == QadaLedger())
        }
    }

    @Test("im Speicher bleibt nichts liegen: ein neuer Start beginnt wieder beim Startwert")
    func ephemeral() {
        let first = make(storage: .ephemeral(.prototypeSample)).model
        first.perform(.applyPeriod)
        #expect(make(storage: .ephemeral(.prototypeSample)).model.ledger == .prototypeSample)
    }

    @Test("„Als offen übernehmen“ ersetzt die Zahlen und nennt sie im Toast")
    func apply() {
        let (model, toast) = make(storage: .ephemeral(.prototypeSample))
        model.perform(.applyPeriod)
        #expect(model.ledger.openCount == 2725)
        #expect(model.ledger.doneCount == 0)
        #expect(toast.message?.text == L10n.qadaApplied(n: 2725))
        #expect(toast.message?.systemImage == "checkmark")
    }

    @Test("Stepper und Schalter zeigen keinen Toast")
    func noToastForSteps() {
        let (model, toast) = make(storage: .ephemeral(.prototypeSample))
        model.perform(.markMadeUp(.asr))
        model.perform(.addMissed(.isha))
        model.perform(.step(.months, by: 1))
        model.perform(.setWitr(true))
        #expect(toast.message == nil)
        #expect(model.ledger.openCount(of: .asr) == 529)
        #expect(model.ledger.openCount(of: .isha) == 527)
        #expect(model.ledger[.months] == 7)
        #expect(model.ledger.includesWitr)
    }
}

#endif
