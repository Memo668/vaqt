import SwiftUI
import UIKit

/// Ein Farbwert in sRGB, jeder Kanal von 0 bis 1 – die Rechengröße hinter den Farb-Tokens.
///
/// Damit lassen sich die Werte des Prototyps wörtlich übernehmen (`#1F7A6D`) und die gemischten
/// Farben so ausrechnen, wie es `color-mix(in srgb, …)` im CSS tut.
public struct RGBA: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Farbwert aus der Schreibweise des Prototyps, z. B. `RGBA(hex: 0x1F7A6D)` für `#1F7A6D`.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    public static let white = RGBA(hex: 0xFFFFFF)
    public static let black = RGBA(hex: 0x000000)

    /// Dieselbe Farbe mit anderer Deckkraft – `color-mix(in srgb, self x%, transparent)`.
    public func opacity(_ alpha: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, alpha: self.alpha * alpha)
    }

    /// `color-mix(in srgb, self fraction, base)` für deckende Farben: `fraction` Anteile dieser Farbe,
    /// der Rest `base`.
    public func mixed(_ fraction: Double, with base: RGBA) -> RGBA {
        RGBA(
            red: red * fraction + base.red * (1 - fraction),
            green: green * fraction + base.green * (1 - fraction),
            blue: blue * fraction + base.blue * (1 - fraction),
            alpha: alpha * fraction + base.alpha * (1 - fraction)
        )
    }

    /// Schreibweise wie im Prototyp, z. B. „#1F7A6D“; die Deckkraft bleibt außen vor.
    public var hexString: String {
        func byte(_ value: Double) -> String {
            let text = String(Int((min(1, max(0, value)) * 255).rounded()), radix: 16, uppercase: true)
            return text.count < 2 ? "0" + text : text
        }
        return "#" + byte(red) + byte(green) + byte(blue)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Der Farbwert, den `color` im hellen oder dunklen Erscheinungsbild annimmt.
    public init(_ color: Color, dark: Bool) {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let resolved = UIColor(color).resolvedColor(with: traits)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {

    /// Eine Farbe mit einem Wert für das helle und einem für das dunkle Erscheinungsbild.
    public init(light: RGBA, dark: RGBA) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark.uiColor : light.uiColor
        })
    }

    /// Eine Farbe, die in beiden Erscheinungsbildern gleich ist.
    public init(_ value: RGBA) {
        self.init(.sRGB, red: value.red, green: value.green, blue: value.blue, opacity: value.alpha)
    }
}
