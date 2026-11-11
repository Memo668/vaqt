import CoreGraphics
import Foundation
import PrayerCore

/// Wo die Teile des Kompasses sitzen – der Rechenteil von `dialSVG()` im Prototyp.
///
/// Reine Geometrie ohne Ansicht, in pt im Feld des Kompasses (280 × 280, Ursprung oben links). Die
/// Skala steht hier mit Norden oben; `Compass` dreht sie um den Kurs.
public struct CompassLayout: Hashable, Sendable {

    /// Ein Strich der Skala.
    public struct Tick: Hashable, Sendable, Identifiable {
        /// Winkel in Grad ab Nord im Uhrzeigersinn.
        public let degrees: Int
        /// Ob es einer der langen Striche alle 30° ist.
        public let isMajor: Bool
        /// Inneres und äußeres Ende.
        public let start: CGPoint
        public let end: CGPoint

        public var id: Int { degrees }
    }

    /// Eine Beschriftung der Skala: alle 30° eine Zahl, bei 0°, 90°, 180° und 270° die Himmelsrichtung.
    public struct Label: Hashable, Sendable, Identifiable {
        public let degrees: Int
        /// Die Himmelsrichtung, die hier statt der Zahl steht; sonst `nil`.
        public let point: CompassPoint?
        /// Mitte der Beschriftung.
        public let center: CGPoint

        public var id: Int { degrees }
    }

    /// Die 72 Striche, im Uhrzeigersinn ab Nord.
    public let ticks: [Tick]
    /// Die zwölf Beschriftungen, im Uhrzeigersinn ab Nord.
    public let labels: [Label]

    public init() {
        ticks = stride(from: 0, to: 360, by: CompassMetrics.tickStep).map { degrees in
            let isMajor = degrees.isMultiple(of: CompassMetrics.majorTickStep)
            return Tick(
                degrees: degrees, isMajor: isMajor,
                start: Self.point(
                    degrees: Double(degrees),
                    radius: isMajor ? CompassMetrics.majorTickInnerRadius : CompassMetrics.tickInnerRadius
                ),
                end: Self.point(degrees: Double(degrees), radius: CompassMetrics.tickOuterRadius)
            )
        }
        labels = stride(from: 0, to: 360, by: CompassMetrics.labelStep).map { degrees in
            let isCardinal = degrees.isMultiple(of: CompassMetrics.cardinalStep)
            return Label(
                degrees: degrees,
                point: isCardinal ? CompassPoint(degrees: Double(degrees)) : nil,
                center: Self.point(
                    degrees: Double(degrees),
                    radius: isCardinal ? CompassMetrics.cardinalRadius : CompassMetrics.numberRadius
                )
            )
        }
    }

    /// Mitte des Kompasses.
    public static let center = CGPoint(x: CompassMetrics.diameter / 2, y: CompassMetrics.diameter / 2)

    /// Punkt im Feld des Kompasses.
    ///
    /// - Parameters:
    ///   - degrees: Winkel in Grad ab Nord (oben) im Uhrzeigersinn.
    ///   - radius: Abstand zur Mitte in Einheiten der Zeichnung.
    public static func point(degrees: Double, radius: CGFloat) -> CGPoint {
        let angle = degrees * .pi / 180
        let distance = radius * CompassMetrics.scale
        return CGPoint(x: center.x + distance * sin(angle), y: center.y - distance * cos(angle))
    }

    // MARK: - Nadel und Kaaba-Marke, mit der Qibla oben

    /// Die beiden Enden der Nadel, wenn die Qibla oben liegt.
    public static let needle = (
        start: point(degrees: 0, radius: CompassMetrics.needleStartRadius),
        end: point(degrees: 0, radius: CompassMetrics.needleEndRadius)
    )

    /// Die drei Ecken der Nadelspitze: Spitze, dann die beiden Enden der Basis (`M0 -95 L-8 -79 L8 -79 Z`).
    public static let needleHead: [CGPoint] = [
        point(degrees: 0, radius: CompassMetrics.needleHeadTipRadius),
        CGPoint(
            x: center.x - CompassMetrics.needleHeadHalfWidth * CompassMetrics.scale,
            y: center.y - CompassMetrics.needleHeadBaseRadius * CompassMetrics.scale
        ),
        CGPoint(
            x: center.x + CompassMetrics.needleHeadHalfWidth * CompassMetrics.scale,
            y: center.y - CompassMetrics.needleHeadBaseRadius * CompassMetrics.scale
        ),
    ]

    /// Mitte der Kaaba-Marke, wenn die Qibla oben liegt: 12 pt über dem Rand des Kompasses.
    public static let kaabaCenter = point(degrees: 0, radius: CompassMetrics.kaabaRadius)

    /// Mitte der Peilmarke: fest oben, über dem Rand.
    public static let lubberCenter = CGPoint(
        x: center.x,
        y: CompassMetrics.lubberTop + CompassMetrics.lubberSize.height / 2
    )
}
