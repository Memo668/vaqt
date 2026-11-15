import CoreGraphics
import Foundation

/// Die Maße des Kompasses – `dialSVG()` und `.compass` im Prototyp.
///
/// Die Skala ist im Prototyp eine Zeichnung mit 300 Einheiten Kantenlänge (`viewBox="-150 -150 300 300"`),
/// dargestellt auf 280 pt. Was aus der Zeichnung stammt, steht hier in ihren Einheiten; `scale` rechnet
/// sie in pt um. Peilmarke, Mittelpunkt und Puls liegen als eigene Elemente darüber und stehen in pt.
public enum CompassMetrics {

    // MARK: - Größe

    /// Kantenlänge des Kompasses in pt (`.compass`: 280 × 280).
    public static let diameter: CGFloat = 280
    /// Kantenlänge der Zeichnung in ihren Einheiten.
    public static let viewBox: CGFloat = 300
    /// Eine Einheit der Zeichnung in pt.
    public static let scale = diameter / viewBox

    // MARK: - Skala (Einheiten der Zeichnung)

    /// Alle 5° steht ein Strich, alle 30° ein langer.
    public static let tickStep = 5
    public static let majorTickStep = 30
    /// Die Striche enden außen bei Radius 144 und beginnen bei 134, die langen bei 127.
    public static let tickOuterRadius: CGFloat = 144
    public static let tickInnerRadius: CGFloat = 134
    public static let majorTickInnerRadius: CGFloat = 127
    /// Strichstärken (`.tick`, `.tick.major`).
    public static let tickWidth: CGFloat = 1.2
    public static let majorTickWidth: CGFloat = 2

    // MARK: - Beschriftung (Einheiten der Zeichnung)

    /// Alle 30° steht eine Zahl, alle 90° an ihrer Stelle die Himmelsrichtung.
    public static let labelStep = 30
    public static let cardinalStep = 90
    /// Radius, auf dem die Mitte der Himmelsrichtungen und der Zahlen liegt.
    public static let cardinalRadius: CGFloat = 106
    public static let numberRadius: CGFloat = 109
    /// Schriftgrößen (`.lbl.card`: 600 18px, `.lbl`: 500 11px).
    public static let cardinalFontSize: CGFloat = 18
    public static let numberFontSize: CGFloat = 11

    // MARK: - Toleranzbereich (Einheiten der Zeichnung, Spec § 9.5)

    /// Der Keil reicht 40° zu jeder Seite der Qibla (`Q_TOL`), von der Mitte bis Radius 144; die
    /// gestrichelten Kanten beginnen bei Radius 22 (`.q-tol`, `.q-tol-edge`).
    public static let toleranceDegrees = 40.0
    public static let toleranceOuterRadius: CGFloat = 144
    public static let toleranceEdgeInnerRadius: CGFloat = 22
    /// Fläche in Akzent zu 11 %, im Toleranzbereich zu 22 %; Kanten 1,5 stark, Akzent zu 50 %,
    /// gestrichelt 3 / 4.
    public static let toleranceFill = 0.11
    public static let toleranceFillInside = 0.22
    public static let toleranceEdgeOpacity = 0.5
    public static let toleranceEdgeWidth: CGFloat = 1.5
    public static let toleranceEdgeDash: [CGFloat] = [3, 4]

    // MARK: - Nadel und Kaaba-Marke (Einheiten der Zeichnung)

    /// Die Nadel läuft von Radius 12 bis 80 (`.q-needle`), 3 breit mit runden Enden.
    public static let needleStartRadius: CGFloat = 12
    public static let needleEndRadius: CGFloat = 80
    public static let needleWidth: CGFloat = 3
    /// Die Spitze ist ein Dreieck von Radius 79 bis 95, an der Basis 16 breit (`.q-head`).
    public static let needleHeadBaseRadius: CGFloat = 79
    public static let needleHeadTipRadius: CGFloat = 95
    public static let needleHeadHalfWidth: CGFloat = 8
    /// Die Kaaba-Marke sitzt außerhalb der Skala bei Radius 163: ein Quadrat mit 16 Kantenlänge und
    /// Eckenradius 2, darin ein Band in Akzent, 2 stark und 3 über der Mitte (`.kaaba`, `.kaaba-band`).
    public static let kaabaRadius: CGFloat = 163
    public static let kaabaSize: CGFloat = 16
    public static let kaabaCornerRadius: CGFloat = 2
    public static let kaabaBandWidth: CGFloat = 2
    public static let kaabaBandOffset: CGFloat = -3

    // MARK: - Peilmarke, Mittelpunkt, Puls (pt)

    /// Die feste Peilmarke: 3 × 26 pt, ihre Oberkante 18 pt über dem Kompass (`.lubber`).
    public static let lubberSize = CGSize(width: 3, height: 26)
    public static let lubberTop: CGFloat = -18
    /// Der Punkt in der Mitte (`.c-center`).
    public static let centerDotDiameter: CGFloat = 10
    /// Wird das Gerät ausgerichtet, läuft ein Ring in Akzent vom Rand 26 pt nach außen und verblasst
    /// dabei von 45 % Deckkraft auf null, in 0,8 Sekunden (`@keyframes qpulse`).
    public static let pulseSpread: CGFloat = 26
    public static let pulseOpacity = 0.45
    public static let pulseDuration: TimeInterval = 0.8
    /// So lange braucht die Peilmarke für den Wechsel der Farbe (`transition: background .2s`).
    public static let alignedTransition: TimeInterval = 0.2
}
