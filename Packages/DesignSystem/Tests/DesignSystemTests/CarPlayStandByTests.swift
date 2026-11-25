#if DEBUG

import CoreGraphics
import Foundation
import PrayerCore
import SwiftUI
import Testing
@testable import DesignSystem

/// CarPlay und StandBy (Phase 19, Spec § 12): das kleine Widget ohne Hintergrund, das neue Widget „Tagesbogen“ und die
/// Live-Aktivität „klein“ – welche Zeilen in welchem Zustand stehen, die Maße aus dem Prototyp (`ARCS.cpw`, `.cpw-*`,
/// `LAS`, `.las-*`) und die Farben.
///
/// Gerechnet wird mit den Mock-Zeiten für Berlin am 10.11.2026: um 14:25 läuft Asr, um 16:05 die Verbotszeit vor
/// Maghrib (15:42–16:27). Die Sollwerte des Bogens stammen aus dem Prototyp (`arcPoint()` mit `ARCS.cpw`, im Browser
/// ausgeführt).
@Suite("CarPlay und StandBy")
struct CarPlayStandByTests {

    // MARK: - Hilfen

    private func content(
        _ time: String, city: String = "berlin", isCurrentLocation: Bool = true, showKerahat: Bool = true
    ) -> PrayerWidgetContent {
        let fixture = CatalogOutsideState.fixture(city: city, time: time).widget
        return PrayerWidgetContent(
            state: fixture.state, cityName: fixture.cityName, isCurrentLocation: isCurrentLocation,
            clockOffset: fixture.clockOffset, showKerahat: showKerahat, style: fixture.style
        )
    }

    private func activity(_ time: String) throws -> LiveActivityContent {
        try #require(CatalogOutsideState.fixture(time: time).liveActivity)
    }

    private func layout(_ city: String, _ time: String) -> DayArcLayout {
        DayArcLayout(
            phase: CatalogFixtures.phase(city: city, time: time), metrics: .smallWidget, showKerahat: true,
            isRightToLeft: false
        )
    }

    private func close(_ point: CGPoint, _ x: CGFloat, _ y: CGFloat) -> Bool {
        abs(point.x - x) < 0.0006 && abs(point.y - y) < 0.0006
    }

    // MARK: - Kleines Widget „Nächstes Gebet“ (§ 12.1)

    @Test("mit Hintergrund wie bisher: Stadt, Gebet, Uhrzeit, Countdown – auch in der Verbotszeit ohne sie")
    func smallWithBackground() {
        let expected: [SmallWidgetLine] = [.city("Berlin", showsArrow: false), .prayer(.maghrib), .time("16:27"), .countdown]
        #expect(SmallPrayerWidget.lines(for: content("14:25:01"), showsBackground: true) == expected)
        #expect(SmallPrayerWidget.lines(for: content("16:05:00"), showsBackground: true) == expected)
    }

