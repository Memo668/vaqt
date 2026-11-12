import SwiftUI

/// Eine Gruppe von Zeilen auf einer Fläche in Kartenfarbe, mit Kopf in Großbuchstaben darüber und
/// Fußzeile darunter – die eingerückte Liste des Prototyps (`group()`, `.group-wrap`).
///
/// Zwischen den Zeilen liegt eine Haarlinie, die 16 pt nach dem Anfang beginnt und bis zum Ende läuft.
/// Die Gruppe füllt die Breite; den Seitenrand und den Abstand zum Nächsten (`InsetGroup.spacingBelow`)
/// setzt die Seite. Beim Nachholen tragen Gruppen den Plan, den Rechner und „Als offen übernehmen“.
public struct InsetGroup<Content: View>: View {
    private let header: String?
    private let footer: String?
    private let content: Content

    @Environment(\.displayScale) private var displayScale

    /// Abstand unter der Gruppe samt Fußzeile (`.group-wrap`: `margin-bottom: 32px`).
    public static var spacingBelow: CGFloat { InsetGroupMetrics.spacingBelow }

    /// - Parameters:
    ///   - header: Kopf über der Gruppe; erscheint in Großbuchstaben.
    ///   - footer: Fußzeile unter der Gruppe.
    ///   - content: die Zeilen, z. B. `StepperRow`, `SwitchRow`, `LinkRow`.
    public init(header: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header {
                // `letter-spacing: -.08px` ist die Laufweite, die das System bei 13 pt ohnehin setzt.
                Text(header)
                    .textStyle(.footnote, lineHeight: InsetGroupMetrics.headerLineHeight)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, InsetGroupMetrics.textInset)
                    .padding(.bottom, InsetGroupMetrics.headerGap)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows) { row in
                        row.overlay(alignment: .top) {
                            if row.id != rows.first?.id {
                                separator
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Palette.backgroundCell)
            .clipShape(.rect(cornerRadius: Radius.group, style: .continuous))
            if let footer {
                Text(footer)
                    .textStyle(.footnote, lineHeight: InsetGroupMetrics.footerLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, InsetGroupMetrics.textInset)
                    .padding(.top, InsetGroupMetrics.footerGap)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// Die Linie über jeder Zeile außer der ersten: eine Haarlinie – im Prototyp `.5px` bei doppelter
    /// Auflösung, also ein Pixel des Bildschirms.
    private var separator: some View {
        Rectangle()
            .fill(Palette.separator)
            .frame(height: 1 / max(displayScale, 1))
            .padding(.leading, InsetGroupMetrics.separatorInset)
            .accessibilityHidden(true)
    }
}

/// Maße der Gruppe (`.group-header`: `font: 400 13px/18px; margin: 0 16px 7px`; `.group-footer`:
/// `font: 400 13px/1.38; margin: 7px 16px 0`; Trennlinie ab 16 pt).
enum InsetGroupMetrics {
    static let spacingBelow: CGFloat = Spacing.x8
    static let textInset: CGFloat = 16
    static let headerLineHeight: CGFloat = 18.0 / 13.0
    static let headerGap: CGFloat = 7
    static let footerLineHeight: CGFloat = 1.38
    static let footerGap: CGFloat = 7
    static let separatorInset: CGFloat = 16
}
