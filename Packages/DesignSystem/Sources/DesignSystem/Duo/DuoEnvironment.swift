import OSLog
import SwiftUI

extension EnvironmentValues {

    /// Wo das System die senkrechte Leiste hinlegt – auf dem iPhone Duo rechts, in RTL ebenfalls
    /// rechts (Design Spec § 8). `nil`, wenn die Leisten waagerecht stehen: auf dem iPhone und innen im
    /// Hochformat. Gesetzt von `readsVerticalBarEdge()`.
    @Entry public var verticalBarEdge: HorizontalEdge? = nil
}

extension View {

    /// Übernimmt aus dem System (ab iOS 27.1), wo die senkrechte Leiste steht, in `verticalBarEdge`.
    /// Davor gibt es keine senkrechte Leiste.
    public func readsVerticalBarEdge() -> some View {
        modifier(VerticalBarEdgeReader())
    }

    /// Bestimmt aus Größenklasse, Breite und Falz, wie die Seiten darunter ihre Teile zeigen
    /// (`pageArrangement`). Gehört an eine Ansicht, deren Rahmen beim Wischen und Scrollen stillsteht –
    /// den Pager oder die Seite eines Tabs –, und misst den Platz ohne die senkrechte Leiste.
    public func readsPageArrangement() -> some View {
        modifier(PageArrangementReader())
    }
}

private struct VerticalBarEdgeReader: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.modifier(SystemVerticalBarEdge())
        } else {
            content
        }
    }
}

@available(iOS 27.1, *)
private struct SystemVerticalBarEdge: ViewModifier {
    @Environment(\.toolbarVerticalEdge) private var edge

    func body(content: Content) -> some View {
        content.environment(\.verticalBarEdge, edge)
    }
}

private struct PageArrangementReader: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var geometry = ContentGeometry.zero

    func body(content: Content) -> some View {
        let arrangement = PageArrangement.resolve(
            horizontalSizeClass: sizeClass, size: CGSize(width: geometry.width, height: geometry.height),
            fold: geometry.fold
        )
        content
            .environment(\.pageArrangement, arrangement)
            .environment(\.pageHeight, geometry.height)
            .onGeometryChange(for: ContentGeometry.self, of: ContentGeometry.init) { geometry in
                self.geometry = geometry
                #if DEBUG
                ContentGeometry.log.debug(
                    "Platz \(geometry.width, format: .fixed(precision: 1)) × \(geometry.height, format: .fixed(precision: 1)) pt, Falz \(String(describing: geometry.fold), privacy: .public), \(String(describing: sizeClass), privacy: .public)"
                )
                #endif
            }
    }
}

/// Größe des Inhalts und der Falz darin.
struct ContentGeometry: Equatable, Sendable {
    var width: CGFloat
    var height: CGFloat
    var fold: Fold?

    static let zero = ContentGeometry(width: 0, height: 0, fold: nil)

    #if DEBUG
    static let log = Logger(subsystem: "com.example.gebetszeiten", category: "duo")
    #endif

    init(width: CGFloat, height: CGFloat, fold: Fold?) {
        self.width = width
        self.height = height
        self.fold = fold
    }

    /// Liest den Platz aus dem Rahmen einer Ansicht. Den Falz meldet das System ab iOS 27.1 als
    /// „division“: auf dem iPhone Duo innen ein 40 pt breiter Streifen um die Mitte des Bildschirms.
    /// Zählt hier nur einer, der den Platz quert.
    init(_ proxy: GeometryProxy) {
        width = proxy.size.width
        height = proxy.size.height
        if #available(iOS 27.1, *) {
            // Flach aufgeklappt meldet das System den Falz als inaktiv; die Spalten treffen sich dort
            // trotzdem (Design Spec § 8).
            let size = proxy.size
            fold = proxy.reservedRegions(kind: .division, options: .includeInactive).lazy.compactMap { region in
                let frame = region.frame
                if frame.height > frame.width {
                    guard frame.midX > 0, frame.midX < size.width else { return nil }
                    return Fold(axis: .vertical, position: frame.midX, thickness: frame.width, isActive: region.isActive)
                }
                guard frame.midY > 0, frame.midY < size.height else { return nil }
                return Fold(axis: .horizontal, position: frame.midY, thickness: frame.height, isActive: region.isActive)
            }.first
        } else {
            fold = nil
        }
    }
}
