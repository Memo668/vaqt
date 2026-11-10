import Foundation
import Testing
@testable import PrayerCore

/// Die Daten der Anleitung müssen `RAKAH`, `NEXT_OF`, `GUIDE_STEPS` und `FORMULA` im Prototyp entsprechen.
@Suite("Guide – Daten")
struct GuideDataTests {

    @Test("Rakʿas je Gebet: Zahl und welche laut rezitiert werden", arguments: [
        (Prayer.fajr, [true, true]),
        (.dhuhr, [false, false, false, false]),
        (.asr, [false, false, false, false]),
        (.maghrib, [true, true, false]),
        (.isha, [true, true, false, false]),
    ])
    func rakahs(prayer: Prayer, aloud: [Bool]) throws {
        let rakahs = try #require(Guide.rakahs(for: prayer))
        #expect(rakahs.aloud == aloud)
        #expect(rakahs.count == aloud.count)
    }

    @Test("die fünf Gebete haben 2, 4, 4, 3 und 4 Fard-Rakʿas")
    func counts() {
        #expect(Prayer.five.map { Guide.rakahs(for: $0)?.count } == [2, 4, 4, 3, 4])
    }

    @Test("der Sonnenaufgang ist kein Gebet")
    func sunrise() {
        #expect(Guide.rakahs(for: .sunrise) == nil)
        #expect(Guide.end(of: .sunrise) == nil)
    }

    @Test("Rezitation: Fadschr laut, Dhuhr und Asr leise, Maghrib und Ischa gemischt")
    func recitation() {
        #expect(Prayer.five.map { Guide.rakahs(for: $0)?.recitation } == [.aloud, .silent, .silent, .mixed, .mixed])
    }

    @Test("ab drei Rakʿas wird nach der zweiten gesessen")
    func moreThanTwo() {
        #expect(Prayer.five.map { Guide.rakahs(for: $0)?.hasMoreThanTwo } == [false, true, true, true, true])
    }

    @Test("ein Gebet ohne Rakʿas zählt als laut rezitiert, wie `every` im Prototyp")
    func emptyRakahs() {
        let empty = Rakahs(aloud: [])
        #expect(empty.count == 0)
        #expect(empty.recitation == .aloud)
        #expect(!empty.hasMoreThanTwo)
    }

    @Test("die Zeit eines Gebets endet mit dem nächsten Ereignis", arguments: [
        (Prayer.fajr, Prayer.sunrise), (.dhuhr, .asr), (.asr, .maghrib), (.maghrib, .isha), (.isha, .fajr),
    ])
    func windowEnd(prayer: Prayer, end: Prayer) {
        #expect(Guide.end(of: prayer) == end)
    }

    @Test("sieben Schritte in der Reihenfolge des Prototyps, jeder mit seiner Haltung")
    func steps() {
        #expect(Guide.steps.map(\.kind.rawValue) == ["takbir", "qiyam", "ruku", "itidal", "sujud", "tash", "salam"])
        #expect(Guide.steps.map(\.pose.rawValue) == ["takbir", "qiyam", "ruku", "itidal", "sujud", "sit", "salam"])
        #expect(Guide.steps.map(\.id) == GuideStep.Kind.allCases)
        #expect(GuideStep.Pose.allCases.count == 7)
    }

    @Test("jeder Schritt außer dem Stehen hat eine Formel")
    func formulas() {
        #expect(Guide.steps.filter { $0.formula == nil }.map(\.kind) == [.qiyam])
    }

    @Test("die Umschrift der Formeln", arguments: [
        ("takbir", "Allāhu akbar"),
        ("ruku", "Subḥāna rabbiya l-ʿaẓīm"),
        ("itidal", "Samiʿa llāhu li-man ḥamidah · Rabbanā laka l-ḥamd"),
        ("sujud", "Subḥāna rabbiya l-aʿlā"),
        ("tash", "At-taḥiyyātu li-llāh …"),
        ("salam", "As-salāmu ʿalaikum wa raḥmatu llāh"),
    ])
    func transliterations(kind: String, expected: String) throws {
        let step = try #require(Guide.steps.first { $0.kind.rawValue == kind })
        #expect(step.formula?.transliteration == expected)
    }

