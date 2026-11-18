import SwiftUI

/// Eine Seite des Onboardings: Zeichen oder Symbol, Titel und Text, mittig, auf Seite 4 darunter die
/// Chips – `.onb-page` im Prototyp.
public struct OnboardingPage<Icon: View, Footer: View>: View {
    private let title: String
    private let message: String
    private let icon: Icon
    private let footer: Footer

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// - Parameters:
    ///   - icon: das große Zeichen der App (`AppMark(size: .large)`) oder ein Symbol auf getöntem Kreis
    ///     (`IconBadge`).
    ///   - footer: was unter dem Text steht – auf Seite 4 die Chips (`OnboardingChips`).
    public init(
        title: String, message: String, @ViewBuilder icon: () -> Icon, @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.message = message
        self.icon = icon()
        self.footer = footer()
    }

    public var body: some View {
        VStack(spacing: 0) {
            icon
            Text(title)
                .tracking(OnboardingMetrics.titleTracking)
                .textStyle(.title1, weight: .bold, lineHeight: OnboardingMetrics.titleLineHeight)
                .foregroundStyle(Palette.label)
                .padding(.top, OnboardingMetrics.titleTop)
                .padding(.bottom, OnboardingMetrics.titleBottom)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .textStyle(.body, lineHeight: OnboardingMetrics.messageLineHeight)
                .foregroundStyle(Palette.textSecondary)
            footer
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        // Innen auf dem iPhone Duo (regular) höchstens so breit wie im Prototyp innen quer.
        .frame(maxWidth: OnboardingMetrics.pageMaxWidth(regular: horizontalSizeClass == .regular))
        .padding(.horizontal, OnboardingMetrics.pageInsetX)
        .frame(maxWidth: .infinity)
    }
}

extension OnboardingPage where Footer == EmptyView {

    /// Eine Seite ohne etwas unter dem Text.
    public init(title: String, message: String, @ViewBuilder icon: () -> Icon) {
        self.init(title: title, message: message, icon: icon) { EmptyView() }
    }
}

/// Der Hinweis auf Seite 3 unter dem Text: Vor jedem Gebet zeigt die App eine Live-Aktivität, und sie lässt sich
/// unter Einstellungen › Live-Aktivität abschalten (`.ob-live`, Spec § 10.5). Info-Symbol in Akzent, getönter
/// Grund, Radius 14, Fußnote.
public struct OnboardingNote: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .top, spacing: OnboardingNoteMetrics.gap) {
            Image(systemName: "info.circle")
                .font(.system(size: OnboardingNoteMetrics.symbolSize))
                .foregroundStyle(Palette.accent)
                .accessibilityHidden(true)
            Text(text)
                .textStyle(.footnote, lineHeight: OnboardingNoteMetrics.lineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, OnboardingNoteMetrics.paddingY)
        .padding(.horizontal, OnboardingNoteMetrics.paddingX)
        .background(Palette.fillTertiary, in: .rect(cornerRadius: OnboardingNoteMetrics.radius, style: .continuous))
        .frame(maxWidth: OnboardingNoteMetrics.maxWidth)
        .padding(.top, OnboardingNoteMetrics.top)
    }
}

/// Maße des Hinweises (`.ob-live`: 18 pt Abstand, 10/12 pt innen, Radius 14, höchstens 320 pt breit).
enum OnboardingNoteMetrics {
    static let top: CGFloat = 18
    static let paddingX: CGFloat = 12
    static let paddingY: CGFloat = 10
    static let radius: CGFloat = 14
    static let gap: CGFloat = 8
    static let symbolSize: CGFloat = 16
    static let lineHeight: CGFloat = 1.38
    static let maxWidth: CGFloat = 320
}

/// Die Chips unter dem Text der Seite „Kostenlos. Ohne Werbung.“: „Keine Werbung“, „Kein Tracking“,
/// „Kein Konto“ mit Haken, getönt in Akzent, mittig umbrechend (`.ob-free`, Spec § 9.9).
public struct OnboardingChips: View {
    private let items: [String]

    public init(_ items: [String]) {
        self.items = items
    }

    public var body: some View {
        CenteredFlowLayout(spacing: OnboardingMetrics.chipGap) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: OnboardingMetrics.chipInnerGap) {
                    Image(systemName: "checkmark")
                        .font(.system(size: OnboardingMetrics.chipSymbolSize, weight: .semibold))
                        .accessibilityHidden(true)
                    Text(item)
                        .textStyle(.subheadline, weight: .semibold, lineHeight: OnboardingMetrics.chipLineHeight)
                }
                .foregroundStyle(Palette.accent)
                .padding(.horizontal, OnboardingMetrics.chipPaddingX)
                .padding(.vertical, OnboardingMetrics.chipPaddingY)
                .background(Palette.accentTint, in: .capsule)
            }
        }
        .padding(.top, OnboardingMetrics.chipsTop)
        .accessibilityElement(children: .combine)
    }
}

