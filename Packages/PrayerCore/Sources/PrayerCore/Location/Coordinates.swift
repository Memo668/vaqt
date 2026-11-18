import Foundation

/// Geografische Koordinaten in Grad (WGS 84). Nord und Ost sind positiv.
public struct Coordinates: Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Auf zwei Nachkommastellen gerundet, also auf gut einen Kilometer (0,01° Breite ≈ 1,1 km). So genau
    /// braucht es die App für Gebetszeiten und Qibla – die Zeiten verschieben sich dadurch um höchstens ein
    /// paar Sekunden. Gespeichert und an den Geocoder von Apple geschickt wird nur das (Sicherheitsprüfung
    /// vom 17.11.2026).
    public var coarse: Coordinates {
        Coordinates(latitude: (latitude * 100).rounded() / 100, longitude: (longitude * 100).rounded() / 100)
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
