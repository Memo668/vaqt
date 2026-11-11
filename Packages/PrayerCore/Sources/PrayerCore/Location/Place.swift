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

    /// Ob der Ort einen Namen hat. Ohne Netz kennt die App vom aktuellen Standort nur die Koordinaten;
    /// der Name bleibt dann leer.
    public var hasName: Bool {
        !name.isEmpty
    }

    /// So nah liegen zwei Standorte beieinander, dass Name, Land und Zeitzone des einen auch für den
    /// anderen gelten – etwa der Umkreis einer Großstadt.
    public static let sameAreaKm = 25.0

    /// Dieser Ort mit Name, Land und Zeitzone von `known`, falls er selbst keinen Namen hat und in
    /// dessen Nähe liegt. So gilt ohne Netz der zuletzt bestimmte Ort weiter, mit den neuen Koordinaten.
    public func named(after known: Place?) -> Place {
        guard !hasName, let known, known.hasName,
              coordinates.distanceKm(to: known.coordinates) <= Self.sameAreaKm
        else { return self }
        return Place(
            name: known.name, countryCode: known.countryCode,
            coordinates: coordinates, timeZoneIdentifier: known.timeZoneIdentifier
        )
    }
}
