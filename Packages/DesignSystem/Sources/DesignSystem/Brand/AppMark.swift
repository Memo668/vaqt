import SwiftUI

/// Das Zeichen der App: das App-Symbol selbst (Spec § 9.1, `appIconImg()` im Prototyp). Es steht groß im
/// ersten Schritt des Onboardings und klein über der Tagline der Einstellungen.
///
/// SwiftUI kann `AppIcon` nicht als Bild laden; deshalb liegt dieselbe Zeichnung als Bildsatz `AppMark` im
/// Paket (hell und dunkel, 360 px, aus `App/Assets.xcassets/AppIcon.appiconset`). Ändert sich das Symbol,
/// den Bildsatz mit `sips -Z 360` neu erzeugen.
///
/// TODO(placeholder): Das App-Symbol ist seit Phase 11 ein Platzhalter (Tagesbogen, `scripts/app-icon.swift`).
public struct AppMark: View {

    /// Größe des Zeichens.
    public enum Size: Sendable {
        /// 120 pt mit weichem Schatten, im Onboarding (`.app-icon-img.ai-xl`).
        case large
        /// 34 pt über der Tagline (`.app-icon-img.ai-tag`).
        case small
    }

    private let size: Size

    public init(size: Size) {
        self.size = size
    }

    public var body: some View {
        let side = AppMarkMetrics.side(for: size)
        let shape = RoundedRectangle(cornerRadius: side * AppMarkMetrics.cornerRatio, style: .continuous)
        Image("AppMark", bundle: .module)
            .resizable()
            .interpolation(.high)
            .frame(width: side, height: side)
            .clipShape(shape)
            .background {
                // `.ai-xl`: `box-shadow: 0 14px 34px rgba(0,0,0,.18), 0 0 0 .5px rgba(0,0,0,.06)`
                if size == .large {
                    shape
                        .fill(.black.opacity(AppMarkMetrics.rimOpacity))
                        .padding(-AppMarkMetrics.rimWidth)
                        .shadow(
                            color: .black.opacity(AppMarkMetrics.shadowOpacity),
                            radius: AppMarkMetrics.shadowBlur / 2, x: 0, y: AppMarkMetrics.shadowY
                        )
                }
            }
            .accessibilityHidden(true)
    }
}

/// Maße des Zeichens (`.app-icon-img`, `.ai-xl`, `.ai-tag`).
enum AppMarkMetrics {
    static func side(for size: AppMark.Size) -> CGFloat {
        switch size {
        case .large: 120
        case .small: 34
        }
    }

    /// `border-radius: 22.4 %` – der Eckenradius der Symbole auf dem Home-Bildschirm.
    static let cornerRatio: CGFloat = 0.224
    static let shadowOpacity = 0.18
    static let shadowBlur: CGFloat = 34
    static let shadowY: CGFloat = 14
    /// Der feine Rand um das große Zeichen (`0 0 0 .5px rgba(0,0,0,.06)`).
    static let rimOpacity = 0.06
    static let rimWidth: CGFloat = 0.5
}

/// Mondsichel und Punkt im Feld 24 × 24 des Prototyps (`appGlyph`) – bis Phase 14 noch im Kopf der
/// Live-Aktivität und der Widgets (Spec § 9.1 ersetzt es auch dort durch das App-Symbol): Die Sichel ist der Kreis um
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

/// Ein Symbol in Akzent auf einem getönten Kreis von 112 pt – `.onb-badge` im Prototyp: Standort und
/// Mitteilungen im Onboarding, das Schild auf der Seite „Datenschutz“.
public struct IconBadge: View {
    private let systemImage: String
    private let symbolSize: CGFloat
    private let side: CGFloat

    /// - Parameters:
    ///   - symbolSize: Schriftgröße des SF Symbols, so gewählt, dass es so groß erscheint wie die
    ///     Zeichnung des Prototyps (`ic(…, 48)`).
    ///   - side: Durchmesser des Kreises; 112 pt, auf der Seite „Unterstützen“ 88 pt (`.sup-hero .onb-badge`).
    public init(systemImage: String, symbolSize: CGFloat, side: CGFloat = IconBadgeMetrics.side) {
        self.systemImage = systemImage
        self.symbolSize = symbolSize
        self.side = side
    }

    public var body: some View {
        Circle()
            .fill(Palette.accentTint)
            .frame(width: side, height: side)
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
    public static let side: CGFloat = 112
    /// Der kleinere Kreis auf der Seite „Unterstützen“.
    public static let supportSide: CGFloat = 88
    /// `ic('heart', 50)` auf Seite 4 des Onboardings, `ic('heart', 44)` auf der Seite „Unterstützen“.
    public static let heartSymbolSize: CGFloat = 38
    public static let supportHeartSymbolSize: CGFloat = 33
    static let symbolWeight: Font.Weight = .medium
    /// `ic('locFill', 48)`: der gefüllte Pfeil, rund 31 pt breit.
    public static let locationSymbolSize: CGFloat = 34
    /// `ic('bellWave', 48)`: Glocke mit Wellen, rund 35 pt breit.
    public static let bellSymbolSize: CGFloat = 30
    /// `ic('shield', 48)`: Schild mit Haken, rund 19 pt breit.
    public static let shieldSymbolSize: CGFloat = 38.5
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
