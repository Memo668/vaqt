import Adhan
import Foundation

// In dieser Datei treffen gleichnamige Typen aufeinander. Ohne Zusatz sind die eigenen gemeint
// (`Qibla`, `Coordinates`), die von Adhan Swift tragen `Adhan.` davor.

/// Richtung und Entfernung zur Kaaba von einem Ort aus.
public struct Qibla: Hashable, Sendable {

    /// Die Kaaba in Mekka – dieselben Koordinaten, mit denen Adhan Swift die Richtung bestimmt.
    public static let kaaba = Coordinates(latitude: 21.4225241, longitude: 39.8261818)

    /// Näher als so viele Kilometer an der Kaaba gilt ein Ort als „in Mekka“: Die Qibla-Seite zeigt dann
    /// eine Meldung statt der Nadel (docs/OPEN-QUESTIONS.md, Punkt 5).
    public static let meccaRadiusKm = 5.0

    /// Richtung zur Kaaba in Grad ab geografisch Nord im Uhrzeigersinn, von 0 bis unter 360.
    public let bearing: Double

    /// Entfernung zur Kaaba in Kilometern entlang des Großkreises.
    public let distanceKm: Double

    public init(from coordinates: Coordinates) {
        let origin = Adhan.Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        bearing = Adhan.Qibla(coordinates: origin).direction
        distanceKm = Self.greatCircleDistanceKm(from: coordinates, to: Self.kaaba)
    }

    /// Ob der Ort in Mekka liegt. Die Richtung sagt dort nichts mehr aus.
    public var isInMecca: Bool {
        distanceKm < Self.meccaRadiusKm
    }

    /// Mittlerer Erdradius in Kilometern (IUGG).
    private static let earthRadiusKm = 6371.0088

    /// Entfernung zweier Orte entlang des Großkreises, mit der Haversine-Formel auf einer Kugel.
    private static func greatCircleDistanceKm(from start: Coordinates, to end: Coordinates) -> Double {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let latitudeDelta = endLatitude - startLatitude
        let longitudeDelta = (end.longitude - start.longitude) * .pi / 180

        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * earthRadiusKm * asin(min(1, haversine.squareRoot()))
    }
}
