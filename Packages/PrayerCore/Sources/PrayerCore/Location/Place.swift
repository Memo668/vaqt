import Foundation

/// Ein Ort, für den Gebetszeiten gelten.
public struct Place: Hashable, Codable, Sendable {
    /// Anzeigename, z. B. „Berlin“.
    public var name: String
    /// ISO-3166-1-Ländercode mit zwei Buchstaben, z. B. „DE“ – bestimmt die automatische Methode.
    public var countryCode: String?
    public var coordinates: Coordinates
    /// Kennung der Zeitzone, z. B. „Europe/Berlin“.
    public var timeZoneIdentifier: String

    public init(name: String, countryCode: String?, coordinates: Coordinates, timeZoneIdentifier: String) {
        self.name = name
        self.countryCode = countryCode
        self.coordinates = coordinates
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    /// Zeitzone des Ortes; bei unbekannter Kennung GMT.
    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }
}
