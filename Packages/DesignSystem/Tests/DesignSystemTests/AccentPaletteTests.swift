import Foundation
import PrayerCore
import SwiftUI
import Testing
@testable import DesignSystem

/// Die 24 Grundfarben (Nachtrag zu Phase 18, Spec § 11.7) – dieselben Prüfungen wie im Bauskript des Vorschlags
/// (`build_stil.py`): Kontrast mindestens 4,5 : 1, deutlich verschieden voneinander, von der Verbotszeit, vom
/// Signalrot und von der grauen Zweitschrift. Dazu die violetten Töne der Verbotszeit bei warmen Grundfarben.
@Suite("Grundfarben")
struct AccentPaletteTests {

    // MARK: - Rechnen

    private func linear(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ color: RGBA) -> Double {
        0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// Kontrast nach WCAG 2.
    private func contrast(_ a: RGBA, _ b: RGBA) -> Double {
        let (hi, lo) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (hi + 0.05) / (lo + 0.05)
    }

    /// sRGB → OKLab (Björn Ottosson).
    private func oklab(_ color: RGBA) -> (Double, Double, Double) {
        let r = linear(color.red), g = linear(color.green), b = linear(color.blue)
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return (
            0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }

    private func distance(_ a: RGBA, _ b: RGBA) -> Double {
        let (x, y) = (oklab(a), oklab(b))
        return sqrt(pow(x.0 - y.0, 2) + pow(x.1 - y.1, 2) + pow(x.2 - y.2, 2))
    }

    /// OKLab → sRGB-Hex; `nil` außerhalb des Farbraums (wie `_to_hex` im Bauskript).
    private func hex(_ L: Double, _ a: Double, _ b: Double) -> UInt32? {
        let l = pow(L + 0.3963377774 * a + 0.2158037573 * b, 3)
        let m = pow(L - 0.1055613458 * a - 0.0638541728 * b, 3)
        let s = pow(L - 0.0894841775 * a - 1.2914855480 * b, 3)
        let rgb = [
            4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
        ]
        guard rgb.allSatisfy({ $0 >= -1e-4 && $0 <= 1 + 1e-4 }) else { return nil }
        func gamma(_ c: Double) -> Double { c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1 / 2.4) - 0.055 }
        return rgb.reduce(0) { value, channel in
            value << 8 | UInt32((max(0, min(1, gamma(max(0, min(1, channel))))) * 255).rounded())
        }
    }

    /// `kerahat_violet()`: derselbe Ton mit gleicher Helligkeit und Buntheit auf OKLCH-Ton 300 gedreht; außerhalb des
    /// Farbraums sinkt die Buntheit in Schritten von 0,002.
    private func violet(_ color: UInt32) -> UInt32? {
        let (L, a, b) = oklab(RGBA(hex: color))
        var chroma = hypot(a, b)
        let hue = 300 * Double.pi / 180
        while chroma >= 0 {
            if let out = hex(L, chroma * cos(hue), chroma * sin(hue)) { return out }
            chroma -= 0.002
        }
        return nil
    }

    // MARK: - Liste

    @Test("24 Farben in vier Reihen zu sechs, Petrol zuerst, die Standardreihe wie in der ersten Fassung")
    func list() {
        #expect(AccentColorID.allCases.count == 24)
        #expect(AccentColorID.allCases.count % AccentColorID.rowLength == 0)
        #expect(AccentColorID.allCases.first == .standard)
        #expect(AccentColorID.standard == .teal)
        #expect(AccentColorID.standardRow == [.teal, .green, .blue, .violet, .berry, .graphite])
        #expect(AccentColorID.allCases.filter(\.isWarm) == [.orange, .gold, .sand])
        #expect(Set(AccentColorID.allCases.map(\.localizedName)).count == 24)
    }

    @Test("Werte wie ACCENTS im Prototyp (Stichprobe)")
    func values() {
        #expect(AccentColorID.teal.light == RGBA(hex: 0x1F7A6D))
        #expect(AccentColorID.teal.dark == RGBA(hex: 0x4CC2AE))
        #expect(AccentColorID.teal.onDark == RGBA(hex: 0x04221D))
        #expect(AccentColorID.teal.light == Palette.Values.accentLight)
        #expect(AccentColorID.orange.light == RGBA(hex: 0xA44C03))
        #expect(AccentColorID.mono.dark == RGBA(hex: 0xF2F2F7))
        #expect(AccentColorID.sand.onDark == RGBA(hex: 0x24180B))
    }

    // MARK: - Kontrast

    @Test("jede Farbe erreicht 4,5 : 1 – hell auf Weiß und #F2F2F7, dunkel auf #1C1C1E, Schrift auf der dunklen Fläche",
          arguments: AccentColorID.allCases)
    func contrasts(accent: AccentColorID) {
        #expect(contrast(accent.light, .white) >= 4.5)
        #expect(contrast(accent.light, RGBA(hex: 0xF2F2F7)) >= 4.5)
        #expect(contrast(.white, accent.light) >= 4.5)
        #expect(contrast(accent.dark, RGBA(hex: 0x1C1C1E)) >= 4.5)
        #expect(contrast(accent.onDark, accent.dark) >= 4.5)
    }

    @Test("die violette Verbotszeit bleibt als Schrift lesbar")
    func violetText() {
        #expect(contrast(RGBA(hex: KerahatTone.violet[0x9A6212] ?? 0), .white) >= 4.5)
        #expect(contrast(RGBA(hex: KerahatTone.violet[0xE3B36B] ?? 0), RGBA(hex: 0x1C1C1E)) >= 4.5)
    }

    // MARK: - Abstände

    @Test("jede Farbe ab Reihe 2 hält zu jeder anderen mindestens 0,065 Abstand (OKLab), hell und dunkel")
    func variation() {
        let all = AccentColorID.allCases
        for (index, first) in all.enumerated() {
            for second in all[(index + 1)...] where !second.isInStandardRow {
                #expect(distance(first.light, second.light) >= 0.065, "\(first) – \(second) hell")
                #expect(distance(first.dark, second.dark) >= 0.065, "\(first) – \(second) dunkel")
            }
        }
    }

    @Test("Abstand zu Verbotszeit und Signalrot mindestens 0,12, zur grauen Zweitschrift mindestens 0,07",
          arguments: AccentColorID.allCases)
    func signals(accent: AccentColorID) {
        let k = { (hex: UInt32) in KerahatTone.rgba(hex, accent: accent) }
        let light = [k(0xC7862A), RGBA(hex: 0xFF3B30)]
        let dark = [k(0xD9A04E), k(0xEC8530), RGBA(hex: 0xFF453A)]
        #expect(light.map { distance(accent.light, $0) }.min() ?? 0 >= 0.12)
        #expect(dark.map { distance(accent.dark, $0) }.min() ?? 0 >= 0.12)
        #expect(distance(accent.light, RGBA(hex: 0x6C6C70)) >= 0.07)
        #expect(distance(accent.dark, RGBA(hex: 0x9A9A9F)) >= 0.07)
    }

    // MARK: - Violette Verbotszeit

    @Test("jeder violette Ton ist der gedrehte Orangeton des Prototyps")
    func violetTones() {
        for (orange, expected) in KerahatTone.violet {
            #expect(violet(orange) == expected, "\(String(orange, radix: 16))")
        }
    }

    @Test("violett nur bei Orange, Gold und Sand")
    func warmOnly() {
        #expect(KerahatTone.rgba(0xC7862A, accent: .teal) == RGBA(hex: 0xC7862A))
        #expect(KerahatTone.rgba(0xC7862A, accent: .orange) == RGBA(hex: 0xA282D9))
        #expect(KerahatTone.rgba(0xF0A257, accent: .sand) == RGBA(hex: 0xC3A2FC))
        #expect(KerahatTone.rgba(0xF0A257, accent: .berry) == RGBA(hex: 0xF0A257))
    }

    @Test("ein eigener Speicher der Grundfarbe beginnt bei Petrol und behält die Wahl")
    func store() {
        let store = AccentStore()
        #expect(store.accent == .teal)
        store.accent = .ocean
        #expect(store.accent == .ocean)
    }
}

/// Die Farben der Live-Aktivität je Stil – die Variablen `--la-*` des Prototyps (Spec § 11.7).
@Suite("Live-Aktivität: Stile")
struct LiveActivityColorsTests {

