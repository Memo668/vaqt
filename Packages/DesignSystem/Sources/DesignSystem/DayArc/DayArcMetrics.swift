import CoreGraphics
import Foundation

/// Die Maße des Tagesbogens – `ARCS` im Prototyp, dazu die Strichstärken aus dem CSS (`.arc-*`).
///
/// Der Bogen ist ein Stück eines Kreises, dessen Mittelpunkt unter der Zeichnung liegt. Er läuft vom
/// Winkel `endAngle` (Fadschr, links) bis `π − endAngle` (Ischa, rechts); bei `endAngle` 0,45 sind das
/// etwa 128°. Alle Längen in pt.
public struct DayArcMetrics: Hashable, Sendable {
    /// Größe der Zeichnung (`w`, `h`). Der Bogen hat diese feste Größe und wächst nicht mit dem Bildschirm.
    public var size: CGSize
    /// Mittelpunkt des Kreises (`cx`, `cy`).
    public var center: CGPoint
    /// Radius des Bogens (`r`).
    public var radius: CGFloat
    /// Winkel an den beiden Enden im Bogenmaß (`a0`).
    public var endAngle: Double
    /// Radius eines Markers (`m`).
    public var markerRadius: CGFloat
    /// Radius des Markers des laufenden Gebets (`mc`).
    public var currentMarkerRadius: CGFloat
    /// Kantenlänge des Symbols in einem Marker (`is`).
    public var symbolSize: CGFloat
    /// Kantenlänge des Symbols im Marker des laufenden Gebets (`isc`).
    public var currentSymbolSize: CGFloat
    /// Radius des Scheins um den Marker des laufenden Gebets (`glow`).
    public var glowRadius: CGFloat
    /// Radius des Knopfes für „jetzt“ (`knob`).
    public var knobRadius: CGFloat
    /// Feld, das eine Zeit am Bogen einnimmt (`lw`, `lh`). Daraus ergibt sich ihr Abstand zum Marker.
    public var timeBox: CGSize
    /// Abstand zwischen Marker und Zeit außen am Bogen (`gap`).
    public var timeGap: CGFloat
    /// Abstand zwischen Marker und Zeit unter den beiden Endmarkern (`below`).
    public var timeBelow: CGFloat
    /// Um so viel liegen die Kerahat-Segmente innerhalb des Bogens (`k`).
    public var kerahatInset: CGFloat
    /// Strichstärke des Bogens (`.arc-track`, `.arc-done`).
    public var trackWidth: CGFloat
    /// Strichstärke der Kerahat-Segmente (`.arc-k`).
    public var kerahatWidth: CGFloat
    /// Sichtbare Breite des Rings um einen Marker, der eng an seinem Vorgänger liegt. Der Prototyp
    /// zeichnet eine 3 pt breite Kontur, deren innere Hälfte unter der Füllung liegt (`paint-order`).
    public var ringWidth: CGFloat
    /// Schriftgröße der Zeiten (`.arc-t`).
    public var timeFontSize: CGFloat
    /// Ob die Zeiten mit Dynamic Type wachsen. In der Live-Aktivität nicht.
    public var timeScales: Bool
    /// Abstand des Inhalts im Bogen zur Unterkante (`.hero-text`, `.la-text`).
    public var contentBottomInset: CGFloat

    /// `ARCS.home`: der Bogen der Zeiten-Seite, 358 × 180 pt.
    public static let home = DayArcMetrics(
        size: CGSize(width: 358, height: 180), center: CGPoint(x: 179, y: 206), radius: 162, endAngle: 0.45,
        markerRadius: 15, currentMarkerRadius: 17, symbolSize: 16, currentSymbolSize: 18,
        glowRadius: 25, knobRadius: 7,
        timeBox: CGSize(width: 34, height: 13), timeGap: 5, timeBelow: 12, kerahatInset: 19,
        trackWidth: 12, kerahatWidth: 3, ringWidth: 1.5,
        timeFontSize: 12, timeScales: true, contentBottomInset: 2
    )

    /// `ARCS.la`: dieselbe Zeichnung kleiner und flacher, für die Live-Aktivität auf dem
    /// Sperrbildschirm, 330 × 122 pt.
    public static let liveActivity = DayArcMetrics(
        size: CGSize(width: 330, height: 122), center: CGPoint(x: 165, y: 190), radius: 166, endAngle: 0.6,
        markerRadius: 10.5, currentMarkerRadius: 12, symbolSize: 12, currentSymbolSize: 13,
        glowRadius: 17, knobRadius: 4.5,
        timeBox: CGSize(width: 28, height: 11), timeGap: 3, timeBelow: 9, kerahatInset: 13.5,
        trackWidth: 7, kerahatWidth: 2, ringWidth: 1.5,
        timeFontSize: 10.5, timeScales: false, contentBottomInset: 6
    )

    // MARK: - Geometrie

    /// Winkel des Bogens im Bogenmaß.
    public var sweep: Double {
        .pi - 2 * endAngle
    }

    /// Winkel zu einem Anteil des Gebetstages – `arcAngle(f)`. 0 ist Fadschr, 1 ist Ischa.
    public func angle(at fraction: Double) -> Double {
        endAngle + fraction * sweep
    }

    /// Punkt auf dem Bogen – `arcPoint(f, g, rr)`.
    ///
    /// - Parameters:
    ///   - radius: Radius des Kreises; ohne Angabe der des Bogens.
    ///   - isRightToLeft: Bei RTL beginnt Fadschr rechts. Gespiegelt wird hier in der Rechnung, nicht
    ///     in der Ansicht – so bleiben Zahlen und Symbole lesbar.
    public func point(at fraction: Double, radius: CGFloat? = nil, isRightToLeft: Bool = false) -> CGPoint {
        let angle = angle(at: fraction)
        let radius = radius ?? self.radius
        let x = center.x - radius * cos(angle)
        return CGPoint(x: isRightToLeft ? size.width - x : x, y: center.y - radius * sin(angle))
    }

    /// Mitte der Zeit zu einem Marker – `arcLabelPos()`.
    ///
    /// Unter den beiden Endmarkern steht die Zeit darunter, bei den übrigen außen am Bogen, in
    /// Richtung der Normalen. Die Zeit bleibt dabei innerhalb der Zeichnung.
    public func timeCenter(
        for marker: CGPoint, markerRadius: CGFloat, fraction: Double, isEnd: Bool, isRightToLeft: Bool = false
    ) -> CGPoint {
        if isEnd {
            return CGPoint(x: marker.x, y: marker.y + markerRadius + timeBelow)
        }
        let angle = angle(at: fraction)
        let normalX = -cos(angle) * (isRightToLeft ? -1 : 1)
        let normalY = -sin(angle)
        let distance = markerRadius + timeGap + abs(normalX) * timeBox.width / 2 + abs(normalY) * timeBox.height / 2
        let x = min(size.width - timeBox.width / 2, max(timeBox.width / 2, marker.x + normalX * distance))
        return CGPoint(x: x, y: marker.y + normalY * distance)
    }

    /// Winkel im Koordinatensystem der Ansicht: 0 zeigt nach rechts, der Winkel wächst im Uhrzeigersinn.
    /// Damit lässt sich der Bogen als Kreisbogen zeichnen.
    public func screenAngle(at fraction: Double, isRightToLeft: Bool = false) -> Double {
        let angle = angle(at: fraction)
        return isRightToLeft ? 2 * .pi - angle : .pi + angle
    }
}
