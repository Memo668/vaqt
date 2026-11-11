import DesignSystem

/// Die drei Seiten des Gebete-Tabs, zwischen denen die Chips der oberen Leiste und das Wischen
/// wechseln – `PANES` im Prototyp.
public enum PrayersPage: String, CaseIterable, Hashable, Identifiable, Sendable {
    /// Zeiten (Home).
    case today
    case qibla
    /// Anleitung.
    case guide

    public var id: Self { self }

    /// Titel des Chips aus dem String Catalog.
    public var title: String {
        switch self {
        case .today: L10n.tabToday
        case .qibla: L10n.tabQibla
        case .guide: L10n.guideChip
        }
    }

    /// Symbol des Chips: `clock` und `safari` wie in der Design Spec; für die Anleitung die Zeichnung
    /// des Prototyps, weil es in den SF Symbols nichts für Gebet oder Moschee gibt.
    public var symbol: GlassSymbol {
        switch self {
        case .today: .system("clock")
        case .qibla: .system("safari")
        case .guide: .prayerRug
        }
    }
}
