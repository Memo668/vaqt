import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Bausteine müssen so groß sein wie im Prototyp. Gemessen wird die Größe, die SwiftUI ihnen gibt –
/// so fällt auf, wenn ein Stil des Systems eigenen Innenabstand oder Zeilenabstand mitbringt.
@MainActor
@Suite("Bausteine: Größen")
struct LayoutTests {

    /// Die Größe, die eine Ansicht von sich aus einnimmt.
    private func size<V: View>(_ view: V) -> CGSize {
        UIHostingController(rootView: view.fixedSize()).sizeThatFits(in: CGSize(width: 2000, height: 2000))
    }

    /// Die Höhe einer Ansicht bei vorgegebener Breite.
    private func height<V: View>(_ view: V, width: CGFloat) -> CGFloat {
        let host = UIHostingController(
            rootView: view.frame(width: width, alignment: .leading).fixedSize(horizontal: false, vertical: true)
        )
        return host.sizeThatFits(in: CGSize(width: width, height: 10_000)).height
    }

    /// SwiftUI rundet Texthöhen auf Gerätepixel; ein Drittel pt Spielraum deckt das ab.
    private func close(_ value: CGFloat, _ expected: CGFloat, tolerance: CGFloat = 0.34) -> Bool {
        abs(value - expected) <= tolerance
    }

    // MARK: - Zeilenhöhen

    @Test("Zeilenhöhe wie im CSS: Der Abstand der Zeilen kommt auf das Maß des Prototyps")
    func lineLayout() {
        let body = TypeScale.body.metrics(for: .large)
        #expect(body.pointSize == 17)
        #expect(close(body.lineHeight, 20.287, tolerance: 0.01))
        #expect(close(body.tightPitch, 20, tolerance: 0.01))
        // Fließtext 17 pt mit Zeilenhöhe 1,3: 22,1 pt je Zeile.
        let text = TypeScale.lineLayout(multiple: 1.3, metrics: body)
        #expect(close(text.lineSpacing, 2.1, tolerance: 0.01))
        #expect(close(text.padding, 0.906, tolerance: 0.01))

        // Eine Zeile, die niedriger ist als die Schrift: zwischen den Zeilen nichts, oben und unten weniger.
        let title = TypeScale.lineLayout(multiple: 1.1, metrics: TypeScale.title2.metrics(for: .large))
        #expect(title.lineSpacing == 0)
        #expect(title.padding < 0)
    }

