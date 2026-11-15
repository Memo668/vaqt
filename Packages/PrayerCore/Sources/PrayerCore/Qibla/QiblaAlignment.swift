/// Wie das Gerät zur Qibla steht – der Rechenteil von `updateQibla()` im Prototyp.
///
/// Aus der Richtung zur Kaaba und dem Kurs des Geräts ergibt sich, ob es ausgerichtet ist, und sonst,
/// wohin und um wie viele Grad zu drehen ist („Nach rechts drehen 39°“).
public struct QiblaAlignment: Hashable, Sendable {

    /// Innerhalb dieser Abweichung in Grad gilt das Gerät als ausgerichtet (`Math.abs(diff) <= 3`,
    /// Design Spec § 3: „Aligned within ±3°“).
    public static let tolerance = 3.0

    /// Der Toleranzbereich: so weit darf das Gerät zu jeder Seite der Qibla zeigen – zusammen 80°
    /// (Spec § 9.5, `Q_TOL`; entschieden am 15.11.2026). Der Kompass zeichnet ihn als Keil.
    public static let toleranceRange = 40.0

    /// Die Richtung, in die zu drehen ist.
    public enum Turn: Hashable, Sendable {
        case left
        case right
    }

    /// Abweichung in Grad, von −180 bis unter 180. Positiv heißt: Die Qibla liegt rechts vom Kurs.
    public let difference: Double

    /// - Parameters:
    ///   - bearing: Richtung zur Kaaba in Grad ab Nord im Uhrzeigersinn (`Qibla.bearing`).
    ///   - heading: Kurs des Geräts in Grad ab Nord im Uhrzeigersinn.
    public init(bearing: Double, heading: Double) {
        difference = Heading.turn(from: heading, to: bearing)
    }

    /// Ob das Gerät zur Qibla zeigt.
    public var isAligned: Bool {
        abs(difference) <= Self.tolerance
    }

    /// Ob das Gerät im Toleranzbereich zeigt (`Math.abs(diff) <= Q_TOL`) – ausgerichtet eingeschlossen.
    public var isWithinToleranceRange: Bool {
        abs(difference) <= Self.toleranceRange
    }

    /// Wohin zu drehen ist; `nil`, wenn das Gerät ausgerichtet ist.
    public var turn: Turn? {
        guard !isAligned else { return nil }
        return difference > 0 ? .right : .left
    }

    /// Um wie viele ganze Grad zu drehen ist – `Math.round(Math.abs(diff))`. Knapp außerhalb der
    /// Toleranz steht deshalb wie im Prototyp noch „3°“ da.
    public var degrees: Int {
        Int(abs(difference).rounded())
    }
}
