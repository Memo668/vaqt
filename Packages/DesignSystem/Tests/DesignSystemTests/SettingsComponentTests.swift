import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Bausteine der Einstellungen, des Onboardings und des Adhan-Players: Geometrie und Texte wie
/// `group()`, `.row`, `adhanSheet()`, `fmtDur()` und `appGlyph` im Prototyp.
@MainActor
@Suite("Einstellungen, Onboarding, Adhan – Bausteine")
struct SettingsComponentTests {

    // MARK: - Wellenform

    @Test("44 Balken mit den Höhen der Formel aus adhanSheet()")
    func waveformHeights() {
        #expect(AdhanWaveformLayout.heights.count == 44)
        // Werte des Prototyps (h.toFixed(4)) für einige Balken.
        let expected: [Int: Double] = [0: 0.2300, 1: 0.3602, 10: 0.5799, 21: 0.6451, 22: 0.9974, 43: 0.2673]
        for (index, value) in expected {
            #expect(abs(Double(AdhanWaveformLayout.heights[index]) - value) < 0.0001, "Balken \(index)")
        }
        #expect(AdhanWaveformLayout.heights.allSatisfy { $0 > 0.17 && $0 <= 1 })
    }

    @Test("gespielt sind floor(pos/dur·44) Balken", arguments: [
        (0.0, 0), (0.5, 22), (12.4 / 27, 20), (1.0, 44), (1.4, 44), (-1.0, 0),
    ])
    func playedBars(progress: Double, bars: Int) {
        #expect(AdhanWaveformLayout.playedBars(progress: progress) == bars)
    }

    @Test("die Balken sind über die ganze Breite verteilt: erster am Anfang, letzter am Ende")
    func waveformSpacing() {
        let layout = AdhanWaveformLayout(width: 334)
        #expect(layout.centerX(of: 0) == 2)
        #expect(abs(layout.centerX(of: 43) - 332) < 0.001)
        let gap = layout.centerX(of: 1) - layout.centerX(of: 0) - AdhanWaveformLayout.barWidth
        #expect(abs(gap - (334 - 44 * 4) / 43) < 0.001)
    }

    @Test("die Balken schwingen zwischen 50 und 100 % ihrer Höhe, jeder versetzt")
    func swing() {
        for time in stride(from: 0.0, to: 2.3, by: 0.05) {
            let scale = AdhanWaveformLayout.swing(bar: 7, at: time)
            #expect(scale >= 0.5 && scale <= 1)
        }
        #expect(AdhanWaveformLayout.swing(bar: 0, at: 0) == 0.5)
        #expect(abs(AdhanWaveformLayout.swing(bar: 0, at: 1.15 / 2) - 1) < 0.0001)
        #expect(AdhanWaveformLayout.swing(bar: 0, at: 1) != AdhanWaveformLayout.swing(bar: 1, at: 1))
    }

    @Test("Zeiten wie fmtDur(): Minuten und zwei Stellen Sekunden, abgerundet", arguments: [
        (0.0, "0:00"), (9.99, "0:09"), (27, "0:27"), (29.5, "0:29"), (61, "1:01"), (-2, "0:00"),
    ])
    func time(seconds: TimeInterval, text: String) {
        #expect(AdhanTime.text(seconds) == text)
    }

    // MARK: - Zeilen

    @Test("ein kurzer Wert bleibt in der Zeile; ein langer bricht in seinen 52 % um, statt den Titel zu verdrängen")
    func valueLayout() {
        func height(value: String) -> CGFloat {
            let host = UIHostingController(rootView: ValueRowLabel("Datenschutz", value: value))
            return host.sizeThatFits(in: CGSize(width: 338, height: CGFloat.infinity)).height
        }
        let short = height(value: "MWL")
        let long = height(value: "Keine Daten erhoben, aber ein sehr langer Wert, der umbricht")
        #expect(short > 20 && short < 25)
        #expect(long > 2 * short)
    }

    // MARK: - Zeichen der App

    @Test("die Mondsichel liegt zwischen den beiden Kreisen des SVG-Pfads")
    func glyphGeometry() {
        // Beide Bögen gehen durch die Endpunkte des Pfads (18,6 | 15,6) und (8,4 | 5,4).
        for point in [CGPoint(x: 18.6, y: 15.6), CGPoint(x: 8.4, y: 5.4)] {
            let outer = hypot(point.x - AppGlyphGeometry.outerCenter.x, point.y - AppGlyphGeometry.outerCenter.y)
            let inner = hypot(point.x - AppGlyphGeometry.innerCenter.x, point.y - AppGlyphGeometry.innerCenter.y)
            #expect(abs(outer - AppGlyphGeometry.outerRadius) < 0.001)
            #expect(abs(inner - AppGlyphGeometry.innerRadius) < 0.001)
        }
        let path = AppGlyph().path(in: CGRect(x: 0, y: 0, width: 24, height: 24))
        // In der Sichel: links unten im großen Kreis; nicht im ausgesparten Kreis oben rechts.
        #expect(path.contains(CGPoint(x: 6, y: 14)))
        #expect(!path.contains(CGPoint(x: 15, y: 9)))
        #expect(path.contains(AppGlyphGeometry.dotCenter))
    }

    // MARK: - Onboarding

    @Test("die Knöpfe des Onboardings sitzen 46 pt über dem unteren Rand, davon 34 pt Home-Indikator")
    func onboardingMetrics() {
        #expect(OnboardingMetrics.actionsBottom + 34 == 46)
        #expect(OnboardingMetrics.buttonHeight == 50)
    }
}
