import SwiftUI

/// Der Hauptknopf: eine Kapsel in Akzent, 50 pt hoch, die Breite füllend, Schrift 17 pt halbfett, davor
/// auf Wunsch ein Symbol – `.btn.btn-primary` im Prototyp. Gesperrt ist er blasser (`.btn:disabled`),
/// gedrückt leicht verkleinert (`.btn:active`).
public struct PrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: PrimaryButtonMetrics.gap) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: PrimaryButtonMetrics.symbolSize, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(TypeScale.body.font(weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, PrimaryButtonMetrics.paddingX)
            .frame(maxWidth: .infinity, minHeight: PrimaryButtonMetrics.height)
            .contentShape(.capsule)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

/// Akzentfläche, Schrift in `--on-accent`; gesperrt zu 40 %.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.onAccent)
            .background(Palette.accent, in: .capsule)
            .opacity(isEnabled ? 1 : PrimaryButtonMetrics.disabledOpacity)
            .scaleEffect(configuration.isPressed && !reduceMotion ? PrimaryButtonMetrics.pressedScale : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Maße des Hauptknopfs (`.btn`: `min-height: 50px; padding: 0 20px; gap: 8px`).
enum PrimaryButtonMetrics {
    static let height: CGFloat = 50
    static let paddingX: CGFloat = 20
    static let gap: CGFloat = 8
    /// `ic('check', 18)`
    static let symbolSize: CGFloat = 15
    static let disabledOpacity = 0.4
    static let pressedScale: CGFloat = 0.97
}