    private func colors(
        _ accent: AccentColorID = .teal, _ kind: LiveActivityStyle = .full, inverted: Bool = false, prohibited: Bool = false
    ) -> LiveActivityColors {
        LiveActivityLook(style: AppStyle(accent: accent, liveActivity: kind, isInverted: inverted), isProhibited: prohibited).colors
    }

    @Test("Farbig wie bisher (Spec § 10.3): Verlauf der Grundfarbe, in der Verbotszeit Orange")
    func full() {
        let regular = colors()
        #expect(regular.base == RGBA(hex: 0x1F7A6D))
        #expect(regular.highlight == 0.82 && regular.shade == 0.78)
        #expect(regular.foreground == .white)
        #expect(regular.line == .white)
        #expect(regular.kerahat == RGBA(hex: 0xF3C979))
        #expect(regular.island == RGBA(hex: 0x4CC2AE))
        let prohibited = colors(prohibited: true)
        #expect(prohibited.base == RGBA(hex: 0xEC8530))
        #expect(prohibited.highlight == 0.80 && prohibited.shade == 0.76)
        #expect(prohibited.markerBegunSymbol == RGBA(hex: 0xC4661F))
        #expect(prohibited.kerahat == RGBA(hex: 0xFFE2BF))
        #expect(prohibited.island == RGBA(hex: 0xF0A257))
    }

