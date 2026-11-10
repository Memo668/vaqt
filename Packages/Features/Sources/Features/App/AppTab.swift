import DesignSystem

/// Die drei Tabs der schwebenden Leiste unten: Gebete · Verse · Nachholen.
public enum AppTab: String, CaseIterable, Hashable, Sendable {
    case prayers
    case verses
    case qada

    /// Titel aus dem String Catalog.
    public var title: String {
        switch self {
        case .prayers: L10n.navPrayers
        case .verses: L10n.navVerses
        case .qada: L10n.navQada
        }
    }

    /// SF Symbol laut Design Spec (Komponente „TabBar“).
    public var systemImage: String {
        switch self {
        case .prayers: "moon.stars"
        case .verses: "book"
        case .qada: "clock.arrow.circlepath"
        }
    }
}
