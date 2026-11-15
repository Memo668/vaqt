import PrayerCore
import SwiftUI

/// Der Durchlauf „Gebet Schritt für Schritt“ als Vollbild (Design Spec § 9.6) – `walkHTML()` im Prototyp.
///
/// Oben der Kreis zum Schließen, der Name des Gebets und die Zeile „Rakʿa 2 von 4 · Schritt 9 von 28“,
/// darunter der Fortschritt (4 pt). In der Mitte die Seite: Haltung, Titel, Anweisung, Formel. Unten
/// „Zurück“ und „Weiter“ im Verhältnis 1 : 1,6; auf der Startseite nur „Beginnen“, auf der letzten nur
/// „Fertig“.
///
/// Die Ansicht hält keinen Zustand: Seite und Richtung kommen von außen, die Knöpfe melden sich über die
/// Rückrufe. Jede neue Seite gleitet 22 pt in Leserichtung herein (rückwärts von der anderen Seite) und
/// blendet dabei auf; mit „Bewegung reduzieren“ blendet sie nur auf.
public struct GuideWalkScreen: View {

    /// Die Knöpfe, auf die VoiceOver nach einem Schritt springt (`focusNext` im Prototyp).
    public enum Control: Hashable, Sendable {
        case close
        case previous
        case next
    }

    /// In welche Richtung zuletzt geblättert wurde (`S.walk.dir`).
    public enum Direction: Sendable {
        case forward
        case backward
    }

    private let walk: GuideWalk
    private let index: Int
    private let direction: Direction
    private let focus: AccessibilityFocusState<Control?>.Binding?
    private let onPrevious: () -> Void
    private let onNext: () -> Void
    private let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// - Parameters:
    ///   - index: die Seite, 0 = Start, `walk.lastIndex` = „Gebet beendet“ (`S.walk.i`).
    ///   - focus: Fokus von VoiceOver auf den Knöpfen.
    ///   - onPrevious: „Zurück“ (`walk-prev`).
    ///   - onNext: „Beginnen“ und „Weiter“ (`walk-next`).
    ///   - onClose: der Kreis oben und „Fertig“ (`walk-close`).
    public init(
        walk: GuideWalk, index: Int, direction: Direction = .forward,
        focus: AccessibilityFocusState<Control?>.Binding? = nil,
        onPrevious: @escaping () -> Void, onNext: @escaping () -> Void, onClose: @escaping () -> Void
    ) {
        self.walk = walk
        self.index = walk.clamped(index)
        self.direction = direction
        self.focus = focus
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            WalkProgressBar(progress: walk.progress(at: index))
                .padding(.top, WalkMetrics.barTop)
                .padding(.horizontal, WalkMetrics.barInsetX)
            page
            actions
        }
        .background(Palette.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(walk.localizedDialogLabel)
        // Wischen mit zwei Fingern in Z-Form schließt wie Esc im Prototyp.
        .accessibilityAction(.escape, onClose)
    }

    // MARK: - Kopf

