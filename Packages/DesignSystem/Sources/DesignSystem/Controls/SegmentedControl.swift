import SwiftUI

/// Segmente: eine Auswahl aus wenigen gleich breiten Teilen, z. B. die fünf Gebete der Anleitung.
///
/// Wie `.seg` und `.seg-wide` im Prototyp: eine graue Spur, darin der gewählte Teil als Daumen mit
/// weichem Schatten. Ein Teil kann unter seinem Titel einen Punkt in Akzent tragen – in der Anleitung
/// das aktuelle Gebet (Design Spec § 3, „Prayer guide“). Der Segment-Picker des Systems kann keinen
/// Punkt zeigen; deshalb dieser eigene Baustein (entschieden mit dem Plan für Phase 5).
///
/// Jeder Teil ist ein Knopf mit dem Merkmal „ausgewählt“. Sein Tippziel reicht oben und unten 5 pt
/// über die Spur hinaus und ist damit 44 pt hoch; für das Layout zählt nur die Spur (34 pt).
public struct SegmentedControl<Value: Hashable>: View {

    /// Ein Teil der Segmente.
    public struct Segment: Identifiable {
        public let value: Value
        /// Titel des Teils; bei einem Teil mit Symbol nur der VoiceOver-Text.
        public let title: String
        /// Ob der Teil den Punkt trägt, und was VoiceOver dazu sagt, z. B. „Jetzt“. `nil`: kein Punkt.
        public let mark: String?
        /// SF Symbol, das statt des Titels erscheint – z. B. die Glocken unter Einstellungen › Pro Gebet.
        public let systemImage: String?

        public var id: Value { value }

        public init(value: Value, title: String, mark: String? = nil) {
            self.value = value
            self.title = title
            self.mark = mark
            systemImage = nil
        }

        /// Ein Teil mit Symbol statt Titel; `title` sagt VoiceOver.
        public init(value: Value, title: String, systemImage: String) {
            self.value = value
            self.title = title
            mark = nil
            self.systemImage = systemImage
        }
    }

    private let label: String
    private let segments: [Segment]
    private let selection: Value
    private let focus: AccessibilityFocusState<Value?>.Binding?
    private let segmentWidth: CGFloat?
    private let onSelect: (Value) -> Void

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1
    /// Wo der Daumen steht. Antippen blendet ihn in 0,2 s über; ändert die Seite die Auswahl von sich aus –
    /// etwa wenn die Zeiten kommen –, springt er ohne Übergang.
    @State private var thumb: Value?

