/// Quelle für den Kompasskurs.
///
/// Views sprechen nie direkt mit `CLLocationManager`. So lässt sich `-debugQiblaHeading` ohne Kompass
/// nachstellen – der Simulator hat keinen.
public protocol HeadingSource: Sendable {

    /// Ob das Gerät einen Kompass hat.
    func isAvailable() async -> Bool

    /// Der Kurs, solange jemand zuhört: jede Änderung, bis die Folge abgebrochen wird. Ohne Kompass endet
    /// sie, ohne etwas zu liefern.
    func updates() async -> AsyncStream<Heading>
}

/// Liefert immer denselben Kurs – für Debug-Argumente, Tests und Previews. Ohne Kurs verhält sich die
/// Quelle wie ein Gerät ohne Kompass.
public struct FixedHeadingSource: HeadingSource {
    public let heading: Heading?

    public init(heading: Heading?) {
        self.heading = heading
    }

    public func isAvailable() async -> Bool {
        heading != nil
    }

    public func updates() async -> AsyncStream<Heading> {
        AsyncStream { continuation in
            if let heading {
                continuation.yield(heading)
            }
            continuation.finish()
        }
    }
}
