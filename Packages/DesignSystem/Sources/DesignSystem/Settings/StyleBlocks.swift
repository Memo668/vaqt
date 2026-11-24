import PrayerCore
import SwiftUI

/// Bausteine der Seite Einstellungen › Stil (Nachtrag zu Phase 18, Spec § 11.7) – `style()`, `laThumb()` und der
/// Block „Stil“ im CSS des Prototyps.

// MARK: - Hintergrundbild

/// Das neutrale Beispielbild hinter der Vorschau und in den Kacheln (`.wall-neutral`): Es zeigt jede Grundfarbe
/// unverfälscht. Im dunklen Erscheinungsbild gedämpft (`filter: brightness(.55) saturate(1.1)`).
public struct NeutralWallpaper: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(RGBA(hex: 0x6A7280)), location: 0),
                        .init(color: Color(RGBA(hex: 0x434A57)), location: 0.46),
                        .init(color: Color(RGBA(hex: 0x2F3442)), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                // `radial-gradient(120% 70% at 15% 0%, #AEB6C2 0%, transparent 58%)`
                Self.glow(RGBA(hex: 0xAEB6C2), radiusX: 1.2 * size.width, radiusY: 0.7 * size.height, stop: 0.58)
                    .position(x: 0.15 * size.width, y: 0)
                // `radial-gradient(110% 80% at 100% 100%, #C7B3A4 0%, transparent 55%)`
                Self.glow(RGBA(hex: 0xC7B3A4), radiusX: 1.1 * size.width, radiusY: 0.8 * size.height, stop: 0.55)
                    .position(x: size.width, y: size.height)
            }
            .frame(width: size.width, height: size.height)
        }
        .colorMultiply(colorScheme == .dark ? Color(white: 0.55) : .white)
        .saturation(colorScheme == .dark ? 1.1 : 1)
        .accessibilityHidden(true)
    }

    /// Ein elliptischer Schein wie `radial-gradient(rx ry at …, color 0%, transparent stop)`: ein runder Verlauf,
    /// senkrecht auf die Ellipse gestaucht.
    private static func glow(_ color: RGBA, radiusX: CGFloat, radiusY: CGFloat, stop: CGFloat) -> some View {
        Rectangle()
            .fill(RadialGradient(
                colors: [Color(color), Color(color.opacity(0))],
                center: .center, startRadius: 0, endRadius: stop * radiusX
            ))
            .frame(width: 2 * radiusX, height: 2 * radiusX)
            .scaleEffect(x: 1, y: radiusY / radiusX)
    }
}

// MARK: - Grundfarben

/// Die Grundfarben als Kreise in Reihen zu sechs (`.st-colors`): zugeklappt die Standardreihe, aufgeklappt das
/// Raster 4 × 6. Kein sichtbarer Name; VoiceOver liest ihn je Kreis. Gewählt: Ring und Haken, nie nur die Farbe.
public struct AccentColorGrid: View {
    private let colors: [AccentColorID]
    private let selection: AccentColorID
    private let onSelect: (AccentColorID) -> Void

    public init(colors: [AccentColorID], selection: AccentColorID, onSelect: @escaping (AccentColorID) -> Void) {
        self.colors = colors
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: AccentColorID.rowLength),
            spacing: StyleMetrics.colorRowGap
        ) {
            ForEach(colors, id: \.self) { accent in
                AccentSwatch(accent: accent, isSelected: accent == selection) {
                    onSelect(accent)
                }
            }
        }
        .padding(StyleMetrics.colorsPadding)
        .accessibilityElement(children: .contain)
    }
}

/// Ein Kreis der Auswahl (`.st-color`): 36 pt, Tippziel 48 pt; gewählt mit Abstand und Ring in der Farbe und Haken.
struct AccentSwatch: View {
    let accent: AccentColorID
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let fill = Color(colorScheme == .dark ? accent.dark : accent.light)
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(fill, lineWidth: StyleMetrics.ringWidth)
                        .frame(width: StyleMetrics.ringDiameter, height: StyleMetrics.ringDiameter)
                }
                Circle()
                    .fill(fill)
                    .frame(width: StyleMetrics.swatchDiameter, height: StyleMetrics.swatchDiameter)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: StyleMetrics.checkSize, weight: .bold))
                        .foregroundStyle(colorScheme == .dark ? Color(accent.onDark) : .white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: StyleMetrics.swatchTarget)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.localizedName)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Der kleine graue Pfeil unter den Kreisen (`.st-more`): klappt das Raster auf und zu. Zugeklappt mit einer
