import SwiftUI

/// Die Zusammenfassung oben auf der Seite „Nachholen“: der Anteil nachgeholt als größte Zahl, darunter
/// „nachgeholt“, der Balken und klein „133 von 2.725 nachgeholt · Noch 2.592 offen“ – `.qsum` in
/// `qadaPage()`.
///
/// Die offene Zahl steht bewusst klein, damit eine große Zahl nicht entmutigt (Design Spec § 3, „Qada
/// tracker“).
public struct QadaSummaryCard: View {
    private let summary: QadaSummary

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ summary: QadaSummary) {
        self.summary = summary
    }

    public var body: some View {
        Card(padding: QadaSummaryMetrics.padding) {
            VStack(spacing: 0) {
                VStack(spacing: QadaSummaryMetrics.unitTop) {
                    let size = QadaSummaryMetrics.percentSize * min(max(typeScale, 0), QadaSummaryMetrics.percentMaxScale)
                    Text(summary.percent)
                        .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
                        .tracking(QadaSummaryMetrics.percentTracking)
                        .lineHeight(QadaSummaryMetrics.percentLineHeight, fontSize: size)
                        .foregroundStyle(Palette.accent)
                    Text(L10n.qadaPctLabel)
                        .textStyle(.subheadline, lineHeight: QadaSummaryMetrics.lineHeight)
                        .foregroundStyle(Palette.textSecondary)
                }
                .multilineTextAlignment(.center)
                // „4,9 % nachgeholt“ als eine Angabe.
                .accessibilityElement(children: .combine)

                ProgressView(value: summary.share)
                    .progressViewStyle(QadaBarStyle(animates: !reduceMotion))
                    .accessibilityLabel(summary.done)
                    .padding(.top, QadaSummaryMetrics.barTop)
                    .padding(.bottom, QadaSummaryMetrics.barBottom)

                // Passen beide Angaben nicht nebeneinander, steht die zweite darunter (`flex-wrap`).
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: QadaSummaryMetrics.metaGapX) {
                        meta(summary.done)
                        Spacer(minLength: 0)
                        meta(summary.remaining)
                    }
                    VStack(alignment: .leading, spacing: QadaSummaryMetrics.metaGapY) {
                        meta(summary.done)
                        meta(summary.remaining)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func meta(_ text: String) -> some View {
        Text(text)
            .monospacedDigit()
            .textStyle(.footnote, lineHeight: QadaSummaryMetrics.lineHeight)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Der Balken der Zusammenfassung: 8 pt hoch, Spur in `--fill-2`, der nachgeholte Teil in Akzentfarbe
/// (`.qbar`). Er füllt sich in Leserichtung und wächst mit einer Feder (`transition: width .4s`).
struct QadaBarStyle: ProgressViewStyle {
    var animates = true

    func makeBody(configuration: Configuration) -> some View {
        let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)
        Capsule(style: .continuous)
            .fill(Palette.fillSecondary)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule(style: .continuous)
                        .fill(Palette.accent)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .clipShape(.capsule)
            .frame(height: QadaSummaryMetrics.barHeight)
            .animation(animates ? .spring(duration: 0.4) : nil, value: fraction)
    }
}

/// Maße der Zusammenfassung (`.qsum`: `padding: 22px 20px 18px`; `.qsum-num`: `font: 700
/// calc(56px*min(var(--ts),1.2))/1.05` gerundet, `letter-spacing: -.5px`; `.qsum-unit`: `margin-top: 2px`;
/// `.qbar`: `height: 8px; margin: 18px 0 10px`; `.qsum-meta`: `gap: 4px 12px`, Footnote).
enum QadaSummaryMetrics {
    static let padding = EdgeInsets(top: 22, leading: 20, bottom: 18, trailing: 20)
    static let percentSize: CGFloat = 56
    static let percentMaxScale: CGFloat = 1.2
    static let percentLineHeight: CGFloat = 1.05
    static let percentTracking: CGFloat = -0.5
    static let unitTop: CGFloat = 2
    /// Zeilenhöhe von „nachgeholt“ und der Zeile unter dem Balken (1,3 von `.screen`).
    static let lineHeight: CGFloat = 1.3
    static let barHeight: CGFloat = 8
    static let barTop: CGFloat = 18
    static let barBottom: CGFloat = 10
    static let metaGapX: CGFloat = 12
    static let metaGapY: CGFloat = 4
}
