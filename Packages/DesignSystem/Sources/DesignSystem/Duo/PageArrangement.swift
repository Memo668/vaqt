import SwiftUI

/// Der Falz des iPhone Duo, wie ihn das System meldet (ab iOS 27.1 als „division“): ein Streifen
/// quer über den Platz der Seite. Innen quer läuft er senkrecht durch die Mitte des Bildschirms, innen
/// hoch waagerecht.
public struct Fold: Equatable, Sendable {
    public enum Axis: Equatable, Sendable {
        /// Von oben nach unten – innen quer.
        case vertical
        /// Von links nach rechts – innen hoch.
        case horizontal
    }

    public var axis: Axis
    /// Lage der Mitte des Streifens: bei einem senkrechten Falz vom führenden Rand des Platzes gemessen,
    /// bei einem waagerechten vom oberen.
    public var position: CGFloat
    /// Breite des Streifens quer zum Falz (40 pt).
    public var thickness: CGFloat
    /// Ob der Falz gerade geknickt ist – halb aufgeklappt, etwa in der Tischhaltung. Flach aufgeklappt
    /// meldet ihn das System als inaktiv.
    public var isActive: Bool

    public init(axis: Axis, position: CGFloat, thickness: CGFloat, isActive: Bool) {
        self.axis = axis
        self.position = position
        self.thickness = thickness
        self.isActive = isActive
    }
}

/// Wie eine Seite ihre beiden Teile zeigt – Design Spec § 8, Variante 5i (erste Option: zwei Spalten
/// am Falz).
///
/// Auf dem iPhone und außen auf dem iPhone Duo (compact) stehen die Teile untereinander, wie bisher.
/// Innen quer (regular) stehen sie als zwei Spalten nebeneinander, die sich am Falz treffen: die erste
/// (`.col-a` im Prototyp) vom führenden Rand bis zur Mitte des Falzes, die zweite (`.col-b`) von dort
/// bis zum anderen Rand. In RTL liegt die erste rechts; die Spalten treffen sich weiter am Falz.
///
/// Innen hoch (Spec-Frage 17, entschieden am 12.11.2026: „Alle drei“) stehen die Teile flach
/// aufgeklappt untereinander wie auf dem iPhone. In der Tischhaltung – halb aufgeklappt, der Falz
/// waagerecht – steht der erste Teil über dem Falz und der zweite darunter, jeder für sich scrollbar.
public enum PageArrangement: Equatable, Sendable {
    /// Die Teile untereinander.
    case stacked
    /// Zwei Spalten nebeneinander, gemessen vom führenden Rand des Inhalts.
    case columns(leading: CGFloat, trailing: CGFloat)
    /// Tischhaltung: zwei Teile übereinander, getrennt vom Streifen des Falzes. Die Höhen sind ohne den
    /// Streifen gemessen.
    case rows(top: CGFloat, gap: CGFloat, bottom: CGFloat)

    /// Schmaler als das wird keine Spalte; liegt der Falz näher am Rand, teilt die Mitte.
    public static let minimumColumnWidth: CGFloat = 300
    /// Niedriger als das wird kein Teil in der Tischhaltung; sonst stehen die Teile untereinander.
    public static let minimumRowHeight: CGFloat = 160

    /// Die Anordnung für den Platz, den die Seite hat.
    ///
    /// - Parameters:
    ///   - horizontalSizeClass: Größenklasse in der Breite. Nur regular teilt in Spalten.
    ///   - size: Platz des Inhalts, ohne die Leisten und Ränder des Systems.
    ///   - fold: der Falz im Platz des Inhalts; `nil`, wenn das System keinen meldet. Dann teilen
    ///     Spalten in der Mitte.
    public static func resolve(
        horizontalSizeClass: UserInterfaceSizeClass?, size: CGSize, fold: Fold?
    ) -> PageArrangement {
        if let fold, fold.axis == .horizontal {
            // Innen hoch: flach wie auf dem iPhone, halb aufgeklappt (Tischhaltung) über und unter dem Falz.
            guard fold.isActive else { return .stacked }
            let top = fold.position - fold.thickness / 2
            let bottom = size.height - fold.position - fold.thickness / 2
            guard top >= minimumRowHeight, bottom >= minimumRowHeight else { return .stacked }
            return .rows(top: top, gap: fold.thickness, bottom: bottom)
        }
        guard horizontalSizeClass == .regular, size.width >= 2 * minimumColumnWidth else { return .stacked }
        let usable = minimumColumnWidth...(size.width - minimumColumnWidth)
        let leading = fold.flatMap { usable.contains($0.position) ? $0.position : nil } ?? size.width / 2
        return .columns(leading: leading, trailing: size.width - leading)
    }

