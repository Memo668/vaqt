import Foundation
import Network

/// Quelle für die Frage, ob das Gerät ein Netz hat.
///
/// Die App rechnet auf dem Gerät und braucht das Netz nur für die Ortssuche und den Stadtnamen. Ohne
/// Netz zeigt die Zeiten-Seite einen kleinen Hinweis, und das Stadt-Sheet bietet nur die gespeicherten
/// Städte an (Design Spec § 5, „Offline“). Views fragen nie selbst nach dem Netz; so lässt sich
/// `-debugOffline` nachstellen.
public protocol ConnectivitySource: Sendable {

    /// Meldet zuerst den aktuellen Stand und danach jede Änderung: `true` heißt, es gibt ein Netz.
    func updates() -> AsyncStream<Bool>
}

/// Immer derselbe Stand – für Debug-Argumente, Tests und Previews.
public struct FixedConnectivity: ConnectivitySource {
    public let isOnline: Bool

    public init(isOnline: Bool) {
        self.isOnline = isOnline
    }

    public func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(isOnline)
            continuation.finish()
        }
    }
}

/// Der Stand des Systems über `NWPathMonitor`. Das beobachtet nur die Verbindungen des Geräts und
/// schickt selbst nichts ins Netz.
public struct NetworkConnectivity: ConnectivitySource {

    public init() {}

    public func updates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            continuation.onTermination = { _ in
                monitor.cancel()
            }
            monitor.start(queue: DispatchQueue(label: "Gebetszeiten.Connectivity", qos: .utility))
        }
    }
}
