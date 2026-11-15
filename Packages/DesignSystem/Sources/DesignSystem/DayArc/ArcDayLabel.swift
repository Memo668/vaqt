import SwiftUI

/// Der Tag statt des Countdowns unten im Bogen, wenn die Zeiten-Seite einen anderen Tag zeigt (Spec § 9.4):
/// oben der Tag relativ zu heute („Übermorgen“, „In 3 Tagen“), darunter das kurze Datum in 40 pt light
/// („Do., 12. Nov.“) – `.hero-label` und `.hero-count.hero-day` im Prototyp.
///
/// Für VoiceOver ein Element: „Übermorgen, Donnerstag, 12. November“.
public struct ArcDayLabel: View {
    private let relativeDay: String
    private let date: String
    private let spokenDate: String

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - relativeDay: der Tag relativ zu heute, mit großem Anfangsbuchstaben.
    ///   - date: das kurze Datum.
    ///   - spokenDate: das Datum für VoiceOver, ausgeschrieben.
    public init(relativeDay: String, date: String, spokenDate: String) {
        self.relativeDay = relativeDay
        self.date = date
        self.spokenDate = spokenDate
    }

    public var body: some View {
        let size = ArcDayLabelMetrics.dateSize * min(max(typeScale, 0), ArcDayLabelMetrics.dateMaxScale)
        VStack(spacing: 0) {
            Text(relativeDay)
                .textStyle(
                    .subheadline, weight: Typography.countdownLabelWeight,
                    lineHeight: Typography.countdownLabelLineHeight
                )
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(ArcCountdownMetrics.labelMinimumScale)
                .frame(maxWidth: ArcCountdownMetrics.labelMaxWidth)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Text(date)
                .font(.system(size: size, weight: .light))
                .tracking(ArcDayLabelMetrics.dateTracking)
                .foregroundStyle(Palette.label)
                .lineLimit(1)
                .minimumScaleFactor(ArcDayLabelMetrics.dateMinimumScale)
                .frame(maxWidth: ArcDayLabelMetrics.dateMaxWidth)
                .lineHeight(Typography.countdownLineHeight, fontSize: size)
                .padding(.bottom, ArcDayLabelMetrics.dateBottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(relativeDay + ", " + spokenDate)
    }
}

/// Maße des Tages im Bogen (`.hero:not(.no-arc) .hero-count.hero-day`).
enum ArcDayLabelMetrics {
    /// `font-size: calc(40px * min(var(--ts), 1.1))`, `font-weight: 300`.
    static let dateSize: CGFloat = 40
    static let dateMaxScale: CGFloat = 1.1
    /// `letter-spacing: -.4px`
    static let dateTracking: CGFloat = -0.4
    /// `padding-bottom: 6px`
    static let dateBottom: CGFloat = 6
    /// Zwischen den Markern an den Enden des Bogens, wie die Zeile darüber.
    static let dateMaxWidth: CGFloat = 270
    static let dateMinimumScale: CGFloat = 0.7
}
