import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Zustand der Qibla-Seite: Richtung und Entfernung zur Kaaba vom Ort aus, der gilt, der Kurs des
/// Geräts und was sich daraus ergibt – der Rechenteil von `qiblaPage()` und `updateQibla()` im Prototyp.
///
/// Der Ort kommt aus `PlaceModel`, demselben Modell wie auf der Zeiten-Seite. Der Kurs kommt aus einer
/// `HeadingSource` und läuft nur, solange die Seite zu sehen ist (`run()`).
@MainActor
@Observable
public final class QiblaModel {

    /// Was in der Statuszeile unter dem Kompass steht.
    public enum Status: Hashable, Sendable {
        /// „Du blickst Richtung Qibla“ – in Akzent, mit Haken.
        case facing
        /// „Im Toleranzbereich“ in Akzent mit Haken, darunter klein „Nach rechts drehen 25°“ (Spec § 9.5).
        case withinTolerance(QiblaAlignment.Turn, degrees: Int)
        /// „Nach rechts drehen 97°“ – außerhalb des Toleranzbereichs.
        case turn(QiblaAlignment.Turn, degrees: Int)
        /// „Kein Kompass verfügbar“ – das Gerät hat keinen.
        case noCompass
    }

    @ObservationIgnored private let location: PlaceModel
    @ObservationIgnored private let headingSource: any HeadingSource
    @ObservationIgnored private let locale: Locale

    /// Ob das Gerät einen Kompass hat; `nil`, solange das noch nicht feststeht.
    public private(set) var hasCompass: Bool?
    /// Der zuletzt gemeldete Kurs; `nil`, solange keiner gekommen ist.
    public private(set) var heading: Heading?

    /// - Parameters:
    ///   - location: welcher Ort gilt.
    ///   - locale: Sprache für die Zahl der Kilometer; ohne Angabe die der Texte.
    public init(location: PlaceModel, headingSource: any HeadingSource, locale: Locale = L10n.locale) {
        self.location = location
        self.headingSource = headingSource
        self.locale = locale
    }

    // MARK: - Ort

    /// Richtung und Entfernung zur Kaaba vom Ort aus, der gilt; `nil` ohne Ort.
    public var qibla: Qibla? {
        location.place.map { Qibla(from: $0.coordinates) }
    }

    /// Die Richtung, in die die Nadel zeigt. In Mekka und ohne Ort gibt es keine Nadel.
    public var bearing: Double? {
        guard let qibla, !qibla.isInMecca else { return nil }
        return qibla.bearing
    }

    /// Ob weder Standort noch Stadt da sind und der Standort auch nicht mehr von selbst kommt: Dann
    /// steht an der Stelle der Info-Zeile „Stadt wählen“.
    public var needsCity: Bool {
        location.needsCity
    }

    /// Die Zeile über dem Kompass: „Qibla · Berlin“. Solange der Name des aktuellen Standorts fehlt,
    /// „Qibla · Aktueller Standort“; ohne Ort nur „Qibla“.
    public var title: String {
        needsCity ? L10n.qibla : "\(L10n.qibla) · \(location.cityTitle)"
    }

    // MARK: - Kurs

    /// Ob die Seite einen Kompass zeigt, der sich dreht. Ohne Kompass steht die Skala fest mit Norden
    /// oben, und Kursanzeige und Peilmarke entfallen.
    public var showsHeading: Bool {
        hasCompass != false
    }

    /// Der Kurs, um den sich die Skala dreht; `nil` ohne Kompass. Bis der erste Kurs kommt, steht
    /// Norden oben.
    public var dialHeading: Double? {
        showsHeading ? heading?.degrees ?? 0 : nil
    }

    /// Die Kursanzeige über dem Kompass: „98°“ und „O“. `nil`, solange es keinen Kurs gibt.
    public var readout: (degrees: String, direction: String)? {
        guard showsHeading, let heading else { return nil }
        return ("\(heading.wholeDegrees)°", heading.compassPoint.localizedAbbreviation)
    }

