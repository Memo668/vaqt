import PrayerCore
import SwiftUI

/// Die Karte mit dem Vers: Stichwort und Datum, der Vers auf Arabisch, die Übersetzung, die Quelle in
/// Akzentfarbe und die Knöpfe Teilen und Kopieren – `article.card` in `versesPage()`.
///
/// Teilen öffnet das Teilen-Menü des Systems mit Arabisch, Übersetzung und Quelle (`ShareLink`).
public struct VerseCard: View {
    private let day: VerseDay
    private let onCopy: () -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - day: der Tag, dessen Vers die Karte zeigt.
    ///   - onCopy: „Kopieren“.
    public init(_ day: VerseDay, onCopy: @escaping () -> Void) {
        self.day = day
        self.onCopy = onCopy
    }

    public var body: some View {
        let verse = day.verse
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardEyebrow(leading: day.cardTitle, trailing: day.shortDate)
                arabic(verse)
                    .padding(.top, VerseCardMetrics.arabicTop)
                    .padding(.bottom, VerseCardMetrics.arabicBottom)
                // Auf Arabisch steht keine Übersetzung, der Vers selbst genügt (`verseTr()`, Spec § 9.10).
                if !verse.localizedTranslation.isEmpty {
                    Text(verse.localizedTranslation)
                        .textStyle(.body, lineHeight: VerseCardMetrics.translationLineHeight)
                        .foregroundStyle(Palette.label)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                // `letter-spacing: -.24px` ist die Laufweite, die das System bei 15 pt ohnehin setzt.
                Text(verse.localizedReference)
                    .textStyle(.subheadline, weight: .semibold, lineHeight: VerseCardMetrics.referenceLineHeight)
                    .foregroundStyle(Palette.accent)
                    .padding(.top, VerseCardMetrics.referenceTop)
                FlowLayout(horizontalSpacing: VerseCardMetrics.actionGap, verticalSpacing: VerseCardMetrics.actionGap) {
                    ShareLink(item: verse.shareText) {
                        PillButtonLabel(L10n.share, systemImage: VerseCardMetrics.shareSymbol)
                    }
                    .buttonStyle(PillButtonStyle())
                    PillButton(L10n.copy, systemImage: VerseCardMetrics.copySymbol, action: onCopy)
                }
                .padding(.top, VerseCardMetrics.actionsTop)
            }
        }
        // `aria-label` der Karte: „Vers des Tages“ bzw. der Name des Tages.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(day.cardTitle)
    }

    /// Der Vers auf Arabisch: von rechts nach links und rechtsbündig, in Amiri Quran (Spec § 9.7). Wächst
    /// mit Dynamic Type ohne Grenze und ist für VoiceOver als Arabisch markiert (`lang="ar"`).
    private func arabic(_ verse: Verse) -> some View {
        let size = VerseCardMetrics.arabicSize * max(typeScale, 0)
        var text = AttributedString(verse.arabic)
        text.languageIdentifier = VerseCardMetrics.arabicLanguage
        return Text(text)
            .arabicFont(.amiriQuran, size: size, lineHeight: VerseCardMetrics.arabicLineHeight)
            .foregroundStyle(Palette.label)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Im Arabischen ist der Anfang rechts: Absatz von rechts nach links, rechtsbündig.
            .environment(\.layoutDirection, .rightToLeft)
    }
}

/// Ein Eintrag der Liste „Letzte Tage“: Tag und Datum, zwei Zeilen Übersetzung, die Quelle in
/// Akzentfarbe. Der Eintrag des Verses, den die Karte zeigt, ist getönt – `.vitem` in `versesPage()`.
public struct VerseListItem: View {
    private let day: VerseDay
    private let isSelected: Bool
    private let action: () -> Void

    /// - Parameters:
    ///   - isSelected: ob die Karte oben gerade diesen Vers zeigt (`aria-pressed`).
    ///   - action: Antippen zeigt den Vers oben (`verse-pick`).
    public init(_ day: VerseDay, isSelected: Bool, action: @escaping () -> Void) {
        self.day = day
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(day.listTitle)
                    .textStyle(.footnote, lineHeight: VerseListMetrics.lineHeight)
                    .foregroundStyle(Palette.textSecondary)
                if day.verse.localizedTranslation.isEmpty {
                    // Arabisch: ohne Übersetzung bleibt vom leeren `.vitem-tr` nur sein Rand (3 px).
                    Color.clear.frame(height: VerseListMetrics.translationGap)
                } else {
                    Text(day.verse.localizedTranslation)
                        .textStyle(.subheadline, lineHeight: VerseListMetrics.translationLineHeight)
                        .lineLimit(VerseListMetrics.translationLines)
                        .foregroundStyle(Palette.label)
                        .padding(.vertical, VerseListMetrics.translationGap)
                }
                Text(day.verse.localizedReference)
                    .textStyle(.footnote, weight: .semibold, lineHeight: VerseListMetrics.lineHeight)
                    .foregroundStyle(Palette.accent)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(VerseListMetrics.insets)
            .background(
                isSelected ? Palette.selectedItem : Palette.backgroundCell,
                in: .rect(cornerRadius: Radius.row, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: Radius.row, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Maße der Karte (`.card-eyebrow`, `.verse-ar`, `.verse-tr`, `.verse-ref`, `.card-actions`).
enum VerseCardMetrics {
    /// `.verse-ar`: `margin: 14px 0 12px`; seit v0.8 `font: 400 calc(31px*var(--ts))/2.15 "Amiri Quran"`
    /// (Spec § 9.7).
    static let arabicTop: CGFloat = 14
    static let arabicBottom: CGFloat = 12
    static let arabicSize: CGFloat = 31
    static let arabicLineHeight: CGFloat = 2.15
    static let arabicLanguage = "ar"
    /// `.verse-tr`: `line-height: 1.45`.
    static let translationLineHeight: CGFloat = 1.45
    /// `.verse-ref`: `margin-top: 10px; font: 600 …/1.3`.
    static let referenceTop: CGFloat = 10
    static let referenceLineHeight: CGFloat = 1.3
    /// `.card-actions`: `gap: 8px; margin-top: 18px`.
    static let actionGap: CGFloat = 8
    static let actionsTop: CGFloat = 18
    /// Symbole der Knöpfe (`ic('share')`, `ic('copy')`). Die Spec nennt keine; die Zeichnung des Prototyps
    /// für Kopieren sind zwei überlappende abgerundete Quadrate wie `square.on.square`.
    static let shareSymbol = "square.and.arrow.up"
    static let copySymbol = "square.on.square"
}

/// Maße eines Eintrags (`.vitem`: `padding: 13px 16px`; `.vitem-tr`: `margin: 3px 0; line-height: 1.35`,
/// zwei Zeilen; Datum und Quelle mit der Zeilenhöhe 1,3 von `.screen`).
enum VerseListMetrics {
    static let insets = EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16)
    static let lineHeight: CGFloat = 1.3
    static let translationLineHeight: CGFloat = 1.35
    static let translationGap: CGFloat = 3
    static let translationLines = 2
    /// Abstand zwischen den Einträgen (`.vlist`: `gap: 8px`).
    static let gap: CGFloat = 8
}
