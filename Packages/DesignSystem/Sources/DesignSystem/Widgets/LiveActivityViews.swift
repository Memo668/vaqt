import PrayerCore
import SwiftUI

/// Maße, Schriften und Farben der Live-Aktivität – `.la-*` und `.di-*` im CSS des Prototyps.
public enum LiveActivityMetrics {

    // MARK: - Sperrbildschirm (`.la`)

    /// Breite im Prototyp: 390 pt minus je 12 pt links und rechts. Auf dem Gerät gibt iOS die Breite vor.
    public static let lockScreenWidth: CGFloat = 366
    /// Innenabstand (`padding: 11px 14px 8px`).
    public static let lockScreenPadding = EdgeInsets(top: 11, leading: 14, bottom: 8, trailing: 14)
    /// Eckenradius im Prototyp (`border-radius: 24px`) – nur für den Katalog; auf dem Gerät rundet iOS.
    public static let lockScreenRadius: CGFloat = 24
    /// Der Bogen rückt 2 pt an den Kopf heran (`.la-arc`: `margin-top: -2px`).
    public static let arcTop: CGFloat = -2

    /// Kopf: Zeichen und Name der App, rechts die Stadt (`.la-head`: 600 13px/16px, `-.08px`).
    public static let headFont = Font.system(size: 13, weight: .semibold)
    public static let headLineHeight: CGFloat = 16 / 13
    public static let headTracking: CGFloat = -0.08
    /// Zeichen der App im Kopf – `ic('appGlyph', 14)`, 5 pt vor dem Namen.
    public static let glyphSize: CGFloat = 14
    public static let glyphGap: CGFloat = 5
    /// Die Stadt ist schwächer (`.la-city`: `opacity: .72`, 500).
    public static let cityOpacity: Double = 0.72

    /// „Maghrib · 16:27“ im Bogen (`.la-name`: 600 13px/16px, `opacity: .86`).
    public static let nameFont = Font.system(size: 13, weight: .semibold).monospacedDigit()
    public static let nameLineHeight: CGFloat = 16 / 13
    public static let nameOpacity: Double = 0.86
    /// Countdown im Bogen (`.la-count`: 700 30px/1.05, gerundet, `-.3px`).
    public static let countSize: CGFloat = 30
    public static let countFont = Font.system(size: 30, weight: .bold, design: .rounded).monospacedDigit()
    public static let countLineHeight: CGFloat = 1.05
    public static let countTracking: CGFloat = -0.3

    /// Der Verlauf des Hintergrunds (`linear-gradient(160deg, …)`): oben links Akzent zu 82 % auf Weiß,
    /// in der Mitte der helle Akzent, unten rechts Akzent zu 78 % auf Schwarz – in beiden
    /// Erscheinungsbildern, wie `activityBackgroundTint` (Spec § 3).
    public static let backgroundStops: [Gradient.Stop] = [
        .init(color: Color(Palette.Values.accentLight.mixed(0.82, with: .white)), location: 0),
        .init(color: Color(Palette.Values.accentLight), location: 0.5),
        .init(color: Color(Palette.Values.accentLight.mixed(0.78, with: .black)), location: 1),
    ]

    /// Anfang und Ende eines Verlaufs mit dem Winkel des CSS (`160deg`) für eine Fläche dieser Größe: Die
    /// Linie läuft durch die Mitte und ist so lang, dass die Ecken genau auf Anfang und Ende fallen.
    public static func gradientPoints(degrees: Double = 160, size: CGSize) -> (start: UnitPoint, end: UnitPoint) {
        let angle = degrees * .pi / 180
        let dx = sin(angle), dy = -cos(angle)
        let length = abs(size.width * dx) + abs(size.height * dy)
        let half = length / 2
        let start = UnitPoint(x: 0.5 - dx * half / size.width, y: 0.5 - dy * half / size.height)
        let end = UnitPoint(x: 0.5 + dx * half / size.width, y: 0.5 + dy * half / size.height)
        return (start, end)
    }

    /// Höhe im Prototyp ohne iOS: Kopf, Bogen und Abstände – höchstens 160 pt (Spec § 3).
    public static let lockScreenHeight: CGFloat = 155

    // MARK: - Dynamic Island (`.di-*`)

    /// Der dunkle Akzent (`--accent-d`, `#4CC2AE`): Symbol, Zeit und Countdown in der Insel.
    public static let islandAccent = Color(Palette.Values.accentDark)
    /// Symbol links in der kompakten Insel – `ic(…, 18)`.
    public static let compactSymbolBox: CGFloat = 18
    /// Countdown rechts (`.di-cd`: 600 14px/1, `-.2px`).
    public static let compactCountFont = Font.system(size: 14, weight: .semibold).monospacedDigit()
    public static let compactCountTracking: CGFloat = -0.2
    /// So breit darf der Countdown rechts höchstens werden; `Text(timerInterval:)` nähme sonst die ganze
    /// Breite.
    public static let compactCountWidth: CGFloat = 58

