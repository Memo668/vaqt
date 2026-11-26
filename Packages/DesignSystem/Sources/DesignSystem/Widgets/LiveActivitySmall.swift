import PrayerCore
import SwiftUI

// MARK: - Maße

extension LiveActivityMetrics {

    /// Die Größen der Familie „small“ laut HIG (`LAS` im Prototyp): CarPlay 240 × 100, 240 × 78 und 170 × 78 pt, im
    /// Smart Stack der Apple Watch (46 mm) 194 × 80,5 pt. CarPlay skaliert sie je nach Bildschirm.
    public static let smallSizes: [CGSize] = [
        CGSize(width: 240, height: 100), CGSize(width: 240, height: 78), CGSize(width: 170, height: 78),
        CGSize(width: 194, height: 80.5),
    ]
    /// Eckenradius im Prototyp (`.las`: 18) – nur für den Katalog; im Auto und auf der Uhr rundet das System.
    public static let smallRadius: CGFloat = 18
    /// Deckkraft der Fläche: voll statt 30 % (Spec § 12.3) – im Auto und im Smart Stack scheint kein Hintergrundbild
    /// durch.
    public static let smallBackgroundOpacity: Double = 1
    /// Ab dieser Höhe steht oben die Kopfzeile: in 240 × 100, nicht in den flachen Größen. Kopf (15 pt) und Bogen
    /// (72 pt) brauchen mit den Rändern des Prototyps (`margin: -1px 0 -3px`) 83 pt.
    public static let smallHeaderMinHeight: CGFloat = 90
    /// Kopf (`.las-head`: 600 12px/15px, `-.08px`, 12 pt seitlich, `margin: -1px 0 -3px`), Stadt zu 75 %; das App-Symbol
    /// 14 pt (`AppMark.Size.smallHeader`), 5 pt vor dem Namen.
    public static let smallHeadSize: CGFloat = 12
    public static let smallHeadFont = Font.system(size: 12, weight: .semibold)
    public static let smallHeadLineHeight: CGFloat = 15 / 12
    public static let smallHeadInset: CGFloat = 12
    public static let smallHeadTop: CGFloat = -1
    public static let smallHeadBottom: CGFloat = -3
    public static let smallCityOpacity: Double = 0.75
    /// Nach dem Wechsel zwei Zeilen, 3 pt Abstand (`.las-ended`: 600 13px/16px), die untere schwächer (500, 72 %).
    public static let smallEndedGap: CGFloat = 3
}

// MARK: - Anordnung

/// Was die Live-Aktivität „klein“ zeigt (Spec § 12.3) – abhängig von Inhalt, Wechsel und Höhe der Fläche, als Daten,
/// damit die Tests es prüfen können.
public struct LiveActivitySmallLayout: Hashable, Sendable {
    /// Die beiden Zeilen nach dem Wechsel.
    public struct EndedLines: Hashable, Sendable {
        /// „Asr · 14:00“.
        public let title: String
        /// „hat begonnen“ bzw. „Verbotszeit ab 15:42“.
        public let trailing: String
    }

    /// Die Aktivität hat gewechselt (`staleDate`): zwei Zeilen statt des Bogens.
    public let isEnded: Bool
    /// Ob oben die Kopfzeile steht – nur, wenn die Fläche hoch genug ist (240 × 100).
    public let showsHeader: Bool
    /// Rechts im Kopf: der Ort oder „Verbotszeit bis …“; `nil` ohne Kopf.
    public let headerTrailing: String?
    /// Im Bogen über dem Countdown: „Maghrib · 16:27“; in den flachen Größen während der Verbotszeit „Verbotszeit
    /// bis …“, weil es dort keinen Kopf gibt.
    public let arcCaption: String
    /// Ob `arcCaption` die Verbotszeit nennt – dann voll deckend, bei „Nur Bogen“ in `--la-warn`.
    public let captionIsProhibited: Bool
    /// Nach dem Wechsel: die beiden Zeilen, z. B. „Asr · 14:00“ und „hat begonnen“.
    public let endedLines: EndedLines?

    public init(content: LiveActivityContent, isStale: Bool, height: CGFloat) {
        isEnded = isStale || content.hasBegun
        let roomForHeader = height >= LiveActivityMetrics.smallHeaderMinHeight
        showsHeader = !isEnded && roomForHeader
        headerTrailing = showsHeader ? (content.isProhibited ? content.prohibitedHeader : content.cityName) : nil
        captionIsProhibited = !isEnded && !showsHeader && content.isProhibited
        arcCaption = captionIsProhibited ? content.prohibitedHeader : LiveActivityTexts.nameAndTime(content)
        endedLines = isEnded
            ? EndedLines(title: LiveActivityTexts.nameAndTime(content), trailing: LiveActivityTexts.endedTrailing(content))
            : nil
    }
}

// MARK: - Ansicht

