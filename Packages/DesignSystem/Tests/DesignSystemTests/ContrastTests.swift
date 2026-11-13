import SwiftUI
import Testing
@testable import DesignSystem

/// Kontrast der Farbpaare nach WCAG 2 (Phase 11): die Werte der Spec (§ 2, Zeile 71) und die übrigen Paare,
/// in denen die App Text setzt. Fließtext braucht 4,5 : 1 (AA), große Schrift und Symbole 3 : 1.
@Suite("Kontrast der Farben")
struct ContrastTests {

    // MARK: - Rechnen

    /// Relative Leuchtdichte (WCAG 2.x) einer deckenden Farbe.
    private func luminance(_ color: RGBA) -> Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// Kontrastverhältnis zweier Farben; eine durchscheinende Vordergrundfarbe liegt dabei auf `background`.
    private func ratio(_ foreground: RGBA, on background: RGBA) -> Double {
        let opaque = foreground.alpha < 1 ? RGBA.composite(foreground, over: background) : foreground
        let lighter = max(luminance(opaque), luminance(background))
        let darker = min(luminance(opaque), luminance(background))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private typealias V = Palette.Values
    private let white = RGBA.white
    private let black = RGBA.black

    /// Karte des laufenden Gebets: Akzent zu 15 % auf der Kartenfarbe.
    private var currentRowLight: RGBA { V.accentLight.mixed(V.currentRowShare, with: V.backgroundCellLight) }
    private var currentRowDark: RGBA { V.accentDark.mixed(V.currentRowShare, with: V.backgroundCellDark) }
    /// Sekundärschrift dunkel: die Systemfarbe (durchscheinend).
    private var textSecondaryDark: RGBA { RGBA(Palette.textSecondary, dark: true) }

    // MARK: - Werte der Spec

    @Test("Spec § 2: Akzent auf Weiß 5,2 : 1, dunkler Akzent auf #1C1C1E 7,8 : 1, Schrift auf Akzent ≥ 5 : 1")
    func specValues() {
        #expect(abs(ratio(V.accentLight, on: white) - 5.2) < 0.05)
        #expect(abs(ratio(V.accentDark, on: V.backgroundCellDark) - 7.8) < 0.05)
        #expect(ratio(V.onAccentLight, on: V.accentLight) >= 5)
        #expect(ratio(V.onAccentDark, on: V.accentDark) >= 5)
    }

    @Test("Spec § 2: Sekundärschrift hell 4,7 : 1 auf der Seite und 5,2 : 1 auf einer Karte")
    func textSecondaryLight() {
        #expect(abs(ratio(V.textSecondaryLight, on: V.backgroundGroupedLight) - 4.7) < 0.05)
        #expect(abs(ratio(V.textSecondaryLight, on: V.backgroundCellLight) - 5.2) < 0.05)
    }

    // MARK: - Übrige Paare mit Text

    @Test("Fließtext erreicht 4,5 : 1: Akzent auf der Seite, Sekundärschrift dunkel, Kerahat-Text auf Karten")
    func bodyTextPairs() {
        #expect(ratio(V.accentLight, on: V.backgroundGroupedLight) >= 4.5)
        #expect(ratio(V.accentDark, on: V.backgroundGroupedDark) >= 4.5)
        #expect(ratio(textSecondaryDark, on: V.backgroundCellDark) >= 4.5)
        #expect(ratio(textSecondaryDark, on: V.backgroundGroupedDark) >= 4.5)
        #expect(ratio(V.kerahatTextLight, on: V.backgroundCellLight) >= 4.5)
        #expect(ratio(V.kerahatTextDark, on: V.backgroundCellDark) >= 4.5)
    }

    @Test("Karte des laufenden Gebets, dunkel: Akzent und Kerahat-Text erreichen 4,5 : 1")
    func currentRowDarkPairs() {
        #expect(ratio(V.accentDark, on: currentRowDark) >= 4.5)
        #expect(ratio(V.kerahatTextDark, on: currentRowDark) >= 4.5)
    }

    /// Hell lag der Text auf der Karte des laufenden Gebets mit den Farben der Spec knapp unter 4,5 : 1
    /// (Akzent 4,2, Sekundärschrift 4,3, Kerahat-Text 4,15 : 1). Seit Phase 11 ist er dort 8 % dunkler
    /// („Schrift dort dunkler“).
    @Test("Karte des laufenden Gebets, hell: die dunklere Schrift erreicht 4,5 : 1")
    func currentRowLightPairs() {
        #expect(abs(ratio(V.accentLight, on: currentRowLight) - 4.22) < 0.05)
        #expect(ratio(RGBA(Palette.currentRowAccent, dark: false), on: currentRowLight) >= 4.5)
        #expect(ratio(RGBA(Palette.currentRowTextSecondary, dark: false), on: currentRowLight) >= 4.5)
        #expect(ratio(RGBA(Palette.currentRowKerahatText, dark: false), on: currentRowLight) >= 4.5)
    }

    @Test("Karte des laufenden Gebets: die Farben der Schrift", arguments: [false, true])
    func currentRowColors(dark: Bool) {
        #expect(RGBA(Palette.currentRowAccent, dark: dark).hexString == (dark ? "#4CC2AE" : "#1D7064"))
        #expect(RGBA(Palette.currentRowKerahatText, dark: dark).hexString == (dark ? "#E3B36B" : "#8E5A11"))
        if !dark {
            #expect(RGBA(Palette.currentRowTextSecondary, dark: false).hexString == "#636367")
        }
    }

    @Test("Live-Aktivität: Zeiten am Bogen in Weiß auf dem Akzent erreichen 4,5 : 1")
    func liveActivityTimes() {
        #expect(ratio(RGBA(Palette.LiveActivity.time, dark: false), on: V.accentLight) >= 4.5)
    }
}

private extension RGBA {
    /// `top` deckend auf `bottom` gelegt.
    static func composite(_ top: RGBA, over bottom: RGBA) -> RGBA {
        RGBA(
            red: top.red * top.alpha + bottom.red * (1 - top.alpha),
            green: top.green * top.alpha + bottom.green * (1 - top.alpha),
            blue: top.blue * top.alpha + bottom.blue * (1 - top.alpha)
        )
    }
}
