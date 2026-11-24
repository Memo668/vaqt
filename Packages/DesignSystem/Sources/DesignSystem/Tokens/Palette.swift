import PrayerCore
import SwiftUI
import UIKit

/// Die Farben der App – Design Spec § 2 und das `:root`-CSS des Prototyps (`[data-theme]`).
///
/// Eigene Werte haben nur der Akzent und was daraus gemischt ist, die Sekundärschrift im hellen
/// Erscheinungsbild und die Kerahat-Farben. Alles andere sind die semantischen Systemfarben, deren Werte der
/// Prototyp nachbildet.
///
/// Seit dem Nachtrag zu Phase 18 ist der Akzent die Grundfarbe aus Einstellungen › Stil (Spec § 11.7, 24 Farben,
/// Standard Petrol). Alles, was von ihr abhängt, liest sie aus `AccentStore` – bei jedem Aufbau neu, und eine
/// Ansicht, die so eine Farbe liest, baut sich nach einem Wechsel neu auf. Bei Orange, Gold und Sand sind die
/// Verbotszeiten violett statt orange.
public enum Palette {

    /// Die Grundfarbe, die gerade gilt.
    static var current: AccentColorID {
        AccentStore.shared.accent
    }

    // MARK: - Akzent

    /// `--accent`: die Grundfarbe, z. B. Petrol `#1F7A6D` hell und `#4CC2AE` dunkel. Petrol steht auch im Asset
    /// `AccentColor` der App – für den Start, bevor die Einstellungen gelesen sind.
    public static var accent: Color {
        let accent = current
        return Color(light: accent.light, dark: accent.dark)
    }

    /// `--on-accent`: Schrift und Symbole auf Akzentflächen, `#FFFFFF` hell und dunkel die Schrift der
    /// Grundfarbe (`--on-accent-d`, bei Petrol `#04221D`).
    public static var onAccent: Color {
        Color(light: Values.onAccentLight, dark: current.onDark)
    }

    /// `--accent-tint`: Akzent mit 13 % Deckkraft.
    public static var accentTint: Color {
        let accent = current
        return Color(
            light: accent.light.opacity(Values.accentTintOpacity),
            dark: accent.dark.opacity(Values.accentTintOpacity)
        )
    }

    // MARK: - Schrift

    /// `--label`: die Schriftfarbe des Systems.
    public static let label = Color.primary

