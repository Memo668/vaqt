import SwiftUI

/// Kapsel-Knopf mit Symbol und Titel auf grauer Fläche – in der Anleitung „Qibla öffnen“ und „Zum
/// aktuellen Gebet“, beim Vers des Tages Teilen und Kopieren. `.pill-btn` im Prototyp.
///
/// So breit wie sein Inhalt, mindestens 44 pt hoch. Gedrückt wird die Fläche dunkler (`:active`).
public struct PillButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    /// - Parameter systemImage: SF Symbol vor dem Titel, z. B. `safari`.
    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: PillButtonMetrics.gap) {
                Image(systemName: systemImage)
                    .font(.system(size: PillButtonMetrics.symbolSize, weight: PillButtonMetrics.symbolWeight))
                    .frame(width: PillButtonMetrics.symbolBox, height: PillButtonMetrics.symbolBox)
                    .accessibilityHidden(true)
                Text(title)
                    .font(TypeScale.subheadline.font(weight: .semibold))
            }
        }
        .buttonStyle(PillButtonStyle())
    }
}

/// Der Stil von `PillButton`: Kapsel in `--fill-3`, gedrückt `--fill-2`, Schrift in Schriftfarbe.
public struct PillButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.label)
            .padding(.horizontal, PillButtonMetrics.paddingX)
            .frame(minHeight: Layout.minTapTarget)
            .background(configuration.isPressed ? Palette.fillSecondary : Palette.fillTertiary, in: .capsule)
            .contentShape(.capsule)
    }
}

/// Maße des Kapsel-Knopfs (`.pill-btn`: `gap: 6px; min-height: 44px; padding: 0 16px; font: 600 15px/1`).
enum PillButtonMetrics {
    static let gap: CGFloat = 6
    static let paddingX: CGFloat = 16
    /// Symbol vor dem Titel – `ic(…, 18)`. Als Schriftgröße eines SF Symbols so gewählt, dass es so groß
    /// erscheint wie die Zeichnung des Prototyps.
    static let symbolBox: CGFloat = 18
    static let symbolSize: CGFloat = 13
    static let symbolWeight: Font.Weight = .medium
}