/// weiteren Farbe steht ein kleiner Punkt in ihrer Farbe daneben.
public struct AccentMoreButton: View {
    private let isExpanded: Bool
    private let hiddenSelection: AccentColorID?
    private let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameter hiddenSelection: die gewählte Farbe, wenn sie zugeklappt nicht zu sehen ist.
    public init(isExpanded: Bool, hiddenSelection: AccentColorID?, action: @escaping () -> Void) {
        self.isExpanded = isExpanded
        self.hiddenSelection = hiddenSelection
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: StyleMetrics.moreGap) {
                if let hiddenSelection, !isExpanded {
                    Circle()
                        .fill(Color(colorScheme == .dark ? hiddenSelection.dark : hiddenSelection.light))
                        .frame(width: StyleMetrics.moreDot, height: StyleMetrics.moreDot)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: StyleMetrics.chevronSize, weight: .semibold))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(reduceMotion ? nil : .spring(duration: 0.25, bounce: 0.3), value: isExpanded)
            }
            .foregroundStyle(Palette.labelTertiary)
            .frame(maxWidth: .infinity, minHeight: StyleMetrics.moreHeight)
            .padding(.bottom, StyleMetrics.moreBottom)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? L10n.styleLessColors : L10n.styleMoreColors)
    }
}

// MARK: - Live-Aktivität

/// Eine Kachel der Stile (`.st-tile`): kleines Zeichen des Stils, Name, Radioknopf.
public struct LiveActivityStyleTile: View {
    private let style: LiveActivityStyle
    private let accent: AccentColorID
    private let isInverted: Bool
    private let isSelected: Bool
    private let action: () -> Void

    public init(style: LiveActivityStyle, accent: AccentColorID, isInverted: Bool, isSelected: Bool, action: @escaping () -> Void) {
        self.style = style
        self.accent = accent
        self.isInverted = isInverted
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            // `.st-tile { gap: 7px }`, der Radioknopf mit `margin-top: auto` unten – deshalb ohne Abstand im Stapel,
            // sonst käme um den Spacer noch zweimal der Abstand dazu.
            VStack(spacing: 0) {
                LiveActivityThumbnail(look: LiveActivityLook(style: AppStyle(accent: accent, liveActivity: style, isInverted: isInverted)))
                    .frame(height: StyleMetrics.thumbHeight)
                    .clipShape(.rect(cornerRadius: StyleMetrics.thumbRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: StyleMetrics.thumbRadius, style: .continuous)
                            .strokeBorder(Palette.separator, lineWidth: 0.5)
                    }
                    .background {
                        if isSelected {
                            // `box-shadow: 0 0 0 2.5px var(--bg-cell), 0 0 0 4.5px var(--accent)`
                            RoundedRectangle(cornerRadius: StyleMetrics.thumbRadius + 4.5, style: .continuous)
                                .fill(Palette.accent)
                                .padding(-4.5)
                        }
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: StyleMetrics.thumbRadius + 2.5, style: .continuous)
                                .strokeBorder(Palette.backgroundCell, lineWidth: 2.5)
                                .padding(-2.5)
                        }
                    }
                Text(style.localizedName)
                    .textStyle(.footnote, weight: isSelected ? .semibold : .regular, lineHeight: 1.25)
                    .foregroundStyle(Palette.label)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, StyleMetrics.tileGap)
                Spacer(minLength: StyleMetrics.tileGap)
                ZStack {
                    if isSelected {
                        Circle().fill(Palette.accent)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.onAccent)
                    } else {
                        Circle().strokeBorder(Palette.labelTertiary, lineWidth: 1.5)
                    }
                }
                .frame(width: StyleMetrics.radio, height: StyleMetrics.radio)
            }
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.localizedName)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Das kleine Zeichen eines Stils (`laThumb()`): Hintergrundbild, darauf eine Fläche mit 75 % Deckkraft, Bogen,
/// fünf Punkte und zwei Striche für Gebet und Countdown. Ein Zeichen, keine Vorschau – die Fläche deckt stärker,
/// damit man die drei unterscheiden kann.
public struct LiveActivityThumbnail: View {
    private let look: LiveActivityLook

    public init(look: LiveActivityLook) {
        self.look = look
    }

    public var body: some View {
        let colors = look.colors
        ZStack {
            NeutralWallpaper()
            GeometryReader { proxy in
                let points = LiveActivityMetrics.gradientPoints(size: proxy.size)
                ZStack {
                    LinearGradient(stops: colors.gradientStops, startPoint: points.start, endPoint: points.end)
                        .opacity(0.75)
                    MiniArc(colors: colors)
                }
                .clipShape(.rect(cornerRadius: 10, style: .continuous))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 8)
        }
        .accessibilityHidden(true)
    }
}

/// Der Bogen im Zeichen (`MINI = {w: 90, h: 46, cx: 45, cy: 55, r: 42.4, a0: .6}`), in 90 × 46 gezeichnet und
/// eingepasst.
struct MiniArc: View {
    let colors: LiveActivityColors

    private nonisolated static let width: CGFloat = 90, height: CGFloat = 46
    private nonisolated static let center = CGPoint(x: 45, y: 55), radius: CGFloat = 42.4, a0 = 0.6

