import PrayerCore
import SwiftUI

/// Der Kompass der Qibla-Seite: eine Skala mit Strichen alle 5°, Zahlen alle 30° und den vier
/// Himmelsrichtungen, das „N“ in Rot. Die Skala dreht sich mit dem Kurs des Geräts; Zahlen und
/// Buchstaben bleiben dabei aufrecht. Eine Nadel in Akzent zeigt zur Kaaba, außen an der Skala sitzt
/// die Kaaba-Marke, um die Nadel ein Keil für den Toleranzbereich von ±40° (Spec § 9.5). Oben steht fest
/// die Peilmarke – zeigt das Gerät zur Qibla, wird sie Akzent und ein Ring läuft einmal nach außen.
///
/// Der Kompass wird nie gespiegelt, auch nicht bei RTL (Design Spec § 5). Er ist Bild, nicht Text: Was
/// er zeigt, sagen Kursanzeige, Statuszeile und Info-Zeile der Seite; für VoiceOver ist er ausgeblendet.
/// Design Spec § 3 („Compass“), `dialSVG()` und `.compass` im Prototyp.
public struct Compass: View {
    private let heading: Double?
    private let bearing: Double?
    private let isAligned: Bool
    private let isWithinToleranceRange: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let layout = CompassLayout()

    /// - Parameters:
    ///   - heading: Kurs des Geräts in Grad ab Nord im Uhrzeigersinn. Ohne Kurs – ein Gerät ohne
    ///     Kompass – steht die Skala fest mit Norden oben, und die Peilmarke fehlt.
    ///   - bearing: Richtung zur Kaaba in Grad ab Nord im Uhrzeigersinn. Ohne Richtung – in Mekka oder
    ///     solange kein Ort gilt – fehlen Nadel und Kaaba-Marke.
    ///   - isAligned: ob das Gerät zur Qibla zeigt.
    ///   - isWithinToleranceRange: ob das Gerät im Toleranzbereich ±40° zeigt; dann ist der Keil kräftiger.
    public init(heading: Double?, bearing: Double?, isAligned: Bool = false, isWithinToleranceRange: Bool = false) {
        self.heading = heading
        self.bearing = bearing
        self.isAligned = isAligned
        self.isWithinToleranceRange = isWithinToleranceRange
    }

    public var body: some View {
        let rotation = heading ?? 0
        ZStack(alignment: .topLeading) {
            dial(rotation: rotation)
                .rotationEffect(.degrees(-rotation))

            if heading != nil {
                Capsule()
                    .fill(isAligned ? Palette.accent : Palette.label)
                    .frame(width: CompassMetrics.lubberSize.width, height: CompassMetrics.lubberSize.height)
                    .position(CompassLayout.lubberCenter)
                    .animation(.easeInOut(duration: CompassMetrics.alignedTransition), value: isAligned)
            }

            Circle()
                .fill(Palette.label)
                .frame(width: CompassMetrics.centerDotDiameter, height: CompassMetrics.centerDotDiameter)
                .position(CompassLayout.center)
        }
        .frame(width: CompassMetrics.diameter, height: CompassMetrics.diameter)
        .background {
            CompassPulse(isAligned: isAligned, isEnabled: !reduceMotion)
        }
        // Skala, Zahlen und Nadel werden nicht gespiegelt.
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    /// Die Skala mit Norden oben, samt Nadel und Kaaba-Marke. Sie dreht sich als Ganzes um den Kurs;
    /// Beschriftung und Kaaba-Marke drehen sich in ihr zurück und bleiben so aufrecht.
    private func dial(rotation: Double) -> some View {
        ZStack(alignment: .topLeading) {
            // Der Toleranzbereich unter allem anderen (Spec § 9.5): ein Keil um die Richtung zur Kaaba.
            if let bearing {
                ZStack(alignment: .topLeading) {
                    CompassToleranceWedge()
                        .fill(Palette.accent.opacity(
                            isWithinToleranceRange ? CompassMetrics.toleranceFillInside : CompassMetrics.toleranceFill
                        ))
                        .animation(.easeInOut(duration: CompassMetrics.alignedTransition), value: isWithinToleranceRange)
                    CompassToleranceEdges()
                        .stroke(
                            Palette.accent.opacity(CompassMetrics.toleranceEdgeOpacity),
                            style: StrokeStyle(
                                lineWidth: CompassMetrics.toleranceEdgeWidth * CompassMetrics.scale,
                                dash: CompassMetrics.toleranceEdgeDash.map { $0 * CompassMetrics.scale }
                            )
                        )
                }
                .frame(width: CompassMetrics.diameter, height: CompassMetrics.diameter)
                .rotationEffect(.degrees(bearing))
            }

            CompassTicks(layout: Self.layout, isMajor: false)
                .stroke(Palette.labelTertiary, lineWidth: CompassMetrics.tickWidth * CompassMetrics.scale)
            CompassTicks(layout: Self.layout, isMajor: true)
                .stroke(Palette.textSecondary, lineWidth: CompassMetrics.majorTickWidth * CompassMetrics.scale)

            ForEach(Self.layout.labels) { label in
                self.label(label)
                    .rotationEffect(.degrees(rotation))
                    .position(label.center)
            }

            if let bearing {
                ZStack(alignment: .topLeading) {
                    CompassNeedle()
                        .stroke(
                            Palette.accent,
                            style: StrokeStyle(
                                lineWidth: CompassMetrics.needleWidth * CompassMetrics.scale, lineCap: .round
                            )
                        )
                    CompassNeedleHead()
                        .fill(Palette.accent)
                    KaabaMark()
                        .rotationEffect(.degrees(rotation - bearing))
                        .position(CompassLayout.kaabaCenter)
                }
                .frame(width: CompassMetrics.diameter, height: CompassMetrics.diameter)
                .rotationEffect(.degrees(bearing))
            }
        }
        .frame(width: CompassMetrics.diameter, height: CompassMetrics.diameter)
    }

    /// Eine Beschriftung: die Himmelsrichtung kräftig und in Schriftfarbe, das „N“ in Rot; die Zahlen
    /// kleiner und in Sekundärfarbe (`.lbl`, `.lbl.card`, `.lbl.north`).
    private func label(_ label: CompassLayout.Label) -> some View {
        Group {
            if let point = label.point {
                Text(point.localizedAbbreviation)
                    .font(.system(size: CompassMetrics.cardinalFontSize * CompassMetrics.scale, weight: .semibold))
                    .foregroundStyle(point == .north ? Palette.red : Palette.label)
            } else {
                Text(String(label.degrees))
                    .font(.system(size: CompassMetrics.numberFontSize * CompassMetrics.scale, weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .fixedSize()
    }
}

// MARK: - Teile

/// Der Keil des Toleranzbereichs mit der Qibla oben: von der Mitte bis Radius 144, 40° zu jeder Seite.
struct CompassToleranceWedge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CompassLayout.center
        let half = CompassMetrics.toleranceDegrees
        path.move(to: center)
        path.addLine(to: CompassLayout.point(degrees: -half, radius: CompassMetrics.toleranceOuterRadius))
        // Oben ist −90° im Koordinatensystem der Ansicht; im Uhrzeigersinn heißt hier `clockwise: false`.
        path.addArc(
            center: center, radius: CompassMetrics.toleranceOuterRadius * CompassMetrics.scale,
            startAngle: .degrees(-90 - half), endAngle: .degrees(-90 + half), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

/// Die beiden gestrichelten Kanten des Keils, von Radius 22 bis 144.
struct CompassToleranceEdges: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for side in [-1.0, 1.0] {
            let degrees = side * CompassMetrics.toleranceDegrees
            path.move(to: CompassLayout.point(degrees: degrees, radius: CompassMetrics.toleranceEdgeInnerRadius))
            path.addLine(to: CompassLayout.point(degrees: degrees, radius: CompassMetrics.toleranceOuterRadius))
        }
        return path
    }
}

/// Die Striche der Skala, wahlweise die kurzen oder die langen.
struct CompassTicks: Shape {
    let layout: CompassLayout
    let isMajor: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for tick in layout.ticks where tick.isMajor == isMajor {
            path.move(to: tick.start)
            path.addLine(to: tick.end)
        }
        return path
    }
}

/// Der Schaft der Nadel, mit der Qibla oben.
struct CompassNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CompassLayout.needle.start)
        path.addLine(to: CompassLayout.needle.end)
        return path
    }
}

