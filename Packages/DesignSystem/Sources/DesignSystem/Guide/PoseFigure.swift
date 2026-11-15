import PrayerCore
import SwiftUI

/// Die Haltungsfigur eines Schritts im Ablauf der Anleitung: ein Strichpiktogramm in Akzent auf einer
/// Kachel in getöntem Akzent, darunter eine blasse Bodenlinie. `poseSvg()` und `.pose` im Prototyp.
///
/// Die Figuren sind die Zeichnungen `POSE` des Prototyps, Punkt für Punkt übernommen (`PoseShape`). Ob es
/// später echte Illustrationen werden, ist offen (Design Spec § 6.14). Die Figur ist Schmuck; was der
/// Schritt meint, sagt der Text daneben. In der Leserichtung von rechts nach links wird sie nicht
/// gespiegelt, wie im Prototyp.
public struct PoseFigure: View {
    /// Größe der Kachel: in den Karten des Ablaufs oder groß im Durchlauf „Schritt für Schritt“.
    public enum Size: Sendable {
        /// Karte im Ablauf (`.pose`: 58 pt, Radius 16, Zeichnung 46 pt).
        case card
        /// Durchlauf (`.walk-pose`: 172 pt, Radius 44, Zeichnung 126 pt; Spec § 9.6).
        case walk
    }

    private let pose: GuideStep.Pose
    private let size: Size

    public init(_ pose: GuideStep.Pose, size: Size = .card) {
        self.pose = pose
        self.size = size
    }

    public var body: some View {
        let metrics = PoseFigureMetrics(size)
        let scale = metrics.figureSize / PoseShape.viewBox
        ZStack {
            PoseShape(pose)
                .stroke(Palette.accent, style: Self.strokeStyle(width: PoseShape.strokeWidth * scale))
            PoseGroundShape()
                .stroke(
                    Palette.accent.opacity(PoseGroundShape.opacity),
                    style: Self.strokeStyle(width: PoseGroundShape.strokeWidth * scale)
                )
        }
        .frame(width: metrics.figureSize, height: metrics.figureSize)
        // Sonst spiegelt SwiftUI die Zeichnung bei der Leserichtung von rechts nach links.
        .environment(\.layoutDirection, .leftToRight)
        .frame(width: metrics.tileSize, height: metrics.tileSize)
        .background(Palette.accentTint, in: .rect(cornerRadius: metrics.tileRadius, style: .continuous))
        .accessibilityHidden(true)
    }

