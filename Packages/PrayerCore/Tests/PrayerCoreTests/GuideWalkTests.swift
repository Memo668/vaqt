import Testing
@testable import PrayerCore

/// Der Durchlauf „Gebet Schritt für Schritt“ muss `walkSteps(p)` und `WALK` im Prototyp entsprechen
/// (Design Spec § 9.6).
@Suite("GuideWalk – Schritt für Schritt")
struct GuideWalkTests {

    private func walk(_ prayer: Prayer) throws -> GuideWalk {
        try #require(GuideWalk(prayer: prayer))
    }

    @Test("Zahl der Schritte: Fadschr 15, Dhuhr 28, Asr 28, Maghrib 22, Ischa 28 – dazu Start und Ende", arguments: [
        (Prayer.fajr, 15), (.dhuhr, 28), (.asr, 28), (.maghrib, 22), (.isha, 28),
    ])
    func stepCount(prayer: Prayer, count: Int) throws {
        let walk = try walk(prayer)
        #expect(walk.stepCount == count)
        #expect(walk.steps.count == count + 2)
        #expect(walk.steps.first?.kind == .intro)
        #expect(walk.steps.last?.kind == .done)
        #expect(walk.lastIndex == count + 1)
    }

    @Test("der Sonnenaufgang hat keinen Durchlauf")
    func sunrise() {
        #expect(GuideWalk(prayer: .sunrise) == nil)
    }

    @Test("Fadschr Schritt für Schritt wie im Prototyp")
    func fajrSequence() throws {
        let walk = try walk(.fajr)
        let rakah: [GuideWalk.Kind] = [.qiyam, .ruku, .itidal, .sujud, .jalsa, .sujud2]
        #expect(walk.steps.map(\.kind) == [.intro, .takbir] + rakah + rakah + [.tashLast, .salam, .done])
        #expect(walk.steps.map(\.rakah) == [nil, 1] + Array(repeating: 1, count: 6) + Array(repeating: 2, count: 6) + [2, 2, nil])
    }