/// Reihen, die mittig umbrechen – wie `display: flex; flex-wrap: wrap; justify-content: center`.
struct CenteredFlowLayout: SwiftUI.Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: min(width, proposal.width ?? width), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            var x = bounds.midX - row.width / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(width: CGFloat, subviews: LayoutSubviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// Punkte unter den Seiten des Onboardings: der aktuelle als Kapsel in Akzent – `.onb-dots` im
/// Prototyp. Für VoiceOver ein Bild mit „1 / 3“.
public struct PageDots: View {
    private let count: Int
    private let current: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter current: der aktuelle Punkt, von 0 an gezählt.
    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: OnboardingMetrics.dotGap) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.accent : Palette.labelQuaternary)
                    .frame(
                        width: index == current ? OnboardingMetrics.currentDotWidth : OnboardingMetrics.dotSize,
                        height: OnboardingMetrics.dotSize
                    )
            }
        }
        .frame(height: OnboardingMetrics.dotsHeight)
        .animation(reduceMotion ? nil : .spring(duration: OnboardingMetrics.dotDuration), value: current)
        .accessibilityElement()
        .accessibilityAddTraits(.isImage)
        .accessibilityLabel("\(current + 1) / \(count)")
    }
}

/// Maße des Onboardings (`.onb`, `.onb-top`, `.onb-page`, `.onb-dots`, `.dot`, `.onb-actions`, `.btn`).
public enum OnboardingMetrics {
    /// Leiste mit „Überspringen“ (`.onb-top`: `height: 44px; padding: 0 8px`; `.link-btn`: `padding: 0 12px`).
    public static let topBarHeight: CGFloat = 44
    public static let topBarInsetX: CGFloat = 8
    public static let skipPaddingX: CGFloat = 12
    /// Seite (`.onb-page`: `padding: 0 34px 30px`).
    public static let pageInsetX: CGFloat = 34
    public static let pageBottom: CGFloat = 30
    /// Breite des Texts innen auf dem iPhone Duo: Der Prototyp lässt auf dem inneren Display (875 pt neben
    /// der Leiste) 150 pt Rand (`.screen[data-dev="duo-open"] .onb-page`: `padding-inline: 150px`), also
    /// 575 pt. Als Breite statt als Rand passt sie auch hochkant (669 pt).
    public static let pageMaxWidthRegular: CGFloat = 875 - 2 * 150
    /// Titel (`.onb-page h1`: `margin: 30px 0 12px; font: 700 28px/1.2; letter-spacing: .36px`).
    static let titleTop: CGFloat = 30
    static let titleBottom: CGFloat = 12
    static let titleLineHeight: CGFloat = 1.2
    static let titleTracking: CGFloat = 0.36
    /// Text (`.onb-page p`: `line-height: 1.42`).
    static let messageLineHeight: CGFloat = 1.42
    /// Chips der Seite 4 (`.ob-free`: `gap: 8px; margin: 22px 0 0`; `li`: `gap: 6px; padding: 7px 12px`,
    /// 600 Subheadline/1,2, `ic('check', 16)`).
    static let chipsTop: CGFloat = 22
    static let chipGap: CGFloat = 8
    static let chipInnerGap: CGFloat = 6
    static let chipPaddingX: CGFloat = 12
    static let chipPaddingY: CGFloat = 7
    static let chipLineHeight: CGFloat = 1.2
    static let chipSymbolSize: CGFloat = 12
    /// Punkte (`.onb-dots`: `height: 24px; gap: 8px`; `.dot`: 7 pt, der aktuelle 20 pt breit).
    static let dotsHeight: CGFloat = 24
    static let dotGap: CGFloat = 8
    static let dotSize: CGFloat = 7
    static let currentDotWidth: CGFloat = 20
    static let dotDuration: TimeInterval = 0.35
    /// Knöpfe (`.onb-actions`: `gap: 4px; padding: 14px 24px 46px`; `.btn`: `min-height: 50px`). Die 46 pt
    /// unten enthalten die 34 pt des Home-Indikators; die App rechnet ab dem sicheren Bereich.
    public static let actionsGap: CGFloat = 4
    public static let actionsTop: CGFloat = 14
    public static let actionsInsetX: CGFloat = 24
    public static let actionsBottom: CGFloat = 46 - 34
    /// Knöpfe innen auf dem iPhone Duo (`.screen[data-dev="duo-open"] .onb-actions`:
    /// `padding: 10px 210px 26px`): 455 pt breit, wie dort neben 875 pt. Unten bleibt der sichere Bereich
    /// des Systems (34 pt), der schon größer ist als die 26 pt.
    public static let actionsTopRegular: CGFloat = 10
    public static let actionsMaxWidthRegular: CGFloat = 875 - 2 * 210
    public static let actionsBottomRegular: CGFloat = 0
    public static let buttonHeight: CGFloat = 50
    /// Seitenwechsel (`.onb-track`: `transition: transform .55s`).
    public static let pageDuration: TimeInterval = 0.55

    /// Größte Breite des Texts einer Seite – nur innen auf dem iPhone Duo (regular).
    public static func pageMaxWidth(regular: Bool) -> CGFloat? {
        regular ? pageMaxWidthRegular : nil
    }

    /// Größte Breite der Knöpfe – nur innen auf dem iPhone Duo (regular).
    public static func actionsMaxWidth(regular: Bool) -> CGFloat? {
        regular ? actionsMaxWidthRegular : nil
    }

    /// Ränder der Knöpfe (oben, links und rechts, unten); innen auf dem iPhone Duo (regular) oben und
    /// unten wie im Prototyp innen.
    public static func actionsInsets(regular: Bool) -> EdgeInsets {
        EdgeInsets(
            top: regular ? actionsTopRegular : actionsTop, leading: actionsInsetX,
            bottom: regular ? actionsBottomRegular : actionsBottom, trailing: actionsInsetX
        )
    }
}
