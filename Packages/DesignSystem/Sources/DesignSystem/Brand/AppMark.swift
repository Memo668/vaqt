import SwiftUI

/// Das Zeichen der App: das App-Symbol selbst (Spec § 9.1, `appIconImg()` im Prototyp). Es steht groß im
/// ersten Schritt des Onboardings, klein über der Tagline der Einstellungen und seit Phase 14 im Kopf der
/// Live-Aktivität und des Widgets „Live“ sowie im Ring auf dem Sperrbildschirm, solange es keine Zeiten gibt.
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
        /// 16 pt mit Radius 4 im Kopf der Live-Aktivität und des Widgets „Live“ (`.app-icon-img.ai-la`).
        case header
        /// 24 pt im Ring auf dem Sperrbildschirm, solange es keine Zeiten gibt – so groß wie bis Phase 13
        /// die Mondsichel dort.
        case accessory
        /// 14 pt mit Radius 3,5 im Kopf der Live-Aktivität „klein“ (`.app-icon-img.ai-las`, Spec § 12.3).
        case smallHeader
    }

    private let size: Size

    public init(size: Size) {
        self.size = size
    }

    public var body: some View {
        let side = AppMarkMetrics.side(for: size)
        let shape = RoundedRectangle(cornerRadius: AppMarkMetrics.cornerRadius(for: size), style: .continuous)
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
        case .header: 16
        case .accessory: 24
        case .smallHeader: 14
        }
    }

    /// `border-radius: 22.4 %` – der Eckenradius der Symbole auf dem Home-Bildschirm; im Kopf der
    /// Live-Aktivität fest 4 pt (`.ai-la`).
    static func cornerRadius(for size: AppMark.Size) -> CGFloat {
        switch size {
        case .header: headerCornerRadius
        case .smallHeader: smallHeaderCornerRadius
        case .large, .small, .accessory: side(for: size) * cornerRatio
        }
    }

    static let cornerRatio: CGFloat = 0.224
    static let headerCornerRadius: CGFloat = 4
    /// Im Kopf der Live-Aktivität „klein“ (`.ai-las`: `border-radius: 3.5px`).
    static let smallHeaderCornerRadius: CGFloat = 3.5
    static let shadowOpacity = 0.18
    static let shadowBlur: CGFloat = 34
    static let shadowY: CGFloat = 14
    /// Der feine Rand um das große Zeichen (`0 0 0 .5px rgba(0,0,0,.06)`).
    static let rimOpacity = 0.06
    static let rimWidth: CGFloat = 0.5
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
    /// `ic('book', 46)` auf der Seite „Deine Rechtsschule“ (Spec § 11.5): das offene Buch, rund 31 pt breit.
    public static let bookSymbolSize: CGFloat = 29
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