    @Test("der arabische Text der Formeln, Zeichen für Zeichen", arguments: [
        ("takbir", [0x0627, 0x0644, 0x0644, 0x0651, 0x0670, 0x0647, 0x064F, 0x0020, 0x0623, 0x064E, 0x0643, 0x0652, 0x0628, 0x064E, 0x0631, 0x064F]),
        ("ruku", [
            0x0633, 0x064F, 0x0628, 0x0652, 0x062D, 0x064E, 0x0627, 0x0646, 0x064E, 0x0020, 0x0631, 0x064E, 0x0628, 0x0650,
            0x0651, 0x064A, 0x064E, 0x0020, 0x0627, 0x0644, 0x0652, 0x0639, 0x064E, 0x0638, 0x0650, 0x064A, 0x0645, 0x0650,
        ]),
        ("itidal", [
            0x0633, 0x064E, 0x0645, 0x0650, 0x0639, 0x064E, 0x0020, 0x0627, 0x0644, 0x0644, 0x0651, 0x0670, 0x0647, 0x064F,
            0x0020, 0x0644, 0x0650, 0x0645, 0x064E, 0x0646, 0x0652, 0x0020, 0x062D, 0x064E, 0x0645, 0x0650, 0x062F, 0x064E,
            0x0647, 0x064F, 0x0020, 0x00B7, 0x0020, 0x0631, 0x064E, 0x0628, 0x064E, 0x0651, 0x0646, 0x064E, 0x0627, 0x0020,
            0x0644, 0x064E, 0x0643, 0x064E, 0x0020, 0x0627, 0x0644, 0x0652, 0x062D, 0x064E, 0x0645, 0x0652, 0x062F, 0x064F,
        ]),
        ("sujud", [
            0x0633, 0x064F, 0x0628, 0x0652, 0x062D, 0x064E, 0x0627, 0x0646, 0x064E, 0x0020, 0x0631, 0x064E, 0x0628, 0x0650,
            0x0651, 0x064A, 0x064E, 0x0020, 0x0627, 0x0644, 0x0652, 0x0623, 0x064E, 0x0639, 0x0652, 0x0644, 0x064E, 0x0649,
        ]),
        ("tash", [
            0x0627, 0x0644, 0x062A, 0x064E, 0x0651, 0x062D, 0x0650, 0x064A, 0x064E, 0x0651, 0x0627, 0x062A, 0x064F, 0x0020,
            0x0644, 0x0650, 0x0644, 0x0651, 0x0670, 0x0647, 0x0650, 0x0020, 0x2026,
        ]),
        ("salam", [
            0x0627, 0x0644, 0x0633, 0x064E, 0x0651, 0x0644, 0x064E, 0x0627, 0x0645, 0x064F, 0x0020, 0x0639, 0x064E, 0x0644,
            0x064E, 0x064A, 0x0652, 0x0643, 0x064F, 0x0645, 0x0652, 0x0020, 0x0648, 0x064E, 0x0631, 0x064E, 0x062D, 0x0652,
            0x0645, 0x064E, 0x0629, 0x064F, 0x0020, 0x0627, 0x0644, 0x0644, 0x0651, 0x0670, 0x0647, 0x0650,
        ]),
    ] as [(String, [UInt32])])
    func arabic(kind: String, scalars: [UInt32]) throws {
        // Die Codepunkte stammen aus `FORMULA` im Prototyp. So fällt auch eine unsichtbare Änderung auf,
        // etwa ein vertauschtes oder verlorenes Vokalzeichen.
        let step = try #require(Guide.steps.first { $0.kind.rawValue == kind })
        #expect(step.formula?.arabic.unicodeScalars.map(\.value) == scalars)
    }

    @Test("nur nach der Niederwerfung steht der Hinweis zum Wiederholen")
    func repeatNote() {
        #expect(Guide.steps.filter(\.isFollowedByRepeatNote).map(\.kind) == [.sujud])
    }
}

