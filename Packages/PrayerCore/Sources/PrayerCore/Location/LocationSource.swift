/// Stand der Standortfreigabe, auf das reduziert, was die App unterscheidet.
public enum LocationAuthorization: Equatable, Sendable {
    /// Noch nicht gefragt.
    case notDetermined
    /// Abgelehnt oder vom System eingeschränkt.
    case denied
    /// „Beim Verwenden der App“ erlaubt.
    case authorized
}

/// Quelle für den aktuellen Ort.
///
/// Views sprechen nie direkt mit `CLLocationManager`. So lassen sich `-debugCity` und
/// `-debugLocationDenied` ohne echtes GPS nachstellen.
public protocol LocationSource: Sendable {
    /// Aktueller Stand der Freigabe.
    func authorization() async -> LocationAuthorization

    /// Fragt die Freigabe an, falls noch nicht entschieden, und liefert den Stand danach.
    func requestAuthorization() async -> LocationAuthorization

    /// Aktueller Ort; `nil`, wenn keiner bestimmt werden kann (z. B. ohne Freigabe).
    func currentPlace() async -> Place?
}

/// Liefert immer denselben Ort und denselben Stand der Freigabe – für Debug-Argumente, Tests und Previews.
public struct FixedLocationSource: LocationSource {
    public let place: Place?
    public let status: LocationAuthorization

    public init(place: Place?, status: LocationAuthorization) {
        self.place = place
        self.status = status
    }

    public func authorization() async -> LocationAuthorization { status }

    public func requestAuthorization() async -> LocationAuthorization { status }

    /// Ohne Freigabe gibt es keinen aktuellen Ort – wie beim echten Gerät.
    public func currentPlace() async -> Place? {
        status == .authorized ? place : nil
    }
}