    /// Runde Enden und Ecken (`stroke-linecap="round" stroke-linejoin="round"`).
    private static func strokeStyle(width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

/// Maße der Kachel: in der Karte `.pose` (58 × 58 pt, Radius 16; die Zeichnung 46 × 46 pt, mittig), im
/// Durchlauf `.walk-pose` (172 × 172 pt, Radius 44; `.walk-pose svg`: 126 × 126 pt).
struct PoseFigureMetrics {
    let tileSize: CGFloat
    let tileRadius: CGFloat
    let figureSize: CGFloat

    init(_ size: PoseFigure.Size) {
        switch size {
        case .card:
            tileSize = 58
            tileRadius = 16
            figureSize = 46
        case .walk:
            tileSize = WalkMetrics.tileSize
            tileRadius = WalkMetrics.tileRadius
            figureSize = 126
        }
    }
}

/// Die Linien einer Haltungsfigur – `POSE` im Prototyp, in dessen Raster von 48 × 48.
///
/// Kopf als Kreis, Rumpf, Arme und Beine als Linien. Beim Friedensgruß zeigt ein Bogen mit Pfeilspitze,
/// dass sich der Kopf dreht. Die Form wird mittig in das Feld skaliert, das sie bekommt.
public struct PoseShape: Shape {

    /// Kantenlänge des Rasters, in dem der Prototyp zeichnet (`viewBox="0 0 48 48"`).
    public static let viewBox: CGFloat = 48
    /// Strichstärke im Raster des Prototyps (`stroke-width="2.6"`).
    public static let strokeWidth: CGFloat = 2.6

    public let pose: GuideStep.Pose

    public init(_ pose: GuideStep.Pose) {
        self.pose = pose
    }

    public func path(in rect: CGRect) -> Path {
        PoseGeometry.path(for: PoseGeometry.elements(for: pose), in: rect)
    }
}

/// Die Bodenlinie unter jeder Figur: `M5 44.5h38`, Strich 1,6, Deckkraft 35 %.
public struct PoseGroundShape: Shape {
    /// Strichstärke im Raster des Prototyps (`stroke-width="1.6"`).
    public static let strokeWidth: CGFloat = 1.6
    /// Deckkraft (`opacity=".35"`).
    public static let opacity = 0.35

    public init() {}

    public func path(in rect: CGRect) -> Path {
        PoseGeometry.path(for: [PoseGeometry.ground], in: rect)
    }
}

/// Die Geometrie der Figuren als Daten, damit sie sich gegen das SVG des Prototyps prüfen lässt.
enum PoseGeometry {

    /// Ein Teil einer Figur, in Koordinaten des Rasters von 48 × 48.
    enum Element: Equatable {
        /// Ein Kreis (`<circle>`), nur als Linie.
        case circle(center: CGPoint, radius: CGFloat)
        /// Ein Linienzug (`M … l … l …`).
        case lines([CGPoint])
        /// Ein Kreisbogen (`a r r 0 0 sweep x y`): der kleinere der beiden Bögen von `from` nach `to`; mit
        /// `sweep` in Richtung wachsender Winkel, auf dem Bildschirm also im Uhrzeigersinn.
        case arc(from: CGPoint, to: CGPoint, radius: CGFloat, sweep: Bool)
    }

    private static func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }

    /// Die Bodenlinie: `M5 44.5h38`.
    static let ground = Element.lines([point(5, 44.5), point(43, 44.5)])

    // Stehend: Kopf, Rumpf und Beine sind bei Takbīr, Qiyām und Iʿtidāl gleich.
    //   <circle cx="24" cy="8.5" r="3.6"/>  M24 13.5V29  M24 29l-3.5 13  M24 29l3.5 13
    private static let standing: [Element] = [
        .circle(center: point(24, 8.5), radius: 3.6),
        .lines([point(24, 13.5), point(24, 29)]),
        .lines([point(24, 29), point(20.5, 42)]),
        .lines([point(24, 29), point(27.5, 42)]),
    ]

    // Sitzend: bei Taschahhud und Salām gleich.
    //   <circle cx="21" cy="11" r="3.6"/>  M21 16v15.5  M21 31.5l12.5 9  M33.5 40.5H19.5  M21 19.5l9 13
    private static let sitting: [Element] = [
        .circle(center: point(21, 11), radius: 3.6),
        .lines([point(21, 16), point(21, 31.5)]),
        .lines([point(21, 31.5), point(33.5, 40.5)]),
        .lines([point(33.5, 40.5), point(19.5, 40.5)]),
        .lines([point(21, 19.5), point(30, 32.5)]),
    ]

    /// Die Teile einer Figur. Die Kommentare nennen die Pfade aus `POSE`; relative Angaben (`l`, `h`, `v`)
    /// sind hier in feste Punkte umgerechnet.
    static func elements(for pose: GuideStep.Pose) -> [Element] {
        switch pose {
        case .takbir:
            // Hände erhoben: M24 16.5l-5.5 2-1-8  M24 16.5l5.5 2 1-8
            standing + [
                .lines([point(24, 16.5), point(18.5, 18.5), point(17.5, 10.5)]),
                .lines([point(24, 16.5), point(29.5, 18.5), point(30.5, 10.5)]),
            ]
        case .qiyam:
            // Hände vor dem Körper: M24 16.5l-4.5 4.5 7 1
            standing + [
                .lines([point(24, 16.5), point(19.5, 21), point(26.5, 22)]),
            ]
        case .ruku:
            // <circle cx="36" cy="16.5" r="3.6"/>  M14 18h17.5  M14 18l1.5 24  M30 18.5l-14 12
            [
                .circle(center: point(36, 16.5), radius: 3.6),
                .lines([point(14, 18), point(31.5, 18)]),
                .lines([point(14, 18), point(15.5, 42)]),
                .lines([point(30, 18.5), point(16, 30.5)]),
            ]
        case .itidal:
            // Arme hängen: M24 16.5l-3 11  M24 16.5l3 11
            standing + [
                .lines([point(24, 16.5), point(21, 27.5)]),
                .lines([point(24, 16.5), point(27, 27.5)]),
            ]
        case .sujud:
            // <circle cx="37.5" cy="38.4" r="3.6"/>  M15 25.5l18.5 10.5  M15 25.5l2.5 16.5  M17.5 42H6
            // M31.5 35.5l-1 6.5
            [
                .circle(center: point(37.5, 38.4), radius: 3.6),
                .lines([point(15, 25.5), point(33.5, 36)]),
                .lines([point(15, 25.5), point(17.5, 42)]),
                .lines([point(17.5, 42), point(6, 42)]),
                .lines([point(31.5, 35.5), point(30.5, 42)]),
            ]
        case .sit:
            sitting
        case .salam:
            // Kopf dreht sich: M28 5.5a7.5 7.5 0 0 1 2.4 8.2  M30.4 13.7l2.4-2.4  M30.4 13.7l-3.1-1
            sitting + [
                .arc(from: point(28, 5.5), to: point(30.4, 13.7), radius: 7.5, sweep: true),
                .lines([point(30.4, 13.7), point(32.8, 11.3)]),
                .lines([point(30.4, 13.7), point(27.3, 12.7)]),
            ]
        }
    }

    /// Mittelpunkt des kleineren Kreisbogens mit Radius `radius` von `from` nach `to` – die Umrechnung
    /// aus der Schreibweise von SVG (SVG 1.1, Anhang F.6.5, für gleiche Radien und ohne Drehung).
    static func arcCenter(from: CGPoint, to: CGPoint, radius: CGFloat, sweep: Bool) -> CGPoint {
        let halfX = (from.x - to.x) / 2
        let halfY = (from.y - to.y) / 2
        let halfSquared = halfX * halfX + halfY * halfY
        guard halfSquared > 0 else { return from }
        // `large-arc-flag` ist 0: Der Mittelpunkt liegt auf der Seite, die zum kleineren Bogen gehört.
        let sign: CGFloat = sweep ? 1 : -1
        let factor = sign * (max(0, radius * radius - halfSquared) / halfSquared).squareRoot()
        return CGPoint(x: factor * halfY + (from.x + to.x) / 2, y: -factor * halfX + (from.y + to.y) / 2)
    }

    /// Zeichnet die Teile mittig in `rect`, skaliert vom Raster 48 × 48.
    static func path(for elements: [Element], in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / PoseShape.viewBox
        let origin = CGPoint(
            x: rect.midX - PoseShape.viewBox / 2 * scale,
            y: rect.midY - PoseShape.viewBox / 2 * scale
        )
        func map(_ point: CGPoint) -> CGPoint {
            CGPoint(x: origin.x + point.x * scale, y: origin.y + point.y * scale)
        }

        var path = Path()
        for element in elements {
            switch element {
            case .circle(let center, let radius):
                let mapped = map(center)
                path.addEllipse(in: CGRect(
                    x: mapped.x - radius * scale, y: mapped.y - radius * scale,
                    width: 2 * radius * scale, height: 2 * radius * scale
                ))
            case .lines(let points):
                guard let first = points.first else { continue }
                path.move(to: map(first))
                for point in points.dropFirst() {
                    path.addLine(to: map(point))
                }
            case .arc(let from, let to, let radius, let sweep):
                let center = arcCenter(from: from, to: to, radius: radius, sweep: sweep)
                let start = Angle(radians: atan2(from.y - center.y, from.x - center.x))
                let end = Angle(radians: atan2(to.y - center.y, to.x - center.x))
                path.move(to: map(from))
                // Im Koordinatensystem von SwiftUI (y nach unten) heißt wachsender Winkel `clockwise: false`.
                path.addArc(
                    center: map(center), radius: radius * scale,
                    startAngle: start, endAngle: end, clockwise: !sweep
                )
            }
        }
        return path
    }
}
