import PrayerCore
import SwiftUI

/// Aussehen des Tagesbogens.
public enum DayArcStyle: Hashable, Sendable {
    /// Der Bogen der Zeiten-Seite (`ARCS.home`).
    case home
    /// Der kleine Bogen der Live-Aktivität (`ARCS.la`, `.arc-la`) im Stil der App und, in der Verbotszeit, orange
    /// bzw. violett (Spec § 10.3, § 11.7).
    case liveActivity(LiveActivityLook)
    /// Der Bogen des mittleren Widgets „Live“: wie in der Live-Aktivität, etwas schmaler (`ARCS.wla` mit
    /// dem Aussehen `la`; Spec § 9.11). Der Stil der Live-Aktivität gilt auch hier (§ 11.7).
    case liveWidget(LiveActivityLook)
    /// Der Bogen des rechteckigen Widgets auf dem Sperrbildschirm: wie in der Live-Aktivität, aber einfarbig
    /// und ohne Uhrzeiten, Kerahat gestreift (`ARCS.acc`, `.arc-acc`; Spec § 9.11).
    case lockScreen

    public var metrics: DayArcMetrics {
        switch self {
        case .home: .home
        case .liveActivity: .liveActivity
        case .liveWidget: .liveWidget
        case .lockScreen: .lockScreen
        }
    }

    var colors: DayArcColors {
        switch self {
        case .home: .home
        case .liveActivity(let look), .liveWidget(let look): .live(look.colors)
        case .lockScreen: .lockScreen
        }
    }
}

/// Der Tagesbogen: ein dicker Kreisbogen für den Gebetstag von Fadschr (links) bis Ischa (rechts).
///
/// Die fünf Gebete sitzen als runde Marker mit Symbol auf dem Bogen, nach ihrer Uhrzeit. Kommende sind
/// getönt, begonnene gefüllt, das laufende ist größer und hat einen Schein. Der Teil bis „jetzt“ ist in
/// Akzent gefüllt, ein weißer Knopf markiert „jetzt“. Die Zeiten stehen außen am Bogen, bei den beiden
/// Endmarkern darunter. Kerahat-Fenster liegen als goldene Abschnitte auf der Spur, ohne Uhrzeiten – die
/// stehen in den Gebetskarten (Spec § 9.3); seit Phase 14 auch in der Live-Aktivität und den Widgets
/// (§ 9.11), auf dem Sperrbildschirm gestrichelt.
///
/// Bei RTL beginnt Fadschr rechts; Zahlen und Symbole werden nicht gespiegelt. Der Sonnenaufgang ist kein
/// Marker, weil er kein Gebet ist. Design Spec § 3 („DayArc“), `ARCS` und `arcHTML()` im Prototyp.
///
/// Der Bogen hat die feste Größe seiner Maße (358 × 180 pt). `content` steht unten mittig im Bogen –
/// auf der Zeiten-Seite die Zeile „Maghrib in“ und der Countdown.
public struct DayArc<Content: View>: View {
    /// Was der Bogen zeigt: die laufende Tagesphase oder einen anderen Tag (Spec § 9.4).
    private enum Source {
        case phase(DayPhase)
        case day(DayTimes)
    }

    private let source: Source
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
        source = .phase(phase)
        self.style = style
        self.showKerahat = showKerahat
        self.content = content()
    }

    public var body: some View {
        let layout = layout
        ZStack(alignment: .bottom) {
            DayArcDrawing(layout: layout, colors: style.colors, typeScale: typeScale)
                // Gespiegelt wird in der Rechnung. Die Zeichnung selbst bleibt von links nach rechts,
                // damit SwiftUI Zahlen und Symbole nicht noch einmal spiegelt.
                .environment(\.layoutDirection, .leftToRight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: layout))
                .accessibilityAddTraits(.isImage)
            content
                .padding(.bottom, layout.metrics.contentBottomInset)
        }
        .frame(width: layout.metrics.size.width, height: layout.metrics.size.height)
    }
}

extension DayArc {

    /// Der Bogen eines anderen Tages: dessen Zeiten und Kerahat-Fenster, ohne Fortschritt und ohne Knopf
    /// (Spec § 9.4). `content` steht unten im Bogen – auf der Zeiten-Seite der Tag statt des Countdowns.
    public init(
        times: DayTimes, style: DayArcStyle = .home, showKerahat: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        source = .day(times)
        self.style = style
        self.showKerahat = showKerahat
        self.content = content()
    }

