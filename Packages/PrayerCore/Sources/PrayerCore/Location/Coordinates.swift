import Foundation

/// Geografische Koordinaten in Grad (WGS 84). Nord und Ost sind positiv.
public struct Coordinates: Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Mittlerer Erdradius in Kilometern (IUGG).
    private static let earthRadiusKm = 6371.0088

    /// Entfernung zu `other` in Kilometern entlang des Großkreises, mit der Haversine-Formel auf einer
    /// Kugel.
    public func distanceKm(to other: Coordinates) -> Double {
        let startLatitude = latitude * .pi / 180
        let endLatitude = other.latitude * .pi / 180
        let latitudeDelta = endLatitude - startLatitude
        let longitudeDelta = (other.longitude - longitude) * .pi / 180

        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude) * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * Self.earthRadiusKm * asin(min(1, haversine.squareRoot()))
    }
}
