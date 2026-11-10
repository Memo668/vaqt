import PrayerCore
import SwiftUI

/// Aussehen des Tagesbogens.
public enum DayArcStyle: Hashable, Sendable {
    /// Der Bogen der Zeiten-Seite (`ARCS.home`).
    case home
    /// Der kleine Bogen der Live-Aktivität: weiß auf Akzent (`ARCS.la`, `.arc-la`).
    case liveActivity

    public var metrics: DayArcMetrics {
        switch self {
        case .home: .home
        case .liveActivity: .liveActivity
        }
    }

    var colors: DayArcColors {
        switch self {
        case .home: .home
        case .liveActivity: .liveActivity
        }
    }
}

/// Der Tagesbogen: ein dicker Kreisbogen für den Gebetstag von Fadschr (links) bis Ischa (rechts).
///
/// Die fünf Gebete sitzen als runde Marker mit Symbol auf dem Bogen, nach ihrer Uhrzeit. Kommende sind
/// getönt, begonnene gefüllt, das laufende ist größer und hat einen Schein. Der Teil bis „jetzt“ ist in
/// Akzent gefüllt, ein weißer Knopf markiert „jetzt“. Die Zeiten stehen außen am Bogen, bei den beiden
/// Endmarkern darunter. Kerahat-Fenster sind dünne Segmente knapp innerhalb des Bogens.
///
/// Bei RTL beginnt Fadschr rechts; Zahlen und Symbole werden nicht gespiegelt. Der Sonnenaufgang ist kein
/// Marker, weil er kein Gebet ist. Design Spec § 3 („DayArc“), `ARCS` und `arcHTML()` im Prototyp.
///
/// Der Bogen hat die feste Größe seiner Maße (358 × 180 pt). `content` steht unten mittig im Bogen –
/// auf der Zeiten-Seite die Zeile „Maghrib in“ und der Countdown.
public struct DayArc<Content: View>: View {
    private let phase: DayPhase
    private let style: DayArcStyle
    private let showKerahat: Bool
    private let content: Content

    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - phase: die Tagesphase aus `PrayerCore`. Knopf und gefüllter Teil folgen `phase.now`.
    ///   - showKerahat: der Schalter „Kerahat-Zeiten zeigen“ aus den Einstellungen.
    ///   - content: Inhalt unten im Bogen.
    public init(
        phase: DayPhase, style: DayArcStyle = .home, showKerahat: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.phase = phase
        self.style = style
        self.showKerahat = showKerahat
        self.content = content()
    }

    public var body: some View {
        let layout = DayArcLayout(
            phase: phase, metrics: style.metrics, showKerahat: showKerahat,
            isRightToLeft: layoutDirection == .rightToLeft
        )
        ZStack(alignment: .bottom) {
            DayArcDrawing(layout: layout, colors: style.colors, typeScale: typeScale)
                // Gespiegelt wird in der Rechnung. Die Zeichnung selbst bleibt von links nach rechts,
                // damit SwiftUI Zahlen und Symbole nicht noch einmal spiegelt.
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.arcPrayers(n: String(layout.begunCount)))
                .accessibilityAddTraits(.isImage)
            content
                .padding(.bottom, layout.metrics.contentBottomInset)
        }
        .frame(width: layout.metrics.size.width, height: layout.metrics.size.height)
    }
}

extension DayArc where Content == EmptyView {

    /// Der Bogen ohne Inhalt in der Mitte.
    public init(phase: DayPhase, style: DayArcStyle = .home, showKerahat: Bool = true) {
        self.init(phase: phase, style: style, showKerahat: showKerahat) { EmptyView() }
    }
}

// MARK: - Farben

/// Die Farben des Bogens je Aussehen (`.arc-*` und `.arc-la .arc-*` im CSS).
struct DayArcColors {
    let track: Color
    let done: Color
    let markerUpcoming: Color
    let symbolUpcoming: Color
    let markerBegun: Color
    let symbolBegun: Color
    let glow: Color
    let ring: Color
    let time: Color
    let timeCurrent: Color
    let kerahat: Color
    let kerahatOpacity: Double
    let kerahatActiveOpacity: Double
    let knob: Color
    let knobStroke: Color
    let knobStrokeWidth: CGFloat
    let knobShadow: ShadowToken?
    /// Strichstärke der Symbole in den Markern (`sw` in `ARCS`, hier als Schriftstärke).
    let symbolWeight: Font.Weight

    static let home = DayArcColors(
        track: Palette.arcTrack, done: Palette.accent,
        markerUpcoming: Palette.arcTrack, symbolUpcoming: Palette.accent,
        markerBegun: Palette.accent, symbolBegun: Palette.onAccent,
        glow: Palette.accent.opacity(0.16), ring: Palette.backgroundGrouped,
        time: Palette.textSecondary, timeCurrent: Palette.accent,
        kerahat: Palette.kerahat, kerahatOpacity: 0.5, kerahatActiveOpacity: 0.95,
        knob: .white, knobStroke: .black.opacity(0.06), knobStrokeWidth: 0.5, knobShadow: .knob,
        symbolWeight: .bold
    )