    @Test("bei warmen Grundfarben wird jedes Orange der Verbotszeit violett")
    func warm() {
        #expect(colors(.orange, prohibited: true).base == RGBA(hex: 0xB38AF6))
        #expect(colors(.gold).kerahat == RGBA(hex: 0xD8C4FF))
        #expect(colors(.sand, .arc, prohibited: true).warning == RGBA(hex: 0xD0B8FF))
        #expect(colors(.orange, prohibited: true).island == RGBA(hex: 0xC3A2FC))
        #expect(colors(.orange).islandKerahat == RGBA(hex: 0xC0A1F7))
        #expect(colors(.teal).islandKerahat == RGBA(hex: 0xE0A84F))
    }

    @Test("Farbig, invertiert: weiß, Bogen und Schrift in der Grundfarbe")
    func fullInverted() {
        let colors = colors(.ocean, inverted: true)
        #expect(colors.base == .white)
        #expect(colors.line == AccentColorID.ocean.light)
        #expect(colors.foreground == AccentColorID.ocean.light.mixed(0.80, with: .black))
        #expect(colors.kerahat == RGBA(hex: 0xC7862A))
        #expect(colors.kerahatPastOpacity == 0.85)
        let prohibited = self.colors(inverted: true, prohibited: true)
        #expect(prohibited.foreground == RGBA(hex: 0x8A4409))
        #expect(prohibited.line == RGBA(hex: 0xB85C12))
    }

    @Test("Nur Bogen: Grund ohne Farbe, Bogen in der dunklen Grundfarbe; invertiert weiß mit heller Grundfarbe")
    func arc() {
        let colors = colors(.blue, .arc)
        #expect(colors.base == RGBA(hex: 0x2E2E33))
        #expect(colors.line == AccentColorID.blue.dark)
        #expect(colors.markerBegunSymbol == AccentColorID.blue.onDark)
        #expect(colors.knob == .white && colors.knobRing == AccentColorID.blue.dark)
        #expect(self.colors(.blue, .arc, prohibited: true).warning == RGBA(hex: 0xF8B877))
        let inverted = self.colors(.blue, .arc, inverted: true)
        #expect(inverted.base == .white)
        #expect(inverted.foreground == RGBA(hex: 0x1C1C1E))
        #expect(inverted.line == AccentColorID.blue.light)
        #expect(self.colors(.blue, .arc, inverted: true, prohibited: true).warning == RGBA(hex: 0x9A4D0E))
    }

    @Test("Schwarz-weiß: ohne Farbe, Verbotszeiten gestreift, auch in der Verbotszeit und bei warmen Farben")
    func mono() {
        for accent in [AccentColorID.teal, .orange] {
            for prohibited in [false, true] {
                let colors = colors(accent, .mono, prohibited: prohibited)
                #expect(colors.isMonochrome)
                #expect(colors.base == RGBA(hex: 0x2E2E33))
                #expect(colors.kerahat == .white)
                #expect(colors.island == .white)
                #expect(colors.warning == nil)
            }
        }
        let inverted = colors(.teal, .mono, inverted: true)
        #expect(inverted.base == .white && inverted.line == RGBA(hex: 0x1C1C1E))
    }

    @Test("ältere Inhalte ohne Stil sehen aus wie der Standard")
    func standardLook() {
        #expect(LiveActivityLook.standard.colors == colors())
    }
}