#if DEBUG

/// Der Stand der Anleitung muss sich verhalten wie `guideState()` und die Aktionen `guide-pick` und
/// `guide-now` im Prototyp. Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026.
@Suite("Guide – Stand und manuelle Wahl")
struct GuideStateTests {

    private let day = FixtureTimes.referenceDay
    private let berlin = fixtureTimeline()

    private func phase(_ time: String) throws -> DayPhase {
        try #require(berlin.phase(at: day.at(time, in: .berlin)))
    }

    // MARK: - Automatik

    @Test("die Anleitung öffnet auf dem laufenden Gebet", arguments: [
        ("05:16", Prayer.fajr), ("06:30", .fajr), ("11:52", .dhuhr), ("14:25", .asr), ("16:27", .maghrib), ("18:17", .isha),
        ("23:30", .isha),
    ])
    func followsCurrent(time: String, prayer: Prayer) throws {
        let state = try GuideState(phase: phase(time))
        #expect(state.prayer == prayer)
        #expect(state.automatic == prayer)
        #expect(state.isCurrent)
        #expect(!state.isNext)
        #expect(!state.showsReturnButton)
    }

    @Test("vor Fadschr zeigt sie noch Ischa, als laufendes Gebet")
    func beforeFajr() throws {
        let state = try GuideState(phase: phase("04:01"))
        #expect(state.prayer == .isha)
        #expect(state.automatic == .isha)
        #expect(state.isCurrent)
        #expect(!state.isNext)
    }

    @Test("zwischen Sonnenaufgang und Dhuhr zeigt sie das nächste Gebet, Dhuhr")
    func afterSunrise() throws {
        for time in ["07:14", "08:04", "11:51:59"] {
            let state = try GuideState(phase: phase(time))
            #expect(state.prayer == .dhuhr, "\(time)")
            #expect(state.automatic == .dhuhr, "\(time)")
            #expect(!state.isCurrent, "\(time)")
            #expect(state.isNext, "\(time)")
            #expect(!state.showsReturnButton, "\(time)")
        }
    }

    // MARK: - Manuelle Wahl

    @Test("eine manuelle Wahl zeigt ein anderes Gebet und den Knopf zurück")
    func manualPick() throws {
        let state = try GuideState(phase: phase("14:25"), pick: .maghrib)
        #expect(state.prayer == .maghrib)
        #expect(state.automatic == .asr)
        #expect(!state.isCurrent)
        #expect(!state.isNext)
        #expect(state.showsReturnButton)
    }

    @Test("die Wahl des laufenden Gebets ist keine Abweichung")
    func pickEqualsAutomatic() throws {
        let state = try GuideState(phase: phase("14:25"), pick: .asr)
        #expect(state.prayer == .asr)
        #expect(state.isCurrent)
        #expect(!state.showsReturnButton)
    }

    @Test("am Vormittag von Hand gewähltes Fadschr ist weder „Jetzt“ noch „Als Nächstes“")
    func pickInMorning() throws {
        let state = try GuideState(phase: phase("08:04"), pick: .fajr)
        #expect(state.prayer == .fajr)
        #expect(state.automatic == .dhuhr)
        #expect(!state.isCurrent)
        #expect(!state.isNext)
        #expect(state.showsReturnButton)
    }

    @Test("der Sonnenaufgang lässt sich nicht wählen")
    func sunriseIsNoPick() throws {
        let state = try GuideState(phase: phase("14:25"), pick: .sunrise)
        #expect(state.prayer == .asr)
        #expect(!state.showsReturnButton)

        var selection = GuideSelection()
        try selection.choose(.sunrise, in: phase("14:25"))
        #expect(selection.pick == nil)
    }

    @Test("Antippen wählt ein Gebet; das laufende anzutippen hebt die Wahl auf")
    func choosing() throws {
        let phase = try phase("14:25")
        var selection = GuideSelection()
        #expect(selection.pick == nil)
        #expect(selection.state(for: phase).prayer == .asr)

        selection.choose(.maghrib, in: phase)
        #expect(selection.pick == .maghrib)
        #expect(selection.state(for: phase).prayer == .maghrib)
        #expect(selection.state(for: phase).showsReturnButton)

        selection.choose(.asr, in: phase)
        #expect(selection.pick == nil)
        #expect(!selection.state(for: phase).showsReturnButton)
    }

