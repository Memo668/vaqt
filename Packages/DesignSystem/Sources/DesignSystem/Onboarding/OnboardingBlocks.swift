import SwiftUI

/// Eine Seite des Onboardings: Zeichen oder Symbol, Titel und Text, mittig – `.onb-page` im Prototyp.
public struct OnboardingPage<Icon: View>: View {
    private let title: String
    private let message: String
    private let icon: Icon

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// - Parameter icon: das große Zeichen der App (`AppMark(size: .large)`) oder ein Symbol auf
    ///   getöntem Kreis (`IconBadge`).
    public init(title: String, message: String, @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.message = message
        self.icon = icon()
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
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, OnboardingMetrics.pageInset(regular: horizontalSizeClass == .regular))
        .frame(maxWidth: .infinity)
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
    /// Seite (`.onb-page`: `padding: 0 34px 30px`); innen auf dem iPhone Duo 150 pt Rand
    /// (`.screen[data-dev="duo-open"] .onb-page`: `padding-inline: 150px`).
    public static let pageInsetX: CGFloat = 34
    public static let pageInsetXRegular: CGFloat = 150
    public static let pageBottom: CGFloat = 30
    /// Titel (`.onb-page h1`: `margin: 30px 0 12px; font: 700 28px/1.2; letter-spacing: .36px`).
    static let titleTop: CGFloat = 30
    static let titleBottom: CGFloat = 12
    static let titleLineHeight: CGFloat = 1.2
    static let titleTracking: CGFloat = 0.36
    /// Text (`.onb-page p`: `line-height: 1.42`).
    static let messageLineHeight: CGFloat = 1.42
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
    /// `padding: 10px 210px 26px`). Unten bleibt der sichere Bereich des Systems (34 pt), der schon
    /// größer ist als die 26 pt.
    public static let actionsTopRegular: CGFloat = 10
    public static let actionsInsetXRegular: CGFloat = 210
    public static let actionsBottomRegular: CGFloat = 0
    public static let buttonHeight: CGFloat = 50
    /// Seitenwechsel (`.onb-track`: `transition: transform .55s`).
    public static let pageDuration: TimeInterval = 0.55

    /// Rand der Seite links und rechts – innen auf dem iPhone Duo (regular) breiter.
    public static func pageInset(regular: Bool) -> CGFloat {
        regular ? pageInsetXRegular : pageInsetX
    }

    /// Ränder der Knöpfe (oben, links und rechts, unten) – innen auf dem iPhone Duo (regular) schmaler.
    public static func actionsInsets(regular: Bool) -> EdgeInsets {
        regular
            ? EdgeInsets(top: actionsTopRegular, leading: actionsInsetXRegular, bottom: actionsBottomRegular, trailing: actionsInsetXRegular)
            : EdgeInsets(top: actionsTop, leading: actionsInsetX, bottom: actionsBottom, trailing: actionsInsetX)
    }
}