    /// Abstand des Inhalts zum linken und rechten Rand der erweiterten Insel (`.di-exp`: `padding: 13px
    /// 24px 16px`). iOS rückt sonst nur 18 pt ein, und die Ecken schneiden die Enden des Balkens an.
    public static let expandedInset: CGFloat = 24
    /// Obere Zeile der erweiterten Insel (`.di-top`: 600 15px/20px, Höhe 26).
    public static let topFont = Font.system(size: 15, weight: .semibold).monospacedDigit()
    public static let topHeight: CGFloat = 26
    /// Symbol und Uhrzeit links (`.di-lead`: `gap: 6px`, `ic(…, 20)`).
    public static let leadSymbolBox: CGFloat = 20
    public static let leadGap: CGFloat = 6
    /// Stadt rechts (`.di-trail`: 500, `opacity: .65`, `gap: 4px`, `ic('locFill', 11)`).
    public static let trailFont = Font.system(size: 15, weight: .medium)
    public static let trailOpacity: Double = 0.65
    public static let trailGap: CGFloat = 4
    public static let locationBox: CGFloat = 11
    /// „Maghrib in“ (`.di-cap`: 500 13px/16px, `opacity: .62`, `margin-top: 8px`).
    public static let captionFont = Font.system(size: 13, weight: .medium)
    public static let captionLineHeight: CGFloat = 16 / 13
    public static let captionOpacity: Double = 0.62
    public static let captionTop: CGFloat = 8
    /// Countdown groß (`.di-big`: 600 38px/1.08, gerundet, `-.4px`).
    public static let bigSize: CGFloat = 38
    public static let bigFont = Font.system(size: 38, weight: .semibold, design: .rounded).monospacedDigit()
    public static let bigLineHeight: CGFloat = 1.08
    public static let bigTracking: CGFloat = -0.4
    /// Balken (`.di-bar`: Höhe 6, Radius 3, `margin-top: 8px`, hinten Weiß zu 18 %).
    public static let barHeight: CGFloat = 6
    public static let barTop: CGFloat = 8
    public static let barTrack = Color.white.opacity(0.18)
    /// Kerahat unter dem Balken (`.di-bar b`: 2 pt hoch, 5 pt unter der Unterkante, `#E0A84F` zu 85 %).
    public static let kerahatHeight: CGFloat = 2
    public static let kerahatDrop: CGFloat = 5
    public static let kerahatColor = Color(RGBA(hex: 0xE0A84F))
    public static let kerahatOpacity: Double = 0.85
    /// Enden des Balkens (`.di-ends`: 500 12px/14px, `opacity: .6`, `margin-top: 8px`).
    public static let endsFont = Font.system(size: 12, weight: .medium).monospacedDigit()
    public static let endsLineHeight: CGFloat = 14 / 12
    public static let endsOpacity: Double = 0.6
    public static let endsTop: CGFloat = 8
}

/// Texte der Live-Aktivität.
public enum LiveActivityTexts {

    /// „Maghrib in“, nach Ischa „Fadschr (morgen) in“ (`laLabel()`); ab Gebetsbeginn nur der Name.
    public static func caption(_ content: LiveActivityContent, hasBegun: Bool) -> String {
        let name = content.prayer.prayer.localizedName
        if hasBegun { return name }
        return content.isTomorrow ? L10n.nextInTomorrow(p: name) : L10n.nextIn(p: name)
    }

    /// „Maghrib · 16:27“ (`.la-name`).
    public static func nameAndTime(_ content: LiveActivityContent) -> String {
        content.prayer.prayer.localizedName + " · " + content.prayerTime.description
    }

    /// „Asr 14:00“ und „Maghrib 16:27“ an den Enden des Balkens (`.di-ends`).
    public static func ends(_ content: LiveActivityContent) -> (start: String, end: String) {
        (
            content.previous.prayer.localizedName + " " + content.previousTime.description,
            content.prayer.prayer.localizedName + " " + content.prayerTime.description
        )
    }
}

/// Der Countdown der Live-Aktivität – oder ab Gebetsbeginn „Jetzt“ (entschieden mit dem Plan für Phase 9).
struct LiveActivityCountdown: View {
    let content: LiveActivityContent
    let hasBegun: Bool

    var body: some View {
        if hasBegun {
            Text(L10n.now)
        } else {
            let end = content.deviceCountdownEnd
            let start = min(content.deviceDate(content.countdown.now), end)
            Text(timerInterval: start...end, countsDown: true)
        }
    }
}