    private var topBar: some View {
        HStack(spacing: WalkMetrics.topBarGap) {
            GlassCircleButton(systemImage: "xmark", label: L10n.close, size: .regular, action: onClose)
                .keyboardShortcut(.cancelAction)
                .walkFocus(focus, .close)
            VStack(spacing: 0) {
                Text(walk.prayer.localizedName)
                    .textStyle(.headline, lineHeight: WalkMetrics.titleLineHeight)
                    .tracking(WalkMetrics.titleTracking)
                    .foregroundStyle(Palette.label)
                    .accessibilityAddTraits(.isHeader)
                Text(walk.localizedProgressLine(at: index))
                    .textStyle(.footnote, weight: .medium, lineHeight: WalkMetrics.countLineHeight)
                    .monospacedDigit()
                    .foregroundStyle(Palette.textSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            // Platzhalter so breit wie der Kreis, damit Titel und Zeile mittig stehen (`.walk-spacer`).
            Color.clear
                .frame(width: WalkMetrics.sideSlot, height: 1)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, WalkMetrics.topBarInsetX)
        .frame(minHeight: WalkMetrics.topBarHeight)
    }

    // MARK: - Seite

    /// Die Seite füllt den Platz zwischen Fortschritt und Knöpfen und steht darin mittig; reicht der Platz
    /// nicht (große Schrift), scrollt sie (`.walk-body`: `overflow: auto; justify-content: center`).
    private var page: some View {
        GeometryReader { proxy in
            ScrollView {
                WalkPage(walk: walk, index: index)
                    .padding(.horizontal, WalkMetrics.bodyInsetX)
                    .padding(.vertical, WalkMetrics.bodyInsetY)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    // Wie eine neue Seite erscheint (`walkIn`/`walkBack`, `.34s var(--ease-spring)`): aus
                    // 22 pt in Leserichtung und unsichtbar an ihren Platz; die vorige ist sofort weg. Mit
                    // „Bewegung reduzieren“ nur das Aufblenden (Spec § 9.6).
                    .keyframeAnimator(initialValue: WalkAppearance.shown, trigger: index) { content, value in
                        content
                            .opacity(value.opacity)
                            .offset(x: value.offset)
                    } keyframes: { _ in
                        KeyframeTrack(\.opacity) {
                            MoveKeyframe(0)
                            LinearKeyframe(1, duration: WalkMetrics.slideDuration, timingCurve: WalkMetrics.slideCurve)
                        }
                        KeyframeTrack(\.offset) {
                            MoveKeyframe(slideStart)
                            LinearKeyframe(0, duration: WalkMetrics.slideDuration, timingCurve: WalkMetrics.slideCurve)
                        }
                    }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// Versatz, aus dem eine neue Seite hereingleitet: vorwärts von der Seite, zu der man liest (im
    /// Deutschen von rechts), rückwärts von der anderen.
    private var slideStart: CGFloat {
        guard !reduceMotion else { return 0 }
        let sign: CGFloat = (direction == .forward ? 1 : -1) * (layoutDirection == .rightToLeft ? -1 : 1)
        return WalkMetrics.slideDistance * sign
    }

    // MARK: - Knöpfe

    @ViewBuilder private var actions: some View {
        Group {
            if index == 0 {
                PrimaryButton(L10n.wkBegin, action: onNext)
                    .walkFocus(focus, .next)
            } else if walk.isLast(index) {
                PrimaryButton(L10n.wkDone, action: onClose)
                    .walkFocus(focus, .next)
            } else if dynamicTypeSize.isAccessibilitySize {
                // Nebeneinander passen „Zurück“ und „Weiter“ ab den AX-Größen nicht mehr.
                VStack(spacing: WalkMetrics.actionsGap) {
                    nextButton
                    previousButton
                }
            } else {
                ProportionalRow(spacing: WalkMetrics.actionsGap, ratios: WalkMetrics.actionsRatios) {
                    previousButton
                    nextButton
                }
            }
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? WalkMetrics.actionsMaxWidthRegular : nil)
        .padding(.top, WalkMetrics.actionsTop)
        .padding(.horizontal, WalkMetrics.actionsInsetX)
        .padding(.bottom, WalkMetrics.actionsBottom)
    }

    private var previousButton: some View {
        TintedButton(L10n.wkPrev, compactSymbol: "chevron.backward", action: onPrevious)
            .walkFocus(focus, .previous)
    }

    private var nextButton: some View {
        PrimaryButton(L10n.wkNext, compactSymbol: "chevron.forward", imagePlacement: .trailing, action: onNext)
            .walkFocus(focus, .next)
    }
}

/// Deckkraft und Versatz einer Seite, während sie erscheint.
struct WalkAppearance: Sendable {
    var opacity: Double
    var offset: CGFloat

    static let shown = WalkAppearance(opacity: 1, offset: 0)
}

extension View {
    /// Bindet den Fokus von VoiceOver an einen Knopf, wenn es eine Bindung gibt.
    @ViewBuilder fileprivate func walkFocus(
        _ focus: AccessibilityFocusState<GuideWalkScreen.Control?>.Binding?, _ control: GuideWalkScreen.Control
    ) -> some View {
        if let focus {
            accessibilityFocused(focus, equals: control)
        } else {
            self
        }
    }
}

// MARK: - Fortschritt

/// Der Fortschritt unter dem Kopf: 4 pt hoch, Spur in `--fill-2`, gefüllt in Akzent (`.walk-bar`). Die
/// Breite gleitet mit (`transition: width .35s var(--ease-spring)`); VoiceOver liest ihn wie eine
/// Fortschrittsanzeige des Systems.
struct WalkProgressBar: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Palette.accent)
                .frame(width: proxy.size.width * min(max(progress, 0), 1))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: WalkMetrics.barHeight)
        .background(Palette.fillSecondary, in: .capsule)
        .clipShape(.capsule)
        .animation(reduceMotion ? nil : WalkMetrics.barAnimation, value: progress)
        .accessibilityRepresentation {
            ProgressView(value: progress)
        }
    }
}

// MARK: - Zeile im Verhältnis

/// Kinder nebeneinander in festen Anteilen der Breite, z. B. 1 : 1,6 (`grid-template-columns: 1fr 1.6fr`),
/// alle so hoch wie das höchste.
struct ProportionalRow: SwiftUI.Layout {
    let spacing: CGFloat
    let ratios: [CGFloat]

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let widths = columnWidths(total: proposal.width, count: subviews.count)
        let height = zip(subviews, widths).map { subview, width in
            subview.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)).height
        }.max() ?? 0
        let width = proposal.width ?? (widths.reduce(0, +) + spacing * CGFloat(max(subviews.count - 1, 0)))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let widths = columnWidths(total: bounds.width, count: subviews.count)
        // SwiftUI spiegelt eigene Layouts bei der Leserichtung von rechts nach links; „Zurück“ steht dann
        // rechts, wie im Prototyp (`dir="rtl"` auf dem Grid).
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths) {
            subview.place(
                at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                proposal: ProposedViewSize(width: width, height: bounds.height)
            )
            x += width + spacing
        }
    }

    func columnWidths(total: CGFloat?, count: Int) -> [CGFloat] {
        let ratios = (0..<count).map { $0 < self.ratios.count ? self.ratios[$0] : 1 }
        let sum = ratios.reduce(0, +)
        guard let total, sum > 0 else { return ratios.map { _ in PrimaryButtonMetrics.height * 2 } }
        let available = max(total - spacing * CGFloat(max(count - 1, 0)), 0)
        return ratios.map { available * $0 / sum }
    }
}

