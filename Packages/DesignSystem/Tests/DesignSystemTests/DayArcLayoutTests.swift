#if DEBUG

import CoreGraphics
import Foundation
import PrayerCore
import SwiftUI
import Testing
@testable import DesignSystem

/// Die Geometrie des Bogens muss dieselben Zahlen liefern wie `ARCS`, `arcAngle()`, `arcPoint()`,
/// `arcLabelPos()` und `arcHTML()` im Prototyp.
///
/// Die Sollwerte stammen aus dem Code des Prototyps selbst (Zeilen 1627–1642 wörtlich in Node
/// ausgeführt), für die Mock-Zeiten vom 10.11.2026 und auf drei Nachkommastellen gerundet.
@Suite("Tagesbogen: Geometrie")
struct DayArcLayoutTests {

    // MARK: - Hilfen

    private func layout(
        _ city: String = "berlin", _ time: String, metrics: DayArcMetrics = .home,
        showKerahat: Bool = true, rtl: Bool = false
    ) -> DayArcLayout {
        DayArcLayout(
            phase: CatalogFixtures.phase(city: city, time: time), metrics: metrics,
            showKerahat: showKerahat, isRightToLeft: rtl
        )
    }

    private func close(_ value: CGFloat, _ expected: CGFloat) -> Bool {
        abs(value - expected) < 0.0006
    }

    private func close(_ point: CGPoint, _ x: CGFloat, _ y: CGFloat) -> Bool {
        close(point.x, x) && close(point.y, y)
    }

    private func marker(_ layout: DayArcLayout, _ prayer: Prayer) -> DayArcLayout.Marker {
        guard let marker = layout.markers.first(where: { $0.prayer == prayer }) else {
            preconditionFailure("Der Bogen zeigt alle fünf Gebete")
        }
        return marker
    }

    // MARK: - Maße

    @Test("ARCS.home: 358 × 180 pt, Radius 162, etwa 128°, Spur 12 pt, Marker 30 und 34 pt, Knopf 14 pt")
    func homeMetrics() {
        let metrics = DayArcMetrics.home
        #expect(metrics.size == CGSize(width: 358, height: 180))
        #expect(metrics.center == CGPoint(x: 179, y: 206))
        #expect(metrics.radius == 162)
        #expect(metrics.endAngle == 0.45)
        #expect(abs(metrics.sweep * 180 / .pi - 128.43) < 0.01)
        #expect(metrics.trackWidth == 12)
        #expect(metrics.markerRadius * 2 == 30)
        #expect(metrics.currentMarkerRadius * 2 == 34)
        #expect(metrics.symbolSize == 16)
        #expect(metrics.currentSymbolSize == 18)
        #expect(metrics.glowRadius == 25)
        #expect(metrics.knobRadius * 2 == 14)
        #expect(metrics.timeBox == CGSize(width: 34, height: 13))
        #expect(metrics.timeGap == 5)
        #expect(metrics.timeBelow == 12)
        // Kerahat auf der Spur (Spec § 9.3): so breit wie sie, ohne Abstand nach innen.
        #expect(metrics.kerahatInset == 0)
        #expect(metrics.kerahatWidth == 12)
        #expect(metrics.kerahatOnTrack)
        #expect(metrics.timeFontSize == 12)
        #expect(metrics.timeScales)
        #expect(metrics.tabularTimes)
    }

    @Test("ARCS.la: 330 × 122 pt, Radius 166, Spur 7 pt, Marker 21 pt")
    func liveActivityMetrics() {
        let metrics = DayArcMetrics.liveActivity
        #expect(metrics.size == CGSize(width: 330, height: 122))
        #expect(metrics.center == CGPoint(x: 165, y: 190))
        #expect(metrics.radius == 166)
        #expect(metrics.endAngle == 0.6)
        #expect(metrics.trackWidth == 7)
        #expect(metrics.markerRadius * 2 == 21)
        #expect(metrics.currentMarkerRadius == 12)
        #expect(metrics.symbolSize == 12)
        #expect(metrics.currentSymbolSize == 13)
        #expect(metrics.glowRadius == 17)
        #expect(metrics.knobRadius == 4.5)
        #expect(metrics.timeBox == CGSize(width: 28, height: 11))
        #expect(metrics.timeGap == 3)
        #expect(metrics.timeBelow == 9)
        // Bis Phase 14 noch dünn innerhalb (Spec § 9.11 folgt).
        #expect(metrics.kerahatInset == 13.5)
        #expect(metrics.kerahatWidth == 2)
        #expect(!metrics.kerahatOnTrack)
        #expect(metrics.timeFontSize == 10.5)
        #expect(!metrics.timeScales)
        #expect(!metrics.tabularTimes)
    }

