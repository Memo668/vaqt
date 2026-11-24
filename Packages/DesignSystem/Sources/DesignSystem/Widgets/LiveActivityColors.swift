import PrayerCore
import SwiftUI

/// Wie eine Live-Aktivität aussieht: Stil der App (Grundfarbe, Stufe, invertiert) und ob sie in der Verbotszeit
/// läuft (Spec § 10.3, § 11.7). Daraus folgen alle Farben (`LiveActivityColors`).
public struct LiveActivityLook: Hashable, Sendable {
    public var style: AppStyle
    public var isProhibited: Bool

    public init(style: AppStyle = .standard, isProhibited: Bool = false) {
        self.style = style
        self.isProhibited = isProhibited
    }

    /// Wie bisher: Petrol, farbig, außerhalb der Verbotszeit.
    public static let standard = LiveActivityLook()

    /// Das Aussehen einer Aktivität mit diesem Inhalt; ältere Inhalte ohne Stil sehen aus wie der Standard.
    public init(content: LiveActivityContent) {
        self.init(style: content.style ?? .standard, isProhibited: content.isProhibited)
    }

    public var colors: LiveActivityColors {
        LiveActivityColors(look: self)
    }
}

/// Die Farben der Live-Aktivität, des Widgets mit dem Bogen und der Dynamic Island je Stil – die Variablen `--la-*`
/// im Block „Stil“ des Prototyps (`[data-la]`, `[data-inv]`, `.is-kerahat`), wörtlich übernommen.
///
/// - Farbig: Verlauf der Grundfarbe, in der Verbotszeit orange; invertiert weiß mit Bogen und Schrift in der
///   Grundfarbe.
/// - Nur Bogen: Grund ohne Farbe (`#2E2E33`), Bogen in der dunklen Grundfarbe; invertiert weiß.
/// - Schwarz-weiß: ohne jede Farbe, Verbotszeiten gestreift.
///
/// Bei den warmen Grundfarben (Orange, Gold, Sand) wird jeder Orangeton der Verbotszeit violett (`KerahatTone`).
/// Die Deckkraft der Fläche ist bei allen Varianten 30 %.
public struct LiveActivityColors: Hashable, Sendable {

    /// Grund des Verlaufs (`--la-base`) und wie viel er oben links aufhellt (`--la-hi`) und unten rechts
    /// abdunkelt (`--la-lo`): `color-mix(base hi%, #fff)` → `base` → `color-mix(base lo%, #000)`.
    public let base: RGBA
    public let highlight: Double
    public let shade: Double
    /// Schrift (`--la-fg`) und Zweitschrift, die Zeiten am Bogen (`--la-fg2`).
    public let foreground: RGBA
    public let foregroundSecondary: RGBA
    /// „Verbotszeit bis …“ im Kopf (`--la-warn`); `nil` heißt in der Schriftfarbe.
    public let warning: RGBA?
    /// Bogen: kommender Teil (`--la-track`), Teil bis jetzt (`--la-line`).
    public let track: RGBA
    public let line: RGBA
    /// Marker kommender Gebete (`--la-dot`) und ihr Symbol (`--la-dot-ic`).
    public let marker: RGBA
    public let markerSymbol: RGBA
    /// Marker begonnener Gebete (`--la-on`) und ihr Symbol (`--la-on-ic`).
    public let markerBegun: RGBA
    public let markerBegunSymbol: RGBA
    /// Schein um das laufende Gebet (`--la-glow`, 22 %).
    public let glow: RGBA
    /// Ring um eng liegende Gebete (`--la-gap`).
    public let gap: RGBA
    /// Knopf „jetzt“ (`--la-knob`) und sein Ring (`--la-knob-ring`).
    public let knob: RGBA
    public let knobRing: RGBA
    /// Verbotszeiten auf der Spur (`--la-k`).
    public let kerahat: RGBA
    /// Deckkraft eines vergangenen Abschnitts: 0,5, auf einer farbigen Linie 0,85 (sonst mischte er sich zu Grau).
    public let kerahatPastOpacity: Double
    /// Schwarz-weiß: Verbotszeiten gestreift (weiße Striche über Schwarz zu 50 %), App-Symbol grau.
    public let isMonochrome: Bool
    /// Farbe der Dynamic Island: Symbol, Uhrzeit, Countdown und Balken.
    public let island: RGBA
    /// Verbotszeiten unter dem Balken der Dynamic Island (`.di-bar b`) und ihre Deckkraft.
    public let islandKerahat: RGBA
    public let islandKerahatOpacity: Double

