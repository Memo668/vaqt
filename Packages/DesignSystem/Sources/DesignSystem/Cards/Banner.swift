import SwiftUI

/// Banner: ein Hinweis mit einer Aktion, z. B. „Standortzugriff aus – Stadt manuell gewählt“ mit
/// „Ändern“ auf der Zeiten-Seite.
///
/// Symbol · Text · Text-Button. Der Text bricht um, der Button bleibt in einer Zeile; sein Tippziel ist
/// 44 pt hoch. Design Spec § 3 („Banner / note / hint pill“), `.banner` im Prototyp.
public struct Banner: View {
    private let text: String
    private let systemImage: String
    private let actionTitle: String
    private let action: () -> Void

    /// - Parameters:
    ///   - systemImage: SF Symbol vor dem Text, z. B. `location.slash`.
    ///   - actionTitle: Titel des Buttons, z. B. `L10n.change`.
    public init(_ text: String, systemImage: String, actionTitle: String, action: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(spacing: BannerMetrics.gap) {
            Image(systemName: systemImage)
                .font(.system(size: BannerMetrics.symbolSize, weight: BannerMetrics.symbolWeight))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: BannerMetrics.symbolBox)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.subheadline, lineHeight: BannerMetrics.lineHeight)
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: action) {
                Text(actionTitle)
                    .font(TypeScale.subheadline.font(weight: .semibold))
                    .lineLimit(1)
                    .padding(.horizontal, BannerMetrics.buttonPaddingX)
                    .frame(minHeight: Layout.minTapTarget)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
        }
        .padding(.leading, BannerMetrics.leading)
        .padding(.trailing, BannerMetrics.trailing)
        .padding(.vertical, BannerMetrics.paddingY)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.group, style: .continuous))
    }
}

/// Maße des Banners (`.banner` und sein `.text-btn`).
enum BannerMetrics {
    /// Abstand zwischen Symbol, Text und Button (`gap: 10px`).
    static let gap: CGFloat = 10
    /// Innenabstand (`padding: 4px 6px 4px 14px`), in Leserichtung.
    static let leading: CGFloat = 14
    static let trailing: CGFloat = 6
    static let paddingY: CGFloat = 4
    /// Zeilenhöhe des Textes (`line-height: 1.3`).
    static let lineHeight: CGFloat = 1.3
    /// Feld des Symbols – `ic('locSlash', 18)`.
    static let symbolBox: CGFloat = 18
    /// Das Symbol als Schriftgröße eines SF Symbols, so breit wie die Zeichnung des Prototyps.
    static let symbolSize: CGFloat = 13.5
    static let symbolWeight: Font.Weight = .medium
    /// Innenabstand des Text-Buttons (`padding: 0 12px`).
    static let buttonPaddingX: CGFloat = 12
}