    @Test("ein-, zwei- und dreizeiliger Text ist so hoch wie Zeilen × Zeilenhöhe", arguments: [
        (TypeScale.body, 1.3, 22.1),
        (.subheadline, 1.25, 18.75),
        (.subheadline, 1.3, 19.5),
        (.caption1, 1.25, 15.0),
        (.footnote, 1.4, 18.2),
    ])
    func textHeights(style: TypeScale, multiple: Double, lineHeight: Double) {
        let lines = ["Ag", "Ag\nAg", "Ag\nAg\nAg"]
        for (index, text) in lines.enumerated() {
            let measured = height(Text(text).textStyle(style, lineHeight: multiple), width: 300)
            // Das System rundet jede Zeile und den Block auf Gerätepixel: bis zu zwei Drittel pt.
            #expect(
                close(measured, CGFloat(index + 1) * lineHeight, tolerance: 0.7),
                "\(style), \(index + 1) Zeilen: \(measured)"
            )
        }
    }

    @Test("der Countdown im Bogen steht in einem Kasten von 56 × 1,05 pt")
    func countdownLineBox() {
        let text = Text("2:01:59")
            .font(Typography.countdown(inArc: true))
            .lineHeight(Typography.countdownLineHeight, fontSize: Typography.countdownSizeInArc)
        #expect(close(size(text).height, 58.8))
    }

    // MARK: - Glass

    @Test("der runde Glass-Button ist so groß wie die Leiste hoch ist: 52 × 52 pt")
    func circleButton() {
        let measured = size(GlassCircleButton(systemImage: "gearshape", label: "Einstellungen") {})
        #expect(measured == CGSize(width: 52, height: 52))
    }

    @Test("ein Chip ist 52 pt hoch; ohne Titel ist er ein Kreis von 52 pt")
    func chips() {
        let chip = size(GlassChip("Zeiten", systemImage: "clock", isSelected: true) {})
        #expect(chip.height == 52)
        // Innenabstand 14 + Symbol 22 + Abstand 7 + Titel + Innenabstand 18.
        #expect(chip.width > 14 + 22 + 7 + 18 + 40)
        #expect(chip.width < 14 + 22 + 7 + 18 + 60)

        let collapsed = size(GlassChip("Zeiten", systemImage: "clock", isSelected: false, showsTitle: false) {})
        #expect(collapsed == CGSize(width: 52, height: 52))
    }

    @Test("in der schwebenden Leiste stehen die Elemente mit 8 pt Abstand und 16 pt Rand")
    func floatingBar() {
        let bar = FloatingBar {
            GlassCircleButton(systemImage: "gearshape", label: "Einstellungen") {}
            GlassChip("Qibla", systemImage: "safari", isSelected: false, showsTitle: false) {}
            GlassChip("Anleitung", symbol: .prayerRug, isSelected: false, showsTitle: false) {}
        }
        #expect(height(bar, width: 390) == 52)
        // Ohne den Rahmen über die ganze Breite: 16 + 52 + 8 + 52 + 8 + 52 + 16.
        #expect(size(bar).width == 204)
    }

    @Test("der Chip „Anleitung“ ist mit der eigenen Zeichnung so groß wie mit einem SF Symbol")
    func prayerRugChip() {
        let drawn = size(GlassChip("Anleitung", symbol: .prayerRug, isSelected: true) {})
        let system = size(GlassChip("Anleitung", systemImage: "clock", isSelected: true) {})
        #expect(drawn == system)
        #expect(size(GlassChip("Anleitung", symbol: .prayerRug, isSelected: false, showsTitle: false) {}) == CGSize(width: 52, height: 52))
    }

    // MARK: - Hinweise

    @Test("der Toast ist 36 pt hoch: 9 + 15 × 1,2 + 9")
    func toast() {
        #expect(close(size(Toast("Fadschr: Lautlos", systemImage: "bell")).height, 36))
        #expect(close(size(Toast("Kopiert")).height, 36))
    }

    @Test("das Banner ist mit zwei Zeilen Text 52 pt hoch, wie in iphone/17")
    func banner() {
        let banner = Banner(
            "Standortzugriff aus – Stadt manuell gewählt", systemImage: "location.slash", actionTitle: "Ändern"
        ) {}
        // 4 + Tippziel 44 + 4; der Text daneben hat zwei Zeilen zu 19,5 pt.
        #expect(close(height(banner, width: 358), 52))
    }

    @Test("die Hinweis-Pille ist 26,25 pt hoch: 5 + 13 × 1,25 + 5")
    func hintPill() {
        let measured = size(HintPill("Offline", systemImage: "wifi.slash")).height
        // Das System rundet Text und Block auf Gerätepixel: gemessen 26,67 pt.
        #expect(close(measured, 26.25, tolerance: 0.7), "\(measured)")
    }

    @Test("die Hinweiskarte: 12 pt oben und unten, Titel 21 pt, 2 pt Abstand, Text in Zeilen zu 18,2 pt")
    func noteCard() {
        // Eine Zeile Text ohne Titel: Das Symbol (1 + 18 pt) ist höher als die Zeile (18,2 pt): 12 + 19 + 12.
        let plain = height(NoteCard(text: "Kurz"), width: 358)
        #expect(close(plain, 43, tolerance: 0.7), "\(plain)")
        // Mit Titel: 12 + 21 + 2 + 18,2 + 12.
        let titled = height(NoteCard(title: "Hohe Breitengrade", text: "Kurz"), width: 358)
        #expect(close(titled, 65.2, tolerance: 0.7), "\(titled)")
    }

    // MARK: - Karten

    @Test("der Stepper ist 94 × 32 pt groß")
    func stepper() {
        #expect(size(StepperPill("Tage", onDecrement: {}, onIncrement: {})) == CGSize(width: 94, height: 32))
    }

    @Test("die Karte hat 20 pt Innenabstand und füllt die Breite")
    func card() {
        let card = Card { Color.clear.frame(height: 40) }
        #expect(height(card, width: 358) == 80)
    }

    @Test("Fakten-Kachel: 10 pt oben, 11 pt unten, dazwischen Wert, 3 pt und Bezeichnung")
    func factTiles() {
        // 10 + 18,75 + 3 + 15 + 11
        #expect(close(height(FactTile(value: "leise", caption: "Rezitation"), width: 100.67), 57.75))
        // 10 + 2 × 18,75 + 3 + 15 + 11 – wie in design/screenshots/iphone/40
        #expect(close(height(FactTile(value: "4 vorher (freiwillig)", caption: "Sunna"), width: 100.67), 76.5))
        // 10 + 22 × 1,1 + 3 + 15 + 11
        #expect(close(height(FactTile(value: "4", caption: "Rakʿa Fard", isProminent: true), width: 100.67), 63.2))
    }

    #if DEBUG

    @Test("jede Gebetskarte ist 52 pt hoch, mit und ohne Kerahat-Zeile")
    func prayerRows() {
        for row in PrayerRowModel.rows(for: CatalogFixtures.phase(time: "16:05")) {
            #expect(height(PrayerRow(row, bell: .sound) {}, width: 358) == 52, "\(row.prayer)")
        }
    }

    @Test("der Bogen hat die Größe seiner Maße: 358 × 180 pt, in der Live-Aktivität 330 × 122 pt")
    func arcSizes() {
        let phase = CatalogFixtures.phase(time: "14:25")
        #expect(size(DayArc(phase: phase)) == CGSize(width: 358, height: 180))
        #expect(size(DayArc(phase: phase, style: .liveActivity(.standard))) == CGSize(width: 330, height: 122))
        #expect(size(CatalogHero(phase: phase)) == CGSize(width: 358, height: 180))
    }

    #endif
}