    /// Ob die Seite in Spalten steht.
    public var isColumns: Bool {
        if case .columns = self { true } else { false }
    }

    /// Ob die Seite ihre Teile nebeneinander oder getrennt übereinander zeigt – nicht wie auf dem iPhone.
    public var isSplit: Bool {
        self != .stacked
    }
}

/// Die mittige Spalte für Einstellungen und ihre Unterseiten innen auf dem iPhone Duo – Design Spec
/// § 8 („Settings content as a centred 600 pt column“, `.page:not(.root-page) .scroll` im Prototyp).
public enum CenteredColumn {
    /// Breite der Spalte innen (`600px`).
    public static let width: CGFloat = 600
    /// Abstand eines Sheets innen zum oberen und unteren Rand (`.sheet`: `top: 36px; bottom: 36px`).
    public static let sheetMargin: CGFloat = 36

    /// Rand links und rechts, damit der Inhalt als mittige Spalte steht. In compact und wenn die Seite
    /// schmaler ist als die Spalte, bleibt kein Rand: Die Seite steht wie auf dem iPhone.
    public static func margin(horizontalSizeClass: UserInterfaceSizeClass?, width: CGFloat) -> CGFloat {
        guard horizontalSizeClass == .regular else { return 0 }
        return max(0, (width - Self.width) / 2)
    }
}

extension View {

    /// Innen auf dem iPhone Duo (regular) als mittige 600-pt-Spalte: Der sichere Bereich der Liste oder
    /// Scroll-Ansicht darunter wächst links und rechts, bis der Inhalt 600 pt breit ist. In compact
    /// bleibt alles, wie es ist – auch die Ränder des Systems.
    public func centeredColumn() -> some View {
        modifier(CenteredColumnModifier())
    }

    /// Innen auf dem iPhone Duo (regular) ein Sheet als mittige Karte, 600 pt breit – Design Spec § 8
    /// („Sheet as a centred 600 pt card“). Gehört an den Inhalt des Sheets; `isRegular` ist die
    /// Größenklasse der Ansicht, die das Sheet zeigt. In compact zeigt iOS das Sheet wie auf dem iPhone.
    public func centeredSheetCard(isRegular: Bool) -> some View {
        modifier(CenteredSheetModifier(isRegular: isRegular))
    }
}

private struct CenteredColumnModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        let margin = CenteredColumn.margin(horizontalSizeClass: sizeClass, width: width)
        Group {
            if margin > 0 {
                // Als Rand des sicheren Bereichs, damit er zum Rand der senkrechten Leiste hinzukommt;
                // die Liste reicht sonst unter die Leiste.
                content.safeAreaPadding(.horizontal, margin)
            } else {
                content
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}

private struct CenteredSheetModifier: ViewModifier {
    let isRegular: Bool

    func body(content: Content) -> some View {
        if isRegular {
            content.presentationSizing(CenteredCardSizing())
        } else {
            content
        }
    }
}

/// Die Größe eines Sheets als mittige Karte: 600 pt breit und oben und unten 36 pt vom Rand
/// (`.sheet`: `top: 36px; bottom: 36px; width: 600px`). Die Höhe, von der die Ränder abgehen, ist die
/// eines Formular-Sheets des Systems – innen auf dem iPhone Duo der ganze Bildschirm.
private struct CenteredCardSizing: PresentationSizing {
    func proposedSize(for root: PresentationSizingRoot, context: PresentationSizingContext) -> ProposedViewSize {
        let form: FormPresentationSizing = .form
        let proposal = form.proposedSize(for: root, context: context)
        return ProposedViewSize(
            width: CenteredColumn.width,
            height: proposal.height.map { max(0, $0 - 2 * CenteredColumn.sheetMargin) }
        )
    }
}
