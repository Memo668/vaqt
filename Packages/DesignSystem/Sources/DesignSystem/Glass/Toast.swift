import SwiftUI

/// HUD-Toast: eine kurze Rückmeldung in einer Glass-Kapsel, z. B. „Fadschr: Lautlos“ nach dem Tippen
/// auf eine Glocke.
///
/// Der Baustein ist nur die Kapsel. Wo sie steht (über der Tableiste, `Layout.toastBottom`) und wie
/// lange (`Layout.toastDuration`), regelt die App. Design Spec § 3 („HUD toast“), `.toast` im Prototyp.
public struct Toast: View {
    private let text: String
    private let systemImage: String?

    /// - Parameters:
    ///   - systemImage: SF Symbol vor dem Text, z. B. das der Glocke; ohne Angabe nur Text.
    public init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: ToastMetrics.gap) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: ToastMetrics.symbolSize, weight: ToastMetrics.symbolWeight))
                    .frame(minWidth: ToastMetrics.symbolBox)
                    .accessibilityHidden(true)
            }
            Text(text)
                .textStyle(.subheadline, weight: .semibold, lineHeight: ToastMetrics.lineHeight)
                .lineLimit(1)
        }
        .foregroundStyle(Palette.label)
        .padding(.horizontal, ToastMetrics.paddingX)
        .padding(.vertical, ToastMetrics.paddingY)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

/// Maße des Toasts (`.toast`).
enum ToastMetrics {
    /// Abstand zwischen Symbol und Text (`gap: 8px`).
    static let gap: CGFloat = 8
    /// Innenabstand (`padding: 9px 15px`).
    static let paddingX: CGFloat = 15
    static let paddingY: CGFloat = 9
    /// Zeilenhöhe des Textes (`font: 600 …/1.2`).
    static let lineHeight: CGFloat = 1.2
    /// Feld des Symbols – `ic(icon, 17)`.
    static let symbolBox: CGFloat = 17
    /// Das Symbol als Schriftgröße eines SF Symbols, im selben Verhältnis wie die Glocke der
    /// Gebetskarte (Feld 20 pt, Schrift 13,5 pt).
    static let symbolSize: CGFloat = 11.5
    static let symbolWeight: Font.Weight = .semibold
}