    /// - Parameters:
    ///   - label: Name der Auswahl für VoiceOver, z. B. „Anleitung“ (`aria-label` der `radiogroup`).
    ///   - selection: der gewählte Teil.
    ///   - focus: Fokus von VoiceOver, um ihn auf einen Teil zu setzen – etwa nach „Zum aktuellen Gebet“.
    ///   - segmentWidth: feste Breite jedes Teils, z. B. 44 pt für die Glocken (`.seg button`:
    ///     `min-width: 44px`); ohne Angabe teilen sich die Teile die Breite (`.seg-wide`).
    ///   - onSelect: Tippen auf einen Teil; die Seite entscheidet, was gewählt ist.
    public init(
        _ label: String, segments: [Segment], selection: Value,
        focus: AccessibilityFocusState<Value?>.Binding? = nil, segmentWidth: CGFloat? = nil,
        onSelect: @escaping (Value) -> Void
    ) {
        self.label = label
        self.segments = segments
        self.selection = selection
        self.focus = focus
        self.segmentWidth = segmentWidth
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                button(for: segment)
            }
        }
        .padding(.horizontal, SegmentMetrics.trackPadding)
        .background {
            RoundedRectangle(cornerRadius: SegmentMetrics.trackRadius, style: .continuous)
                .fill(Palette.fillTertiary)
                .padding(.vertical, SegmentMetrics.hitOutset)
        }
        // Das Tippziel ragt über die Spur hinaus; für das Layout zählt nur die Spur.
        .padding(.vertical, -SegmentMetrics.hitOutset)
        .onChange(of: selection) { _, selection in
            thumb = selection
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private func button(for segment: Segment) -> some View {
        let isSelected = segment.value == selection
        let button = Button {
            // Nur der Daumen blendet über (`transition: background .2s`); der Rest der Seite wechselt sofort.
            withAnimation(.easeInOut(duration: SegmentMetrics.transitionDuration)) {
                thumb = segment.value
            }
            onSelect(segment.value)
        } label: {
            content(for: segment)
                .frame(maxWidth: segmentWidth == nil ? .infinity : nil)
                .frame(width: segmentWidth, height: SegmentMetrics.segmentHeight)
                .background {
                    if segment.value == (thumb ?? selection) {
                        thumbView
                    }
                }
                .padding(.vertical, SegmentMetrics.trackPadding + SegmentMetrics.hitOutset)
                .contentShape(.rect)
        }
        .buttonStyle(SegmentButtonStyle())
        .accessibilityLabel(segment.title)
        .accessibilityValue(segment.mark ?? "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if let focus {
            button.accessibilityFocused(focus, equals: segment.value)
        } else {
            button
        }
    }

    /// Titel und – beim markierten Teil – der Punkt darunter, der Punkt um 2 pt zur Seite des Zeilenendes
    /// versetzt (`.cur-dot`: `margin-inline-start: 4px`).
    ///
    /// Im Prototyp ist der Knopf ein Raster (`display: grid; place-items: center`): Titel und Punkt sind
    /// zwei Zeilen, die sich den freien Platz der 30 pt teilen, und jedes steht mittig in seiner Zeile.
    @ViewBuilder
    private func content(for segment: Segment) -> some View {
        if let systemImage = segment.systemImage {
            Image(systemName: systemImage)
                .font(.system(size: SegmentMetrics.symbolSize, weight: SegmentMetrics.symbolWeight))
                .foregroundStyle(Palette.label)
                .accessibilityHidden(true)
        } else {
            titleContent(for: segment)
        }
    }

    private func titleContent(for segment: Segment) -> some View {
        let rows = SegmentMetrics.rows(fontSize: fontSize, isMarked: segment.mark != nil)
        return VStack(spacing: 0) {
            Text(segment.title)
                .font(.system(size: fontSize, weight: SegmentMetrics.fontWeight))
                .foregroundStyle(Palette.label)
                .lineLimit(1)
                .minimumScaleFactor(SegmentMetrics.minimumScaleFactor)
                .frame(height: rows.title)
            if segment.mark != nil {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: SegmentMetrics.dotSize, height: SegmentMetrics.dotSize)
                    .padding(.leading, SegmentMetrics.dotOffset)
                    .frame(height: rows.dot)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, SegmentMetrics.segmentPaddingX)
    }

    /// Der Daumen: `--seg-thumb` mit `box-shadow: 0 3px 8px rgba(0,0,0,.12), 0 0 0 .5px rgba(0,0,0,.04)`.
    private var thumbView: some View {
        RoundedRectangle(cornerRadius: SegmentMetrics.thumbRadius, style: .continuous)
            .fill(Palette.segmentThumb)
            .background {
                RoundedRectangle(cornerRadius: SegmentMetrics.thumbRadius + SegmentMetrics.ringWidth, style: .continuous)
                    .fill(.black.opacity(SegmentMetrics.ringOpacity))
                    .padding(-SegmentMetrics.ringWidth)
            }
            .shadow(color: .black.opacity(SegmentMetrics.shadowOpacity), radius: SegmentMetrics.shadowBlur / 2, x: 0, y: SegmentMetrics.shadowY)
    }

    /// Schriftgröße der Titel: 13 pt, mit Dynamic Type höchstens das 1,2-Fache.
    private var fontSize: CGFloat {
        SegmentMetrics.fontSize(typeScale: typeScale)
    }
}

