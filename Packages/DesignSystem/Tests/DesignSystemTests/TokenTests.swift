import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Tokens müssen die Werte aus Design Spec § 2 und dem `:root`-CSS des Prototyps tragen.
@Suite("Tokens")
struct TokenTests {

    private func hex(_ color: Color, dark: Bool = false) -> String {
        RGBA(color, dark: dark).hexString
    }

    // MARK: - Farben

    @Test("Pine Teal ist der Akzent: #1F7A6D hell, #4CC2AE dunkel")
    func accent() {
        #expect(hex(Palette.accent) == "#1F7A6D")
        #expect(hex(Palette.accent, dark: true) == "#4CC2AE")
    }

    @Test("Schrift auf Akzent: Weiß hell, #04221D dunkel")
    func onAccent() {
        #expect(hex(Palette.onAccent) == "#FFFFFF")
        #expect(hex(Palette.onAccent, dark: true) == "#04221D")
    }

    @Test("accent-tint ist der Akzent mit 13 % Deckkraft", arguments: [false, true])
    func accentTint(dark: Bool) {
        let tint = RGBA(Palette.accentTint, dark: dark)
        #expect(tint.hexString == hex(Palette.accent, dark: dark))
        #expect(abs(tint.alpha - 0.13) < 0.001)
    }

    @Test("Sekundärschrift: hell #6C6C70, dunkel die Systemfarbe")
    func textSecondary() {
        #expect(RGBA(Palette.textSecondary, dark: false) == RGBA(hex: 0x6C6C70))
        let system = UIColor.secondaryLabel.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(RGBA(Palette.textSecondary, dark: true) == RGBA(Color(uiColor: system), dark: true))
    }

    @Test("die Systemflächen haben die Werte, mit denen der Prototyp mischt")
    func systemBackgrounds() {
        #expect(hex(Palette.backgroundGrouped) == "#F2F2F7")
        #expect(hex(Palette.backgroundGrouped, dark: true) == "#000000")
        #expect(hex(Palette.backgroundCell) == "#FFFFFF")
        #expect(hex(Palette.backgroundCell, dark: true) == "#1C1C1E")
    }

    @Test("arc-track: Akzent zu 20 % auf dem Hintergrund, dunkel zu 30 %")
    func arcTrack() {
        #expect(hex(Palette.arcTrack) == "#C8DADB")
        #expect(hex(Palette.arcTrack, dark: true) == "#173A34")
        #expect(RGBA(Palette.arcTrack, dark: false).alpha == 1)
    }

    @Test("Karte des laufenden Gebets: Akzent zu 15 % auf der Kartenfarbe")
    func currentRow() {
        #expect(hex(Palette.currentRow) == "#DDEBE9")
        #expect(hex(Palette.currentRow, dark: true) == "#233534")
    }

    @Test("Kerahat: #C7862A und #9A6212 hell, #D9A04E und #E3B36B dunkel")
    func kerahat() {
        #expect(hex(Palette.kerahat) == "#C7862A")
        #expect(hex(Palette.kerahat, dark: true) == "#D9A04E")
        #expect(hex(Palette.kerahatText) == "#9A6212")
        #expect(hex(Palette.kerahatText, dark: true) == "#E3B36B")
    }

    @Test("die Live-Aktivität nimmt in beiden Erscheinungsbildern den hellen Akzent", arguments: [false, true])
    func liveActivity(dark: Bool) {
        #expect(hex(Palette.LiveActivity.background, dark: dark) == "#1F7A6D")
        #expect(hex(Palette.LiveActivity.marker, dark: dark) == "#62A299")
        #expect(hex(Palette.LiveActivity.kerahat, dark: dark) == "#F3C979")
        #expect(abs(RGBA(Palette.LiveActivity.track, dark: dark).alpha - 0.28) < 0.001)
        // Phase 11: voll Weiß statt 80 % (Kontrast 5,2 : 1).
        #expect(RGBA(Palette.LiveActivity.time, dark: dark).alpha == 1)
    }

