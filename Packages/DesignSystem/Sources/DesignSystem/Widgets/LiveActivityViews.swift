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

    /// Kopf: App-Symbol und Name der App, rechts die Stadt (`.la-head`: 600 13px/16px, `-.08px`).
    public static let headFont = Font.system(size: 13, weight: .semibold)
    public static let headLineHeight: CGFloat = 16 / 13
    public static let headTracking: CGFloat = -0.08
    /// Das App-Symbol steht 5 pt vor dem Namen (`.la-app`: `gap: 5px`); Größe in `AppMark.Size.header`.
    public static let iconGap: CGFloat = 5
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

    /// Deckkraft des Verlaufs von Live-Aktivität und Widget „Live“: 30 %, damit Hintergrundbild und Unschärfe
    /// des Systems durchscheinen (Spec § 10.3, § 10.4; `--la-pct: 30%`).
    public static let backgroundOpacity: Double = 0.3
    /// Deckkraft im Widget „Live“: voll. iOS legt unter `containerBackground` eine eigene helle bzw. dunkle Fläche
    /// statt des Hintergrundbilds; mit 30 % wurde das Widget blass und die weiße Schrift schwer lesbar
    /// (Simulator, 18.11.2026). Spec § 10.4 lässt das offen; die Entscheidung liegt beim Nutzer.
    public static let liveWidgetBackgroundOpacity: Double = 1

    /// Der Verlauf in der Verbotszeit (`.la.is-kerahat`, `--k-or: #EC8530`): oben links Orange zu 80 % auf Weiß,
    /// in der Mitte das Orange, unten rechts zu 76 % auf Schwarz (Spec § 10.3).
    public static let prohibitedStops: [Gradient.Stop] = [
        .init(color: Color(Palette.Values.liveActivityProhibited.mixed(0.80, with: .white)), location: 0),
        .init(color: Color(Palette.Values.liveActivityProhibited), location: 0.5),
        .init(color: Color(Palette.Values.liveActivityProhibited.mixed(0.76, with: .black)), location: 1),
    ]

    /// Die schmale Zeile einer abgelaufenen Aktivität (`.la-compact`): 11 pt oben und unten, 14 pt seitlich,
    /// 13 pt halbfett (Spec § 10.3).
    public static let endedPadding = EdgeInsets(top: 11, leading: 14, bottom: 11, trailing: 14)

    /// Höhe im Prototyp ohne iOS: Kopf, Bogen und Abstände – höchstens 160 pt (Spec § 3).
    public static let lockScreenHeight: CGFloat = 155

    // MARK: - Dynamic Island (`.di-*`)

    /// Der dunkle Akzent (`--accent-d`, `#4CC2AE`): Symbol, Zeit und Countdown in der Insel.
    public static let islandAccent = Color(Palette.Values.accentDark)
    /// Die Farbe der Insel: in der Verbotszeit Orange (`#F0A257`, Spec § 10.3), sonst der dunkle Akzent.
    public static func islandAccent(_ content: LiveActivityContent) -> Color {
        content.isProhibited ? Palette.LiveActivity.islandProhibited : islandAccent
    }
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
    /// Die Enden rücken weiter ein als der Balken – im Prototyp stehen sie bündig mit ihm. iOS schneidet den
    /// Inhalt der erweiterten Insel unten an den runden Ecken ab, auf Höhe dieser Zeile gut 25 pt vom Rand;
    /// mit `expandedInset` allein fehlte dem „A“ von „Asr“ und der letzten Ziffer rechts ein Stück (gemessen
    /// auf dem iPhone 18 Pro mit iOS 27.2 am 16.11.2026).
    public static let endsInset: CGFloat = 8
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
        content.prayer.prayer.localizedName + " · " + L10n.time(content.prayerTime)
    }

    /// „Asr 14:00“ und „Maghrib 16:27“ an den Enden des Balkens (`.di-ends`).
    public static func ends(_ content: LiveActivityContent) -> (start: String, end: String) {
        (
            content.previous.prayer.localizedName + " " + L10n.time(content.previousTime),
            content.prayer.prayer.localizedName + " " + L10n.time(content.prayerTime)
        )
    }
}

/// Der Countdown der Live-Aktivität. Nach dem Wechsel steht die Uhrzeit des Gebets – „Jetzt“ gibt es seit
/// Spec § 10.3 nicht mehr.
struct LiveActivityCountdown: View {
    let content: LiveActivityContent
    let hasBegun: Bool

