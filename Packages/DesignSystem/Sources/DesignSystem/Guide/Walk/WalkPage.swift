import PrayerCore
import SwiftUI

/// Eine Seite des Durchlaufs, mittig gesetzt (`.walk-body` in `walkHTML()`):
///
/// - **Start:** Kachel mit dem Symbol des Gebets, „Dhuhr · 4 Rakʿas“, Waschung, Qibla und Absicht, die
///   Rakʿas als Punkte (laut gefüllt, leise getönt).
/// - **Schritt:** die Haltung groß, beim Stehen die Marke „Rezitation: laut/leise“, Titel, Anweisung und,
///   wo etwas gesprochen wird, die Formel in Amiri mit Umschrift.
/// - **Ende:** ein Haken im Akzentkreis, „Gebet beendet“ und „Möge Allah dein Gebet annehmen.“
struct WalkPage: View {
    let walk: GuideWalk
    let index: Int

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    var body: some View {
        let step = walk.step(at: index)
        VStack(spacing: 0) {
            switch step.kind {
            case .intro:
                WalkBadge(systemImage: walk.prayer.symbolName, isDone: false)
                    .padding(.bottom, WalkMetrics.tileBottom)
                title(walk.localizedIntroTitle)
                message(walk.localizedIntroBody)
                WalkRakahDots(rakahs: walk.rakahs)
                    .padding(.top, WalkPageMetrics.dotsTop)
            case .done:
                WalkBadge(systemImage: WalkPageMetrics.doneSymbol, isDone: true)
                    .padding(.bottom, WalkMetrics.tileBottom)
                title(step.localizedTitle)
                message(step.localizedText)
            default:
                if let pose = step.kind.pose {
                    PoseFigure(pose, size: .walk)
                        .padding(.bottom, WalkMetrics.tileBottom)
                }
                if let tag = step.localizedRecitationTag {
                    WalkTag(text: tag, isAloud: step.isAloud)
                        .padding(.bottom, WalkPageMetrics.tagBottom)
                }
                title(step.localizedTitle)
                message(step.localizedText)
                if let formula = step.kind.formula {
                    WalkFormulaCard(formula: formula)
                        .padding(.top, WalkPageMetrics.formulaTop)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// Titel der Seite (`.walk-body h1`: `margin: 0 0 8px; font: 700 title1/1.2`); die Laufweite
    /// `.36px` setzt das System bei 28 pt selbst.
    private func title(_ text: String) -> some View {
        Text(text)
            .textStyle(.title1, weight: .bold, lineHeight: WalkPageMetrics.titleLineHeight)
            .foregroundStyle(Palette.label)
            .accessibilityAddTraits(.isHeader)
            .padding(.bottom, WalkPageMetrics.titleBottom)
    }

    /// Anweisung (`.walk-body p`: Body, Zeilenhöhe 1,42, `label-2`, höchstens 30 Zeichen breit – `30ch`
    /// sind 30 Ziffern „0“ der Schrift, bei 17 pt 321 pt; wächst mit der Schrift).
    private func message(_ text: String) -> some View {
        Text(text)
            .textStyle(.body, lineHeight: WalkPageMetrics.messageLineHeight)
            .foregroundStyle(Palette.textSecondary)
            .frame(maxWidth: WalkPageMetrics.messageMaxWidth * max(typeScale, 0))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Kachel der Start- und Schlussseite (`.walk-pose.walk-badge`): auf dem Start das Symbol des Gebets in
/// Akzent auf getöntem Grund, am Ende ein Haken in `--on-accent` im Akzentkreis (`.done`).
struct WalkBadge: View {
    let systemImage: String
    let isDone: Bool

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(
                size: isDone ? WalkPageMetrics.doneSymbolSize : WalkPageMetrics.badgeSymbolSize,
                weight: isDone ? WalkPageMetrics.doneSymbolWeight : WalkPageMetrics.badgeSymbolWeight
            ))
            .foregroundStyle(isDone ? Palette.onAccent : Palette.accent)
            .frame(width: WalkMetrics.tileSize, height: WalkMetrics.tileSize)
            .background(
                isDone ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Palette.accentTint),
                in: isDone
                    ? AnyShape(.circle)
                    : AnyShape(.rect(cornerRadius: WalkMetrics.tileRadius, style: .continuous))
            )
            .accessibilityHidden(true)
    }
}

/// Marke beim Stehen (`.walk-tag`): „Rezitation: laut“ in `--on-accent` auf Akzent, „leise“ in Akzent auf
/// getöntem Grund – nicht nur die Farbe, auch der Text sagt es.
struct WalkTag: View {
    let text: String
    let isAloud: Bool

    var body: some View {
        Text(text)
            .textStyle(.footnote, weight: .semibold, lineHeight: WalkPageMetrics.tagLineHeight)
            .foregroundStyle(isAloud ? Palette.onAccent : Palette.accent)
            .padding(.horizontal, WalkPageMetrics.tagPaddingX)
            .padding(.vertical, WalkPageMetrics.tagPaddingY)
            .background(isAloud ? Palette.accent : Palette.accentTint, in: .capsule)
    }
}

/// Die Formel im Durchlauf (`.walk-formula`): Arabisch in Amiri 27 pt (Spec § 9.7), darunter die Umschrift
/// kursiv, beides mittig auf einer Fläche in `--fill-4`, höchstens 320 pt breit.
struct WalkFormulaCard: View {
    let formula: GuideStep.Formula

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    var body: some View {
        let size = WalkPageMetrics.arabicSize * max(typeScale, 0)
        VStack(spacing: 0) {
            Text(arabic)
                .arabicFont(.amiri, size: size, lineHeight: WalkPageMetrics.arabicLineHeight)
                .foregroundStyle(Palette.label)
                // Im Arabischen ist der Anfang rechts; die Zeilen stehen mittig wie im Prototyp.
                .environment(\.layoutDirection, .rightToLeft)
            Text(formula.transliteration)
                .textStyle(.subheadline, lineHeight: WalkPageMetrics.transliterationLineHeight)
                .italic()
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, WalkPageMetrics.transliterationTop)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, WalkPageMetrics.formulaPaddingX)
        .padding(.vertical, WalkPageMetrics.formulaPaddingY)
        .background(Palette.fillQuaternary, in: .rect(cornerRadius: WalkPageMetrics.formulaRadius, style: .continuous))
        .frame(maxWidth: WalkPageMetrics.formulaMaxWidth)
        .accessibilityElement(children: .combine)
    }

    /// Der arabische Text mit seiner Sprache, damit VoiceOver ihn mit arabischer Stimme liest (`lang="ar"`).
    private var arabic: AttributedString {
        var text = AttributedString(formula.arabic)
        text.languageIdentifier = "ar"
        return text
    }
}

/// Die Rakʿas auf der Startseite als Punkte (`.walk-rak`): 34 pt, laut gefüllt, leise getönt, mit der
/// Nummer in gerundeter Schrift. Schmuck – Zahl und Rezitation stehen im Text und in der Anleitung.
struct WalkRakahDots: View {
    let rakahs: Rakahs

    var body: some View {
        HStack(spacing: WalkPageMetrics.dotsGap) {
            ForEach(Array(rakahs.aloud.enumerated()), id: \.offset) { index, isAloud in
                Text(String(index + 1))
                    .font(.system(size: WalkPageMetrics.dotFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isAloud ? Palette.onAccent : Palette.accent)
                    .frame(width: WalkPageMetrics.dotSize, height: WalkPageMetrics.dotSize)
                    .background(isAloud ? Palette.accent : Palette.accentTint, in: .circle)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Maße der Seite (`.walk-body h1`, `p`, `.walk-tag`, `.walk-formula`, `.walk-rak`, `.walk-badge`).
enum WalkPageMetrics {
    static let titleLineHeight: CGFloat = 1.2
    static let titleBottom: CGFloat = 8
    static let messageLineHeight: CGFloat = 1.42
    /// `max-width: 30ch` bei 17 pt – im Prototyp gemessen 321,23 pt (`getBoundingClientRect`).
    static let messageMaxWidth: CGFloat = 321.23
    /// `.walk-tag`: `margin-bottom: 10px; padding: 4px 11px; font: 600 footnote/1.3`.
    static let tagBottom: CGFloat = 10
    static let tagPaddingX: CGFloat = 11
    static let tagPaddingY: CGFloat = 4
    static let tagLineHeight: CGFloat = 1.3
    /// `.walk-formula`: `max-width: 320px; margin-top: 18px; padding: 12px 16px; border-radius: 16px`;
    /// `.ar`: `font: 400 calc(27px*var(--ts))/1.9 "Amiri"`; `.lat`: `margin-top: 2px`, Subheadline kursiv.
    static let formulaTop: CGFloat = 18
    static let formulaMaxWidth: CGFloat = 320
    static let formulaPaddingX: CGFloat = 16
    static let formulaPaddingY: CGFloat = 12
    static let formulaRadius: CGFloat = 16
    static let arabicSize: CGFloat = 27
    static let arabicLineHeight: CGFloat = 1.9
    static let transliterationTop: CGFloat = 2
    static let transliterationLineHeight: CGFloat = 1.3
    /// `.walk-rak`: `gap: 8px; margin-top: 20px`; Punkte 34 pt, `font: 700 15px/1 rounded`.
    static let dotsTop: CGFloat = 20
    static let dotsGap: CGFloat = 8
    static let dotSize: CGFloat = 34
    static let dotFontSize: CGFloat = 15
    /// `.walk-badge svg`: 62 pt im Raster von 24. Das Symbol des Gebets so groß, dass es so breit erscheint
    /// wie die Zeichnung im Referenzbild (gut 50 pt); der Haken so breit wie `check` dort (36 pt) – SF
    /// Symbols zeichnet ihn höher.
    static let badgeSymbolSize: CGFloat = 48
    static let badgeSymbolWeight: Font.Weight = .medium
    static let doneSymbol = "checkmark"
    static let doneSymbolSize: CGFloat = 40
    static let doneSymbolWeight: Font.Weight = .semibold
}
