import SwiftUI
import UIKit

/// Das Symbol eines Chips: ein SF Symbol oder eine eigene Zeichnung.
public enum GlassSymbol: Hashable, Sendable {
    /// Ein SF Symbol, z. B. `clock`.
    case system(String)
    /// Gebetsteppich mit Mihrab-Bogen – die Zeichnung `pray` des Prototyps für den Chip „Anleitung“.
    ///
    /// Die Design Spec nennt für diesen Chip kein SF Symbol, und in den SF Symbols gibt es keines für
    /// Gebet oder Moschee. Es gilt deshalb das Referenzbild (entschieden mit dem Plan für Phase 3,
    /// docs/OPEN-QUESTIONS.md).
    case prayerRug
}

/// Gebetsteppich mit Mihrab-Bogen: die Linien von `P.pray` im Prototyp, in einem Feld von 24 × 24.
///
/// ```
/// M6 19.5V9.2a6 6 0 0 1 12 0v10.3z      Teppich mit rundem Abschluss
/// M9.2 19.5v-8.6a2.8 2.8 0 0 1 5.6 0v8.6  Mihrab-Bogen
/// M7.5 22v-1 M10.5 22v-1 M13.5 22v-1 M16.5 22v-1   Fransen
/// ```
public struct PrayerRugShape: Shape {

    /// Kantenlänge des Felds, in dem der Prototyp zeichnet (`viewBox="0 0 24 24"`).
    public static let viewBox: CGFloat = 24
    /// Strichstärke im Feld des Prototyps (`stroke-width="1.8"`).
    public static let strokeWidth: CGFloat = 1.8

    public init() {}

    public func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / Self.viewBox
        let origin = CGPoint(x: rect.midX - Self.viewBox / 2 * scale, y: rect.midY - Self.viewBox / 2 * scale)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }

        var path = Path()
        // Die Bögen laufen von links über den Scheitel nach rechts. Im Koordinatensystem von SwiftUI
        // (y nach unten) ist das die Richtung wachsender Winkel, also `clockwise: false`.
        path.move(to: point(6, 19.5))
        path.addLine(to: point(6, 9.2))
        path.addArc(
            center: point(12, 9.2), radius: 6 * scale,
            startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false
        )
        path.addLine(to: point(18, 19.5))
        path.closeSubpath()

        path.move(to: point(9.2, 19.5))
        path.addLine(to: point(9.2, 10.9))
        path.addArc(
            center: point(12, 10.9), radius: 2.8 * scale,
            startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false
        )
        path.addLine(to: point(14.8, 19.5))

        for x in [7.5, 10.5, 13.5, 16.5] as [CGFloat] {
            path.move(to: point(x, 22))
            path.addLine(to: point(x, 21))
        }
        return path
    }
}

/// Zeichnet ein `GlassSymbol` in der Farbe des Vordergrunds.
struct GlassSymbolView: View {
    let symbol: GlassSymbol
    /// Schriftgröße für ein SF Symbol.
    let pointSize: CGFloat
    /// Kantenlänge des Felds für eine eigene Zeichnung – `ic(icon, 22)` im Prototyp.
    let box: CGFloat

    var body: some View {
        switch symbol {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: pointSize, weight: GlassMetrics.symbolWeight))
        case .prayerRug:
            PrayerRugShape()
                .stroke(style: StrokeStyle(
                    lineWidth: PrayerRugShape.strokeWidth * box / PrayerRugShape.viewBox,
                    lineCap: .round, lineJoin: .round
                ))
                .frame(width: box, height: box)
        }
    }
}

extension GlassSymbol {

    /// Das Symbol als Bild für die Leisten des Systems, etwa für die senkrechte Leiste des iPhone Duo:
    /// ein SF Symbol oder die Zeichnung des Gebetsteppichs als Vorlage, die die Leiste einfärbt. Eine
    /// eigene Ansicht nähme die Leiste nicht als Symbol; sie zeigte dann den Titel.
    @MainActor
    public var barImage: Image {
        switch self {
        case .system(let name):
            Image(systemName: name)
        case .prayerRug:
            Image(uiImage: PrayerRugImage.template)
        }
    }
}

/// Der Gebetsteppich als Bildvorlage in der Größe eines Symbols in den Leisten – einmal gezeichnet.
@MainActor
private enum PrayerRugImage {
    static let template: UIImage = {
        let box = GlassMetrics.chipSymbolBox
        let renderer = ImageRenderer(content: GlassSymbolView(symbol: .prayerRug, pointSize: 0, box: box))
        renderer.scale = 3
        return (renderer.uiImage ?? UIImage()).withRenderingMode(.alwaysTemplate)
    }()
}