    nonisolated static func point(_ fraction: Double) -> CGPoint {
        let angle = a0 + fraction * (.pi - 2 * a0)
        return CGPoint(x: center.x - radius * cos(angle), y: center.y - radius * sin(angle))
    }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / Self.width, size.height / Self.height)
            context.translateBy(x: (size.width - Self.width * scale) / 2, y: (size.height - Self.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            func arc(to fraction: Double) -> Path {
                var path = Path()
                let steps = 48
                for step in 0...steps {
                    let point = Self.point(fraction * Double(step) / Double(steps))
                    step == 0 ? path.move(to: point) : path.addLine(to: point)
                }
                return path
            }
            let stroke = StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
            context.stroke(arc(to: 1), with: .color(Color(colors.track)), style: stroke)
            context.stroke(arc(to: 0.6), with: .color(Color(colors.line)), style: stroke)
            for (fraction, begun, radius) in [(0.0, true, 3.6), (0.3, true, 3.6), (0.6, true, 4.6), (0.82, false, 3.6), (1.0, false, 3.6)] {
                let point = Self.point(fraction)
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(Color(begun ? colors.markerBegun : colors.marker)))
            }
            let foreground = Color(colors.foreground)
            context.fill(Path(roundedRect: CGRect(x: 36.5, y: 24, width: 17, height: 2.6), cornerRadius: 1.3), with: .color(foreground.opacity(0.7)))
            context.fill(Path(roundedRect: CGRect(x: 33, y: 29.5, width: 24, height: 5), cornerRadius: 2.5), with: .color(foreground))
        }
    }
}

extension LiveActivityStyle {
    /// „Farbig“, „Nur Bogen“, „Schwarz-weiß“ (`laFull`, `laArc`, `laMono`).
    public var localizedName: String {
        switch self {
        case .full: L10n.laFull
        case .arc: L10n.laArc
        case .mono: L10n.laMono
        }
    }
}

// MARK: - Vorschau

/// Die Vorschau oben auf der Seite (`.st-preview`): die Live-Aktivität, wie sie jetzt aussähe, auf dem neutralen
/// Hintergrundbild, auf 94 % verkleinert.
public struct LiveActivityPreview: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        let scale = StyleMetrics.previewScale
        LiveActivityLockScreen(content: content, isStale: false)
            .frame(width: LiveActivityMetrics.lockScreenWidth, height: LiveActivityMetrics.lockScreenHeight)
            .background {
                LiveActivityBackground(look: LiveActivityLook(content: content))
                    .background(.ultraThinMaterial.opacity(0.35))
            }
            .clipShape(.rect(cornerRadius: LiveActivityMetrics.lockScreenRadius, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 13, y: 8)
            .environment(\.colorScheme, .dark)
            .scaleEffect(scale)
            .frame(width: LiveActivityMetrics.lockScreenWidth * scale, height: LiveActivityMetrics.lockScreenHeight * scale)
            .padding(.vertical, StyleMetrics.previewPaddingY)
            .frame(maxWidth: .infinity)
            .background { NeutralWallpaper() }
            .clipShape(.rect(cornerRadius: Radius.group, style: .continuous))
    }
}

// MARK: - Maße

/// Maße der Seite (`.st-*` im CSS).
public enum StyleMetrics {
    /// `.st-colors`: `padding: 12px 8px 2px`, `row-gap: 4px`.
    public static let colorsPadding = EdgeInsets(top: 12, leading: 8, bottom: 2, trailing: 8)
    public static let colorRowGap: CGFloat = 4
    /// `.st-color`: 48 pt hoch, Kreis 36 pt; gewählt 2,5 pt Abstand und 2,5 pt Ring (`box-shadow`).
    static let swatchTarget: CGFloat = 48
    static let swatchDiameter: CGFloat = 36
    static let ringWidth: CGFloat = 2.5
    static let ringDiameter: CGFloat = 46
    static let checkSize: CGFloat = 15
    /// `.st-more`: 40 pt hoch, unten 4 pt, Pfeil 15 pt, Punkt 8 pt, 6 pt Abstand.
    static let moreHeight: CGFloat = 36
    static let moreBottom: CGFloat = 4
    static let chevronSize: CGFloat = 12
    static let moreDot: CGFloat = 8
    static let moreGap: CGFloat = 6
    /// `.st-tiles`: `padding: 14px 12px 12px`, `gap: 10px`; Kachel: Zeichen 62 pt hoch, Radius 13, 7 pt Abstand,
    /// Radioknopf 22 pt.
    public static let tilesPadding = EdgeInsets(top: 14, leading: 12, bottom: 12, trailing: 12)
    public static let tilesGap: CGFloat = 10
    static let tileGap: CGFloat = 7
    static let thumbHeight: CGFloat = 62
    static let thumbRadius: CGFloat = 13
    static let radio: CGFloat = 22
    /// `.st-preview`: 12 pt oben und unten; `.la { zoom: .94 }`; `.group-wrap.st-wrap { margin-bottom: 20px }`.
    static let previewPaddingY: CGFloat = 12
    static let previewScale: CGFloat = 0.94
    public static let previewBottom: CGFloat = 20
}
