import Foundation

/// Ein Kompasskurs: die Richtung, in die die Oberkante des Geräts zeigt.
public struct Heading: Hashable, Sendable {

    /// Worauf sich der Kurs bezieht.
    public enum Reference: Hashable, Sendable {
        /// Geografisch Nord – darauf bezieht sich auch die Richtung zur Kaaba (Design Spec § 4).
        case trueNorth
        /// Magnetisch Nord. Ohne Standortfreigabe liefert iOS nur das; der Kurs weicht dann um die
        /// örtliche Missweisung von geografisch Nord ab (docs/OPEN-QUESTIONS.md).
        case magneticNorth
    }

    /// Weicht der Kurs um mehr als so viele Grad ab, gilt die Genauigkeit als schlecht: Die Qibla-Seite
    /// zeigt dann die Karte „Kompass kalibrieren“. Apple nennt keine Schwelle; der Wert ist eine Annahme
    /// und am echten Gerät zu prüfen (docs/OPEN-QUESTIONS.md).
    public static let poorAccuracy = 25.0

    /// Kurs in Grad ab Nord im Uhrzeigersinn, 0 bis unter 360.
    public let degrees: Double
    /// Größte Abweichung des Kurses in Grad, wie `CLHeading.headingAccuracy`. Negativ heißt: Der Kurs
    /// ist ungültig – der Kompass ist nicht kalibriert, oder ein Magnetfeld stört.
    public let accuracy: Double
    public let reference: Reference

    /// - Parameters:
    ///   - degrees: Kurs in Grad; Werte außerhalb von 0 bis unter 360 werden dorthin gebracht.
    ///   - accuracy: größte Abweichung in Grad, negativ für einen ungültigen Kurs.
    public init(degrees: Double, accuracy: Double = 0, reference: Reference = .trueNorth) {
        self.degrees = Self.normalized(degrees)
        self.accuracy = accuracy
        self.reference = reference
    }

    /// Ob der Kurs etwas aussagt. Ein ungültiger Kurs richtet nichts aus und meldet keine Ausrichtung.
    public var isValid: Bool {
        accuracy >= 0
    }

    /// Ob die Karte „Kompass kalibrieren“ erscheint: bei ungültigem Kurs und bei schlechter Genauigkeit
    /// (Design Spec § 4: nur bei schlechter `headingAccuracy`).
    public var needsCalibration: Bool {
        !isValid || accuracy > Self.poorAccuracy
    }

    /// Der Kurs in ganzen Grad, 0 bis 359 – `Math.round(h) % 360` im Prototyp.
    public var wholeDegrees: Int {
        Int(degrees.rounded()) % 360
    }

    /// Die Himmelsrichtung des Kurses, bestimmt aus den ganzen Grad wie in `updateQibla()`.
    public var compassPoint: CompassPoint {
        CompassPoint(degrees: Double(wholeDegrees))
    }

    // MARK: - Winkel

    /// Ein Winkel in Grad, auf 0 bis unter 360 gebracht – `((deg % 360) + 360) % 360`.
    public static func normalized(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        let remainder = degrees.truncatingRemainder(dividingBy: 360)
        let positive = remainder < 0 ? remainder + 360 : remainder
        // Ein winziger negativer Rest ergibt mit 360 addiert genau 360.
        return positive >= 360 ? 0 : positive
    }

    /// Der kürzeste Weg von einem Winkel zum anderen in Grad, von −180 bis unter 180. Positiv heißt im
    /// Uhrzeigersinn – `((q - h + 540) % 360) - 180` im Prototyp.
    public static func turn(from start: Double, to end: Double) -> Double {
        normalized(end - start + 180) - 180
    }
}
