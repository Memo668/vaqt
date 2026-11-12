import SwiftUI
import UIKit

/// Die Farben der App – Design Spec § 2 und das `:root`-CSS des Prototyps (`[data-theme]`).
///
/// Eigene Werte haben nur der Akzent (Pine Teal) und was daraus gemischt ist, die Sekundärschrift im
/// hellen Erscheinungsbild und die Kerahat-Farben. Alles andere sind die semantischen Systemfarben,
/// deren Werte der Prototyp nachbildet.
public enum Palette {

    // MARK: - Akzent

    /// `--accent`: Pine Teal, `#1F7A6D` hell und `#4CC2AE` dunkel. Dieselben Werte stehen im Asset
    /// `AccentColor` der App.
    public static let accent = Color(light: Values.accentLight, dark: Values.accentDark)

    /// `--on-accent`: Schrift und Symbole auf Akzentflächen, `#FFFFFF` hell und `#04221D` dunkel.
    public static let onAccent = Color(light: Values.onAccentLight, dark: Values.onAccentDark)

    /// `--accent-tint`: Akzent mit 13 % Deckkraft.
    public static let accentTint = Color(
        light: Values.accentLight.opacity(Values.accentTintOpacity),
        dark: Values.accentDark.opacity(Values.accentTintOpacity)
    )

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
    public static let arcTrack = Color(
        light: Values.accentLight.mixed(Values.arcTrackShareLight, with: Values.backgroundGroupedLight),
        dark: Values.accentDark.mixed(Values.arcTrackShareDark, with: Values.backgroundGroupedDark)
    )

    /// Karte des laufenden Gebets: Akzent zu 15 % auf der Kartenfarbe (`.prow.is-current`).
    public static let currentRow = Color(
        light: Values.accentLight.mixed(Values.currentRowShare, with: Values.backgroundCellLight),
        dark: Values.accentDark.mixed(Values.currentRowShare, with: Values.backgroundCellDark)
    )

    /// Gewählter Eintrag einer Liste aus Karten, z. B. der Vers, den die Karte oben zeigt: Akzent zu 13 %
    /// auf der Kartenfarbe (`.vitem[aria-pressed="true"]`).
    public static let selectedItem = Color(
        light: Values.accentLight.mixed(Values.selectedItemShare, with: Values.backgroundCellLight),
        dark: Values.accentDark.mixed(Values.selectedItemShare, with: Values.backgroundCellDark)
    )

    /// `--kerahat`: die Kerahat-Marken, `#C7862A` hell und `#D9A04E` dunkel.
    public static let kerahat = Color(light: Values.kerahatLight, dark: Values.kerahatDark)

    /// `--kerahat-text`: die Kerahat-Zeile, solange das Fenster läuft – `#9A6212` hell, `#E3B36B` dunkel.
    public static let kerahatText = Color(light: Values.kerahatTextLight, dark: Values.kerahatTextDark)

    // MARK: - Live-Aktivität

    /// Die Farben des kleinen Bogens auf dem Sperrbildschirm (`.arc-la`). Der Hintergrund ist in beiden
    /// Erscheinungsbildern der helle Akzent, deshalb gibt es hier keine dunklen Werte.
    public enum LiveActivity {
        /// Hintergrund der Live-Aktivität (`--accent-l`).
        public static let background = Color(Values.accentLight)
        /// Bogen, kommender Teil: Weiß mit 28 % Deckkraft.
        public static let track = Color(RGBA.white.opacity(0.28))
        /// Bogen bis „jetzt“, begonnene Marker und der Rand des Knopfes.
        public static let foreground = Color(RGBA.white)
        /// Marker kommender Gebete: Weiß zu 30 % auf dem Akzent.
        public static let marker = Color(RGBA.white.mixed(0.30, with: Values.accentLight))
        /// Zeiten am Bogen: Weiß mit 80 % Deckkraft.
        public static let time = Color(RGBA.white.opacity(0.80))
        /// Kerahat-Marken in warmem Gelb, `#F3C979`.
        public static let kerahat = Color(Values.liveActivityKerahat)
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
        public static let selectedItemShare = 0.13

        public static let kerahatLight = RGBA(hex: 0xC7862A)
        public static let kerahatDark = RGBA(hex: 0xD9A04E)
        public static let kerahatTextLight = RGBA(hex: 0x9A6212)
        public static let kerahatTextDark = RGBA(hex: 0xE3B36B)

        public static let liveActivityKerahat = RGBA(hex: 0xF3C979)
    }
}
