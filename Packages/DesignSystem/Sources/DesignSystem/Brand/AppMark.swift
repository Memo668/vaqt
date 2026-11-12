import SwiftUI

/// Das Zeichen der App: Mondsichel und Punkt auf einem Verlauf in Akzent – `.app-icon` mit `appGlyph`
/// im Prototyp. Es steht groß im ersten Schritt des Onboardings und klein über der Tagline der
/// Einstellungen.
///
/// TODO(placeholder): Das Zeichen ist der Platzhalter des Prototyps (Spec § 6.9); das App-Symbol kommt
/// in Phase 11.
public struct AppMark: View {

    /// Größe des Zeichens.
    public enum Size: Sendable {
        /// 112 pt mit weichem Schatten, im Onboarding (`.app-icon.xl`, `ic('appGlyph', 60)`).
        case large
        /// 34 pt über der Tagline (`.tagline .app-icon`, `ic('appGlyph', 22)`).
        case small
    }

    private let size: Size

    public init(size: Size) {
        self.size = size
    }

    public var body: some View {
        let metrics = AppMarkMetrics.metrics(for: size)
        RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
            .fill(AppMarkMetrics.gradient)
            .overlay {
                // `box-shadow: inset 0 0 0 .5px rgba(255,255,255,.25)`
                RoundedRectangle(cornerRadius: metrics.radius, style: .continuous)
                    .strokeBorder(.white.opacity(AppMarkMetrics.rimOpacity), lineWidth: AppMarkMetrics.rimWidth)
            }
            .overlay {
                AppGlyph()
                    .fill(.white)
                    .frame(width: metrics.glyph, height: metrics.glyph)
            }
            .frame(width: metrics.side, height: metrics.side)
            .shadow(
                color: metrics.hasShadow ? AppMarkMetrics.shadowColor : .clear,
                radius: AppMarkMetrics.shadowBlur / 2, x: 0, y: AppMarkMetrics.shadowY
            )
            .accessibilityHidden(true)
    }
}

/// Mondsichel und Punkt im Feld 24 × 24 des Prototyps (`appGlyph`): Die Sichel ist der Kreis um
/// (11,59 | 12,41) mit Radius 7,7 ohne den Kreis um (15,19 | 8,81) mit Radius 7,6 – die beiden Bögen des
/// SVG-Pfads `M18.6 15.6A7.6 7.6 0 0 1 8.4 5.4a7.7 7.7 0 1 0 10.2 10.2z` –, der Punkt der Kreis um
/// (16,6 | 7,4) mit Radius 1,7.
public struct AppGlyph: Shape {

    public init() {}

    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / AppGlyphGeometry.viewBox
        let origin = CGPoint(
            x: rect.midX - AppGlyphGeometry.viewBox * scale / 2,
            y: rect.midY - AppGlyphGeometry.viewBox * scale / 2
        )
        func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
            Path(ellipseIn: CGRect(
                x: origin.x + (center.x - radius) * scale, y: origin.y + (center.y - radius) * scale,
                width: 2 * radius * scale, height: 2 * radius * scale
            ))
        }
        var glyph = circle(AppGlyphGeometry.outerCenter, AppGlyphGeometry.outerRadius)
            .subtracting(circle(AppGlyphGeometry.innerCenter, AppGlyphGeometry.innerRadius))
        glyph.addPath(circle(AppGlyphGeometry.dotCenter, AppGlyphGeometry.dotRadius))
        return glyph
    }
}

/// Die Geometrie von `appGlyph`. Die Mittelpunkte der Bögen sind aus dem SVG-Pfad gerechnet (Endpunkte
/// 18,6 | 15,6 und 8,4 | 5,4; Radien 7,6 und 7,7; Flags wie im Pfad).
enum AppGlyphGeometry {
    static let viewBox: CGFloat = 24
    static let outerCenter = CGPoint(x: 11.5934, y: 12.4066)
    static let outerRadius: CGFloat = 7.7
    static let innerCenter = CGPoint(x: 15.1941, y: 8.8059)
    static let innerRadius: CGFloat = 7.6
    static let dotCenter = CGPoint(x: 16.6, y: 7.4)
    static let dotRadius: CGFloat = 1.7
}

/// Maße des Zeichens (`.app-icon`, `.app-icon.xl`, `.tagline .app-icon`).
enum AppMarkMetrics {
    struct Metrics {
        let side: CGFloat
        let radius: CGFloat
        let glyph: CGFloat
        let hasShadow: Bool
    }

