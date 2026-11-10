import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Symbole, Glass-Maße und Stepper.
@Suite("Bausteine")
struct ComponentTests {

    // MARK: - Symbole

    @Test("die Ereignisse tragen die SF Symbols aus der Design Spec")
    func prayerSymbols() {
        #expect(Prayer.allCases.map(\.symbolName) == ["sun.horizon", "sunrise", "sun.max", "sun.min", "sunset", "moon.stars"])
    }

    @Test("die Glocke: Ton, Lautlos, Aus")
    func bellSymbols() {
        #expect(BellState.allCases.map(\.symbolName) == ["bell.and.waves.left.and.right", "bell", "bell.slash"])
    }

    @Test("jedes benutzte Symbol gibt es im System", arguments: [
        "sun.horizon", "sunrise", "sun.max", "sun.min", "sunset", "moon.stars",
        "bell.and.waves.left.and.right", "bell", "bell.slash",
        "info.circle", "minus", "plus", "gearshape", "clock", "safari",
    ])
    func symbolExists(name: String) {
        #expect(UIImage(systemName: name) != nil)
    }

    @Test("jedes Ereignis und jeder Stand der Glocke hat einen eigenen Namen aus dem String Catalog")
    func names() {
        let prayers = Prayer.allCases.map(\.localizedName)
        #expect(Set(prayers).count == 6)
        #expect(!prayers.contains { $0.isEmpty || $0.hasPrefix("p_") })

        let bells = BellState.allCases.map(\.localizedName)
        #expect(Set(bells).count == 3)
        #expect(!bells.contains { $0.isEmpty || $0.hasPrefix("bell") })
    }

    // MARK: - Glass

    @Test("die Leiste ist 52 pt hoch und wächst mit Dynamic Type höchstens auf das 1,15-Fache")
    func barHeight() {
        #expect(GlassMetrics.barHeight(typeScale: 1) == 52)
        #expect(abs(GlassMetrics.barHeight(typeScale: 1.1) - 57.2) < 0.001)
        #expect(abs(GlassMetrics.barHeight(typeScale: 1.35) - 59.8) < 0.001)
        #expect(abs(GlassMetrics.barHeight(typeScale: 3.1) - 59.8) < 0.001)
        // Mit kleinerer Schrift schrumpft die Leiste nicht unter das Tippziel.
        #expect(GlassMetrics.barHeight(typeScale: 0.8) == 52)
    }

    @Test("Chip: Symbol 22 pt breit, 7 pt Abstand, Innenabstand 14 und 18 pt, Tönung 17 %")
    func chipMetrics() {
        #expect(GlassMetrics.chipSymbolBox == 22)
        #expect(GlassMetrics.chipGap == 7)
        #expect(GlassMetrics.chipLeading == 14)
        #expect(GlassMetrics.chipTrailing == 18)
        #expect(GlassMetrics.selectedTintOpacity == 0.17)
    }

    // MARK: - Stepper

    /// Ein Wert, den der Stepper über ein Binding ändert.
    private final class Box: @unchecked Sendable {
        var value: Int
        init(_ value: Int) { self.value = value }
    }

    private func pill(_ box: Box, in range: ClosedRange<Int>) -> StepperPill {
        StepperPill("Tage", value: Binding(get: { box.value }, set: { box.value = $0 }), in: range)
    }

    @Test("der Stepper ist 94 × 32 pt groß, das Tippziel 44 pt hoch")
    func stepperMetrics() {
        #expect(StepperMetrics.keyWidth * 2 == 94)
        #expect(StepperMetrics.height == 32)
        #expect(StepperMetrics.radius == 8)
        #expect(Layout.minTapTarget == 44)
    }

    @Test("an der unteren Grenze ist „−“ gesperrt, an der oberen „+“", arguments: [
        (1, false, true),
        (2, true, true),
        (19, true, true),
        (20, true, false),
    ])
    func stepperBounds(value: Int, canDecrement: Bool, canIncrement: Bool) {
        let pill = pill(Box(value), in: 1...20)
        #expect(pill.canDecrement == canDecrement)
        #expect(pill.canIncrement == canIncrement)
    }

    @Test("„+“ zählt eins hoch, „−“ eins herunter, nie über die Grenzen")
    func stepperSteps() {
        let box = Box(1)
        pill(box, in: 1...3).onIncrement()
        #expect(box.value == 2)
        pill(box, in: 1...3).onIncrement()
        pill(box, in: 1...3).onIncrement()
        #expect(box.value == 3)
        pill(box, in: 1...3).onDecrement()
        #expect(box.value == 2)
        pill(box, in: 1...3).onDecrement()
        pill(box, in: 1...3).onDecrement()
        #expect(box.value == 1)
    }

    @Test("ohne eigene Texte sagt VoiceOver „… weniger“ und „… mehr“")
    func stepperLabels() {
        let standard = StepperPill("Tage", onDecrement: {}, onIncrement: {})
        #expect(standard.label == "Tage")
        #expect(standard.decrementLabel == L10n.stepLess(x: "Tage"))
        #expect(standard.incrementLabel == L10n.stepMore(x: "Tage"))
        #expect(standard.decrementLabel != standard.incrementLabel)

        let qada = StepperPill("Fadschr", decrementLabel: "nachgeholt", incrementLabel: "mehr offen", onDecrement: {}, onIncrement: {})
        #expect(qada.decrementLabel == "nachgeholt")
        #expect(qada.incrementLabel == "mehr offen")
    }

    // MARK: - Katalog

    #if DEBUG
    @Test("der Countdown im Katalog schreibt wie cdDigital()", arguments: [
        (7319.0, "2:01:59"),
        (74.9, "1:14"),
        (3600.0, "1:00:00"),
        (59.0, "0:59"),
        (0.0, "0:00"),
        (-5.0, "0:00"),
        (36_000.0, "10:00:00"),
    ])
    func countdownText(remaining: Double, expected: String) {
        #expect(CatalogFixtures.countdownText(remaining) == expected)
    }

    @Test("die Abschnitte des Katalogs heißen wie die Werte von -debugCatalog")
    func catalogSections() {
        #expect(ComponentCatalog.Section.allCases.map(\.rawValue) == ["arc", "rows", "glass", "cards", "all"])
    }
    #endif
}
