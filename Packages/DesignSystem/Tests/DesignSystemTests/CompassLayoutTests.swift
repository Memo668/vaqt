import CoreGraphics
import Foundation
import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Geometrie des Kompasses muss dieselben Zahlen liefern wie `dialSVG()` und `.compass` im
/// Prototyp: eine Zeichnung mit 300 Einheiten Kantenlänge, dargestellt auf 280 pt.
///
/// Die Sollwerte sind die Koordinaten aus `dialSVG()`, mit 280 ÷ 300 in pt umgerechnet und in das Feld
/// des Kompasses verschoben (Mitte bei 140 | 140).
@Suite("Kompass: Geometrie")
struct CompassLayoutTests {

    private let layout = CompassLayout()

    private func close(_ value: CGFloat, _ expected: CGFloat) -> Bool {
        abs(value - expected) < 0.0006
    }

    private func close(_ point: CGPoint, _ x: CGFloat, _ y: CGFloat) -> Bool {
        close(point.x, x) && close(point.y, y)
    }

    private func tick(_ degrees: Int) -> CompassLayout.Tick {
        guard let tick = layout.ticks.first(where: { $0.degrees == degrees }) else {
            preconditionFailure("Die Skala hat alle 5° einen Strich")
        }
        return tick
    }

    private func label(_ degrees: Int) -> CompassLayout.Label {
        guard let label = layout.labels.first(where: { $0.degrees == degrees }) else {
            preconditionFailure("Die Skala hat alle 30° eine Beschriftung")
        }
        return label
    }

    // MARK: - Maße

    @Test("280 pt für 300 Einheiten der Zeichnung")
    func scale() {
        #expect(CompassMetrics.diameter == 280)
        #expect(CompassMetrics.viewBox == 300)
        #expect(close(CompassMetrics.scale, 0.9333))
        #expect(CompassLayout.center == CGPoint(x: 140, y: 140))
    }

    @Test("die Maße aus dialSVG() und dem CSS")
    func metrics() {
        #expect(CompassMetrics.tickStep == 5)
        #expect(CompassMetrics.majorTickStep == 30)
        #expect(CompassMetrics.tickOuterRadius == 144)
        #expect(CompassMetrics.tickInnerRadius == 134)
        #expect(CompassMetrics.majorTickInnerRadius == 127)
        #expect(CompassMetrics.tickWidth == 1.2)
        #expect(CompassMetrics.majorTickWidth == 2)
        #expect(CompassMetrics.labelStep == 30)
        #expect(CompassMetrics.cardinalRadius == 106)
        #expect(CompassMetrics.numberRadius == 109)
        #expect(CompassMetrics.cardinalFontSize == 18)
        #expect(CompassMetrics.numberFontSize == 11)
        #expect(CompassMetrics.needleStartRadius == 12)
        #expect(CompassMetrics.needleEndRadius == 80)
        #expect(CompassMetrics.needleWidth == 3)
        #expect(CompassMetrics.kaabaRadius == 163)
        #expect(CompassMetrics.kaabaSize == 16)
        #expect(CompassMetrics.lubberSize == CGSize(width: 3, height: 26))
        #expect(CompassMetrics.lubberTop == -18)
        #expect(CompassMetrics.centerDotDiameter == 10)
        #expect(CompassMetrics.pulseSpread == 26)
        #expect(CompassMetrics.pulseOpacity == 0.45)
        #expect(CompassMetrics.pulseDuration == 0.8)
    }

    // MARK: - Skala

    @Test("72 Striche alle 5°, jeder sechste lang")
    func tickCount() {
        #expect(layout.ticks.count == 72)
        #expect(layout.ticks.map(\.degrees) == Array(stride(from: 0, to: 360, by: 5)))
        #expect(layout.ticks.filter(\.isMajor).map(\.degrees) == Array(stride(from: 0, to: 360, by: 30)))
    }

    @Test("der Strich bei Nord zeigt nach oben: lang, von Radius 127 bis 144")
    func northTick() {
        let north = tick(0)
        #expect(north.isMajor)
        #expect(close(north.start, 140, 21.4667))
        #expect(close(north.end, 140, 5.6))
    }

    @Test("ein kurzer Strich bei 5°: von Radius 134 bis 144, leicht nach rechts geneigt")
    func minorTick() {
        let minor = tick(5)
        #expect(!minor.isMajor)
        #expect(close(minor.start, 150.9003, 15.4092))
        #expect(close(minor.end, 151.7137, 6.1114))
    }

    @Test("Ost liegt rechts, Süd unten, West links")
    func quarterTicks() {
        #expect(close(tick(90).start, 258.5333, 140))
        #expect(close(tick(90).end, 274.4, 140))
        #expect(close(tick(180).end, 140, 274.4))
        #expect(close(tick(270).end, 5.6, 140))
    }

    @Test("jeder Strich läuft von innen nach außen auf seinem Winkel")
    func tickLengths() {
        for tick in layout.ticks {
            let inner = hypot(tick.start.x - 140, tick.start.y - 140)
            let outer = hypot(tick.end.x - 140, tick.end.y - 140)
            #expect(close(outer, 134.4))
            #expect(close(inner, tick.isMajor ? 118.5333 : 125.0667))
        }
    }

