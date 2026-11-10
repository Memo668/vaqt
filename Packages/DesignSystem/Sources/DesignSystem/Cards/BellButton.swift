import PrayerCore
import SwiftUI

/// Die Glocke einer Gebetskarte: zeigt den Stand der Mitteilung und wechselt ihn beim Tippen.
///
/// Drei Stände – Ton, Lautlos, Aus – mit je eigenem Symbol. Das Tippziel ist 44 × 44 pt. Beim Wechsel
/// macht das Symbol einen kleinen Hüpfer (nicht bei „Bewegung reduzieren“) und es gibt eine leichte
/// Haptik. Den Wechsel selbst und den Toast macht die Seite. Design Spec § 3 („BellButton“), `.bell`.
public struct BellButton: View {
    private let state: BellState
    private let prayerName: String
    private let isCurrent: Bool
    private let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - prayerName: Name des Ereignisses für VoiceOver, z. B. „Fadschr“.
    ///   - isCurrent: ob die Glocke auf der Karte des laufenden Gebets sitzt; dann ist sie in Akzent.
    public init(state: BellState, prayerName: String, isCurrent: Bool = false, action: @escaping () -> Void) {
        self.state = state
        self.prayerName = prayerName
        self.isCurrent = isCurrent
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            symbol
                .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                .contentShape(.circle)
        }
        .buttonStyle(BellButtonStyle())
        .foregroundStyle(color)
        .sensoryFeedback(.selection, trigger: state)
        .accessibilityLabel(L10n.bellAria(p: prayerName, s: state.localizedName))
    }

    private var color: Color {
        if isCurrent { return Palette.accent }
        return state == .off ? Palette.labelTertiary : Palette.textSecondary
    }

    @ViewBuilder
    private var symbol: some View {
        let image = Image(systemName: state.symbolName)
            .font(.system(size: BellMetrics.symbolSize, weight: BellMetrics.symbolWeight))
        if reduceMotion {
            image
        } else {
            // `@keyframes pop`: 0 % klein und nach links gedreht, 60 % etwas zu groß, dann Ruhe.
            image.keyframeAnimator(initialValue: Pop(), trigger: state) { content, pop in
                content
                    .scaleEffect(pop.scale)
                    .rotationEffect(.degrees(pop.angle))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    MoveKeyframe(0.6)
                    CubicKeyframe(1.12, duration: BellMetrics.popDuration * 0.6)
                    CubicKeyframe(1, duration: BellMetrics.popDuration * 0.4)
                }
                KeyframeTrack(\.angle) {
                    MoveKeyframe(-14)
                    CubicKeyframe(6, duration: BellMetrics.popDuration * 0.6)
                    CubicKeyframe(0, duration: BellMetrics.popDuration * 0.4)
                }
            }
        }
    }

    private struct Pop {
        var scale: CGFloat = 1
        var angle: Double = 0
    }
}

/// Maße der Glocke (`.bell`).
enum BellMetrics {
    /// Symbol der Glocke – `ic(BELL_ICON[st], 20)`. Als Schriftgröße eines SF Symbols so gewählt, dass
    /// der Glockenkörper so groß erscheint wie in der Zeichnung des Prototyps (gut 12 pt).
    static let symbolSize: CGFloat = 13.5
    /// Strichstärke des Symbols: Der Prototyp zeichnet mit 1,5 pt.
    static let symbolWeight: Font.Weight = .semibold
    /// Dauer des Hüpfers (`animation: pop .45s`).
    static let popDuration: TimeInterval = 0.45
}

/// Beim Drücken liegt ein Kreis in `--fill-4` unter der Glocke (`.bell:active`).
private struct BellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Palette.fillQuaternary : .clear, in: .circle)
    }
}
