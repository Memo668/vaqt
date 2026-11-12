import SwiftUI

/// Die Karte des Adhan-Players: Stimme, „Kurzer Adhan · für Mitteilungen“, Wellenform, Scrubber, Zeiten
/// und der runde Play-Knopf – `.player` in `adhanSheet()` im Prototyp (Spec § 3, „Adhan player“).
public struct AdhanPlayerCard: View {
    private let title: String
    private let subtitle: String
    private let position: TimeInterval
    private let duration: TimeInterval
    private let isPlaying: Bool
    private let onSeek: (TimeInterval) -> Void
    private let onToggle: () -> Void

    /// - Parameters:
    ///   - title: „Stimme 1 · Makkah“.
    ///   - subtitle: „Kurzer Adhan · für Mitteilungen“, mit der Fadschr-Variante „… · Fadschr-Variante“.
    ///   - position: gespielte Sekunden.
    ///   - duration: Länge des Ausschnitts, höchstens 30 Sekunden.
    public init(
        title: String, subtitle: String, position: TimeInterval, duration: TimeInterval, isPlaying: Bool,
        onSeek: @escaping (TimeInterval) -> Void, onToggle: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.position = position
        self.duration = duration
        self.isPlaying = isPlaying
        self.onSeek = onSeek
        self.onToggle = onToggle
    }

    public var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .tracking(AdhanPlayerMetrics.titleTracking)
                .textStyle(.title3, weight: .semibold, lineHeight: AdhanPlayerMetrics.titleLineHeight)
                .foregroundStyle(Palette.label)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .tracking(AdhanPlayerMetrics.subtitleTracking)
                .font(TypeScale.subheadline.font())
                .foregroundStyle(Palette.textSecondary)
                .padding(.top, AdhanPlayerMetrics.subtitleTop)
            AdhanWaveform(progress: progress, isPlaying: isPlaying)
                .frame(height: AdhanPlayerMetrics.waveHeight)
                .padding(.top, AdhanPlayerMetrics.waveTop)
                .padding(.bottom, AdhanPlayerMetrics.waveBottom)
            Slider(value: Binding(get: { position }, set: onSeek), in: 0...max(duration, 0.1))
                .tint(Palette.accent)
                .frame(height: AdhanPlayerMetrics.scrubberHeight)
                .accessibilityLabel(L10n.progress)
                .accessibilityValue("\(AdhanTime.text(position)) / \(AdhanTime.text(duration))")
            HStack {
                Text(AdhanTime.text(position))
                Spacer()
                Text("\u{2212}" + AdhanTime.text(max(0, duration - position)))
            }
            .font(TypeScale.caption1.font(weight: .medium))
            .monospacedDigit()
            .foregroundStyle(Palette.textSecondary)
            .padding(.top, AdhanPlayerMetrics.timesTop)
            .accessibilityHidden(true)
            PlayPauseButton(isPlaying: isPlaying, action: onToggle)
                .padding(.top, AdhanPlayerMetrics.playTop)
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, AdhanPlayerMetrics.paddingY)
        .padding(.horizontal, AdhanPlayerMetrics.paddingX)
        .frame(maxWidth: .infinity)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.playerCard, style: .continuous))
    }

    private var progress: Double {
        duration > 0 ? min(1, max(0, position / duration)) : 0
    }
}

/// Die Wellenform: 44 Balken, der gespielte Teil in Akzent. Beim Abspielen schwingen die Balken, jeder
/// mit eigener Verzögerung (`@keyframes wv`); bei „Bewegung reduzieren“ stehen sie still. Für VoiceOver
/// ist sie ausgeblendet – was sie zeigt, sagt der Scrubber.
public struct AdhanWaveform: View {
    private let progress: Double
    private let isPlaying: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(progress: Double, isPlaying: Bool) {
        self.progress = progress
        self.isPlaying = isPlaying
    }