    // MARK: - Beschriftung

    @Test("zwölf Beschriftungen alle 30°: vier Himmelsrichtungen, acht Zahlen")
    func labelCount() {
        #expect(layout.labels.count == 12)
        #expect(layout.labels.map(\.degrees) == Array(stride(from: 0, to: 360, by: 30)))
        #expect(layout.labels.compactMap(\.point) == [.north, .east, .south, .west])
        #expect(layout.labels.filter { $0.point == nil }.map(\.degrees) == [30, 60, 120, 150, 210, 240, 300, 330])
    }

    @Test("die Himmelsrichtungen sitzen bei Radius 106, die Zahlen bei 109")
    func labelPositions() {
        #expect(label(0).point == .north)
        #expect(close(label(0).center, 140, 41.0667))
        #expect(label(90).point == .east)
        #expect(close(label(90).center, 238.9333, 140))
        #expect(close(label(180).center, 140, 238.9333))
        #expect(close(label(270).center, 41.0667, 140))
        #expect(close(label(30).center, 190.8667, 51.8963))
        #expect(close(label(240).center, 51.8963, 190.8667))
    }

    @Test("die Abkürzungen der Himmelsrichtungen kommen aus dem String Catalog")
    func abbreviations() {
        #expect(CompassPoint.allCases.map(\.localizedAbbreviation) == L10n.dirs)
        #expect(Set(CompassPoint.allCases.map(\.localizedAbbreviation)).count == 8)
        #expect(!CompassPoint.allCases.contains { $0.localizedAbbreviation.hasPrefix("dirs") })
    }

    // MARK: - Nadel, Kaaba-Marke, Peilmarke

    @Test("die Nadel läuft von Radius 12 bis 80, ihre Spitze von 79 bis 95")
    func needle() {
        #expect(close(CompassLayout.needle.start, 140, 128.8))
        #expect(close(CompassLayout.needle.end, 140, 65.3333))
        #expect(CompassLayout.needleHead.count == 3)
        #expect(close(CompassLayout.needleHead[0], 140, 51.3333))
        #expect(close(CompassLayout.needleHead[1], 132.5333, 66.2667))
        #expect(close(CompassLayout.needleHead[2], 147.4667, 66.2667))
    }

    @Test("die Kaaba-Marke sitzt außerhalb der Skala: ihre Mitte 12 pt über dem Rand")
    func kaaba() {
        #expect(close(CompassLayout.kaabaCenter, 140, -12.1333))
        // Mit ihrer halben Kantenlänge reicht sie knapp 20 pt über den Rand hinaus.
        let reach = -CompassLayout.kaabaCenter.y + CompassMetrics.kaabaSize * CompassMetrics.scale / 2
        #expect(close(reach, 19.6))
    }

    @Test("die Peilmarke steht mittig oben und reicht von 18 pt über dem Rand bis 8 pt darunter")
    func lubber() {
        #expect(CompassLayout.lubberCenter == CGPoint(x: 140, y: -5))
        #expect(CompassLayout.lubberCenter.y - CompassMetrics.lubberSize.height / 2 == -18)
        #expect(CompassLayout.lubberCenter.y + CompassMetrics.lubberSize.height / 2 == 8)
    }

    // MARK: - Farben und Katalog

    @Test("das „N“ trägt das Rot des Systems", arguments: [false, true])
    func red(dark: Bool) {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let system = UIColor.systemRed.resolvedColor(with: traits)
        #expect(RGBA(Palette.red, dark: dark) == RGBA(Color(uiColor: system), dark: dark))
    }

    #if DEBUG
    @Test("die Zustände des Katalogs: Kurs 98°, ausgerichtet, in Mekka, ohne Kompass")
    func catalogStates() throws {
        let states = CatalogFixtures.compassStates
        #expect(states.map(\.id) == ["Kurs 98°", "ausgerichtet", "in Mekka", "ohne Kompass"])
        #expect(states.map(\.heading) == [98, 137, 138, nil])
        #expect(states.map(\.isAligned) == [false, true, false, false])

        // Berlin: 136,68° – in den Referenzbildern 137°.
        let berlin = try #require(states[0].bearing)
        #expect(abs(berlin - 136.68) < 0.01)
        #expect(states[1].bearing == berlin)
        #expect(states[3].bearing == berlin)
        // In Mekka gibt es keine Richtung und damit keine Nadel.
        #expect(states[2].bearing == nil)
    }

    @Test("ohne Kurs oder ohne Richtung ist nichts ausgerichtet")
    func catalogAlignment() {
        #expect(!CatalogFixtures.CompassState(id: "a", heading: nil, bearing: 137).isAligned)
        #expect(!CatalogFixtures.CompassState(id: "b", heading: 137, bearing: nil).isAligned)
        #expect(CatalogFixtures.CompassState(id: "c", heading: 139.9, bearing: 137).isAligned)
        #expect(!CatalogFixtures.CompassState(id: "d", heading: 141, bearing: 137).isAligned)
    }
    #endif
}