    /// Wie das Gerät zur Qibla steht; `nil` ohne Nadel, ohne Kurs und bei ungültigem Kurs – ein Kompass,
    /// der kalibriert werden muss, meldet keine Ausrichtung.
    public var alignment: QiblaAlignment? {
        guard showsHeading, let heading, heading.isValid, let bearing else { return nil }
        return QiblaAlignment(bearing: bearing, heading: heading.degrees)
    }

    /// Ob das Gerät zur Qibla zeigt: Statuszeile und Peilmarke in Akzent, Haptik.
    public var isAligned: Bool {
        alignment?.isAligned == true
    }

    /// Die Statuszeile; `nil` heißt, sie bleibt leer – in Mekka, ohne Ort und solange kein Kurs da ist.
    public var status: Status? {
        guard showsHeading else { return .noCompass }
        guard let alignment else { return nil }
        guard let turn = alignment.turn else { return .facing }
        guard !alignment.isWithinToleranceRange else { return .withinTolerance(turn, degrees: alignment.degrees) }
        return .turn(turn, degrees: alignment.degrees)
    }

    /// Ob das Gerät im Toleranzbereich zeigt; dann ist der Keil des Kompasses kräftiger (`in-tol`).
    public var isWithinToleranceRange: Bool {
        alignment?.isWithinToleranceRange == true
    }

    /// Der Text der Statuszeile, wie `updateQibla()` ihn schreibt.
    public var statusText: String? {
        switch status {
        case .facing: L10n.facing
        case .withinTolerance: L10n.inTol
        case .turn(let turn, let degrees): Self.turnText(turn, degrees: degrees)
        case .noCompass: L10n.noCompass
        case nil: nil
        }
    }

    /// Die kleine Zeile unter „Im Toleranzbereich“: wohin noch zu drehen ist.
    public var statusDetail: String? {
        guard case .withinTolerance(let turn, let degrees) = status else { return nil }
        return Self.turnText(turn, degrees: degrees)
    }

    /// Ob unter der Info-Zeile die Legende zum Keil steht – überall, wo es eine Richtung gibt.
    public var showsToleranceLegend: Bool {
        bearing != nil
    }

    private static func turnText(_ turn: QiblaAlignment.Turn, degrees: Int) -> String {
        "\(turn == .left ? L10n.turnLeft : L10n.turnRight) \(degrees)°"
    }

    /// Die Zeile unter dem Status: „Qibla 137° SO · 4.130 km bis zur Kaaba“, in Mekka der Hinweis
    /// `inMecca`; `nil` ohne Ort.
    public var info: String? {
        guard let qibla else { return nil }
        guard !qibla.isInMecca else { return L10n.inMecca }
        let direction = L10n.qiblaAt(
            deg: String(qibla.wholeDegrees), dir: qibla.compassPoint.localizedAbbreviation
        )
        let distance = L10n.distance(km: qibla.displayDistanceKm.formatted(.number.locale(locale)))
        return "\(direction) · \(distance)"
    }

    /// Ob die Karte „Kompass kalibrieren“ erscheint: nur bei ungültigem Kurs oder schlechter Genauigkeit
    /// (Design Spec § 4; der Prototyp zeigt sie immer).
    public var showsCalibration: Bool {
        showsHeading && heading?.needsCalibration == true
    }

    // MARK: - Ablauf

    /// Hört auf den Kompass, bis die Aufgabe abgebrochen wird – die Seite ruft das, solange sie zu
    /// sehen ist. Danach bleibt der letzte Kurs stehen.
    public func run() async {
        let isAvailable = await headingSource.isAvailable()
        hasCompass = isAvailable
        guard isAvailable else { return }
        for await heading in await headingSource.updates() where heading != self.heading {
            self.heading = heading
        }
    }
}