// MARK: - Sperrbildschirm

/// Die Live-Aktivität auf dem Sperrbildschirm: Kopf mit Zeichen, Name der App und Stadt, darunter der
/// Tagesbogen in Weiß auf Akzent, im Bogen „Maghrib · 16:27“ und der Countdown (`laBanner()`; Spec § 3,
/// „Live Activity“, Variante 5h: Akzent-Hintergrund mit Bogen).
///
/// Ab Gebetsbeginn (`isStale`) zeigt der Bogen das Gebet als laufend, und statt des Countdowns steht
/// „Jetzt“. Den Hintergrund setzt `LiveActivityBackground`.
public struct LiveActivityLockScreen: View {
    private let content: LiveActivityContent
    private let hasBegun: Bool

    /// - Parameter isStale: `context.isStale` – das Gebet hat begonnen.
    public init(content: LiveActivityContent, isStale: Bool) {
        self.content = content
        hasBegun = isStale || content.hasBegun
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: LiveActivityMetrics.glyphGap) {
                    AppGlyph()
                        .frame(width: LiveActivityMetrics.glyphSize, height: LiveActivityMetrics.glyphSize)
                        .accessibilityHidden(true)
                    Text(L10n.appName)
                }
                Spacer(minLength: 8)
                Text(content.cityName)
                    .fontWeight(.medium)
                    .opacity(LiveActivityMetrics.cityOpacity)
            }
            .font(LiveActivityMetrics.headFont)
            .tracking(LiveActivityMetrics.headTracking)
            .lineLimit(1)
            .lineHeight(LiveActivityMetrics.headLineHeight, fontSize: 13)

            DayArc(phase: hasBegun ? content.begun : content.countdown, style: .liveActivity, showKerahat: content.showKerahat) {
                VStack(spacing: 0) {
                    Text(LiveActivityTexts.nameAndTime(content))
                        .font(LiveActivityMetrics.nameFont)
                        .opacity(LiveActivityMetrics.nameOpacity)
                        .lineHeight(LiveActivityMetrics.nameLineHeight, fontSize: 13)
                    LiveActivityCountdown(content: content, hasBegun: hasBegun)
                        .font(LiveActivityMetrics.countFont)
                        .tracking(LiveActivityMetrics.countTracking)
                        .multilineTextAlignment(.center)
                        .lineHeight(LiveActivityMetrics.countLineHeight, fontSize: LiveActivityMetrics.countSize)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.top, LiveActivityMetrics.arcTop)
            .frame(maxWidth: .infinity)
        }
        .padding(LiveActivityMetrics.lockScreenPadding)
        .foregroundStyle(.white)
    }
}

/// Der Hintergrund der Live-Aktivität: der Verlauf auf dem hellen Akzent (`.la`).
public struct LiveActivityBackground: View {
    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let points = LiveActivityMetrics.gradientPoints(size: proxy.size)
            LinearGradient(stops: LiveActivityMetrics.backgroundStops, startPoint: points.start, endPoint: points.end)
        }
    }
}

// MARK: - Dynamic Island

/// Kompakt links: das Symbol des Gebets im dunklen Akzent (`diCompact()`).
public struct LiveActivityCompactLeading: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        WidgetSymbol(name: content.prayer.prayer.symbolName, box: LiveActivityMetrics.compactSymbolBox)
            .foregroundStyle(LiveActivityMetrics.islandAccent)
    }
}

/// Kompakt rechts: der Countdown im dunklen Akzent, ab Gebetsbeginn „Jetzt“ (`.di-cd`).
public struct LiveActivityCompactTrailing: View {
    private let content: LiveActivityContent
    private let hasBegun: Bool

    public init(content: LiveActivityContent, isStale: Bool) {
        self.content = content
        hasBegun = isStale || content.hasBegun
    }

    public var body: some View {
        LiveActivityCountdown(content: content, hasBegun: hasBegun)
            .font(LiveActivityMetrics.compactCountFont)
            .tracking(LiveActivityMetrics.compactCountTracking)
            .foregroundStyle(LiveActivityMetrics.islandAccent)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: LiveActivityMetrics.compactCountWidth, alignment: .trailing)
    }
}

/// Minimal: das Symbol des Gebets in einem Ring, der vom vorigen Ereignis bis zum Gebet läuft
/// (Spec § 3: „prayer symbol in a progress ring“).
public struct LiveActivityMinimal: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        ProgressView(
            timerInterval: content.deviceBarInterval, countsDown: false,
            label: { EmptyView() },
            currentValueLabel: {
                WidgetSymbol(name: content.prayer.prayer.symbolName, box: 14)
                    .foregroundStyle(LiveActivityMetrics.islandAccent)
            }
        )
        .progressViewStyle(.circular)
        .tint(LiveActivityMetrics.islandAccent)
    }
}

