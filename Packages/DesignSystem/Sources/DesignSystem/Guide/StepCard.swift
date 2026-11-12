import SwiftUI

/// Eine Karte der Anleitung: links ein Bild, rechts Titel und kurze Anweisung, darunter, was zum Schritt
/// gehört – die Formel oder der Knopf „Qibla öffnen“. `.step` im Prototyp.
///
/// Unter „Vorher“ ist das Bild ein Symbol im Kreis (`SymbolBadge.step`), im Ablauf die Haltungsfigur
/// (`PoseFigure`) und der Titel trägt die Nummer des Schritts. Der Titel ist für VoiceOver eine
/// Überschrift (`<h3>`).
public struct StepCard<Leading: View, Extra: View>: View {
    private let number: Int?
    private let title: String
    private let text: String
    private let leading: Leading
    private let extra: Extra

    /// - Parameters:
    ///   - number: Nummer des Schritts im Ablauf; `nil` unter „Vorher“.
    ///   - leading: das Bild links.
    ///   - extra: was unter der Anweisung steht; seinen Abstand nach oben setzt es selbst.
    public init(
        number: Int? = nil, title: String, text: String,
        @ViewBuilder leading: () -> Leading, @ViewBuilder extra: () -> Extra = { EmptyView() }
    ) {
        self.number = number
        self.title = title
        self.text = text
        self.leading = leading()
        self.extra = extra()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: StepCardMetrics.gap) {
            leading
            VStack(alignment: .leading, spacing: 0) {
                // Die Laufweite steckt im Text selbst: Eine Laufweite für die ganze Zeile hebt die der
                // Nummer auf.
                Text(heading)
                    .textStyle(.headline, lineHeight: StepCardMetrics.titleLineHeight)
                    .foregroundStyle(Palette.label)
                    .padding(.bottom, StepCardMetrics.titleBottom)
                    // Für VoiceOver mit Leerzeichen: „1 Takbīr“ statt „1Takbīr“.
                    .accessibilityLabel(number.map { "\($0) \(title)" } ?? title)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h3)
                Text(text)
                    .textStyle(.subheadline, lineHeight: StepCardMetrics.textLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                extra
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, StepCardMetrics.paddingX)
        .padding(.vertical, StepCardMetrics.paddingY)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.row, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    /// Titel mit Nummer davor: Die Nummer steht in Sekundärfarbe und medium, 6 pt vor dem Titel
    /// (`.n`: `margin-inline-end: 6px`). Bricht der Titel um, beginnt die zweite Zeile wie im Prototyp
    /// am Rand, nicht unter dem Titel.
    private var heading: AttributedString {
        var heading = AttributedString(title)
        heading.tracking = StepCardMetrics.titleTracking
        guard let number else { return heading }
        var prefix = AttributedString(String(number))
        prefix.foregroundColor = Palette.textSecondary
        prefix.font = TypeScale.headline.font(weight: .medium).leading(.tight)
        // Laufweite steht hinter jedem Zeichen; bei einer einstelligen Nummer ist das genau der Abstand.
        prefix.tracking = StepCardMetrics.numberGap
        return prefix + heading
    }
}

/// Maße der Karte (`.step`: `gap: 14px; padding: 14px 16px; border-radius: var(--r-row)`; `.step h3`:
/// `margin: 0 0 3px; font: 600 …/1.3; letter-spacing: -.3px`; `.step p`: Subheadline, Zeilenhöhe 1,4).
enum StepCardMetrics {
    static let gap: CGFloat = 14
    static let paddingX: CGFloat = 16
    static let paddingY: CGFloat = 14
    static let titleLineHeight: CGFloat = 1.3
    static let titleBottom: CGFloat = 3
    /// `letter-spacing: -.3px` statt der −0,41 pt, die das System bei 17 pt setzt.
    static let titleTracking: CGFloat = 0.11
    static let textLineHeight: CGFloat = 1.4
    /// Abstand der Nummer zum Titel.
    static let numberGap: CGFloat = 6
    /// Abstand des Knopfs „Qibla öffnen“ zur Anweisung (`.step .pill-btn`: `margin-top: 10px`).
    static let buttonTop: CGFloat = 10
}