    static func metrics(for size: AppMark.Size) -> Metrics {
        switch size {
        case .large: Metrics(side: 112, radius: 25, glyph: 60, hasShadow: true)
        case .small: Metrics(side: 34, radius: 8, glyph: 22, hasShadow: false)
        }
    }

    /// `linear-gradient(165deg, mix(accent-l 62 %, #fff) 0 %, accent-l 52 %, mix(accent-l 68 %, #000) 100 %)`
    /// – in beiden Erscheinungsbildern mit dem hellen Akzent. Der Winkel 165° läuft fast senkrecht nach
    /// unten, leicht nach rechts; Anfang und Ende liegen dort, wo die Gradientenlinie des CSS das Quadrat
    /// verlässt.
    static let gradient = LinearGradient(
        stops: [
            .init(color: Color(Palette.Values.accentLight.mixed(0.62, with: .white)), location: 0),
            .init(color: Color(Palette.Values.accentLight), location: 0.52),
            .init(color: Color(Palette.Values.accentLight.mixed(0.68, with: .black)), location: 1),
        ],
        startPoint: gradientPoint(start: true), endPoint: gradientPoint(start: false)
    )

    private static func gradientPoint(start: Bool) -> UnitPoint {
        let angle = 165.0 * .pi / 180
        // Richtung der Gradientenlinie (y nach unten) und halbe Länge im Einheitsquadrat.
        let direction = (x: sin(angle), y: -cos(angle))
        let half = (abs(sin(angle)) + abs(cos(angle))) / 2
        let sign = start ? -1.0 : 1.0
        return UnitPoint(x: 0.5 + sign * direction.x * half, y: 0.5 + sign * direction.y * half)
    }

    /// `box-shadow: 0 14px 34px color-mix(in srgb, var(--accent-l) 38%, transparent)`
    static let shadowColor = Color(Palette.Values.accentLight.opacity(0.38))
    static let shadowBlur: CGFloat = 34
    static let shadowY: CGFloat = 14
    static let rimOpacity = 0.25
    static let rimWidth: CGFloat = 0.5
}

/// Ein Symbol in Akzent auf einem getönten Kreis von 112 pt – `.onb-badge` im Prototyp: Standort und
/// Mitteilungen im Onboarding, das Schild auf der Seite „Datenschutz“.
public struct IconBadge: View {
    private let systemImage: String
    private let symbolSize: CGFloat

    /// - Parameter symbolSize: Schriftgröße des SF Symbols, so gewählt, dass es so groß erscheint wie die
    ///   Zeichnung des Prototyps (`ic(…, 48)`).
    public init(systemImage: String, symbolSize: CGFloat) {
        self.systemImage = systemImage
        self.symbolSize = symbolSize
    }

    public var body: some View {
        Circle()
            .fill(Palette.accentTint)
            .frame(width: IconBadgeMetrics.side, height: IconBadgeMetrics.side)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: symbolSize, weight: IconBadgeMetrics.symbolWeight))
                    .foregroundStyle(Palette.accent)
            }
            .accessibilityHidden(true)
    }
}

/// Maße des Kreises (`.onb-badge`: 112 × 112 pt) und der Symbole darin.
public enum IconBadgeMetrics {
    static let side: CGFloat = 112
    static let symbolWeight: Font.Weight = .medium
    /// `ic('locFill', 48)`: der gefüllte Pfeil, rund 31 pt breit.
    public static let locationSymbolSize: CGFloat = 34
    /// `ic('bellWave', 48)`: Glocke mit Wellen, rund 35 pt breit.
    public static let bellSymbolSize: CGFloat = 30
    /// `ic('shield', 48)`: Schild mit Haken, rund 28 pt breit.
    public static let shieldSymbolSize: CGFloat = 34
}

/// Zeichen der App über einer Zeile in Sekundärfarbe, mittig – `.tagline` am Ende der Einstellungen:
/// „Gemeinnützig · Werbefrei · Ohne Tracking“.
public struct Tagline: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(spacing: TaglineMetrics.gap) {
            AppMark(size: .small)
            Text(text)
                .font(TypeScale.footnote.font())
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// Maße der Tagline (`.tagline`: `gap: 8px; margin: -6px 0 0`).
public enum TaglineMetrics {
    static let gap: CGFloat = 8
    /// Abstand zur Gruppe darüber: die 32 pt unter jeder Gruppe, 6 pt kürzer.
    public static let top: CGFloat = 26
}
