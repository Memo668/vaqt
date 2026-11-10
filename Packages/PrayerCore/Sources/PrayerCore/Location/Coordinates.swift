/// Geografische Koordinaten in Grad (WGS 84). Nord und Ost sind positiv.
public struct Coordinates: Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
