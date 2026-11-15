import PrayerCore
import SwiftUI

/// Die Formel eines Schritts: arabisch, von rechts nach links und rechtsbündig, darunter die Umschrift
/// kursiv, von links nach rechts. `.formula` im Prototyp.
///
/// Das Arabische steht seit v0.8 in Amiri (Spec § 9.7). Es wächst mit Dynamic Type und ist für VoiceOver
/// als Arabisch markiert, damit es mit arabischer Stimme gelesen wird (`lang="ar"`).
public struct FormulaBox: View {
    private let formula: GuideStep.Formula

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    public init(_ formula: GuideStep.Formula) {
        self.formula = formula
    }

    public var body: some View {
        let arabicSize = FormulaMetrics.arabicSize * max(typeScale, 0)
        VStack(alignment: .leading, spacing: 0) {
            Text(arabic)
                .arabicFont(.amiri, size: arabicSize, lineHeight: FormulaMetrics.arabicLineHeight)
                .foregroundStyle(Palette.label)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Im Arabischen ist der Anfang rechts: Absatz von rechts nach links, rechtsbündig.
                .environment(\.layoutDirection, .rightToLeft)
            Text(formula.transliteration)
                .textStyle(.subheadline, lineHeight: FormulaMetrics.transliterationLineHeight)
                .italic()
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, FormulaMetrics.paddingX)
        .padding(.vertical, FormulaMetrics.paddingY)
        .background(Palette.fillQuaternary, in: .rect(cornerRadius: FormulaMetrics.radius, style: .continuous))
    }

    /// Der arabische Text mit seiner Sprache – für den Satz und für VoiceOver.
    private var arabic: AttributedString {
        var text = AttributedString(formula.arabic)
        text.languageIdentifier = FormulaMetrics.arabicLanguage
        return text
    }
}

/// Maße der Formel (`.formula`: `padding: 8px 11px; border-radius: 12px`; `.ar` seit v0.8: `font: 400
/// calc(23px*var(--ts))/1.85 "Amiri"`; `.lat`: Subheadline, Zeilenhöhe 1,3 von `.screen`).
enum FormulaMetrics {
    static let paddingX: CGFloat = 11
    static let paddingY: CGFloat = 8
    static let radius: CGFloat = 12
    /// Abstand zur Anweisung darüber (`margin-top: 9px`).
    static let top: CGFloat = 9
    static let arabicSize: CGFloat = 23
    static let arabicLineHeight: CGFloat = 1.85
    static let transliterationLineHeight: CGFloat = 1.3
    static let arabicLanguage = "ar"
}
