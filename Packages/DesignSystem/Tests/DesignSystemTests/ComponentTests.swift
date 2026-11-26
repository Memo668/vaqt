import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Symbole, Glass-Maße und Stepper.
// Auf dem Hauptthread, weil die Tests des Steppers Views anlegen und ihre Aktionen auslösen.
@MainActor
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
        "location.fill", "location.slash", "wifi.slash", "checkmark", "infinity",
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
    @Test("der Countdown schreibt wie cdDigital()", arguments: [
        (7319.0, "2:01:59"),
        (74.9, "1:14"),
        (3600.0, "1:00:00"),
        (59.0, "0:59"),
        (0.0, "0:00"),
        (-5.0, "0:00"),
        (36_000.0, "10:00:00"),
    ])
    func countdownText(remaining: Double, expected: String) {
        #expect(CountdownFormat.digital(remaining) == expected)
    }

    @Test("die Abschnitte des Katalogs heißen wie die Werte von -debugCatalog")
    func catalogSections() {
        #expect(ComponentCatalog.Section.allCases.map(\.rawValue) == [
            "arc", "rows", "glass", "cards", "compass", "guide", "steps", "verses", "qada", "settings", "onboarding",
            "adhan", "widgets", "live", "carplay", "all",
        ])
    }
    #endif
}

/// Countdown in Worten, Regelnamen und die Zeichnung für den Chip „Anleitung“.
@Suite("Bausteine der Zeiten-Seite")
struct TodayComponentTests {

    @Test("der Countdown in Worten rundet auf volle Minuten auf wie cdText()", arguments: [
        (7319.0, "2 Std. 2 Min."),
        (7200.0, "2 Std."),
        (3600.0, "1 Std."),
        (3599.0, "1 Std."),
        (74.9, "2 Min."),
        (60.0, "1 Min."),
        (1.0, "1 Min."),
        (0.0, "1 Min."),
        (-5.0, "1 Min."),
    ])
    func spokenCountdown(remaining: Double, expected: String) throws {
        // Die Kürzel kommen aus dem String Catalog; verglichen wird mit den deutschen.
        let german = try #require(L10n.bundle.url(forResource: "de", withExtension: "lproj").flatMap(Bundle.init(url:)))
        let hours = german.localizedString(forKey: "hShort", value: nil, table: nil)
        let minutes = german.localizedString(forKey: "mShort", value: nil, table: nil)
        let localized = expected.replacingOccurrences(of: "Std.", with: L10n.hShort)
            .replacingOccurrences(of: "Min.", with: L10n.mShort)
        #expect(hours == "Std." && minutes == "Min.")
        #expect(CountdownFormat.spoken(remaining) == localized)
    }

    @Test("jede Regel für hohe Breiten hat ihren Namen aus dem String Catalog")
    func highLatitudeRuleNames() {
        let names = HighLatitudeRule.allCases.map(\.localizedName)
        #expect(names == [L10n.hlAngle, L10n.hlSeventh, L10n.hlMiddle, L10n.hlManual])
        #expect(Set(names).count == 4)
        #expect(!names.contains { $0.isEmpty || $0.hasPrefix("hl") })
    }

    @Test("der Gebetsteppich füllt sein Feld wie im Prototyp: 12 von 24 breit, von 3,2 bis 22 hoch")
    func prayerRug() {
        let box = PrayerRugShape().path(in: CGRect(x: 0, y: 0, width: 24, height: 24)).cgPath.boundingBoxOfPath
        #expect(abs(box.minX - 6) < 0.01 && abs(box.maxX - 18) < 0.01)
        #expect(abs(box.minY - 3.2) < 0.01 && abs(box.maxY - 22) < 0.01)

        // In einem Feld von 22 pt: im selben Verhältnis kleiner, mittig.
        let small = PrayerRugShape().path(in: CGRect(x: 0, y: 0, width: 22, height: 22)).cgPath.boundingBoxOfPath
        #expect(abs(small.width - 11) < 0.01)
        #expect(abs(small.midX - 11) < 0.01)
    }
}
