import SwiftUI

/// Zeile mit Titel, Wert und Stepper in einer `InsetGroup`, z. B. „Pro Tag nachholen · 5“ oder „Jahre · 1“
/// beim Nachholen – `stepRow()` im Prototyp (`.row` mit `.row-value` und `.stepper`).
///
/// Der Wert steht in Sekundärfarbe mit Ziffern gleicher Breite direkt vor dem Stepper.
public struct StepperRow: View {
    private let title: String
    private let value: String
    private let stepper: StepperPill

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - title: Titel der Zeile; zugleich der VoiceOver-Text des Steppers.
    ///   - value: der Wert, fertig geschrieben, z. B. „5“.
    public init(
        _ title: String, value: String,
        canDecrement: Bool, canIncrement: Bool,
        onDecrement: @escaping () -> Void, onIncrement: @escaping () -> Void
    ) {
        self.title = title
        self.value = value
        stepper = StepperPill(
            title, canDecrement: canDecrement, canIncrement: canIncrement,
            onDecrement: onDecrement, onIncrement: onIncrement
        )
    }

    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Ab den AX-Größen untereinander, damit Titel und Zahl nicht mitten im Wort umbrechen (Phase 11).
                VStack(alignment: .leading, spacing: GroupRowMetrics.gap) {
                    VStack(alignment: .leading, spacing: GroupRowMetrics.detailGap) {
                        titleText
                            .fixedSize(horizontal: false, vertical: true)
                        valueText
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    stepper
                }
            } else {
                HStack(spacing: GroupRowMetrics.gap) {
                    HStack(spacing: GroupRowMetrics.gap) {
                        titleText
                            .frame(maxWidth: .infinity, alignment: .leading)
                        valueText
                            .multilineTextAlignment(.trailing)
                    }
                    // Titel und Wert sind für VoiceOver eine Angabe: „Jahre, 1“.
                    .accessibilityElement(children: .combine)
                    stepper
                }
            }
        }
        .groupRowPadding()
    }

    private var titleText: some View {
        Text(hyphenating: title)
            .textStyle(.body, lineHeight: GroupRowMetrics.lineHeight)
            .foregroundStyle(Palette.label)
    }

    private var valueText: some View {
        Text(value)
            .monospacedDigit()
            .textStyle(.body, lineHeight: GroupRowMetrics.lineHeight)
            .foregroundStyle(Palette.textSecondary)
    }
}

/// Zeile mit Titel, Zusatz und dem Schalter des Systems in einer `InsetGroup`, z. B. „Witr einbeziehen“
/// beim Nachholen – `rowSwitch()` im Prototyp.
public struct SwitchRow: View {
    private let title: String
    private let detail: String?
    @Binding private var isOn: Bool

    /// - Parameter detail: Zusatz unter dem Titel in Sekundärfarbe (`.row-sub`).
    public init(_ title: String, detail: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.detail = detail
        _isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: GroupRowMetrics.detailGap) {
                Text(hyphenating: title)
                    .textStyle(.body, lineHeight: GroupRowMetrics.lineHeight)
                    .foregroundStyle(Palette.label)
                if let detail {
                    Text(hyphenating: detail)
                        .textStyle(.footnote, lineHeight: GroupRowMetrics.lineHeight)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toggleStyle(.switch)
        .tint(Palette.accent)
        .groupRowPadding()
    }
}

/// Zeile als Knopf in Akzentfarbe mit Symbol am Ende, z. B. „Als offen übernehmen ✓“ beim Nachholen –
/// `rowLink()` im Prototyp. Gedrückt liegt `--fill-4` unter der Zeile.
public struct LinkRow: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    /// - Parameter systemImage: SF Symbol am Ende der Zeile, z. B. `checkmark`.
    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: GroupRowMetrics.gap) {
                Text(hyphenating: title)
                    .textStyle(.body, lineHeight: GroupRowMetrics.lineHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: systemImage)
                    .font(.system(size: GroupRowMetrics.linkSymbolSize, weight: GroupRowMetrics.linkSymbolWeight))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Palette.accent)
            .groupRowPadding()
            .contentShape(.rect)
        }
        .buttonStyle(GroupRowButtonStyle())
    }
}

/// Gedrückt liegt `--fill-4` unter der Zeile (`button.row:active`).
private struct GroupRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Palette.fillQuaternary : .clear)
    }
}

extension View {

    /// Innenabstand und Mindesthöhe einer Zeile (`.row`: `padding: 11px 16px; min-height: 44px`).
    func groupRowPadding() -> some View {
        padding(GroupRowMetrics.insets)
            .frame(maxWidth: .infinity, minHeight: Layout.minRowHeight)
    }
}

/// Maße der Zeilen (`.row`, `.row-sub`, `rowLink()`).
enum GroupRowMetrics {
    static let insets = EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
    /// Abstand zwischen Titel, Wert und Stepper (`gap: 12px`).
    static let gap: CGFloat = 12
    /// Zeilenhöhe von Titel und Zusatz (`line-height: 1.3`).
    static let lineHeight: CGFloat = 1.3
    /// Abstand zwischen Titel und Zusatz (`.row-sub`: `margin-top: 2px`).
    static let detailGap: CGFloat = 2
    /// Symbol am Ende eines Links – `ic(…, 17)`. Als Schriftgröße eines SF Symbols so gewählt, dass das
    /// Häkchen so groß erscheint wie die Zeichnung des Prototyps (rund 11 pt breit).
    static let linkSymbolSize: CGFloat = 11.8
    static let linkSymbolWeight: Font.Weight = .semibold
}
