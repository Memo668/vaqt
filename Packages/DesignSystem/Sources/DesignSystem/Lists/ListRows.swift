import SwiftUI

// Zeilen für die Liste des Systems (`List`), wie die eingerückten Gruppen des Prototyps (`group()`,
// `.row`): Titel mit Zusatz, Wert, Häkchen, Link. Die Einstellungen und das Adhan-Sheet bauen ihre Seiten
// daraus; das Stadt-Sheet hat dieselben Maße (`CitySheetMetrics`). Die Fläche, die Ecken, die Trennlinien
// und – bei `NavigationLink` – den Chevron zeichnet die Liste.

/// Titel einer Zeile mit Zusatz darunter (`.row-label`, `.row-sub`).
public struct RowTitle: View {
    private let title: String
    private let detail: String?
    private let isDisabled: Bool

    /// - Parameters:
    ///   - detail: Zusatz in Sekundärfarbe, z. B. „Automatisch für Deutschland“.
    ///   - isDisabled: Titel in der Farbe gesperrter Zeilen.
    public init(_ title: String, detail: String? = nil, isDisabled: Bool = false) {
        self.title = title
        self.detail = detail
        self.isDisabled = isDisabled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ListRowMetrics.detailGap) {
            Text(hyphenating: title)
                .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
                .foregroundStyle(isDisabled ? Palette.labelTertiary : Palette.label)
            if let detail {
                Text(hyphenating: detail)
                    .textStyle(.footnote, lineHeight: ListRowMetrics.lineHeight)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Titel, Zusatz und Wert einer Zeile – `rowNav()` und `rowValue()` im Prototyp. In einem
/// `NavigationLink` setzt die Liste den Chevron dahinter.
public struct ValueRowLabel: View {
    private let title: String
    private let detail: String?
    private let value: String?
    private let showsChevron: Bool

    /// - Parameter showsChevron: ein Chevron am Ende, wie ihn die Liste hinter einen `NavigationLink`
    ///   setzt – für Zeilen, die ein Sheet öffnen, z. B. „Stadt“.
    public init(_ title: String, detail: String? = nil, value: String?, showsChevron: Bool = false) {
        self.title = title
        self.detail = detail
        self.value = value
        self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack(spacing: ListRowMetrics.gap) {
            ValueRowLayout {
                RowTitle(title, detail: detail)
                if let value {
                    Text(value)
                        .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.system(size: ListRowMetrics.chevronSize, weight: ListRowMetrics.chevronWeight))
                    .foregroundStyle(Palette.labelTertiary)
                    .accessibilityHidden(true)
            }
        }
        // Für VoiceOver eine Angabe: „Methode, Automatisch für Deutschland, MWL“.
        .accessibilityElement(children: .combine)
    }
}

/// Titel links, Wert rechts wie die Flex-Zeile des Prototyps: Der Wert nimmt seine natürliche Breite,
/// höchstens 52 % der Zeile (`.row-value`: `flex: 0 1 auto; max-width: 52%`), und bricht erst darüber um;
/// der Titel bekommt den Rest (`.row-label`: `flex: 1 1 auto`). Ohne Wert füllt der Titel die Zeile.
struct ValueRowLayout: SwiftUI.Layout {

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let frames = self.frames(width: proposal.width, subviews: subviews)
        let width = proposal.width ?? frames.reduce(0) { max($0, $1.maxX) }
        return CGSize(width: width, height: frames.reduce(0) { max($0, $1.height) })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let frames = self.frames(width: bounds.width, subviews: subviews)
        let height = frames.reduce(0) { max($0, $1.height) }
        for (subview, frame) in zip(subviews, frames) {
            // Beide mittig in der Höhe der Zeile (`align-items: center`).
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + (height - frame.height) / 2),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    /// Breite und Höhe von Titel und Wert, ohne Lage in der Höhe.
    private func frames(width: CGFloat?, subviews: LayoutSubviews) -> [CGRect] {
        guard let title = subviews.first else { return [] }
        guard subviews.count > 1, let width else {
            let size = title.sizeThatFits(ProposedViewSize(width: width, height: nil))
            return [CGRect(origin: .zero, size: size)]
        }
        let value = subviews[1]
        let natural = value.sizeThatFits(.unspecified).width
        let valueWidth = min(natural, width * ListRowMetrics.valueMaxShare)
        let titleWidth = max(0, width - valueWidth - ListRowMetrics.gap)
        let titleSize = title.sizeThatFits(ProposedViewSize(width: titleWidth, height: nil))
        let valueSize = value.sizeThatFits(ProposedViewSize(width: valueWidth, height: nil))
        return [
            CGRect(x: 0, y: 0, width: titleWidth, height: titleSize.height),
            CGRect(x: width - valueSize.width, y: 0, width: valueSize.width, height: valueSize.height),
        ]
    }
}

/// Zeile mit Häkchen, die eine von mehreren Möglichkeiten wählt – `rowCheck()` im Prototyp
/// (`role="radio"`). Das Häkchen hat sein Feld auch, wenn es fehlt, damit die Titel bündig bleiben.
public struct CheckRow: View {
    private let title: String
    private let detail: String?
    private let isSelected: Bool
    private let action: () -> Void

    public init(_ title: String, detail: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: ListRowMetrics.gap) {
                RowTitle(title, detail: detail)
                Image(systemName: "checkmark")
                    .font(.system(size: ListRowMetrics.checkSize, weight: ListRowMetrics.checkWeight))
                    .foregroundStyle(Palette.accent)
                    .frame(width: ListRowMetrics.checkBox)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Zeile als Knopf in Akzentfarbe, mit Symbol am Ende – `rowLink()` im Prototyp, z. B. „Adhan anhören“.
/// Mit `role: .destructive` rot und ohne Symbol, z. B. „Zurücksetzen“.
public struct ListLinkRow: View {
    private let title: String
    private let systemImage: String?
    private let role: ButtonRole?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: ListRowMetrics.gap) {
                Text(hyphenating: title)
                    .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: ListRowMetrics.linkSymbolSize, weight: ListRowMetrics.linkSymbolWeight))
                        .frame(width: ListRowMetrics.linkSymbolBox)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(role == .destructive ? Palette.red : Palette.accent)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// Zeile, die eine Adresse außerhalb der App öffnet, mit ↗ in Tertiärfarbe – „Quellcode“ im Prototyp.
public struct ExternalLinkRow: View {
    private let title: String
    private let detail: String?
    private let destination: URL

    public init(_ title: String, detail: String? = nil, destination: URL) {
        self.title = title
        self.detail = detail
        self.destination = destination
    }

    public var body: some View {
        Link(destination: destination) {
            HStack(spacing: ListRowMetrics.gap) {
                RowTitle(title, detail: detail)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: ListRowMetrics.externalSymbolSize, weight: ListRowMetrics.externalSymbolWeight))
                    .foregroundStyle(Palette.labelTertiary)
                    .frame(width: ListRowMetrics.externalSymbolBox)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// Zeile mit Titel, Zusatz und dem Schalter des Systems – `rowSwitch()` im Prototyp, z. B. „Kerahat-Zeiten
/// zeigen“.
///
/// Wie im CSS bestimmt das höchste Element die Höhe der Zeile, 11 pt darüber und darunter: Mit dem
/// Schalter von iOS 26 (28 pt) ist sie 50 pt hoch. Die Liste des Systems setzt einen `Toggle` sonst nach
/// der Höhe seines Titels. Der Schalter schaltet beim Tippen auf ihn, wie in den Listen des Systems;
/// VoiceOver liest Titel und Zusatz als seinen Namen.
public struct ListSwitchRow: View {
    private let title: String
    private let detail: String?
    @Binding private var isOn: Bool

    public init(_ title: String, detail: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.detail = detail
        _isOn = isOn
    }

    public var body: some View {
        HStack(spacing: ListRowMetrics.gap) {
            RowTitle(title, detail: detail)
                .accessibilityHidden(true)
            Toggle(isOn: $isOn) {
                Text(title)
                if let detail {
                    Text(detail)
                }
            }
            .labelsHidden()
            .tint(Palette.accent)
        }
    }
}

/// Kopf einer Gruppe in Großbuchstaben (`.group-header`): 16 pt eingerückt, 7 pt über der Gruppe. Die
/// Abstände der Liste um den Kopf entfallen; den Abstand zur Gruppe davor setzt `groupedListMetrics()`.
public struct ListSectionHeader: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .textStyle(.footnote, lineHeight: ListRowMetrics.headerLineHeight)
            .textCase(.uppercase)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .listRowInsets(ListRowMetrics.headerInsets)
    }
}

/// Fußzeile einer Gruppe (`.group-footer`): 16 pt eingerückt, 7 pt unter der Gruppe.
public struct ListSectionFooter: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .textStyle(.footnote, lineHeight: ListRowMetrics.footerLineHeight)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(ListRowMetrics.footerInsets)
    }
}

extension View {

    /// Innenabstand einer Zeile der Liste (`.row`: `padding: 11px 16px`).
    public func listRowMetrics() -> some View {
        listRowInsets(ListRowMetrics.insets)
    }

    /// Eine Liste des Systems wie die Gruppen des Prototyps: Zeilen mindestens 44 pt hoch statt der 52 pt
    /// von iOS 26, 32 pt zwischen den Gruppen (`.group-wrap`: `margin-bottom: 32px`), Akzentfarbe.
    public func groupedListMetrics() -> some View {
        listStyle(.insetGrouped)
            .listSectionSpacing(ListRowMetrics.sectionSpacing)
            .environment(\.defaultMinListRowHeight, Layout.minRowHeight)
            // Kopf und Fuß sind so hoch wie ihr Text samt Abstand; die Liste gäbe ihnen sonst 28 pt.
            .environment(\.defaultMinListHeaderHeight, 0)
            .tint(Palette.accent)
    }
}

/// Maße der Zeilen (`.row`, `.row-sub`, `.row-value`, `.check`, `.group-header`, `.group-footer`).
public enum ListRowMetrics {
    /// Innenabstand einer Zeile (`padding: 11px 16px`).
    public static let insets = EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
    /// Abstand zwischen Titel, Wert, Häkchen und Symbol (`gap: 12px`).
    public static let gap: CGFloat = 12
    /// Größter Anteil des Werts an der Breite (`.row-value`: `max-width: 52%`).
    public static let valueMaxShare: CGFloat = 0.52
    /// Zeilenhöhe von Titel und Zusatz (`line-height: 1.3`) und ihr Abstand (`.row-sub`: `margin-top: 2px`).
    public static let lineHeight: CGFloat = 1.3
    public static let detailGap: CGFloat = 2
    /// Feld des Häkchens (`.check`: 20 pt, `ic('check', 18)`); als Schriftgröße eines SF Symbols so
    /// gewählt, dass es so breit erscheint wie die Zeichnung (rund 12 pt), wie im Stadt-Sheet.
    public static let checkBox: CGFloat = 20
    public static let checkSize: CGFloat = 12.5
    public static let checkWeight: Font.Weight = .semibold
    /// Symbol am Ende eines Links – `ic(…, 17)`, wie bei `LinkRow`, mittig im Feld der Zeichnung.
    public static let linkSymbolSize: CGFloat = 11.8
    public static let linkSymbolWeight: Font.Weight = .semibold
    public static let linkSymbolBox: CGFloat = 17
    /// Chevron hinter einer Zeile, die ein Sheet öffnet – so groß wie der, den die Liste hinter einen
    /// `NavigationLink` setzt.
    public static let chevronSize: CGFloat = 13
    public static let chevronWeight: Font.Weight = .semibold
    /// ↗ hinter „Quellcode“ – `ic('arrowUpRight', 16, 'chev')` in `--label-3`.
    public static let externalSymbolSize: CGFloat = 10
    public static let externalSymbolWeight: Font.Weight = .semibold
    public static let externalSymbolBox: CGFloat = 16
    /// Abstand zwischen den Gruppen (`.group-wrap`: `margin-bottom: 32px`).
    public static let sectionSpacing: CGFloat = 32
    /// Kopf (`font: 400 13px/18px`) und Fuß (`font: 400 13px/1.38`) einer Gruppe.
    public static let headerLineHeight: CGFloat = 18.0 / 13.0
    public static let footerLineHeight: CGFloat = 1.38
    /// Kopf und Fuß: 16 pt eingerückt (`margin: 0 16px 7px`, `margin: 7px 16px 0`), sonst keine Abstände
    /// der Liste.
    public static let headerInsets = EdgeInsets(top: 0, leading: 16, bottom: 7, trailing: 16)
    public static let footerInsets = EdgeInsets(top: 7, leading: 16, bottom: 0, trailing: 16)
}