    /// `--label-2` (textSecondary): hell `#6C6C70` – 4,7 : 1 auf der Seite, 5,2 : 1 auf einer Karte;
    /// die Sekundärfarbe des Systems käme hell nur auf etwa 3,4 : 1. Dunkel gilt die Systemfarbe.
    public static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel.resolvedColor(with: traits)
            : Values.textSecondaryLight.uiColor
    })

    /// `--label-3`: z. B. das Symbol einer vergangenen Zeile oder eine ausgeschaltete Glocke.
    public static let labelTertiary = Color(uiColor: .tertiaryLabel)

    /// `--label-4`: die Balken der Wellenform im Adhan-Player und die übrigen Punkte im Onboarding.
    public static let labelQuaternary = Color(uiColor: .quaternaryLabel)

    /// `--red`: das Rot des Systems – das „N“ auf der Skala des Kompasses.
    public static let red = Color(uiColor: .systemRed)

    // MARK: - Flächen

    /// `--bg`: der Hintergrund des Onboardings, `#FFFFFF` hell und `#000000` dunkel.
    public static let background = Color(uiColor: .systemBackground)

    /// `--bg-grouped`: der Hintergrund der Seiten, `#F2F2F7` hell und `#000000` dunkel.
    public static let backgroundGrouped = Color(uiColor: .systemGroupedBackground)

    /// `--bg-cell`: Karten und Listengruppen, `#FFFFFF` hell und `#1C1C1E` dunkel.
    public static let backgroundCell = Color(uiColor: .secondarySystemGroupedBackground)

    /// `--separator`.
    public static let separator = Color(uiColor: .separator)

    /// `--fill-2`: z. B. die gedrückte Taste des Steppers.
    public static let fillSecondary = Color(uiColor: .secondarySystemFill)

    /// `--fill-3`: z. B. der Stepper und Kapsel-Buttons.
    public static let fillTertiary = Color(uiColor: .tertiarySystemFill)

    /// `--fill-4`: z. B. die Fakten-Kachel und die gedrückte Glocke.
    public static let fillQuaternary = Color(uiColor: .quaternarySystemFill)

    /// `--seg-thumb`: der gewählte Teil der Segmente, `#FFFFFF` hell und `#636366` dunkel.
    public static let segmentThumb = Color(light: Values.segmentThumbLight, dark: Values.segmentThumbDark)

    // MARK: - Bogen und Gebetskarte

    /// `--arc-track`: der noch kommende Teil des Bogens und die Marker kommender Gebete – Akzent zu
    /// 20 % auf dem Seitenhintergrund, dunkel zu 30 %. Deckend, damit sich Marker und Bogen decken.
    public static var arcTrack: Color {
        let accent = current
        return Color(
            light: accent.light.mixed(Values.arcTrackShareLight, with: Values.backgroundGroupedLight),
            dark: accent.dark.mixed(Values.arcTrackShareDark, with: Values.backgroundGroupedDark)
        )
    }

    /// Karte des laufenden Gebets: Akzent zu 15 % auf der Kartenfarbe (`.prow.is-current`).
    public static var currentRow: Color {
        let accent = current
        return Color(
            light: accent.light.mixed(Values.currentRowShare, with: Values.backgroundCellLight),
            dark: accent.dark.mixed(Values.currentRowShare, with: Values.backgroundCellDark)
        )
    }

    /// Schrift in Akzent auf der Karte des laufenden Gebets: hell 8 % dunkler als `accent`, damit sie auf der
    /// getönten Karte 4,5 : 1 erreicht (WCAG AA; 4,8 statt 4,2 : 1) – entschieden mit dem Plan für Phase 11
    /// („Schrift dort dunkler“). Dunkel gilt der Akzent, er erreicht dort 5,9 : 1.
    public static var currentRowAccent: Color {
        let accent = current
        return Color(light: accent.light.mixed(Values.currentRowTextShare, with: RGBA.black), dark: accent.dark)
    }

    /// Sekundärschrift auf der Karte des laufenden Gebets, z. B. die Kerahat-Zeile: hell 8 % dunkler
    /// (4,9 statt 4,3 : 1), dunkel die Systemfarbe.
    public static let currentRowTextSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel.resolvedColor(with: traits)
            : Values.textSecondaryLight.mixed(Values.currentRowTextShare, with: RGBA.black).uiColor
    })

    /// Die laufende Kerahat-Zeile auf der Karte des laufenden Gebets: hell 8 % dunkler (4,7 statt 4,2 : 1).
    public static var currentRowKerahatText: Color {
        let accent = current
        return Color(
            light: KerahatTone.rgba(0x9A6212, accent: accent).mixed(Values.currentRowTextShare, with: RGBA.black),
            dark: KerahatTone.rgba(0xE3B36B, accent: accent)
        )
    }

    /// Gewählter Eintrag einer Liste aus Karten, z. B. der Vers, den die Karte oben zeigt: Akzent zu 13 %
    /// auf der Kartenfarbe (`.vitem[aria-pressed="true"]`).
    public static var selectedItem: Color {
        let accent = current
        return Color(
            light: accent.light.mixed(Values.selectedItemShare, with: Values.backgroundCellLight),
            dark: accent.dark.mixed(Values.selectedItemShare, with: Values.backgroundCellDark)
        )
    }

    /// `--kerahat`: die Kerahat-Marken, `#C7862A` hell und `#D9A04E` dunkel; bei warmen Grundfarben violett
    /// (`#A282D9`, `#B89AED`, Spec § 11.7).
    public static var kerahat: Color {
        let accent = current
        return Color(light: KerahatTone.rgba(0xC7862A, accent: accent), dark: KerahatTone.rgba(0xD9A04E, accent: accent))
    }

    /// `--kerahat-text`: die Kerahat-Zeile, solange das Fenster läuft – `#9A6212` hell, `#E3B36B` dunkel; bei
    /// warmen Grundfarben violett (`#7B5FA8`, `#C6ADF6`).
    public static var kerahatText: Color {
        let accent = current
        return Color(light: KerahatTone.rgba(0x9A6212, accent: accent), dark: KerahatTone.rgba(0xE3B36B, accent: accent))
    }

    // MARK: - Live-Aktivität

    /// Die Farben des kleinen Bogens auf dem Sperrbildschirm (`.arc-la`) im Stil „Farbig“ und in der Grundfarbe,
    /// die gerade gilt. Der Hintergrund ist in beiden Erscheinungsbildern der helle Akzent, deshalb gibt es hier
    /// keine dunklen Werte. Alle Stile beschreibt `LiveActivityColors` (Spec § 11.7).
    public enum LiveActivity {
        /// Hintergrund der Live-Aktivität (`--accent-l`).
        public static var background: Color { Color(Palette.current.light) }
        /// Bogen, kommender Teil: Weiß mit 28 % Deckkraft.
        public static let track = Color(RGBA.white.opacity(0.28))
        /// Bogen bis „jetzt“, begonnene Marker und der Rand des Knopfes.
        public static let foreground = Color(RGBA.white)
        /// Marker kommender Gebete: Weiß zu 30 % auf dem Akzent.
        public static var marker: Color { Color(RGBA.white.mixed(0.30, with: Palette.current.light)) }
        /// Zeiten am Bogen: Weiß. Der Prototyp nimmt 80 % Deckkraft (3,9 : 1); voll Weiß erreicht 5,2 : 1
        /// (WCAG AA, entschieden mit dem Plan für Phase 11: „Schrift dort dunkler“).
        public static let time = Color(RGBA.white)
        /// Kerahat-Marken in warmem Gelb, `#F3C979`.
        public static let kerahat = Color(Values.liveActivityKerahat)

        // Spec § 10.3: in der Verbotszeit orange (`.la.is-kerahat`).
        /// Grundfarbe in der Verbotszeit, `#EC8530`.
        public static let prohibited = Color(Values.liveActivityProhibited)
        /// Symbole begonnener Gebete und Knopf auf Orange, `#C4661F`.
        public static let prohibitedDeep = Color(Values.liveActivityProhibitedDeep)
        /// Marker kommender Gebete: Weiß zu 30 % auf Orange.
        public static let prohibitedMarker = Color(RGBA.white.mixed(0.30, with: Values.liveActivityProhibited))
        /// Kerahat-Abschnitte auf Orange, `#FFE2BF`.
        public static let prohibitedKerahat = Color(RGBA(hex: 0xFFE2BF))
        /// Symbol, Zeit, Countdown und Balken in der Dynamic Island, `#F0A257`.
        public static let islandProhibited = Color(RGBA(hex: 0xF0A257))
    }

    // MARK: - Sperrbildschirm

    /// Die Farben des Bogens im rechteckigen Widget (`.arc-acc`). Der Sperrbildschirm ist einfarbig: Alles ist
    /// Weiß, unterschieden nur durch die Deckkraft; iOS tönt es passend zum Hintergrund und zeigt Dunkles
    /// durchsichtig.
    public enum LockScreen {
        /// Bogen, kommender Teil: Weiß mit 32 % Deckkraft.
        public static let track = Color(RGBA.white.opacity(0.32))
        /// Bogen bis „jetzt“, begonnene Gebete, Symbole kommender, Kerahat und der Ring des Knopfes.
        public static let foreground = Color(RGBA.white)
        /// Kommende Gebete: Weiß mit 30 % Deckkraft (wie Weiß zu 30 % auf dem Akzent in der Live-Aktivität).
        public static let marker = Color(RGBA.white.opacity(0.3))
        /// Schein um das laufende Gebet: Weiß mit 22 % Deckkraft.
        public static let glow = Color(RGBA.white.opacity(0.22))
        /// Symbol auf einem begonnenen Gebet: Schwarz mit 70 % – erscheint wie ausgestanzt.
        public static let cutOut = Color(RGBA.black.opacity(0.7))
        /// Mitte des Knopfes: Schwarz mit 55 %.
        public static let knob = Color(RGBA.black.opacity(0.55))
        /// Ring um eng liegende Gebete und Grund unter den Strichen von Kerahat: Schwarz mit 45 %.
        public static let gap = Color(RGBA.black.opacity(0.45))
    }

    // MARK: - Werte

    /// Die Zahlen hinter den Farben, wörtlich aus Spec und Prototyp.
    public enum Values {
        public static let accentLight = RGBA(hex: 0x1F7A6D)
        public static let accentDark = RGBA(hex: 0x4CC2AE)
        public static let onAccentLight = RGBA(hex: 0xFFFFFF)
        public static let onAccentDark = RGBA(hex: 0x04221D)
        public static let accentTintOpacity = 0.13

        public static let textSecondaryLight = RGBA(hex: 0x6C6C70)

        public static let backgroundGroupedLight = RGBA(hex: 0xF2F2F7)
        public static let backgroundGroupedDark = RGBA(hex: 0x000000)
        public static let backgroundCellLight = RGBA(hex: 0xFFFFFF)
        public static let backgroundCellDark = RGBA(hex: 0x1C1C1E)

        public static let segmentThumbLight = RGBA(hex: 0xFFFFFF)
        public static let segmentThumbDark = RGBA(hex: 0x636366)

        public static let arcTrackShareLight = 0.20
        public static let arcTrackShareDark = 0.30
        public static let currentRowShare = 0.15
        /// Schrift auf der Karte des laufenden Gebets, hell: 92 % der Farbe, 8 % Schwarz (Phase 11).
        public static let currentRowTextShare = 0.92
        public static let selectedItemShare = 0.13

        public static let kerahatLight = RGBA(hex: 0xC7862A)
        public static let kerahatDark = RGBA(hex: 0xD9A04E)
        public static let kerahatTextLight = RGBA(hex: 0x9A6212)
        public static let kerahatTextDark = RGBA(hex: 0xE3B36B)

        public static let liveActivityKerahat = RGBA(hex: 0xF3C979)
        /// Orange der Live-Aktivität in der Verbotszeit (Spec § 10.3).
        public static let liveActivityProhibited = RGBA(hex: 0xEC8530)
        public static let liveActivityProhibitedDeep = RGBA(hex: 0xC4661F)
    }
}