    public var body: some View {
        if isPlaying && !reduceMotion {
            TimelineView(.animation) { context in
                bars(time: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            bars(time: nil)
        }
    }

    /// Die Balken; `time` ist die Zeit der Schwingung, `nil` ohne Schwingung.
    private func bars(time: TimeInterval?) -> some View {
        let played = AdhanWaveformLayout.playedBars(progress: progress)
        return GeometryReader { proxy in
            let layout = AdhanWaveformLayout(width: proxy.size.width)
            ZStack(alignment: .topLeading) {
                ForEach(0..<AdhanWaveformLayout.barCount, id: \.self) { index in
                    let scale = time.map { AdhanWaveformLayout.swing(bar: index, at: $0) } ?? AdhanWaveformLayout.restScale
                    let height = AdhanWaveformLayout.heights[index] * proxy.size.height * scale
                    RoundedRectangle(cornerRadius: AdhanWaveformLayout.barRadius)
                        .fill(index < played ? Palette.accent : Palette.labelQuaternary)
                        .frame(width: AdhanWaveformLayout.barWidth, height: height)
                        .position(x: layout.centerX(of: index), y: proxy.size.height / 2)
                }
            }
        }
        // Rechts nach links spiegelt SwiftUI die Balken mit: Der gespielte Teil wächst dann wie der
        // Scrubber von rechts.
        .accessibilityHidden(true)
    }
}

/// Die Geometrie der Wellenform – `adhanSheet()` im Prototyp: 44 Balken, je 4 pt breit (`max-width: 4px`),
/// über die ganze Breite verteilt (`justify-content: space-between`), Höhe nach der Formel des Prototyps.
public struct AdhanWaveformLayout: Sendable {
    public static let barCount = 44
    public static let barWidth: CGFloat = 4
    public static let barRadius: CGFloat = 2
    /// In Ruhe stehen die Balken auf 62 % ihrer Höhe (`transform: scaleY(.62)`).
    public static let restScale: CGFloat = 0.62
    /// Eine Schwingung dauert 1,15 s, zwischen 50 % und 100 % der Höhe (`@keyframes wv`).
    public static let swingPeriod: TimeInterval = 1.15

    /// Höhe jedes Balkens als Anteil der Wellenform:
    /// `env = sin(π(i + .5)/N)^.6; h = .18 + .82·env·(.45 + .55·|sin(1,93 i)·cos(0,71 i)|)`.
    public static let heights: [CGFloat] = (0..<barCount).map { index in
        let i = Double(index)
        let envelope = pow(sin(Double.pi * (i + 0.5) / Double(barCount)), 0.6)
        return CGFloat(0.18 + 0.82 * envelope * (0.45 + 0.55 * abs(sin(i * 1.93) * cos(i * 0.71))))
    }

    /// Wie viele Balken als gespielt gelten (`Math.floor(pos/dur*N)`).
    public static func playedBars(progress: Double) -> Int {
        Int((min(1, max(0, progress)) * Double(barCount)).rounded(.down))
    }

    /// Höhe eines Balkens beim Abspielen, 0,5 bis 1: Jeder beginnt um `(97 i mod 1100) ms` versetzt
    /// (`--dl`), die Schwingung ist weich wie `ease-in-out`.
    public static func swing(bar index: Int, at time: TimeInterval) -> CGFloat {
        let offset = Double((index * 97) % 1100) / 1000
        let phase = ((time + offset).truncatingRemainder(dividingBy: swingPeriod)) / swingPeriod
        return CGFloat(0.5 + 0.5 * (1 - cos(2 * Double.pi * phase)) / 2)
    }

    public let width: CGFloat

    public init(width: CGFloat) {
        self.width = width
    }

    /// Mitte eines Balkens: der erste am Anfang, der letzte am Ende, dazwischen gleiche Abstände.
    public func centerX(of index: Int) -> CGFloat {
        let gap = (width - CGFloat(Self.barCount) * Self.barWidth) / CGFloat(Self.barCount - 1)
        return CGFloat(index) * (Self.barWidth + gap) + Self.barWidth / 2
    }
}

/// Der runde Knopf zum Abspielen und Anhalten: 72 pt, Akzent (`.play-btn`).
public struct PlayPauseButton: View {
    private let isPlaying: Bool
    private let action: () -> Void

    public init(isPlaying: Bool, action: @escaping () -> Void) {
        self.isPlaying = isPlaying
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: AdhanPlayerMetrics.playSymbolSize))
                .foregroundStyle(Palette.onAccent)
                .frame(width: AdhanPlayerMetrics.playSize, height: AdhanPlayerMetrics.playSize)
                .background(Palette.accent, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(PlayButtonStyle())
        .accessibilityLabel(isPlaying ? L10n.pause : L10n.play)
    }
}

/// Gedrückt etwas kleiner (`.play-btn:active { transform: scale(.9) }`).
private struct PlayButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.9 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Minuten und Sekunden wie `fmtDur()` im Prototyp: „0:27“.
public enum AdhanTime {
    public static func text(_ seconds: TimeInterval) -> String {
        let whole = Int(max(0, seconds).rounded(.down))
        return "\(whole / 60):" + String(format: "%02d", whole % 60)
    }
}

/// Maße der Karte (`.player`, `.player-title`, `.player-sub`, `.wave`, `.scrub`, `.times`, `.play-btn`).
public enum AdhanPlayerMetrics {
    /// `.player { margin: 4px 16px 30px; padding: 22px 18px }`
    public static let marginTop: CGFloat = 4
    public static let marginBottom: CGFloat = 30
    static let paddingY: CGFloat = 22
    static let paddingX: CGFloat = 18
    /// `.player-title { font: 600 var(--fs-title3)/1.25; letter-spacing: .38px }`
    static let titleLineHeight: CGFloat = 1.25
    static let titleTracking: CGFloat = 0.38
    /// `.player-sub { margin-top: 3px; letter-spacing: -.24px }`
    static let subtitleTop: CGFloat = 3
    static let subtitleTracking: CGFloat = -0.24
    /// `.wave { height: 64px; margin: 22px 0 14px }`
    static let waveHeight: CGFloat = 64
    static let waveTop: CGFloat = 22
    static let waveBottom: CGFloat = 14
    /// `.scrub { height: 22px }`, `.times { margin-top: 4px }`
    static let scrubberHeight: CGFloat = 22
    static let timesTop: CGFloat = 4
    /// `.play-btn { width: 72px; height: 72px; margin: 16px auto 0 }`, `ic('play', 30)`
    static let playTop: CGFloat = 16
    static let playSize: CGFloat = 72
    static let playSymbolSize: CGFloat = 26
}
