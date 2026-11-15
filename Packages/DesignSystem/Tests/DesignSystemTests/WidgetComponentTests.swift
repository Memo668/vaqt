#if DEBUG

import Foundation
import PrayerCore
import SwiftUI
import Testing
@testable import DesignSystem

/// Die Bausteine der Widgets und der Live-Aktivität (Plan für Phase 9): Stand in der App Group, Texte,
/// Maße aus dem CSS des Prototyps.
@Suite("Widgets und Live-Aktivität – Bausteine")
struct WidgetComponentTests {

    private func berlin() -> Place {
        Place(
            name: "Berlin", countryCode: "DE",
            coordinates: Coordinates(latitude: 52.52, longitude: 13.405), timeZoneIdentifier: "Europe/Berlin"
        )
    }

    // MARK: - Stand in der App Group

    @Test("der Stand lässt sich speichern; geschrieben wird nur, was sich geändert hat")
    func saveAndLoad() throws {
        let suite = "test.widgets.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        #expect(WidgetState.load(from: defaults) == nil)
        var state = WidgetState(
            place: berlin(), cityName: "Berlin", isCurrentLocation: true, calculation: CalculationSettings(),
            showKerahat: true, language: .de
        )
        #expect(state.save(to: defaults))
        #expect(WidgetState.load(from: defaults) == state)
        #expect(!state.save(to: defaults))

        state.language = .tr
        state.debug = WidgetState.Debug(fixtureTimes: true, highLatitude: false, clockOffset: -3600)
        #expect(state.save(to: defaults))
        #expect(WidgetState.load(from: defaults)?.clockOffset == -3600)
    }

    @Test("ohne Ort heißt es „Stadt wählen“; ohne Debug-Uhr ist der Abstand 0")
    func withoutPlace() {
        let state = WidgetState(
            place: nil, cityName: L10n.citySheetTitle, isCurrentLocation: false, calculation: CalculationSettings(),
            showKerahat: true, language: .de
        )
        #expect(state.place == nil)
        #expect(state.clockOffset == 0)
    }

    // MARK: - Texte

    @Test("der Countdown steht an der Stelle des Platzhalters: „in 2:01:29“, türkisch „2:01:29 sonra“")
    func timerParts() {
        #expect(TimerText.parts { "in \($0)" } == ("in ", ""))
        #expect(TimerText.parts { "\($0) sonra" } == ("", " sonra"))
        #expect(TimerText.parts { "en \($0)" } == ("en ", ""))
        // Ohne Platzhalter steht der Countdown hinten.
        #expect(TimerText.parts { _ in "in" } == ("in ", ""))
    }

    @Test("„Maghrib in“, nach Ischa „(morgen)“, ab Gebetsbeginn nur der Name")
    func caption() throws {
        let content = try maghribContent()
        #expect(LiveActivityTexts.caption(content, hasBegun: false) == L10n.nextIn(p: L10n.p_maghrib))
        #expect(LiveActivityTexts.caption(content, hasBegun: true) == L10n.p_maghrib)
        #expect(LiveActivityTexts.nameAndTime(content) == L10n.p_maghrib + " · 16:27")
        #expect(LiveActivityTexts.ends(content) == (L10n.p_asr + " 14:00", L10n.p_maghrib + " 16:27"))
    }

    // MARK: - Maße

    @Test("Maße der Widgets wie im CSS: klein 154, mittel 338 × 154, Ring 72 mit Radius 30 und Strich 5")
    func widgetMetrics() {
        #expect(WidgetMetrics.smallSize == CGSize(width: 154, height: 154))
        #expect(WidgetMetrics.mediumSize == CGSize(width: 338, height: 154))
        #expect(WidgetMetrics.mediumLeftWidth == 118)
        #expect(WidgetMetrics.circularSize == CGSize(width: 72, height: 72))
        #expect(WidgetMetrics.ringRadius == 30)
        #expect(WidgetMetrics.ringWidth == 5)
        #expect(WidgetMetrics.rectangularSize == CGSize(width: 170, height: 72))
        #expect(WidgetMetrics.cornerRadius == 22)
        // Ein Symbol in einem Feld von 22 pt ist so groß wie auf der Gebetskarte.
        #expect(WidgetMetrics.symbolSize(box: 22) == 14.5)
    }