    @Test("ohne Hintergrund (StandBy, CarPlay): ohne Stadt, in der Verbotszeit „Verbotszeit bis 16:27“")
    func smallWithoutBackground() {
        #expect(SmallPrayerWidget.lines(for: content("14:25:01"), showsBackground: false) == [
            .prayer(.maghrib), .time("16:27"), .countdown,
        ])
        #expect(SmallPrayerWidget.lines(for: content("16:05:00"), showsBackground: false) == [
            .prayer(.maghrib), .time("16:27"), .countdown, .kerahat(L10n.kerahatNow(b: "16:27")),
        ])
        // Nach Sonnenaufgang läuft die Verbotszeit bis 07:59; das nächste Ereignis ist Dhuhr.
        #expect(SmallPrayerWidget.lines(for: content("07:30:00"), showsBackground: false) == [
            .prayer(.dhuhr), .time("11:52"), .countdown, .kerahat(L10n.kerahatNow(b: "07:59")),
        ])
        // Ohne den Schalter „Verbotszeiten zeigen“ keine Zeile.
        #expect(!SmallPrayerWidget.lines(for: content("16:05:00", showKerahat: false), showsBackground: false)
            .contains { if case .kerahat = $0 { true } else { false } })
    }

    @Test("ohne Zeiten oder Ort der Hinweis, mit und ohne Hintergrund")
    func smallMessages() {
        let noTimes = PrayerWidgetContent(state: .noTimes, cityName: "Tromsø", isCurrentLocation: false)
        let noPlace = PrayerWidgetContent(state: .noPlace, cityName: "", isCurrentLocation: false)
        for showsBackground in [true, false] {
            #expect(SmallPrayerWidget.lines(for: noTimes, showsBackground: showsBackground) == [
                .city("Tromsø", showsArrow: false), .message(L10n.noTimes),
            ])
            #expect(SmallPrayerWidget.lines(for: noPlace, showsBackground: showsBackground) == [
                .appName, .message(L10n.citySheetTitle),
            ])
        }
    }

    @Test("ohne Hintergrund wie `.cpw-next`: Name 19 pt, Uhrzeit 46 pt, „in …“ 15 pt, Verbotszeit 11,5 pt – passt in 158 pt")
    func bareMetrics() {
        #expect(WidgetMetrics.smallReferenceSize == CGSize(width: 158, height: 158))
        #expect(WidgetMetrics.barePadding == EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))
        #expect(WidgetMetrics.bareNameSize == 19 && WidgetMetrics.bareTimeSize == 46)
        #expect(WidgetMetrics.bareCountSize == 15 && WidgetMetrics.bareKerahatSize == 11.5)
        #expect(WidgetMetrics.bareTimeFont() == Font.system(size: 46, weight: .semibold, design: .rounded).monospacedDigit())
        // Höhe mit allen vier Zeilen: 21,85 + 3 + 46 + 5 + 18 + 6 + 13,8 = 113,65 pt; dazu 24 pt Rand.
        let lines = WidgetMetrics.bareNameSize * WidgetMetrics.bareNameLineHeight
            + WidgetMetrics.bareTimeTop + WidgetMetrics.bareTimeSize * WidgetMetrics.bareTimeLineHeight
            + WidgetMetrics.bareCountTop + WidgetMetrics.bareCountSize * WidgetMetrics.bareCountLineHeight
            + WidgetMetrics.bareKerahatTop + WidgetMetrics.bareKerahatSize * WidgetMetrics.bareKerahatLineHeight
        #expect(abs(lines - 113.65) < 0.001)
        #expect(lines + WidgetMetrics.barePadding.top + WidgetMetrics.barePadding.bottom <= WidgetMetrics.smallReferenceSize.height)
    }

    // MARK: - Widget „Tagesbogen“ (§ 12.2)

    @Test("Tagesbogen: im Bogen Gebet · Uhrzeit und Countdown, darunter der Ort mit Pfeil – in der Verbotszeit „Verbotszeit bis …“")
    func arcWidgetLines() {
        #expect(SmallArcPrayerWidget.lines(for: content("14:25:01")) == [
            .prayer(.maghrib), .time(L10n.p_maghrib + " · 16:27"), .countdown, .city("Berlin", showsArrow: true),
        ])
        #expect(SmallArcPrayerWidget.lines(for: content("16:05:00")).last == .kerahat(L10n.kerahatNow(b: "16:27")))
        // Der Pfeil steht nur beim aktuellen Standort; ohne den Schalter steht auch in der Verbotszeit der Ort.
        #expect(SmallArcPrayerWidget.lines(for: content("14:25:01", isCurrentLocation: false)).last == .city("Berlin", showsArrow: false))
        #expect(SmallArcPrayerWidget.lines(for: content("16:05:00", showKerahat: false)).last == .city("Berlin", showsArrow: true))
    }

    @Test("Tagesbogen ohne Hintergrund (StandBy, CarPlay) wie „Nächstes Gebet“: kein Bogen, Uhrzeit groß, ohne Stadt",
          arguments: ["14:25:01", "16:05:00", "07:30:00"])
    func arcWidgetWithoutBackground(time: String) {
        let content = content(time)
        #expect(SmallArcPrayerWidget.lines(for: content, showsBackground: false)
            == SmallPrayerWidget.lines(for: content, showsBackground: false))
        #expect(!SmallArcPrayerWidget.lines(for: content, showsBackground: false)
            .contains { if case .city = $0 { true } else { false } })
        // Mit Hintergrund bleibt der Bogen: „Maghrib · 16:27“ im Bogen statt der Uhrzeit allein.
        #expect(SmallArcPrayerWidget.lines(for: content) != SmallPrayerWidget.lines(for: content, showsBackground: false))
    }

    @Test("Tagesbogen: die Verbotszeit endet nach der Rechtsschule – Schafii nach Sonnenaufgang 25 statt 45 Minuten")
    func arcWidgetMadhab() throws {
        let fixture = try #require(FixtureTimes.city("berlin"))
        let place = fixture.place(named: "Berlin")
        let now = FixtureTimes.referenceDay.date(at: try #require(ClockTime("07:30")), in: place.timeZone)
        let state = CatalogOutsideState.make(
            source: FixtureTimesSource(), place: place, cityName: "Berlin", isCurrentLocation: true,
            settings: CalculationSettings(madhab: .shafii), showKerahat: true, now: now, clockOffset: 0
        )
        #expect(SmallArcPrayerWidget.lines(for: state.widget).last == .kerahat(L10n.kerahatNow(b: "07:39")))
    }

    @Test("ARCS.cpw: 146 × 84 pt, Radius 80, Gebete 15/18 pt mit Symbol, Spur 6 pt, Knopf 5 pt, ohne Zeiten")
    func arcWidgetMetrics() {
        let metrics = DayArcMetrics.smallWidget
        #expect(metrics.size == CGSize(width: 146, height: 84))
        #expect(metrics.center == CGPoint(x: 73, y: 100))
        #expect(metrics.radius == 80 && metrics.endAngle == 0.66)
        #expect(metrics.markerRadius == 7.5 && metrics.currentMarkerRadius == 9)
        #expect(metrics.symbolSize == 9.5 && metrics.currentSymbolSize == 10.5 && metrics.glowRadius == 12)
        #expect(metrics.knobRadius == 5)
        #expect(metrics.trackWidth == 6 && metrics.kerahatWidth == 6 && metrics.kerahatOnTrack)
        #expect(!metrics.showsTimes && metrics.contentBottomInset == 0)
        #expect(DayArcStyle.smallWidget.metrics == .smallWidget)
        // Bogen, Abstand und Zeile darunter passen mit dem Rand in 158 × 158.
        let height = WidgetMetrics.arcPadding.top + metrics.size.height + WidgetMetrics.arcFooterTop
            + WidgetMetrics.arcFooterSize * WidgetMetrics.arcFooterLineHeight + WidgetMetrics.arcPadding.bottom
        #expect(height <= WidgetMetrics.smallReferenceSize.height)
        #expect(WidgetMetrics.arcPadding.leading + metrics.size.width + WidgetMetrics.arcPadding.trailing == 158)
    }

    @Test("Tagesbogen um 14:25 wie im Prototyp: Lage der Gebete, Maghrib und Ischa eng, der Knopf hinter Asr")
    func arcWidgetBerlin() {
        let layout = layout("berlin", "14:25:01")
        let centers = layout.markers.map(\.center)
        #expect(close(centers[0], 9.801, 50.951))
        #expect(close(centers[1], 25.509, 35.622))
        #expect(close(centers[2], 74.026, 20.007))
        #expect(close(centers[3], 97.509, 23.847))
        #expect(close(centers[4], 121.684, 36.519))
        #expect(close(centers[5], 136.199, 50.951))
        #expect(layout.markers.map(\.radius) == [7.5, 7.5, 7.5, 9, 7.5, 7.5])
        #expect(layout.markers.map(\.isTight) == [false, false, false, false, true, true])
        #expect(abs(layout.knobCenter.x - 101.908) < 0.002 && abs(layout.knobCenter.y - 25.406) < 0.002)
    }

    @Test("Tagesbogen in Jakarta um 17:57: Sonnenaufgang und Ischa eng wie im Prototyp")
    func arcWidgetJakarta() {
        let layout = layout("jakarta", "17:57:01")
        #expect(layout.markers.map(\.isTight) == [false, true, false, false, false, true])
        #expect(close(layout.markers[1].center, 18.349, 41.576))
        #expect(close(layout.markers[4].center, 128.36, 42.248))
    }

    @Test("Tagesbogen in Farben der Zeiten-Seite: Knopf weiß mit Ring in Akzent, ohne Schatten; Ring enger Gebete in der Widget-Fläche",
          arguments: [ColorScheme.light, .dark])
    func arcWidgetColors(scheme: ColorScheme) {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let resolved = { (color: Color) in color.resolve(in: environment) }
        let colors = DayArcStyle.smallWidget.colors
        #expect(resolved(colors.knob) == resolved(.white))
        #expect(resolved(colors.knobStroke) == resolved(Palette.accent) && colors.knobStrokeWidth == 2)
        #expect(colors.knobShadow == nil)
        #expect(resolved(colors.ring) == resolved(Palette.backgroundCell))
        #expect(resolved(colors.kerahat) == resolved(Palette.kerahat) && colors.kerahatOpacity == 0.92)
        #expect(resolved(colors.track) == resolved(Palette.arcTrack))
    }

    // MARK: - Live-Aktivität „klein“ (§ 12.3)

    @Test("Größen laut HIG; die Kopfzeile nur in 240 × 100")
    func smallSizes() throws {
        let content = try activity("14:25:01")
        #expect(LiveActivityMetrics.smallSizes.map(\.height) == [100, 78, 78, 80.5])
        let headers = LiveActivityMetrics.smallSizes.map {
            LiveActivitySmallLayout(content: content, isStale: false, height: $0.height).showsHeader
        }
        #expect(headers == [true, false, false, false])
        // Kopf und Bogen (15 − 1 − 3 + 72 pt) passen in 100 pt, nicht in 80,5 pt.
        #expect(LiveActivityMetrics.smallHeaderMinHeight > 80.5 && LiveActivityMetrics.smallHeaderMinHeight <= 100)
    }

    @Test("um 14:25: Kopf mit Ort, im Bogen „Maghrib · 16:27“")
    func smallRunning() throws {
        let content = try activity("14:25:01")
        let tall = LiveActivitySmallLayout(content: content, isStale: false, height: 100)
        #expect(tall.headerTrailing == "Berlin")
        #expect(tall.arcCaption == L10n.p_maghrib + " · 16:27" && !tall.captionIsProhibited)
        #expect(tall.endedLines == nil)
        let flat = LiveActivitySmallLayout(content: content, isStale: false, height: 78)
        #expect(flat.headerTrailing == nil)
        #expect(flat.arcCaption == L10n.p_maghrib + " · 16:27")
    }

    @Test("in der Verbotszeit: „Verbotszeit bis 16:27“ im Kopf – in den flachen Größen statt Gebet und Uhrzeit im Bogen")
    func smallProhibited() throws {
        let content = try activity("16:05:00")
        #expect(content.isProhibited)
        let tall = LiveActivitySmallLayout(content: content, isStale: false, height: 100)
        #expect(tall.headerTrailing == L10n.kerahatNow(b: "16:27"))
        #expect(tall.arcCaption == L10n.p_maghrib + " · 16:27" && !tall.captionIsProhibited)
        let flat = LiveActivitySmallLayout(content: content, isStale: false, height: 80.5)
        #expect(flat.arcCaption == L10n.kerahatNow(b: "16:27") && flat.captionIsProhibited)
    }

    @Test("nach dem Wechsel zwei Zeilen: der grüne Teil vor der Verbotszeit „Verbotszeit ab 15:42“, der orange „hat begonnen“")
    func smallEnded() throws {
        let green = LiveActivitySmallLayout(content: try activity("14:25:01"), isStale: true, height: 78)
        #expect(green.isEnded && !green.showsHeader)
        #expect(green.endedLines == .init(title: L10n.p_maghrib + " · 16:27", trailing: L10n.kerahatFrom(a: "15:42")))
        let orange = LiveActivitySmallLayout(content: try activity("16:05:00"), isStale: true, height: 100)
        #expect(orange.endedLines == .init(title: L10n.p_maghrib + " · 16:27", trailing: L10n.laBegan))
        #expect(!orange.showsHeader)
    }

    @Test("Zeichnung des Sperrbildschirm-Widgets in den Farben der Live-Aktivität, volle Deckkraft")
    func smallStyle() {
        let look = LiveActivityLook(style: AppStyle(liveActivity: .mono, isInverted: false), isProhibited: true)
        let style = DayArcStyle.liveActivitySmall(look)
        #expect(style.metrics == .lockScreen)
        #expect(style.colors.knobStrokeWidth == 1.6)
        // Schwarz-weiß bleibt gestreift, wie auf dem Sperrbildschirm.
        #expect(style.colors.kerahatDash == [2.4, 2.2])
        #expect(LiveActivityMetrics.smallBackgroundOpacity == 1)
        #expect(LiveActivityMetrics.backgroundOpacity == 0.3)
        #expect(AppMarkMetrics.side(for: .smallHeader) == 14 && AppMarkMetrics.cornerRadius(for: .smallHeader) == 3.5)
    }

    // MARK: - Katalog

    @Test("Katalog: die Live-Aktivität „klein“ liegt unter der des Sperrbildschirms, in den Größen der HIG, innerhalb von 390 pt")
    func catalogFrames() {
        let live = CatalogOutsideMetrics.smallActivityFrames
        #expect(live.map(\.size) == LiveActivityMetrics.smallSizes)
        #expect(live.allSatisfy { $0.minX >= 0 && $0.maxX <= CatalogMetrics.referenceWidth && $0.maxY < 874 - 20 })
        #expect(live[0].minY > CatalogOutsideMetrics.lockScreenTop + LiveActivityMetrics.lockScreenHeight)
        let carplay = CatalogOutsideMetrics.smallWidgetFrames + CatalogOutsideMetrics.endedActivityFrames
        #expect(carplay.allSatisfy { $0.maxX <= CatalogMetrics.referenceWidth })
        for (index, frame) in carplay.enumerated() {
            #expect(carplay[(index + 1)...].allSatisfy { !$0.intersects(frame) })
        }
    }
}

#endif