    @Test("„Zurück zum aktuellen Gebet“ und das Verlassen der Seite heben die Wahl auf")
    func returning() throws {
        let phase = try phase("14:25")
        var selection = GuideSelection()
        selection.choose(.fajr, in: phase)
        selection.followTime()
        #expect(selection.pick == nil)
        #expect(selection.state(for: phase).prayer == .asr)
    }

    // MARK: - Zeitwechsel

    @Test("die Wahl bleibt, solange dasselbe Gebet läuft")
    func pickSurvivesWithinPrayer() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("14:25"))
        try selection.choose(.isha, in: phase("14:25"))
        for time in ["14:26", "15:42", "16:26:59"] {
            try selection.update(for: phase(time))
            #expect(selection.pick == .isha, "\(time)")
            #expect(try selection.state(for: phase(time)).automatic == .asr, "\(time)")
        }
    }

    @Test("wechselt das laufende Gebet, verfällt die Wahl und die Anleitung folgt wieder der Zeit")
    func pickExpiresAtPrayerChange() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("14:25"))
        try selection.choose(.isha, in: phase("14:25"))

        let maghrib = try phase("16:27")
        selection.update(for: maghrib)
        #expect(selection.pick == nil)
        let state = selection.state(for: maghrib)
        #expect(state.prayer == .maghrib)
        #expect(state.isCurrent)
        #expect(!state.showsReturnButton)
    }

    @Test("auch der Sonnenaufgang ist ein Wechsel: Danach gilt Dhuhr")
    func pickExpiresAtSunrise() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("06:30"))
        try selection.choose(.asr, in: phase("06:30"))
        #expect(selection.pick == .asr)

        try selection.update(for: phase("07:14"))
        #expect(selection.pick == nil)
        #expect(try selection.state(for: phase("07:14")).prayer == .dhuhr)
    }

    @Test("Mitternacht ist kein Wechsel: Ischa läuft weiter, die Wahl bleibt")
    func pickSurvivesMidnight() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("23:30"))
        try selection.choose(.fajr, in: phase("23:30"))

        let nextDay = day.adding(days: 1)
        let afterMidnight = try #require(fixtureTimeline(on: nextDay).phase(at: nextDay.at("00:30", in: .berlin)))
        selection.update(for: afterMidnight)
        #expect(selection.pick == .fajr)
        #expect(selection.state(for: afterMidnight).automatic == .isha)
    }

    @Test("eine Wahl, die zum neuen laufenden Gebet passt, verfällt beim Wechsel trotzdem")
    func pickOfUpcomingPrayerExpires() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("14:25"))
        try selection.choose(.maghrib, in: phase("14:25"))
        #expect(try selection.state(for: phase("14:25")).showsReturnButton)

        try selection.update(for: phase("16:27"))
        #expect(selection.pick == nil)
        #expect(try selection.state(for: phase("16:27")).isCurrent)
    }

    @Test("die Wahl merkt sich, bei welchem Gebet sie getroffen wurde – auch ohne vorherigen Abgleich")
    func pickRemembersItsPrayer() throws {
        var selection = GuideSelection()
        try selection.choose(.isha, in: phase("14:25"))
        try selection.update(for: phase("15:00"))
        #expect(selection.pick == .isha)
        try selection.update(for: phase("16:27"))
        #expect(selection.pick == nil)
    }

    @Test("der erste Abgleich allein ändert nichts")
    func firstUpdate() throws {
        var selection = GuideSelection()
        try selection.update(for: phase("14:25"))
        #expect(selection.pick == nil)
        #expect(try selection.state(for: phase("14:25")).prayer == .asr)

        // Zwei Auswahlen mit demselben Verlauf sind gleich.
        var other = GuideSelection()
        try other.update(for: phase("14:25"))
        #expect(selection == other)
    }
}

#endif