    @Test("arcAngle und arcPoint: Fadschr links unten, Ischa rechts unten, die Mitte ganz oben")
    func pointsOnTheArc() {
        let metrics = DayArcMetrics.home
        #expect(metrics.angle(at: 0) == 0.45)
        #expect(abs(metrics.angle(at: 1) - (Double.pi - 0.45)) < 1e-12)
        #expect(close(metrics.point(at: 0), 33.128, 135.536))
        #expect(close(metrics.point(at: 1), 324.872, 135.536))
        #expect(close(metrics.point(at: 0.5), 179, 44))
        #expect(close(metrics.point(at: 0.5, radius: 143), 179, 63))
    }

    // MARK: - Die Zustände der Referenzbilder

    @Test("14:25, Asr läuft (iphone/10): Lage der Marker und der Zeiten")
    func asrActive() {
        let layout = layout("berlin", "14:25")
        #expect(layout.markers.map(\.prayer) == [.fajr, .dhuhr, .asr, .maghrib, .isha])
        #expect(layout.markers.map(\.state) == [.passed, .passed, .current, .upcoming, .upcoming])
        #expect(layout.markers.map(\.radius) == [15, 15, 17, 15, 15])
        #expect(layout.markers.map(\.symbolSize) == [16, 16, 18, 16, 16])
        #expect(layout.markers.map(\.time.description) == ["05:16", "11:52", "14:00", "16:27", "18:17"])
        #expect(layout.markers.allSatisfy { !$0.isTight })

        #expect(close(marker(layout, .fajr).center, 33.128, 135.536))
        #expect(close(marker(layout, .dhuhr).center, 181.557, 44.02))
        #expect(close(marker(layout, .asr).center, 239.565, 55.747))
        #expect(close(marker(layout, .maghrib).center, 295.783, 93.725))
        #expect(close(marker(layout, .isha).center, 324.872, 135.536))

        // Unter den Endmarkern, sonst außen am Bogen.
        #expect(close(marker(layout, .fajr).timeCenter, 33.128, 162.536))
        #expect(close(marker(layout, .dhuhr).timeCenter, 181.98, 17.256))
        #expect(close(marker(layout, .asr).timeCenter, 252.42, 23.856))
        #expect(close(marker(layout, .maghrib).timeCenter, 322.283, 68.249))
        #expect(close(marker(layout, .isha).timeCenter, 324.872, 162.536))

        #expect(close(CGFloat(marker(layout, .dhuhr).fraction), 0.507))
        #expect(close(CGFloat(marker(layout, .asr).fraction), 0.671))
        #expect(close(CGFloat(marker(layout, .maghrib).fraction), 0.859))
    }

    @Test("14:25: Der Bogen ist bis „jetzt“ gefüllt, dort sitzt der Knopf")
    func asrActiveProgress() {
        let layout = layout("berlin", "14:25")
        #expect(close(CGFloat(layout.progress), 0.703))
        #expect(layout.showsKnob)
        #expect(close(layout.knobCenter, 250.181, 60.476))
        #expect(layout.begunCount == 3)
    }