    static let liveActivity = DayArcColors(
        track: Palette.LiveActivity.track, done: Palette.LiveActivity.foreground,
        markerUpcoming: Palette.LiveActivity.marker, symbolUpcoming: Palette.LiveActivity.foreground,
        markerBegun: Palette.LiveActivity.foreground, symbolBegun: Palette.LiveActivity.background,
        glow: Palette.LiveActivity.foreground.opacity(0.22), ring: Palette.LiveActivity.background,
        time: Palette.LiveActivity.time, timeCurrent: Palette.LiveActivity.foreground,
        kerahat: Palette.LiveActivity.kerahat, kerahatOpacity: 0.75, kerahatActiveOpacity: 1,
        knob: Palette.LiveActivity.background, knobStroke: Palette.LiveActivity.foreground, knobStrokeWidth: 2,
        knobShadow: nil,
        symbolWeight: .semibold
    )
}

// MARK: - Zeichnung

/// Die Zeichnung des Bogens im Koordinatensystem seiner Maße.
struct DayArcDrawing: View {
    let layout: DayArcLayout
    let colors: DayArcColors
    let typeScale: CGFloat

    /// Anteil der Kantenlänge, den ein SF Symbol als Schriftgröße bekommt, damit es so groß erscheint
    /// wie die Zeichnung des Prototyps in ihrem Feld.
    static let symbolFontScale: CGFloat = 0.72

    var body: some View {
        let metrics = layout.metrics
        ZStack(alignment: .topLeading) {
            segment(from: 0, to: 1)
                .stroke(colors.track, style: StrokeStyle(lineWidth: metrics.trackWidth, lineCap: .round))

            if layout.progress > 0 {
                segment(from: 0, to: layout.progress)
                    .stroke(colors.done, style: StrokeStyle(lineWidth: metrics.trackWidth, lineCap: .round))
            }

            ForEach(layout.kerahat) { window in
                segment(from: window.start, to: window.end, radius: layout.kerahatRadius)
                    .stroke(colors.kerahat, style: StrokeStyle(lineWidth: metrics.kerahatWidth, lineCap: .round))
                    .opacity(window.isActive ? colors.kerahatActiveOpacity : colors.kerahatOpacity)
            }

            // Der Knopf liegt unter den Markern: Beginnt ein Gebet, verschwindet er unter dessen Marker.
            if layout.showsKnob {
                knob.position(layout.knobCenter)
            }

            ForEach(layout.markers) { marker in
                self.marker(marker).position(marker.center)
            }

            ForEach(layout.markers) { marker in
                Text(marker.time.description)
                    .font(Typography.arcTime(
                        size: metrics.timeFontSize, isCurrent: marker.state == .current,
                        scales: metrics.timeScales, typeScale: typeScale
                    ))
                    .tracking(Typography.arcTimeTracking)
                    .foregroundStyle(marker.state == .current ? colors.timeCurrent : colors.time)
                    .fixedSize()
                    .position(marker.timeCenter)
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
    }

    private func segment(from start: Double, to end: Double, radius: CGFloat? = nil) -> ArcSegment {
        ArcSegment(metrics: layout.metrics, start: start, end: end, radius: radius, isRightToLeft: layout.isRightToLeft)
    }

    private var knob: some View {
        let diameter = layout.metrics.knobRadius * 2
        return Circle()
            .fill(colors.knob)
            .overlay(Circle().stroke(colors.knobStroke, lineWidth: colors.knobStrokeWidth))
            .frame(width: diameter, height: diameter)
            .shadow(colors.knobShadow ?? ShadowToken(color: .clear, blur: 0, y: 0))
    }

    private func marker(_ marker: DayArcLayout.Marker) -> some View {
        let metrics = layout.metrics
        let begun = marker.state != .upcoming
        return ZStack {
            if marker.state == .current {
                Circle()
                    .fill(colors.glow)
                    .frame(width: metrics.glowRadius * 2, height: metrics.glowRadius * 2)
            }
            if marker.isTight {
                Circle()
                    .fill(colors.ring)
                    .frame(width: (marker.radius + metrics.ringWidth) * 2, height: (marker.radius + metrics.ringWidth) * 2)
            }
            Circle()
                .fill(begun ? colors.markerBegun : colors.markerUpcoming)
                .frame(width: marker.radius * 2, height: marker.radius * 2)
            Image(systemName: marker.prayer.symbolName)
                .font(.system(size: marker.symbolSize * Self.symbolFontScale, weight: colors.symbolWeight))
                .foregroundStyle(begun ? colors.symbolBegun : colors.symbolUpcoming)
                .frame(width: marker.symbolSize, height: marker.symbolSize)
        }
    }
}

/// Ein Stück des Bogens zwischen zwei Anteilen des Gebetstages.
struct ArcSegment: Shape {
    let metrics: DayArcMetrics
    var start: Double
    var end: Double
    var radius: CGFloat?
    let isRightToLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Im Koordinatensystem der Ansicht wächst der Winkel im Uhrzeigersinn. Von links nach rechts
        // läuft der Bogen mit wachsendem Winkel – das nennt `addArc` wegen der nach unten zeigenden
        // y-Achse „nicht im Uhrzeigersinn“. Bei RTL läuft er andersherum.
        path.addArc(
            center: metrics.center,
            radius: radius ?? metrics.radius,
            startAngle: .radians(metrics.screenAngle(at: start, isRightToLeft: isRightToLeft)),
            endAngle: .radians(metrics.screenAngle(at: end, isRightToLeft: isRightToLeft)),
            clockwise: isRightToLeft
        )
        return path
    }
}