/// Die Spitze der Nadel, mit der Qibla oben.
struct CompassNeedleHead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(CompassLayout.needleHead)
        path.closeSubpath()
        return path
    }
}

/// Die Kaaba-Marke: ein Quadrat in Schriftfarbe mit einem Band in Akzent.
struct KaabaMark: View {
    var body: some View {
        let size = CompassMetrics.kaabaSize * CompassMetrics.scale
        RoundedRectangle(cornerRadius: CompassMetrics.kaabaCornerRadius * CompassMetrics.scale)
            .fill(Palette.label)
            .frame(width: size, height: size)
            .overlay {
                Rectangle()
                    .fill(Palette.accent)
                    .frame(height: CompassMetrics.kaabaBandWidth * CompassMetrics.scale)
                    .offset(y: CompassMetrics.kaabaBandOffset * CompassMetrics.scale)
            }
    }
}

/// Der Ring, der einmal vom Rand des Kompasses nach außen läuft, sobald das Gerät zur Qibla zeigt
/// (`.compass.pulse`). Bei „Bewegung reduzieren“ bleibt er aus.
private struct CompassPulse: View {
    let isAligned: Bool
    let isEnabled: Bool

    /// Zählt, wie oft das Gerät ausgerichtet wurde; jeder Schritt löst den Ring einmal aus.
    @State private var count = 0

    private struct Frame {
        var spread: CGFloat = 0
        var opacity: Double = 0
    }

    var body: some View {
        Color.clear
            .keyframeAnimator(initialValue: Frame(), trigger: count) { content, frame in
                content.overlay {
                    // Ein Band der Breite `spread`, das am Rand des Kompasses beginnt.
                    Circle()
                        .stroke(Palette.accent.opacity(frame.opacity), lineWidth: frame.spread)
                        .padding(-frame.spread / 2)
                }
            } keyframes: { _ in
                KeyframeTrack(\.spread) {
                    MoveKeyframe(0)
                    LinearKeyframe(
                        CompassMetrics.pulseSpread, duration: CompassMetrics.pulseDuration, timingCurve: .easeOut
                    )
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(CompassMetrics.pulseOpacity)
                    LinearKeyframe(0, duration: CompassMetrics.pulseDuration, timingCurve: .easeOut)
                }
            }
            .onChange(of: isAligned) { _, isAligned in
                if isAligned, isEnabled {
                    count += 1
                }
            }
            .allowsHitTesting(false)
    }
}

extension CompassPoint {

    /// Abkürzung der Himmelsrichtung aus dem String Catalog (`dirs`): „N“, „NO“, „O“ …
    public var localizedAbbreviation: String {
        L10n.text("dirs.\(rawValue)")
    }
}