    @Test("vor Fadschr (iphone/12): nichts gefüllt, nichts hervorgehoben, kein Knopf")
    func beforeFajr() {
        let layout = layout("berlin", "05:14")
        #expect(layout.progress == 0)
        #expect(!layout.showsKnob)
        #expect(layout.markers.allSatisfy { $0.state == .upcoming })
        #expect(layout.markers.allSatisfy { $0.radius == 15 })
        #expect(layout.begunCount == 0)
        // Ohne laufendes Gebet steht die Zeit von Asr etwas näher am Marker.
        #expect(close(marker(layout, .asr).timeCenter, 251.672, 25.711))
    }

    @Test("08:04, nach Sonnenaufgang (iphone/13): Fadschr hat begonnen, keines läuft, der Knopf ist zu sehen")
    func afterSunrise() {
        let layout = layout("berlin", "08:04")
        #expect(layout.markers.map(\.state) == [.passed, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(close(CGFloat(layout.progress), 0.215))
        #expect(layout.showsKnob)
        #expect(close(layout.knobCenter, 82.435, 75.926))
        #expect(layout.begunCount == 1)
        #expect(layout.kerahat.allSatisfy { !$0.isActive })
    }

    @Test("07:30 (iphone/14): Das Kerahat-Fenster nach Sonnenaufgang läuft")
    func kerahatAfterSunrise() {
        let layout = layout("berlin", "07:30")
        #expect(layout.kerahat.map(\.id) == [.sunrise, .zenith, .sunset])
        #expect(layout.kerahat.map(\.isActive) == [true, false, false])
        #expect(close(layout.knobCenter, 70.221, 85.953))
    }

    @Test("16:05 (iphone/15): Das Kerahat-Fenster vor Maghrib läuft, Asr bleibt hervorgehoben")
    func kerahatBeforeMaghrib() {
        let layout = layout("berlin", "16:05")
        #expect(layout.kerahat.map(\.isActive) == [false, false, true])
        #expect(marker(layout, .asr).state == .current)
        #expect(close(layout.knobCenter, 288.466, 86.58))
    }

    @Test("nach Ischa (iphone/16): alles gefüllt, Ischa hervorgehoben, kein Knopf")
    func afterIsha() {
        let layout = layout("berlin", "23:30")
        #expect(layout.progress == 1)
        #expect(!layout.showsKnob)
        #expect(layout.markers.map(\.state) == [.passed, .passed, .passed, .passed, .current])
        #expect(layout.begunCount == 5)
        // Der größere Marker schiebt die Zeit darunter um 2 pt nach unten.
        #expect(close(marker(layout, .isha).timeCenter, 324.872, 164.536))
    }

    @Test("Jakarta 17:57 (iphone/22): Ischa liegt eng an Maghrib und bekommt den Ring")
    func jakartaCloseMarkers() {
        let layout = layout("jakarta", "17:57")
        #expect(layout.markers.map(\.state) == [.passed, .passed, .passed, .current, .upcoming])
        #expect(layout.markers.map(\.isTight) == [false, false, false, false, true])
        #expect(close(marker(layout, .asr).center, 258.04, 64.59))
        #expect(close(marker(layout, .maghrib).center, 309.869, 110.515))
        #expect(close(marker(layout, .isha).center, 324.872, 135.536))
        // Die Zeit von Maghrib stößt an den rechten Rand der Zeichnung: 358 − 34 / 2.
        #expect(close(marker(layout, .maghrib).timeCenter, 341, 87.196))
        #expect(close(layout.knobCenter, 311.756, 113.157))
        #expect(layout.begunCount == 4)
    }

    @Test("eng bleibt eng, auch wenn Maghrib nicht läuft; in Berlin ist kein Marker eng", arguments: [
        ("jakarta", "14:00", true),
        ("jakarta", "19:30", true),
        ("berlin", "16:30", false),
        ("berlin", "12:00", false),
    ])
    func tightRule(city: String, time: String, expected: Bool) {
        let layout = layout(city, time)
        #expect(marker(layout, .isha).isTight == expected)
        #expect(layout.markers.dropLast().allSatisfy { !$0.isTight })
    }

    // MARK: - Kerahat