    @Test("Widget „Live“ wie `.w-la`: 338 × 158; Kopf, 2 pt und der Bogen 314 × 116 passen hinein")
    func liveWidgetMetrics() {
        #expect(WidgetMetrics.liveSize == CGSize(width: 338, height: 158))
        let arc = DayArcMetrics.liveWidget.size
        #expect(WidgetMetrics.livePadding.leading + arc.width + WidgetMetrics.livePadding.trailing == WidgetMetrics.liveSize.width)
        let height = WidgetMetrics.livePadding.top + 16 + WidgetMetrics.liveArcTop + arc.height
        #expect(height == 143)
        #expect(height <= WidgetMetrics.liveSize.height)
    }

    @Test("Rechteck mit Mini-Bogen wie `.acc-arcw`: Bogen 148 × 32 oben, die Zeilen (17,5 + 15 pt) ab 32,5 pt")
    func rectangularArcMetrics() {
        let padding = WidgetMetrics.rectangularArcPadding
        #expect(padding.leading + DayArcMetrics.lockScreen.size.width + padding.trailing == WidgetMetrics.rectangularSize.width)
        let lines = 14 * WidgetMetrics.rectangularLineHeight + 12 * WidgetMetrics.rectangularLineHeight
        // Im Prototyp gemessen: Die Zeile „Maghrib 16:27“ beginnt 32,5 pt unter der Oberkante.
        #expect(WidgetMetrics.rectangularSize.height - padding.bottom - lines == 32.5)
        #expect(WidgetMetrics.rectangularArcCountOpacity == 0.75)
    }

    @Test("Maße der Live-Aktivität wie im CSS: 366 breit, höchstens 160 hoch, Countdown 30 und 38 pt")
    func liveActivityMetrics() {
        #expect(LiveActivityMetrics.lockScreenWidth == 366)
        #expect(LiveActivityMetrics.lockScreenHeight <= 160)
        #expect(LiveActivityMetrics.countSize == 30)
        #expect(LiveActivityMetrics.bigSize == 38)
        #expect(LiveActivityMetrics.expandedInset == 24)
        #expect(DayArcMetrics.liveActivity.size == CGSize(width: 330, height: 122))
    }

    @Test("der Verlauf mit 160° läuft von oben links nach unten rechts und trifft die Ecken")
    func gradient() {
        let points = LiveActivityMetrics.gradientPoints(size: CGSize(width: 366, height: 154))
        #expect(abs(points.start.x - 0.3739) < 0.001)
        #expect(abs(points.start.y + 0.3234) < 0.001)
        #expect(abs(points.end.x - 0.6261) < 0.001)
        #expect(abs(points.end.y - 1.3234) < 0.001)
    }

    // MARK: - Dynamic Type (Phase 11: „Begrenzt mitwachsen“)

    @Test("die Texte wachsen wie Fließtext, höchstens auf das 1,2-Fache, nie kleiner als im Prototyp", arguments: [
        (DynamicTypeSize.xSmall, 1.0), (.medium, 1.0), (.large, 1.0), (.xLarge, 19.0 / 17), (.xxLarge, 1.2),
        (.xxxLarge, 1.2), (.accessibility1, 1.2), (.accessibility5, 1.2),
    ])
    func textScale(size: DynamicTypeSize, expected: Double) {
        #expect(abs(WidgetMetrics.textScale(for: size) - expected) < 0.001)
    }

    @Test("passt der Inhalt nicht, versucht das Widget die halbe Zugabe, dann die Größe des Prototyps")
    func textScaleSteps() {
        #expect(WidgetMetrics.textScaleSteps(for: .large) == [1])
        #expect(WidgetMetrics.textScaleSteps(for: .accessibility3) == [1.2, 1.1, 1])
    }

    @Test("die Schriften folgen dem Faktor; ohne Faktor die Größen des Prototyps")
    func scaledFonts() {
        #expect(WidgetMetrics.timeFont() == Font.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
        #expect(WidgetMetrics.nameFont(1.2) == Font.system(size: 17 * 1.2, weight: .semibold))
        #expect(WidgetMetrics.listFont(1, isNext: true) == Font.system(size: 13, weight: .bold).monospacedDigit())
    }

    // MARK: - Hilfen

    /// Die Aktivität für Maghrib, angemeldet um 14:25 mit den Mock-Zeiten für Berlin.
    private func maghribContent() throws -> LiveActivityContent {
        let place = FixtureTimes.city("berlin").map { $0.place(named: "Berlin") } ?? berlin()
        let now = FixtureTimes.referenceDay.date(at: FixtureTimes.referenceTime, in: place.timeZone)
        let plan = LiveActivityPlanner(source: FixtureTimesSource()).plan(
            at: now, place: place, settings: CalculationSettings(),
            options: LiveActivityPlanner.Options(leadMinutes: 30, cityName: "Berlin", isCurrentLocation: true, showKerahat: true)
        )
        return try #require(plan.first).content
    }
}

#endif