    var layout: DayArcLayout {
        let isRightToLeft = layoutDirection == .rightToLeft
        switch source {
        case .phase(let phase):
            return DayArcLayout(phase: phase, metrics: style.metrics, showKerahat: showKerahat, isRightToLeft: isRightToLeft)
        case .day(let times):
            return DayArcLayout(times: times, metrics: style.metrics, showKerahat: showKerahat, isRightToLeft: isRightToLeft)
        }
    }

    /// „3 von 5 Gebetszeiten heute begonnen“; auf der Zeiten-Seite dazu die Kerahat-Zeiten, die im Bogen
    /// nur eingezeichnet sind (`kerahatArc`, Spec § 9.3).
    func accessibilityLabel(for layout: DayArcLayout) -> String {
        let prayers = L10n.arcPrayers(n: layout.begunCount)
        guard style == .home, !layout.kerahat.isEmpty else { return prayers }
        return prayers + " " + L10n.kerahatArc(list: layout.kerahatList)
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
    let kerahatPastOpacity: Double
    let kerahatActiveOpacity: Double
    /// Strichmuster der Kerahat-Abschnitte; `nil` heißt durchgezogen. Auf dem einfarbigen Sperrbildschirm
    /// gestrichelt (`stroke-dasharray: 1.6 1.4`).
    var kerahatDash: [CGFloat]? = nil
    /// Grund unter den Strichen (`.arc-k-base`): Dunkel erscheint auf dem Sperrbildschirm durchsichtig, so
    /// sind die Striche auch auf dem schon gefüllten, weißen Teil der Spur zu sehen.
    var kerahatBase: Color? = nil
    let knob: Color
    let knobStroke: Color
    let knobStrokeWidth: CGFloat
    let knobShadow: ShadowToken?
    /// Strichstärke der Symbole in den Markern (`sw` in `ARCS`, hier als Schriftstärke).
    let symbolWeight: Font.Weight

    /// Seit dem Nachtrag zu Phase 18 hängen die Farben an der Grundfarbe, die gerade gilt (`AccentStore`): Sie
    /// entstehen bei jedem Aufbau neu.
    static var home: DayArcColors {
        DayArcColors(
            track: Palette.arcTrack, done: Palette.accent,
            markerUpcoming: Palette.arcTrack, symbolUpcoming: Palette.accent,
            markerBegun: Palette.accent, symbolBegun: Palette.onAccent,
            glow: Palette.accent.opacity(0.16), ring: Palette.backgroundGrouped,
            time: Palette.textSecondary, timeCurrent: Palette.accent,
            // `.arc-k.on-track`: 0,92, vorbei 0,42, laufend 1 (Spec § 9.3).
            kerahat: Palette.kerahat, kerahatOpacity: 0.92, kerahatPastOpacity: 0.42, kerahatActiveOpacity: 1,
            knob: .white, knobStroke: .black.opacity(0.06), knobStrokeWidth: 0.5, knobShadow: .knob,
            symbolWeight: .bold
        )
    }

    /// `.arc-la` in einem Stil der Live-Aktivität (`--la-*`, Spec § 10.3, § 11.7).
    static func live(_ la: LiveActivityColors) -> DayArcColors {
        DayArcColors(
            track: Color(la.track), done: Color(la.line),
            markerUpcoming: Color(la.marker), symbolUpcoming: Color(la.markerSymbol),
            markerBegun: Color(la.markerBegun), symbolBegun: Color(la.markerBegunSymbol),
            glow: Color(la.glow).opacity(0.22), ring: Color(la.gap),
            time: Color(la.arcTime), timeCurrent: Color(la.foreground),
            // `.arc-la .arc-k.on-track`: 0,95, vorbei 0,5 (auf farbiger Linie 0,85); laufend 1 wie in Spec § 9.3
            // (Phase 14). Im CSS gewinnt für das laufende Fenster die spätere Regel mit 0,95 – der Unterschied ist
            // nicht zu sehen.
            kerahat: Color(la.kerahat), kerahatOpacity: 0.95, kerahatPastOpacity: la.kerahatPastOpacity, kerahatActiveOpacity: 1,
            // Schwarz-weiß: gestreift über Schwarz zu 50 % (`[data-la="mono"] .arc-k-base`, `stroke-dasharray: 2.4 2.2`).
            kerahatDash: la.isMonochrome ? [2.4, 2.2] : nil,
            kerahatBase: la.isMonochrome ? Color.black.opacity(0.5) : nil,
            knob: Color(la.knob), knobStroke: Color(la.knobRing), knobStrokeWidth: 2,
            knobShadow: nil,
            // Die Symbole sind hier nur gut 8 pt groß; erst mit dieser Stärke ist der Strich so kräftig
            // wie im Prototyp (1,15 pt).
            symbolWeight: .heavy
        )
    }

    /// `.arc-acc`: alles Weiß, abgestuft über die Deckkraft; Dunkles (Symbole begonnener Gebete, Mitte des
    /// Knopfes, Ring enger Gebete, Grund von Kerahat) zeigt iOS auf dem Sperrbildschirm durchsichtig.
    static var lockScreen: DayArcColors { DayArcColors(
        track: Palette.LockScreen.track, done: Palette.LockScreen.foreground,
        markerUpcoming: Palette.LockScreen.marker, symbolUpcoming: Palette.LockScreen.foreground,
        markerBegun: Palette.LockScreen.foreground, symbolBegun: Palette.LockScreen.cutOut,
        glow: Palette.LockScreen.glow, ring: Palette.LockScreen.gap,
        time: .clear, timeCurrent: .clear,
        kerahat: Palette.LockScreen.foreground, kerahatOpacity: 0.95, kerahatPastOpacity: 0.5, kerahatActiveOpacity: 1,
        kerahatDash: [1.6, 1.4], kerahatBase: Palette.LockScreen.gap,
        knob: Palette.LockScreen.knob, knobStroke: Palette.LockScreen.foreground, knobStrokeWidth: 1.6,
        knobShadow: nil,
        // Die Symbole sind nur knapp 6 pt groß – wie in der Live-Aktivität kräftig.
        symbolWeight: .heavy
    ) }
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

            if let base = colors.kerahatBase {
                ForEach(layout.kerahat) { window in
                    segment(from: window.start, to: window.end, radius: layout.kerahatRadius)
                        .stroke(base, style: StrokeStyle(lineWidth: metrics.kerahatWidth, lineCap: .butt))
                        .opacity(opacity(of: window))
                }
            }

            ForEach(layout.kerahat) { window in
                segment(from: window.start, to: window.end, radius: layout.kerahatRadius)
                    .stroke(colors.kerahat, style: StrokeStyle(
                        lineWidth: metrics.kerahatWidth, lineCap: metrics.kerahatOnTrack ? .butt : .round,
                        dash: colors.kerahatDash ?? []
                    ))
                    .opacity(opacity(of: window))
            }

            // Der Knopf liegt unter den Markern: Beginnt ein Gebet, verschwindet er unter dessen Marker.
            if layout.showsKnob {
                knob.position(layout.knobCenter)
            }

            ForEach(layout.markers) { marker in
                self.marker(marker).position(marker.center)
            }

            // Im Widget des Sperrbildschirms stehen keine Zeiten (`times: false`).
            ForEach(metrics.showsTimes ? layout.markers : []) { marker in
                Text(L10n.time(marker.time))
                    .font(Typography.arcTime(
                        size: metrics.timeFontSize, isCurrent: marker.state == .current,
                        scales: metrics.timeScales, tabular: metrics.tabularTimes, typeScale: typeScale
                    ))
                    .tracking(Typography.arcTimeTracking)
                    .foregroundStyle(marker.state == .current ? colors.timeCurrent : colors.time)
                    .fixedSize()
                    .position(marker.timeCenter)
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
    }

    private func opacity(of window: DayArcLayout.KerahatSegment) -> Double {
        switch window.state {
        case .upcoming: colors.kerahatOpacity
        case .past: colors.kerahatPastOpacity
        case .active: colors.kerahatActiveOpacity
        }
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
            if marker.state == .current, metrics.glowRadius > 0 {
                Circle()
                    .fill(colors.glow)
                    .frame(width: metrics.glowRadius * 2, height: metrics.glowRadius * 2)
            }
            if marker.isTight, metrics.ringWidth > 0 {
                Circle()
                    .fill(colors.ring)
                    .frame(width: (marker.radius + metrics.ringWidth) * 2, height: (marker.radius + metrics.ringWidth) * 2)
            }
            Circle()
                .fill(begun ? colors.markerBegun : colors.markerUpcoming)
                .frame(width: marker.radius * 2, height: marker.radius * 2)
            if marker.symbolSize > 0 {
                Image(systemName: marker.prayer.symbolName)
                    .font(.system(size: marker.symbolSize * Self.symbolFontScale, weight: colors.symbolWeight))
                    .foregroundStyle(begun ? colors.symbolBegun : colors.symbolUpcoming)
                    .frame(width: marker.symbolSize, height: marker.symbolSize)
            }
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