    @Test("Kerahat-Segmente liegen auf der Spur, an den Anteilen der Fenster")
    func kerahatSegments() {
        let layout = layout("berlin", "14:25")
        #expect(layout.kerahatRadius == 162)
        #expect(layout.kerahat.map(\.id) == [.sunrise, .zenith, .sunset])
        let expected: [(Double, Double)] = [(0.151, 0.209), (0.494, 0.507), (0.802, 0.859)]
        for (segment, (start, end)) in zip(layout.kerahat, expected) {
            #expect(close(CGFloat(segment.start), CGFloat(start)))
            #expect(close(CGFloat(segment.end), CGFloat(end)))
        }
        let metrics = layout.metrics
        #expect(close(metrics.point(at: layout.kerahat[0].start, radius: 143), 78.216, 104.553))
        #expect(close(metrics.point(at: layout.kerahat[0].end, radius: 143), 92.122, 92.417))
        #expect(close(metrics.point(at: layout.kerahat[2].start, radius: 143), 268.463, 94.441))
        #expect(close(metrics.point(at: layout.kerahat[2].end, radius: 143), 282.087, 106.893))
        #expect(layout.kerahat.allSatisfy { !$0.isActive })
        // 14:25: Die Fenster nach Sonnenaufgang und vor Dhuhr sind vorbei, das vor Maghrib kommt noch.
        #expect(layout.kerahat.map(\.state) == [.past, .past, .upcoming])
        #expect(layout.kerahatList == "07:14–07:59, 11:42–11:52, 15:42–16:27")
    }

    @Test("Zustände der Kerahat-Abschnitte über den Tag (is-now, is-past)", arguments: [
        ("05:30", [DayArcLayout.KerahatState.upcoming, .upcoming, .upcoming]),
        ("07:30", [.active, .upcoming, .upcoming]),
        ("07:59", [.past, .upcoming, .upcoming]),
        ("11:45", [.past, .active, .upcoming]),
        ("16:05", [.past, .past, .active]),
        ("17:00", [.past, .past, .past]),
    ])
    func kerahatStates(time: String, expected: [DayArcLayout.KerahatState]) {
        #expect(layout("berlin", time).kerahat.map(\.state) == expected)
    }

    @Test("ohne den Schalter „Kerahat-Zeiten zeigen“ gibt es keine Segmente")
    func kerahatOff() {
        #expect(layout("berlin", "07:30", showKerahat: false).kerahat.isEmpty)
    }

    // MARK: - RTL

    @Test("RTL (iphone/20): Fadschr beginnt rechts, alles ist an der Mitte gespiegelt")
    func rightToLeft() {
        let ltr = layout("berlin", "14:25")
        let rtl = layout("berlin", "14:25", rtl: true)
        #expect(rtl.isRightToLeft)
        #expect(close(marker(rtl, .fajr).center, 324.872, 135.536))
        #expect(close(marker(rtl, .dhuhr).center, 176.443, 44.02))
        #expect(close(marker(rtl, .asr).center, 118.435, 55.747))
        #expect(close(marker(rtl, .maghrib).center, 62.217, 93.725))
        #expect(close(marker(rtl, .isha).center, 33.128, 135.536))
        #expect(close(marker(rtl, .asr).timeCenter, 105.58, 23.856))
        #expect(close(marker(rtl, .maghrib).timeCenter, 35.717, 68.249))
        #expect(close(rtl.knobCenter, 107.819, 60.476))

        for (mirrored, original) in zip(rtl.markers, ltr.markers) {
            #expect(close(mirrored.center.x, 358 - original.center.x))
            #expect(mirrored.center.y == original.center.y)
            #expect(close(mirrored.timeCenter.x, 358 - original.timeCenter.x))
            #expect(mirrored.state == original.state)
            // Zahlen werden nicht gespiegelt.
            #expect(mirrored.time == original.time)
        }
        #expect(rtl.progress == ltr.progress)
        #expect(rtl.kerahat == ltr.kerahat)
    }

    // MARK: - Live-Aktivität