/// Die Live-Aktivität „klein“ – in CarPlay auf dem Dashboard und im Smart Stack der Apple Watch (`laSmall()`, Spec
/// § 12.3, seit Phase 19): die Zeichnung des Sperrbildschirm-Widgets (Bogen 160 × 72 mit „Maghrib · 16:27“ und dem
/// Countdown) mittig auf der Fläche der Aktivität, in den Farben des Stils und mit voller Deckkraft, in der
/// Verbotszeit orange bzw. violett. Ist die Fläche hoch genug, steht oben ein Kopf mit App-Symbol, Name und Ort bzw.
/// „Verbotszeit bis …“. Keine Knöpfe – im Auto täten sie nichts.
///
/// Nach dem Wechsel (`isStale`) zeigt sie mittig „Asr · 14:00“ und „hat begonnen“ – die schmale Zeile des
/// Sperrbildschirms passt nicht in 170 pt. Den Verlauf zeichnet die Ansicht selbst; die Größe gibt das System vor.
public struct LiveActivitySmall: View {
    private let content: LiveActivityContent
    private let isStale: Bool

    /// - Parameter isStale: `context.isStale` – die Aktivität hat gewechselt.
    public init(content: LiveActivityContent, isStale: Bool) {
        self.content = content
        self.isStale = isStale
    }

    public var body: some View {
        let look = LiveActivityLook(content: content)
        let colors = look.colors
        GeometryReader { proxy in
            let layout = LiveActivitySmallLayout(content: content, isStale: isStale, height: proxy.size.height)
            Group {
                if let lines = layout.endedLines {
                    ended(lines, colors: colors)
                } else {
                    running(layout, look: look)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .foregroundStyle(Color(colors.foreground))
        .background(LiveActivityBackground(look: look, opacity: LiveActivityMetrics.smallBackgroundOpacity))
    }

    private func running(_ layout: LiveActivitySmallLayout, look: LiveActivityLook) -> some View {
        let colors = look.colors
        return VStack(spacing: 0) {
            if let trailing = layout.headerTrailing {
                HStack(spacing: 8) {
                    HStack(spacing: LiveActivityMetrics.iconGap) {
                        // Die helle Fassung mit Kachel wie im Kopf der Live-Aktivität (`LiveHeader`).
                        AppMark(size: .smallHeader)
                            .environment(\.colorScheme, .light)
                            .grayscale(colors.isMonochrome ? 1 : 0)
                        Text(L10n.appName)
                    }
                    Spacer(minLength: 0)
                    Text(trailing)
                        .fontWeight(content.isProhibited ? .semibold : .medium)
                        .foregroundStyle(content.isProhibited ? Color(colors.warning ?? colors.foreground) : Color(colors.foreground))
                        .opacity(content.isProhibited ? 1 : LiveActivityMetrics.smallCityOpacity)
                }
                .font(LiveActivityMetrics.smallHeadFont)
                .tracking(LiveActivityMetrics.headTracking)
                .lineLimit(1)
                .lineHeight(LiveActivityMetrics.smallHeadLineHeight, fontSize: LiveActivityMetrics.smallHeadSize)
                .padding(.horizontal, LiveActivityMetrics.smallHeadInset)
                .padding(.top, LiveActivityMetrics.smallHeadTop)
                .padding(.bottom, LiveActivityMetrics.smallHeadBottom)
            }
            DayArc(phase: content.countdown, style: .liveActivitySmall(look), showKerahat: content.showKerahat) {
                VStack(spacing: 0) {
                    Text(layout.arcCaption)
                        .font(WidgetMetrics.rectangularArcNameFont)
                        .foregroundStyle(layout.captionIsProhibited ? Color(colors.warning ?? colors.foreground) : Color(colors.foreground))
                        .opacity(layout.captionIsProhibited ? 1 : WidgetMetrics.rectangularArcNameOpacity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: WidgetMetrics.rectangularArcNameMaxWidth)
                        .lineHeight(WidgetMetrics.rectangularArcNameLineHeight, fontSize: 11)
                    LiveActivityCountdown(content: content, hasBegun: false)
                        .font(WidgetMetrics.rectangularArcCountFont)
                        .tracking(WidgetMetrics.rectangularArcCountTracking)
                        .multilineTextAlignment(.center)
                        .lineHeight(WidgetMetrics.rectangularArcCountLineHeight, fontSize: WidgetMetrics.rectangularArcCountSize)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func ended(_ lines: LiveActivitySmallLayout.EndedLines, colors: LiveActivityColors) -> some View {
        VStack(spacing: LiveActivityMetrics.smallEndedGap) {
            HStack(spacing: LiveActivityMetrics.iconGap) {
                AppMark(size: .header)
                    .environment(\.colorScheme, .light)
                    .grayscale(colors.isMonochrome ? 1 : 0)
                Text(lines.title)
            }
            Text(lines.trailing)
                .fontWeight(.medium)
                .opacity(LiveActivityMetrics.cityOpacity)
        }
        .font(LiveActivityMetrics.headFont)
        .tracking(LiveActivityMetrics.headTracking)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .lineHeight(LiveActivityMetrics.headLineHeight, fontSize: 13)
        .padding(.horizontal, LiveActivityMetrics.smallHeadInset)
        .accessibilityElement(children: .combine)
    }
}