/// Erweitert, oben links: Symbol und Uhrzeit des Gebets (`.di-lead`).
public struct LiveActivityExpandedLeading: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: LiveActivityMetrics.leadGap) {
            WidgetSymbol(name: content.prayer.prayer.symbolName, box: LiveActivityMetrics.leadSymbolBox)
            Text(content.prayerTime.description)
        }
        .font(LiveActivityMetrics.topFont)
        .foregroundStyle(LiveActivityMetrics.islandAccent)
        .frame(height: LiveActivityMetrics.topHeight)
    }
}

/// Erweitert, oben rechts: die Stadt, beim aktuellen Standort mit Pfeil (`.di-trail`).
public struct LiveActivityExpandedTrailing: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: LiveActivityMetrics.trailGap) {
            if content.isCurrentLocation {
                Image(systemName: "location.fill")
                    .font(.system(size: WidgetMetrics.symbolSize(box: LiveActivityMetrics.locationBox) + 1, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(content.cityName)
                .lineLimit(1)
        }
        .font(LiveActivityMetrics.trailFont)
        .foregroundStyle(.white)
        .opacity(LiveActivityMetrics.trailOpacity)
        .frame(height: LiveActivityMetrics.topHeight)
    }
}

/// Erweitert, unten: „Maghrib in“, der große Countdown, der Balken vom vorigen Ereignis bis zum Gebet mit
/// den Kerahat-Fenstern darunter und die beiden Enden (`diExpanded()`).
public struct LiveActivityExpandedBottom: View {
    private let content: LiveActivityContent
    private let hasBegun: Bool

    public init(content: LiveActivityContent, isStale: Bool) {
        self.content = content
        hasBegun = isStale || content.hasBegun
    }

    public var body: some View {
        let ends = LiveActivityTexts.ends(content)
        VStack(alignment: .leading, spacing: 0) {
            Text(LiveActivityTexts.caption(content, hasBegun: hasBegun))
                .font(LiveActivityMetrics.captionFont)
                .opacity(LiveActivityMetrics.captionOpacity)
                .lineHeight(LiveActivityMetrics.captionLineHeight, fontSize: 13)
            LiveActivityCountdown(content: content, hasBegun: hasBegun)
                .font(LiveActivityMetrics.bigFont)
                .tracking(LiveActivityMetrics.bigTracking)
                .foregroundStyle(LiveActivityMetrics.islandAccent)
                .lineHeight(LiveActivityMetrics.bigLineHeight, fontSize: LiveActivityMetrics.bigSize)
            LiveActivityBar(content: content)
                .padding(.top, LiveActivityMetrics.barTop)
            HStack {
                Text(ends.start)
                Spacer(minLength: 8)
                Text(ends.end)
            }
            .font(LiveActivityMetrics.endsFont)
            .opacity(LiveActivityMetrics.endsOpacity)
            .lineHeight(LiveActivityMetrics.endsLineHeight, fontSize: 12)
            .padding(.top, LiveActivityMetrics.endsTop)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Der Balken der erweiterten Insel: läuft von selbst vom vorigen Ereignis bis zum Gebet; darunter dünn
/// die Kerahat-Fenster dieser Strecke (`.di-bar`).
struct LiveActivityBar: View {
    let content: LiveActivityContent

    var body: some View {
        ProgressView(timerInterval: content.deviceBarInterval, countsDown: false, label: { EmptyView() }, currentValueLabel: { EmptyView() })
            .progressViewStyle(.linear)
            .tint(LiveActivityMetrics.islandAccent)
            .frame(height: LiveActivityMetrics.barHeight)
            .overlay(alignment: .topLeading) {
                if content.showKerahat, !content.kerahat.isEmpty {
                    GeometryReader { proxy in
                        ForEach(Array(content.kerahat.enumerated()), id: \.offset) { _, mark in
                            Capsule()
                                .fill(LiveActivityMetrics.kerahatColor)
                                .opacity(LiveActivityMetrics.kerahatOpacity)
                                .frame(width: proxy.size.width * mark.length, height: LiveActivityMetrics.kerahatHeight)
                                .offset(
                                    x: proxy.size.width * mark.start,
                                    y: proxy.size.height + LiveActivityMetrics.kerahatDrop - LiveActivityMetrics.kerahatHeight
                                )
                        }
                    }
                    .flipsForRightToLeftLayoutDirection(true)
                    .accessibilityHidden(true)
                }
            }
    }
}
