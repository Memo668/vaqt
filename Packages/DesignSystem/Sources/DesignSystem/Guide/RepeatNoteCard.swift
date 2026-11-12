import SwiftUI

/// Gestrichelte Karte im Ablauf der Anleitung: „Für jede weitere Rakʿa wiederholst du die Schritte 2–5.“
/// Sie steht nach der Niederwerfung. `.repeat` im Prototyp.
public struct RepeatNoteCard: View {
    private let text: String
    private let systemImage: String

    /// - Parameter systemImage: SF Symbol vor dem Text.
    public init(_ text: String, systemImage: String) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: RepeatNoteMetrics.gap) {
            Image(systemName: systemImage)
                .font(.system(size: RepeatNoteMetrics.symbolSize, weight: RepeatNoteMetrics.symbolWeight))
                .frame(width: RepeatNoteMetrics.symbolBox, height: RepeatNoteMetrics.symbolBox)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.footnote, lineHeight: RepeatNoteMetrics.lineHeight)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Palette.textSecondary)
        .padding(.horizontal, RepeatNoteMetrics.paddingX)
        .padding(.vertical, RepeatNoteMetrics.paddingY)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.row, style: .continuous)
                .strokeBorder(
                    Palette.separator,
                    style: StrokeStyle(lineWidth: RepeatNoteMetrics.borderWidth, dash: RepeatNoteMetrics.dash)
                )
        }
        .accessibilityElement(children: .combine)
    }
}

/// Maße der Karte (`.repeat`: `gap: 10px; padding: 11px 16px; border: 1.5px dashed var(--separator)`;
/// Footnote mit der Zeilenhöhe 1,3 von `.screen`).
enum RepeatNoteMetrics {
    static let gap: CGFloat = 10
    static let paddingX: CGFloat = 16
    static let paddingY: CGFloat = 11
    static let lineHeight: CGFloat = 1.3
    static let borderWidth: CGFloat = 1.5
    /// Strich und Lücke der gestrichelten Linie: je das Dreifache der Linienstärke, wie Browser `dashed`
    /// zeichnen.
    static let dash: [CGFloat] = [4.5, 4.5]
    /// Symbol – `ic('qada', 18)`.
    static let symbolBox: CGFloat = 18
    static let symbolSize: CGFloat = 13
    static let symbolWeight: Font.Weight = .medium
}