    var body: some View {
        if hasBegun {
            Text(L10n.time(content.prayerTime))
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
/// In der Verbotszeit ist sie orange, und im Kopf steht „Verbotszeit bis 16:27“ statt der Stadt. Nach ihrem
/// Wechsel (`isStale`: Gebetsbeginn oder Beginn der Verbotszeit) schrumpft sie auf eine schmale Zeile
/// (`LiveActivityEndedRow`, Spec § 10.3). Den Hintergrund setzt `LiveActivityBackground`.
public struct LiveActivityLockScreen: View {
    private let content: LiveActivityContent
    private let hasEnded: Bool

    /// - Parameter isStale: `context.isStale` – die Aktivität hat gewechselt.
    public init(content: LiveActivityContent, isStale: Bool) {
        self.content = content
        hasEnded = isStale || content.hasBegun
    }

    public var body: some View {
        if hasEnded {
            LiveActivityEndedRow(content: content)
        } else {
            running
        }
    }

    private var running: some View {
        VStack(spacing: 0) {
            LiveHeader(
                trailing: content.isProhibited ? content.prohibitedHeader : content.cityName,
                isEmphasized: content.isProhibited
            )

            DayArc(phase: content.countdown, style: content.isProhibited ? .liveActivityProhibited : .liveActivity,
                   showKerahat: content.showKerahat) {
                VStack(spacing: 0) {
                    Text(LiveActivityTexts.nameAndTime(content))
                        .font(LiveActivityMetrics.nameFont)
                        .opacity(LiveActivityMetrics.nameOpacity)
                        .lineHeight(LiveActivityMetrics.nameLineHeight, fontSize: 13)
                    LiveActivityCountdown(content: content, hasBegun: false)
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

/// Eine abgelaufene Aktivität als schmale Zeile (`.la-compact`, Spec § 10.3): App-Symbol, „Asr · 14:27“ und
/// rechts „hat begonnen“ – beim grünen Teil vor einer Verbotszeit „Verbotszeit ab 11:42“.
public struct LiveActivityEndedRow: View {
    private let content: LiveActivityContent

    public init(content: LiveActivityContent) {
        self.content = content
    }

    public var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: LiveActivityMetrics.iconGap) {
                AppMark(size: .header)
                    .environment(\.colorScheme, .light)
                Text(LiveActivityTexts.nameAndTime(content))
            }
            Spacer(minLength: 8)
            Text(trailing)
                .fontWeight(.medium)
                .opacity(LiveActivityMetrics.cityOpacity)
        }
        .font(LiveActivityMetrics.headFont)
        .tracking(LiveActivityMetrics.headTracking)
        .lineLimit(1)
        .foregroundStyle(.white)
        .padding(LiveActivityMetrics.endedPadding)
        .accessibilityElement(children: .combine)
    }

    private var trailing: String {
        if content.kind == .beforeProhibited, let start = content.prohibitedStartTime {
            return L10n.kerahatFrom(a: L10n.time(start))
        }
        return L10n.laBegan
    }
}

extension LiveActivityContent {
    /// „Verbotszeit bis 16:27“ im Kopf der orangen Aktivität (`kerahatNow`).
    var prohibitedHeader: String {
        L10n.kerahatNow(b: L10n.time(prayerTime))
    }
}

/// Kopf der Live-Aktivität und des Widgets „Live“: App-Symbol und Name der App, rechts die Stadt – oder in der
/// Verbotszeit „Verbotszeit bis …“ (`.la-head`; Spec § 9.1, § 10.3).
struct LiveHeader: View {
    let trailing: String
    var isEmphasized = false

    init(cityName: String) {
        trailing = cityName
    }

    init(trailing: String, isEmphasized: Bool) {
        self.trailing = trailing
        self.isEmphasized = isEmphasized
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: LiveActivityMetrics.iconGap) {
                // Immer die helle Fassung mit Kachel: Der Akzentverlauf dahinter ist in beiden
                // Erscheinungsbildern derselbe, und iOS zeichnet die Live-Aktivität auf dem Sperrbildschirm auch
                // im hellen System dunkel. Die dunkle Fassung ist durchsichtig und verschwände fast (Phase 14).
                AppMark(size: .header)
                    .environment(\.colorScheme, .light)
                Text(L10n.appName)
            }
            Spacer(minLength: 8)
            Text(trailing)
                .fontWeight(isEmphasized ? .semibold : .medium)
                .opacity(isEmphasized ? 1 : LiveActivityMetrics.cityOpacity)
        }
        .font(LiveActivityMetrics.headFont)
        .tracking(LiveActivityMetrics.headTracking)
        .lineLimit(1)
        .lineHeight(LiveActivityMetrics.headLineHeight, fontSize: 13)
    }
}

/// Der Hintergrund der Live-Aktivität und des Widgets „Live“: der Verlauf auf dem hellen Akzent (`.la`), in der
/// Verbotszeit auf Orange, mit 30 % Deckkraft (Spec § 10.3, § 10.4).
public struct LiveActivityBackground: View {
    private let isProhibited: Bool
    private let opacity: Double

    public init(isProhibited: Bool = false, opacity: Double = LiveActivityMetrics.backgroundOpacity) {
        self.isProhibited = isProhibited
        self.opacity = opacity
    }

    public var body: some View {
        GeometryReader { proxy in
            let points = LiveActivityMetrics.gradientPoints(size: proxy.size)
            LinearGradient(
                stops: isProhibited ? LiveActivityMetrics.prohibitedStops : LiveActivityMetrics.backgroundStops,
                startPoint: points.start, endPoint: points.end
            )
            .opacity(opacity)
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
            .foregroundStyle(LiveActivityMetrics.islandAccent(content))
            // VoiceOver: der Name des Gebets vor dem Countdown rechts, statt nur „2:01:29“ (Phase 11).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(content.prayer.prayer.localizedName)
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
            .foregroundStyle(LiveActivityMetrics.islandAccent(content))
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
                    .foregroundStyle(LiveActivityMetrics.islandAccent(content))
            }
        )
        .progressViewStyle(.circular)
        .tint(LiveActivityMetrics.islandAccent(content))
        // VoiceOver: der Name des Gebets statt eines namenlosen Rings (Phase 11).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(content.prayer.prayer.localizedName)
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
            Text(L10n.time(content.prayerTime))
        }
        .font(LiveActivityMetrics.topFont)
        .foregroundStyle(LiveActivityMetrics.islandAccent(content))
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
                .foregroundStyle(LiveActivityMetrics.islandAccent(content))
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
            .padding(.horizontal, LiveActivityMetrics.endsInset)
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
            .tint(LiveActivityMetrics.islandAccent(content))
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