    @Test("ARCS.la: dieselbe Zeichnung kleiner und flacher")
    func liveActivityLayout() {
        let layout = layout("berlin", "14:25", metrics: .liveActivity)
        #expect(layout.markers.map(\.radius) == [10.5, 10.5, 12, 10.5, 10.5])
        #expect(layout.markers.map(\.symbolSize) == [12, 12, 13, 12, 12])
        #expect(close(marker(layout, .fajr).center, 27.994, 96.269))
        #expect(close(marker(layout, .dhuhr).center, 167.27, 24.016))
        #expect(close(marker(layout, .asr).center, 219.087, 33.059))
        #expect(close(marker(layout, .maghrib).center, 271.601, 62.751))
        #expect(close(marker(layout, .isha).center, 302.006, 96.269))
        #expect(close(marker(layout, .fajr).timeCenter, 27.994, 115.769))
        #expect(close(marker(layout, .asr).timeCenter, 227.155, 9.648))
        #expect(close(marker(layout, .maghrib).timeCenter, 288.751, 42.279))
        #expect(close(layout.knobCenter, 228.73, 36.721))
        #expect(layout.kerahatRadius == 152.5)
    }

    @Test("ARCS.la, Jakarta: Ischa ist auch im kleinen Bogen eng")
    func liveActivityTight() {
        let layout = layout("jakarta", "17:57", metrics: .liveActivity)
        #expect(layout.markers.map(\.isTight) == [false, false, false, false, true])
        #expect(close(marker(layout, .maghrib).center, 285.757, 76.098))
        #expect(close(marker(layout, .maghrib).timeCenter, 306.823, 56.228))
    }

    // MARK: - Zeichnung

    @Test("der gezeichnete Bogen läuft über die Mitte oben, nicht unten herum", arguments: [false, true])
    func arcPathDirection(rtl: Bool) {
        let metrics = DayArcMetrics.home
        // `boundingBoxOfPath` misst die Kurve selbst; `boundingRect` schlösse die Stützpunkte mit ein.
        let bounds = ArcSegment(metrics: metrics, start: 0, end: 1, radius: nil, isRightToLeft: rtl)
            .path(in: CGRect(origin: .zero, size: metrics.size)).cgPath.boundingBoxOfPath
        #expect(abs(bounds.minX - 33.128) < 0.01)
        #expect(abs(bounds.maxX - 324.872) < 0.01)
        // Der Kreisbogen ist aus Bézierkurven genähert; am Scheitel weicht er um 0,04 pt vom Kreis ab.
        #expect(abs(bounds.minY - 44) < 0.1)
        #expect(abs(bounds.maxY - 135.536) < 0.01)
    }

    @Test("ein Stück des Bogens endet dort, wo der Knopf sitzt", arguments: [false, true])
    func arcPathEnd(rtl: Bool) throws {
        let layout = layout("berlin", "14:25", rtl: rtl)
        let path = ArcSegment(metrics: layout.metrics, start: 0, end: layout.progress, radius: nil, isRightToLeft: rtl)
            .path(in: CGRect(origin: .zero, size: layout.metrics.size))
        let end = try #require(path.currentPoint)
        #expect(abs(end.x - layout.knobCenter.x) < 0.01)
        #expect(abs(end.y - layout.knobCenter.y) < 0.01)
    }

    // MARK: - Fixtures

    @Test("die acht Zustände der Abnahme zeigen den Countdown der Referenzbilder", arguments: [
        ("14:25", "2:01:59"),
        ("vor Fadschr", "1:14"),
        ("08:04", "3:47:59"),
        ("Jakarta", "1:03:59"),
        ("RTL", "2:01:58"),
    ])
    func countdownOfReference(state: String, expected: String) throws {
        let state = try #require(CatalogFixtures.arcStates.first { $0.id == state })
        #expect(CountdownFormat.digital(state.phase.remaining) == expected)
    }

    @Test("der Katalog kennt die acht Zustände aus dem Bauplan")
    func arcStates() {
        #expect(CatalogFixtures.arcStates.map(\.id) == [
            "14:25", "vor Fadschr", "08:04", "07:30", "16:05", "nach Ischa", "Jakarta", "RTL",
        ])
    }
}

#endif