    @Test("Farbwerte lassen sich lesen, mischen und wieder schreiben")
    func rgba() {
        #expect(RGBA(hex: 0x1F7A6D).hexString == "#1F7A6D")
        #expect(RGBA(hex: 0x04221D).hexString == "#04221D")
        #expect(RGBA.black.mixed(0.5, with: .white).hexString == "#808080")
        #expect(RGBA.white.mixed(1, with: .black) == .white)
        #expect(RGBA.white.mixed(0, with: .black) == .black)
        #expect(RGBA(hex: 0x1F7A6D).opacity(0.2).alpha == 0.2)
    }

    // MARK: - Abstände und Radien

    @Test("Abstände: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40")
    func spacing() {
        #expect(Spacing.scale == [4, 8, 12, 16, 20, 24, 32, 40])
    }

    @Test("Maße: Rand 16, Tippziel 44, Gebetskarte 52 mit 8 Abstand, Leiste 52 mit 8 Abstand")
    func layout() {
        #expect(Layout.inset == 16)
        #expect(Layout.minTapTarget == 44)
        #expect(Layout.minRowHeight == 44)
        #expect(Layout.prayerRowHeight == 52)
        #expect(Layout.prayerRowGap == 8)
        #expect(Layout.topBarHeight == 52)
        #expect(Layout.chipGap == 8)
    }

    @Test("Radien: Karten 26, Gebetskarten 18")
    func radii() {
        #expect(Radius.group == 26)
        #expect(Radius.row == 18)
        #expect([Radius.xs, Radius.sm, Radius.playerCard, Radius.widget, Radius.sheet] == [6, 10, 20, 22, 24])
    }

    @Test("Schatten: SwiftUI bekommt die halbe Weichzeichnung des CSS")
    func shadows() {
        #expect(ShadowToken.row.blur == 2)
        #expect(ShadowToken.row.y == 1)
        #expect(ShadowToken.currentRow.blur == 22)
        #expect(ShadowToken.currentRow.y == 8)
        #expect(ShadowToken.selectedChip.blur == 26)
        #expect(ShadowToken.selectedChip.y == 10)
    }

    // MARK: - Schrift

    @Test("die Skala hat die Größen des Prototyps")
    func typeScaleSizes() {
        #expect(TypeScale.allCases.map(\.pointSize) == [34, 28, 22, 20, 17, 17, 16, 15, 13, 12, 11])
    }

    @Test("die Skala entspricht den Textstilen des Systems bei der Standardgröße", arguments: TypeScale.allCases)
    func typeScaleMatchesSystem(style: TypeScale) {
        let large = UITraitCollection(preferredContentSizeCategory: .large)
        let font = UIFont.preferredFont(forTextStyle: style.uiTextStyle, compatibleWith: large)
        #expect(font.pointSize == style.pointSize)
    }

    @Test("Countdown: 64 pt, im Bogen 56 pt; ab zehn Stunden ×0,86 bzw. 50 pt")
    func countdownSizes() {
        #expect(Typography.countdownSize(inArc: false, isWide: false) == 64)
        #expect(abs(Typography.countdownSize(inArc: false, isWide: true) - 55.04) < 0.001)
        #expect(Typography.countdownSize(inArc: true, isWide: false) == 56)
        #expect(Typography.countdownSize(inArc: true, isWide: true) == 50)
        #expect(Typography.countdownWideThreshold == 10 * 3600)
    }

    @Test("der Countdown wächst mit Dynamic Type höchstens auf das 1,05-Fache")
    func countdownCap() {
        #expect(abs(Typography.countdownSize(inArc: false, isWide: false, typeScale: 1.35) - 67.2) < 0.001)
        #expect(abs(Typography.countdownSize(inArc: true, isWide: false, typeScale: 3.1) - 58.8) < 0.001)
        #expect(abs(Typography.countdownSize(inArc: true, isWide: false, typeScale: 1.03) - 57.68) < 0.001)
        #expect(Typography.countdownSize(inArc: true, isWide: false, typeScale: 0.9) == 50.4)
    }
}