    public init(look: LiveActivityLook) {
        let style = look.style
        let accent = style.accent
        let light = accent.light, dark = accent.dark
        let prohibited = look.isProhibited
        let white = RGBA.white, black = RGBA.black
        /// Ein Orangeton der Verbotszeit: violett bei warmen Grundfarben.
        func k(_ hex: UInt32) -> RGBA { KerahatTone.rgba(hex, accent: accent) }

        // `[data-la]`: farbig, Stand Spec § 10.3.
        var base = light, highlight = 0.82, shade = 0.78
        var foreground = white, foregroundSecondary = white.opacity(0.8)
        var warning: RGBA?
        var track = white.opacity(0.28), line = white
        var marker = white.mixed(0.30, with: light), markerSymbol = white
        var markerBegun = white, markerBegunSymbol = light
        var glow = white, gap = light
        var knob = light, knobRing = white
        var kerahat = k(0xF3C979)
        var pastOpacity = 0.5

        switch (style.liveActivity, style.isInverted) {
        case (.full, false):
            if prohibited {
                // `.is-kerahat`: Orange.
                base = k(0xEC8530); highlight = 0.80; shade = 0.76
                marker = white.mixed(0.30, with: k(0xD9772B))
                markerBegunSymbol = k(0xC4661F); gap = k(0xD9772B); knob = k(0xD9772B)
                kerahat = k(0xFFE2BF)
            }
        case (.full, true):
            // Weiß, Bogen und Schrift in der Grundfarbe.
            base = white
            foreground = light.mixed(0.80, with: black); foregroundSecondary = foreground
            track = light.opacity(0.26); line = light
            marker = light.mixed(0.24, with: white); markerSymbol = light
            markerBegun = light; markerBegunSymbol = white
            glow = light; gap = white; knob = white; knobRing = light
            kerahat = k(0xC7862A)
            pastOpacity = 0.85
            if prohibited {
                foreground = k(0x8A4409); foregroundSecondary = foreground
                track = k(0xB85C12).opacity(0.26); line = k(0xB85C12)
                marker = k(0xF1DCCB); markerSymbol = k(0xB85C12)
                markerBegun = k(0xB85C12); glow = k(0xB85C12); knobRing = k(0xB85C12)
                kerahat = k(0xEDA35C)
            }
        case (.arc, false):
            base = RGBA(hex: 0x2E2E33); marker = RGBA(hex: 0x6A6A70); gap = RGBA(hex: 0x2E2E33)
            track = white.opacity(0.26); line = dark
            markerBegun = dark; markerBegunSymbol = accent.onDark; glow = dark
            knob = white; knobRing = dark
            pastOpacity = 0.85
            if prohibited {
                line = k(0xF0A257); markerBegun = k(0xF0A257); markerBegunSymbol = k(0x3A1D05)
                glow = k(0xF0A257); knobRing = k(0xF0A257)
                kerahat = k(0xFFE2BF); warning = k(0xF8B877)
            }
        case (.arc, true):
            base = white; foreground = RGBA(hex: 0x1C1C1E); foregroundSecondary = black.opacity(0.62)
            track = black.opacity(0.16); marker = RGBA(hex: 0xD6D6DB); markerSymbol = black.opacity(0.6)
            gap = white; knob = white
            line = light; markerBegun = light; markerBegunSymbol = white; glow = light; knobRing = light
            kerahat = k(0xC7862A)
            pastOpacity = 0.85
            if prohibited {
                line = k(0xB85C12); markerBegun = k(0xB85C12); glow = k(0xB85C12); knobRing = k(0xB85C12)
                kerahat = k(0xEDA35C); warning = k(0x9A4D0E)
            }
        case (.mono, false):
            base = RGBA(hex: 0x2E2E33); marker = RGBA(hex: 0x6A6A70); gap = RGBA(hex: 0x2E2E33)
            markerBegunSymbol = RGBA(hex: 0x2E2E33); knob = RGBA(hex: 0x2E2E33)
            kerahat = white
        case (.mono, true):
            base = white; foreground = RGBA(hex: 0x1C1C1E); foregroundSecondary = black.opacity(0.62)
            track = black.opacity(0.16); marker = RGBA(hex: 0xD6D6DB); markerSymbol = black.opacity(0.6)
            gap = white; knob = white
            line = RGBA(hex: 0x1C1C1E); markerBegun = RGBA(hex: 0x1C1C1E); markerBegunSymbol = white
            glow = black; knobRing = RGBA(hex: 0x1C1C1E)
            kerahat = white
        }

        self.base = base
        self.highlight = highlight
        self.shade = shade
        self.foreground = foreground
        self.foregroundSecondary = foregroundSecondary
        self.warning = warning
        self.track = track
        self.line = line
        self.marker = marker
        self.markerSymbol = markerSymbol
        self.markerBegun = markerBegun
        self.markerBegunSymbol = markerBegunSymbol
        self.glow = glow
        self.gap = gap
        self.knob = knob
        self.knobRing = knobRing
        self.kerahat = kerahat
        kerahatPastOpacity = pastOpacity
        isMonochrome = style.liveActivity == .mono

        // Dynamic Island (`.di-*`): immer schwarz; dunkle Grundfarbe, in der Verbotszeit `#F0A257`, schwarz-weiß weiß.
        if style.liveActivity == .mono {
            island = white
            islandKerahat = white
            islandKerahatOpacity = 0.6
        } else {
            island = prohibited ? k(0xF0A257) : dark
            islandKerahat = k(0xE0A84F)
            islandKerahatOpacity = 0.85
        }
    }

    /// Der Verlauf der Fläche (`linear-gradient(160deg, …)`), ohne die Deckkraft.
    public var gradientStops: [Gradient.Stop] {
        [
            .init(color: Color(base.mixed(highlight, with: .white)), location: 0),
            .init(color: Color(base), location: 0.5),
            .init(color: Color(base.mixed(shade, with: .black)), location: 1),
        ]
    }

    /// Die Zeiten am Bogen. Wo der Prototyp Weiß zu 80 % nimmt (3,9 : 1), steht volles Weiß (5,2 : 1, WCAG AA –
    /// entschieden mit dem Plan für Phase 11, „Schrift dort dunkler“).
    public var arcTime: RGBA {
        foregroundSecondary == RGBA.white.opacity(0.8) ? .white : foregroundSecondary
    }
}
