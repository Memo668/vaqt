import SwiftUI

/// Stepper: zwei Tasten „−“ und „+“ in einer gemeinsamen Fläche, 94 × 32 pt.
///
/// Anders als der `Stepper` des Systems hat jede Taste ihren eigenen VoiceOver-Text – beim Nachholen
/// heißt „−“ „Ein Fadschr nachgeholt“ und „+“ „Ein Fadschr mehr offen“. Den Wert zeigt die Zeile daneben.
/// Das Tippziel jeder Taste ist 44 pt hoch. `.stepper` und `qStepper()` im Prototyp.
public struct StepperPill: View {
    let label: String
    let decrementLabel: String
    let incrementLabel: String
    let canDecrement: Bool
    let canIncrement: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    /// - Parameters:
    ///   - label: wofür der Stepper steht, z. B. „Pro Tag nachholen“ – der VoiceOver-Text der Gruppe.
    ///   - decrementLabel: VoiceOver-Text von „−“; ohne Angabe „… weniger“ (`stepLess`).
    ///   - incrementLabel: VoiceOver-Text von „+“; ohne Angabe „… mehr“ (`stepMore`).
    public init(
        _ label: String,
        canDecrement: Bool = true, canIncrement: Bool = true,
        decrementLabel: String? = nil, incrementLabel: String? = nil,
        onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void
    ) {
        self.label = label
        self.decrementLabel = decrementLabel ?? L10n.stepLess(x: label)
        self.incrementLabel = incrementLabel ?? L10n.stepMore(x: label)
        self.canDecrement = canDecrement
        self.canIncrement = canIncrement
        self.onDecrement = onDecrement
        self.onIncrement = onIncrement
    }

    /// Stepper für einen Zahlenwert mit Grenzen: An der unteren Grenze ist „−“ gesperrt, an der oberen „+“.
    public init(
        _ label: String, value: Binding<Int>, in range: ClosedRange<Int>,
        decrementLabel: String? = nil, incrementLabel: String? = nil
    ) {
        self.init(
            label,
            canDecrement: value.wrappedValue > range.lowerBound,
            canIncrement: value.wrappedValue < range.upperBound,
            decrementLabel: decrementLabel, incrementLabel: incrementLabel,
            onDecrement: { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) },
            onIncrement: { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) }
        )
    }

    public var body: some View {
        HStack(spacing: 0) {
            key("minus", label: decrementLabel, isEnabled: canDecrement, action: onDecrement)
            key("plus", label: incrementLabel, isEnabled: canIncrement, action: onIncrement)
                // Trennstrich am Anfang der zweiten Taste, oben und unten 8 pt kürzer.
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Palette.separator)
                        .frame(width: 1, height: StepperMetrics.height - 2 * StepperMetrics.dividerInset)
                }
        }
        .background(Palette.fillTertiary, in: .rect(cornerRadius: StepperMetrics.radius, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func key(_ systemImage: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: StepperMetrics.symbolSize))
                .frame(width: StepperMetrics.keyWidth, height: StepperMetrics.height)
                .contentShape(TapArea())
        }
        .buttonStyle(StepperKeyStyle())
        .foregroundStyle(isEnabled ? Palette.label : Palette.labelTertiary)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// Maße des Steppers (`.stepper`).
enum StepperMetrics {
    static let height: CGFloat = 32
    static let keyWidth: CGFloat = 47
    static let radius: CGFloat = 8
    static let dividerInset: CGFloat = 8
    /// Symbole der Tasten – `ic('minus', 18)`, `ic('plus', 18)`. Als Schriftgröße eines SF Symbols so
    /// gewählt, dass die Striche so lang erscheinen wie im Prototyp (gut 10 pt).
    static let symbolSize: CGFloat = 12.5
}

/// Das Tippziel einer Taste reicht oben und unten 6 pt über die Fläche hinaus – 44 pt Höhe
/// (`.stepper button::after { inset: -6px 0 }`).
private struct TapArea: Shape {
    func path(in rect: CGRect) -> Path {
        Path(rect.insetBy(dx: 0, dy: -(Layout.minTapTarget - StepperMetrics.height) / 2))
    }
}

/// Beim Drücken liegt `--fill-2` unter der Taste (`.stepper button:active`).
private struct StepperKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Palette.fillSecondary : .clear,
                in: .rect(cornerRadius: StepperMetrics.radius, style: .continuous)
            )
    }
}