/// Ein Teil der Segmente sieht gedrückt nicht anders aus (`.seg button` hat kein `:active`).
private struct SegmentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// Maße der Segmente (`.seg`, `.seg-wide`, `.cur-dot`).
enum SegmentMetrics {
    /// Spur (`.seg`: `padding: 2px; border-radius: 9px`).
    static let trackPadding: CGFloat = 2
    static let trackRadius: CGFloat = 9
    /// Ein Teil (`.seg button`: `height: 30px; border-radius: 7px`; `.seg-wide button`: `padding: 0 2px`).
    static let segmentHeight: CGFloat = 30
    static let segmentPaddingX: CGFloat = 2
    static let thumbRadius: CGFloat = 7
    /// Höhe der Spur: ein Teil plus der Innenabstand oben und unten – 34 pt.
    static let trackHeight: CGFloat = segmentHeight + 2 * trackPadding
    /// So weit reicht das Tippziel oben und unten über die Spur hinaus: bis 44 pt.
    static let hitOutset: CGFloat = (Layout.minTapTarget - trackHeight) / 2

    /// Schrift der Titel (`font: 500 13px`, `.seg-wide`: `calc(13px*min(var(--ts),1.2))`).
    static let baseFontSize: CGFloat = 13
    static let fontWeight: Font.Weight = .medium
    static let maxScale: CGFloat = 1.2
    /// Reicht der Platz nicht, wird ein Titel kleiner statt abgeschnitten.
    static let minimumScaleFactor: CGFloat = 0.7

    static func fontSize(typeScale: CGFloat) -> CGFloat {
        baseFontSize * min(max(typeScale, 0), maxScale)
    }

    /// Punkt beim aktuellen Gebet (`.cur-dot`: 6 × 6 pt, `margin-inline-start: 4px`). Weil Titel und Punkt
    /// mittig stehen, rückt der Rand den Punkt um die Hälfte, 2 pt, zum Zeilenende.
    static let dotSize: CGFloat = 6
    static let dotOffset: CGFloat = 4

    /// Höhe der beiden Zeilen eines Teils: Ohne Punkt füllt der Titel den Teil. Mit Punkt bekommen Titel
    /// und Punkt je ihre eigene Höhe plus die Hälfte des freien Platzes – wie Rasterzeilen, die sich
    /// strecken (`align-content: normal`). Der Titel ist so hoch wie eine Zeile der Systemschrift
    /// (`line-height: normal`).
    static func rows(fontSize: CGFloat, isMarked: Bool) -> (title: CGFloat, dot: CGFloat) {
        guard isMarked else { return (segmentHeight, 0) }
        let title = fontSize * systemFontLineHeight
        let free = max(0, segmentHeight - title - dotSize)
        return (title + free / 2, dotSize + free / 2)
    }

    /// Schatten und Rand des Daumens.
    static let shadowOpacity = 0.12
    static let shadowBlur: CGFloat = 8
    static let shadowY: CGFloat = 3
    static let ringWidth: CGFloat = 0.5
    static let ringOpacity = 0.04

    /// Der Daumen blendet über (`transition: background .2s, box-shadow .2s`).
    static let transitionDuration: TimeInterval = 0.2

    /// Symbol eines Teils – die Glocken unter „Pro Gebet“ (`ic(BELL_ICON[v], 18)`); als Schriftgröße eines
    /// SF Symbols so gewählt wie die Glocke der Gebetskarten (`ic(…, 20)`), auf 18 pt verkleinert.
    static let symbolSize: CGFloat = 12.2
    static let symbolWeight: Font.Weight = .semibold
    /// Breite eines Teils mit Symbol (`.seg button`: `min-width: 44px`).
    static let symbolSegmentWidth: CGFloat = 44
}
