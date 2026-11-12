import CoreGraphics
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

/// Maße, die für jede Seite der drei Tabs gelten (`.root-page .scroll`, `.tab-spacer`).
enum PageMetrics {
    /// Abstand zwischen oberer Leiste und Inhalt (`.root-page .scroll`: 8 pt unter der Leiste).
    static let contentTop: CGFloat = 8
    /// Abstand oben, wenn die Leisten senkrecht am Rand stehen (iPhone Duo): Oben gibt es dann keine
    /// Leiste (`.screen[data-dev^="duo"] .root-page .scroll`: `padding-top: 14px`).
    static let contentTopWithVerticalBar: CGFloat = 14
    /// Platz unter dem letzten Element, über der Tableiste: `.tab-spacer` ist 112 pt hoch, davon liegen
    /// 84 pt hinter der Tableiste (22 pt Rand + 62 pt Leiste). Auf dem iPhone Duo ohne Tableiste unten
    /// ebenso (`.tab-spacer`: `height: 28px`).
    static let contentBottom: CGFloat = 28
    /// Abstand unter dem oberen Teil der Tischhaltung, über dem Falz.
    static let rowGap: CGFloat = 8

    /// Abstand oben über dem Inhalt, gemessen vom sicheren Bereich des Systems: unter der oberen Leiste
    /// 8 pt. Stehen die Leisten senkrecht, beginnt der Inhalt 14 pt unter dem oberen Rand – liegt der
    /// sichere Bereich schon tiefer (innen auf dem iPhone Duo: 24 pt), gleich an seinem Rand.
    static func contentTop(hasVerticalBar: Bool, safeAreaTop: CGFloat) -> CGFloat {
        hasVerticalBar ? max(0, contentTopWithVerticalBar - safeAreaTop) : contentTop
    }
}
