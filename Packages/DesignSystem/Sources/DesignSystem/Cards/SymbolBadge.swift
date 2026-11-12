import SwiftUI

/// Ein SF Symbol in Akzent auf einem Kreis in getöntem Akzent – das Symbol des Gebets in der Kopfkarte
/// der Anleitung (`.g-ic`) und die Symbole der Karten unter „Vorher“ (`.pose.sm`).
///
/// Nur Schmuck: Für VoiceOver ist das Symbol ausgeblendet; was es meint, sagt der Text daneben.
public struct SymbolBadge: View {
    private let systemImage: String
    private let diameter: CGFloat
    private let symbolSize: CGFloat
    private let symbolWeight: Font.Weight

    /// Symbol eines Gebets in der Kopfkarte: Kreis 46 pt, `ic(PICON[p], 24)`.
    public static func prayer(_ systemImage: String) -> SymbolBadge {
        SymbolBadge(
            systemImage, diameter: SymbolBadgeMetrics.prayerDiameter,
            symbolSize: SymbolBadgeMetrics.prayerSymbolSize, symbolWeight: SymbolBadgeMetrics.symbolWeight
        )
    }

    /// Symbol einer Karte unter „Vorher“: Kreis 42 pt, `ic(icon, 22)`.
    ///
    /// - Parameter symbolSize: Schriftgröße des SF Symbols. Die Symbole sind verschieden groß gezeichnet;
    ///   jedes bekommt deshalb die Größe, in der es so groß erscheint wie seine Zeichnung im Prototyp.
    public static func step(_ systemImage: String, symbolSize: CGFloat) -> SymbolBadge {
        SymbolBadge(
            systemImage, diameter: SymbolBadgeMetrics.stepDiameter,
            symbolSize: symbolSize, symbolWeight: SymbolBadgeMetrics.symbolWeight
        )
    }

    /// - Parameters:
    ///   - diameter: Durchmesser des Kreises.
    ///   - symbolSize: Schriftgröße des SF Symbols.
    public init(_ systemImage: String, diameter: CGFloat, symbolSize: CGFloat, symbolWeight: Font.Weight = .regular) {
        self.systemImage = systemImage
        self.diameter = diameter
        self.symbolSize = symbolSize
        self.symbolWeight = symbolWeight
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: symbolSize, weight: symbolWeight))
            .foregroundStyle(Palette.accent)
            .frame(width: diameter, height: diameter)
            .background(Palette.accentTint, in: .circle)
            .accessibilityHidden(true)
    }
}

/// Maße der Symbolkreise (`.g-ic`: 46 × 46 pt; `.pose.sm`: 42 × 42 pt). Die Schriftgröße des Gebetssymbols
/// ist so gewählt, dass es so groß erscheint wie die Zeichnung des Prototyps (16 × 16 pt in `iphone/40`).
enum SymbolBadgeMetrics {
    static let prayerDiameter: CGFloat = 46
    static let prayerSymbolSize: CGFloat = 16
    static let stepDiameter: CGFloat = 42
    static let symbolWeight: Font.Weight = .medium
}