// MARK: - Maße

/// Maße des Durchlaufs (`.walk-top`, `.walk-title`, `.walk-count`, `.walk-bar`, `.walk-body`, `.walk-pose`,
/// `.walk-tag`, `.walk-formula`, `.walk-rak`, `.walk-actions`, `.walk-nav`).
enum WalkMetrics {
    /// `.walk-top`: `height: 52px; padding: 0 12px; gap: 8px`; Kreis und Platzhalter 44 pt.
    static let topBarHeight: CGFloat = 52
    static let topBarInsetX: CGFloat = 12
    static let topBarGap: CGFloat = 8
    static let sideSlot: CGFloat = 44
    /// `.walk-title`: `font: 600 headline/1.25; letter-spacing: -.3px`.
    static let titleLineHeight: CGFloat = 1.25
    static let titleTracking: CGFloat = -0.3
    /// `.walk-count`: `font: 500 footnote/1.3`, Ziffern gleich breit.
    static let countLineHeight: CGFloat = 1.3
    /// `.walk-bar`: `height: 4px; margin: 6px 20px 0; border-radius: 2px`.
    static let barHeight: CGFloat = 4
    static let barTop: CGFloat = 6
    static let barInsetX: CGFloat = 20
    static let barAnimation = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.35)
    /// `.walk-body`: `padding: 12px 30px`.
    static let bodyInsetX: CGFloat = 30
    static let bodyInsetY: CGFloat = 12
    /// `walkIn`/`walkBack`: 22 pt, `.34s var(--ease-spring)` = `cubic-bezier(.32,.72,0,1)`.
    static let slideDistance: CGFloat = 22
    static let slideDuration: TimeInterval = 0.34
    static let slideCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.32, y: 0.72), endControlPoint: UnitPoint(x: 0, y: 1)
    )
    /// `.walk-pose`: 172 × 172 pt, Radius 44, `margin-bottom: 20px`.
    static let tileSize: CGFloat = 172
    static let tileRadius: CGFloat = 44
    static let tileBottom: CGFloat = 20
    /// Knöpfe (`.walk-actions`: `padding: 14px 24px 46px`; `.walk-nav`: `1fr 1.6fr; gap: 10px`). Die 46 pt
    /// unten enthalten die 34 pt des Home-Indikators; die App rechnet ab dem sicheren Bereich. Innen auf dem
    /// iPhone Duo 420 pt breit (`padding-inline: calc((100% - 420px)/2)`).
    static let actionsTop: CGFloat = 14
    static let actionsInsetX: CGFloat = 24
    static let actionsBottom: CGFloat = 46 - 34
    static let actionsGap: CGFloat = 10
    static let actionsRatios: [CGFloat] = [1, 1.6]
    static let actionsMaxWidthRegular: CGFloat = 420
}
