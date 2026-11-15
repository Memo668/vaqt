import SwiftUI

// Bausteine der Seite „Unterstützen“ (Spec § 9.9, `PAGES.support` im Prototyp). Gezahlt wird in v1 nichts
// (entschieden am 15.11.2026: „Erst nur der Hinweis“); die Seite erklärt, wofür Spenden gedacht sind.

/// Zeile mit einem Symbol vor Titel und Zusatz (`.row` mit `.row-ic`): in den Einstellungen „Gebetszeiten
/// unterstützen“ mit rotem Herz, auf der Seite „Unterstützen“ die drei Zwecke in Akzent. Die Trennlinie
/// der Liste beginnt beim Titel.
public struct IconRowLabel: View {
    private let systemImage: String
    private let tint: Color
    private let title: String
    private let detail: String?

    public init(_ title: String, detail: String? = nil, systemImage: String, tint: Color = Palette.accent) {
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: ListRowMetrics.gap) {
            Image(systemName: systemImage)
                .font(.system(size: SupportMetrics.rowSymbolSize, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: SupportMetrics.rowSymbolBox)
                .accessibilityHidden(true)
            RowTitle(title, detail: detail)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
    }
}

/// Kopf der Seite „Unterstützen“: Herz im getönten Kreis (88 pt), „Kostenlos. Ohne Werbung.“ und der
/// Absatz dazu (`.sup-hero`).
public struct SupportHero: View {
    private let title: String
    private let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 0) {
            IconBadge(
                systemImage: "heart", symbolSize: IconBadgeMetrics.supportHeartSymbolSize,
                side: IconBadgeMetrics.supportSide
            )
            Text(title)
                .textStyle(.title2, weight: .bold, lineHeight: SupportMetrics.heroTitleLineHeight)
                .foregroundStyle(Palette.label)
                .padding(.top, SupportMetrics.heroTitleTop)
                .padding(.bottom, SupportMetrics.heroTitleBottom)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .textStyle(.subheadline, lineHeight: SupportMetrics.heroLineHeight)
                .foregroundStyle(Palette.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(SupportMetrics.heroPadding)
    }
}

/// Die Karte „Spenden sind bald möglich“ mit dem Knopf, der die App weiterempfiehlt (`.sup-soon`). Ohne
/// Adresse im App Store fehlt der Knopf.
public struct SupportSoonCard<Share: View>: View {
    private let title: String
    private let message: String
    private let share: Share

    public init(title: String, message: String, @ViewBuilder share: () -> Share) {
        self.title = title
        self.message = message
        self.share = share()
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: SupportMetrics.soonHeadGap) {
                    Image(systemName: "sparkles")
                        .font(.system(size: SupportMetrics.soonSymbolSize, weight: .medium))
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                    Text(title)
                        .textStyle(.headline, lineHeight: SupportMetrics.soonTitleLineHeight)
                        .foregroundStyle(Palette.label)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.bottom, SupportMetrics.soonTitleBottom)
                Text(message)
                    .textStyle(.subheadline, lineHeight: SupportMetrics.heroLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.bottom, SupportMetrics.soonMessageBottom)
                share
            }
        }
    }
}

/// Maße der Seite „Unterstützen“ (`.support-row`, `.sup-hero`, `.sup-soon`).
public enum SupportMetrics {
    /// `.row-ic`: 24 pt breit, `ic(…, 20)`.
    static let rowSymbolBox: CGFloat = 24
    static let rowSymbolSize: CGFloat = 17
    /// `.sup-hero`: `padding: 4px 28px 18px`; Titel `margin: 16px 0 6px`, 700 Title 2/1,25; Absatz
    /// Subheadline/1,42.
    static let heroPadding = EdgeInsets(top: 4, leading: 28, bottom: 18, trailing: 28)
    static let heroTitleTop: CGFloat = 16
    static let heroTitleBottom: CGFloat = 6
    static let heroTitleLineHeight: CGFloat = 1.25
    static let heroLineHeight: CGFloat = 1.42
    /// `.sup-soon`: `margin-top: 18px`; Kopf `gap: 8px; margin-bottom: 6px`, `ic('sparkle', 18)`, 600
    /// Headline/1,3; Absatz `margin: 0 0 14px`.
    public static let soonTop: CGFloat = 18
    static let soonHeadGap: CGFloat = 8
    static let soonSymbolSize: CGFloat = 15
    static let soonTitleLineHeight: CGFloat = 1.3
    static let soonTitleBottom: CGFloat = 6
    static let soonMessageBottom: CGFloat = 14
}