    @Test("Maghrib: erstes Sitzen nach der 2. Rakʿa, dann die 3.")
    func maghribSequence() throws {
        let walk = try walk(.maghrib)
        let rakah: [GuideWalk.Kind] = [.qiyam, .ruku, .itidal, .sujud, .jalsa, .sujud2]
        #expect(walk.steps.map(\.kind)
            == [.intro, .takbir] + rakah + rakah + [.tashFirst] + rakah + [.tashLast, .salam, .done])
        let first = try #require(walk.steps.firstIndex { $0.kind == .tashFirst })
        #expect(walk.steps[first].rakah == 2)
        #expect(walk.steps[first + 1].kind == .qiyam)
        #expect(walk.steps[first + 1].rakah == 3)
    }

    @Test("Dhuhr: vier Rakʿas, das erste Sitzen genau einmal, Takbīr nur am Anfang")
    func dhuhrSequence() throws {
        let walk = try walk(.dhuhr)
        let kinds = walk.steps.map(\.kind)
        #expect(kinds.filter { $0 == .takbir }.count == 1)
        #expect(kinds.filter { $0 == .tashFirst }.count == 1)
        #expect(kinds.filter { $0 == .tashLast }.count == 1)
        #expect(kinds.filter { $0 == .qiyam }.count == 4)
        #expect(kinds.filter { $0 == .sujud }.count == 4)
        #expect(kinds.filter { $0 == .sujud2 }.count == 4)
        #expect(kinds.filter { $0 == .jalsa }.count == 4)
        // Start 0, Takbīr 1, Rakʿa 1: 2–7, Rakʿa 2: 8–13, erstes Sitzen 14 (`walk` im Prototyp mit `i`).
        #expect(walk.steps[1].kind == .takbir)
        #expect(walk.steps[14].kind == .tashFirst)
        #expect(walk.steps[15].kind == .qiyam)
        #expect(walk.steps[27].kind == .tashLast)
        #expect(walk.steps[28].kind == .salam)
        #expect(walk.steps[29].kind == .done)
    }

    @Test("Stehen: laut oder leise wie die Rakʿa, ab der 3. nur al-Fātiḥa", arguments: Prayer.five)
    func qiyam(prayer: Prayer) throws {
        let walk = try walk(prayer)
        let rakahs = try #require(Guide.rakahs(for: prayer))
        let qiyam = walk.steps.filter { $0.kind == .qiyam }
        #expect(qiyam.map(\.rakah) == Array(1...rakahs.count))
        #expect(qiyam.map(\.isAloud) == rakahs.aloud)
        #expect(qiyam.map(\.isOnlyFatiha) == (1...rakahs.count).map { $0 >= 3 })
        // Nur das Stehen trägt laut/leise.
        #expect(walk.steps.filter { $0.kind != .qiyam }.allSatisfy { !$0.isAloud && !$0.isOnlyFatiha })
    }

    @Test("erstes Sitzen nur bei mehr als zwei Rakʿas")
    func firstSitting() throws {
        #expect(try walk(.fajr).steps.contains { $0.kind == .tashFirst } == false)
        for prayer in [Prayer.dhuhr, .asr, .maghrib, .isha] {
            #expect(try walk(prayer).steps.contains { $0.kind == .tashFirst })
        }
    }

    @Test("Haltung je Schritt wie `WALK`")
    func poses() {
        let poses = GuideWalk.Kind.allCases.map(\.pose)
        #expect(poses == [nil, .takbir, .qiyam, .ruku, .itidal, .sujud, .sit, .sujud, .sit, .sit, .salam, nil])
    }

    @Test("Formel je Schritt wie `WALK`: beide Niederwerfungen, beide Sitzen; Stehen und kurzes Sitzen ohne")
    func formulas() throws {
        #expect(GuideWalk.Kind.allCases.map(\.formulaStep)
            == [nil, .takbir, nil, .ruku, .itidal, .sujud, nil, .sujud, .tash, .tash, .salam, nil])
        let sujud = try #require(Guide.steps.first { $0.kind == .sujud }?.formula)
        #expect(GuideWalk.Kind.sujud2.formula == sujud)
        #expect(GuideWalk.Kind.tashFirst.formula?.transliteration == "At-taḥiyyātu li-llāh …")
        #expect(GuideWalk.Kind.qiyam.formula == nil)
        #expect(GuideWalk.Kind.jalsa.formula == nil)
    }

    @Test("Schrittnummer: Start und Ende ohne, dazwischen 1 bis k")
    func stepNumbers() throws {
        let walk = try walk(.dhuhr)
        #expect(walk.stepNumber(at: 0) == nil)
        #expect(walk.stepNumber(at: 1) == 1)
        #expect(walk.stepNumber(at: 9) == 9)
        #expect(walk.stepNumber(at: 28) == 28)
        #expect(walk.stepNumber(at: 29) == nil)
        #expect((1...28).map { walk.stepNumber(at: $0) } == Array(1...28))
    }

    @Test("Fortschritt: Start 0, Ende 1, dazwischen Schritt ÷ k")
    func progress() throws {
        let walk = try walk(.dhuhr)
        #expect(walk.progress(at: 0) == 0)
        #expect(walk.progress(at: 7) == 7.0 / 28)
        #expect(walk.progress(at: 28) == 1)
        #expect(walk.progress(at: 29) == 1)
        let fajr = try self.walk(.fajr)
        #expect(fajr.progress(at: 1) == 1.0 / 15)
    }

    @Test("Weiter und Zurück bleiben an den Enden stehen")
    func navigation() throws {
        let walk = try walk(.fajr)
        #expect(walk.index(before: 0) == 0)
        #expect(walk.index(after: 0) == 1)
        #expect(walk.index(before: 5) == 4)
        #expect(walk.index(after: walk.lastIndex) == walk.lastIndex)
        #expect(walk.isLast(walk.lastIndex))
        #expect(!walk.isLast(walk.lastIndex - 1))
        #expect(walk.step(at: 99).kind == .done)
        #expect(walk.step(at: -3).kind == .intro)
    }

    @Test("Rakʿa des Schritts für „Rakʿa {r} von {n}“")
    func rakahOfStep() throws {
        let walk = try walk(.maghrib)
        #expect(walk.step(at: 0).rakah == nil)
        #expect(walk.step(at: 1).rakah == 1)
        #expect(walk.step(at: walk.lastIndex - 1).rakah == 3)
        #expect(walk.step(at: walk.lastIndex).rakah == nil)
    }
}
