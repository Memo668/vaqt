#if DEBUG

import PrayerCore
import SwiftUI

/// Widgets und Live-Aktivität im Katalog – zum Abgleich mit `system/90`, `91` und `93`–`96` (seit Phase 14
/// mit dem Widget „Live“ und dem Rechteck mit Mini-Bogen, Spec § 9.11), seit Phase 19 mit der Live-Aktivität „klein“
/// und den kleinen Widgets ohne Hintergrund (`carplay/cp-40`–`cp-52`, Spec § 12).
///
/// Der Katalog zeigt die Ansichten der Extension in den Maßen des Prototyps auf einem Hintergrund wie
/// `.wall`. Was iOS selbst zeichnet – Fläche, Ecken und Schatten der Widgets, die Form der Dynamic Island,
/// der Sperrbildschirm –, ist hier nur nachgestellt.
public struct CatalogOutsideState: Sendable {
    public let widget: PrayerWidgetContent
    public let liveActivity: LiveActivityContent?

    public init(widget: PrayerWidgetContent, liveActivity: LiveActivityContent?) {
        self.widget = widget
        self.liveActivity = liveActivity
    }

    /// Der Stand zu einem Zeitpunkt der App-Uhr: der Eintrag der Zeitleiste für jetzt und die Live-Aktivität
    /// zum nächsten Gebet, als habe sie eben begonnen (wie `-debugLiveActivity`).
    ///
    /// - Parameter clockOffset: Uhr der App minus Gerätezeit – damit der Countdown in Gerätezeit dieselbe
    ///   Restzeit zeigt.
    ///   - style: Stil der App (Spec § 11.7) – Grundfarbe und Aussehen der Live-Aktivität und des Widgets „Live“.
    public static func make(
        source: any PrayerTimesSource, place: Place, cityName: String, isCurrentLocation: Bool,
        settings: CalculationSettings, showKerahat: Bool, now: Date, clockOffset: TimeInterval, style: AppStyle = .standard
    ) -> CatalogOutsideState {
        let entry = WidgetTimeline.entries(from: now, source: source, place: place, settings: settings).entries.first
        let state: PrayerWidgetContent.State
        switch entry?.content {
        case .times(let snapshot): state = .times(snapshot)
        case .noTimes, nil: state = .noTimes
        }
        let plan = LiveActivityPlanner(source: source).plan(
            at: now, place: place, settings: settings,
            options: LiveActivityPlanner.Options(
                leadMinutes: 0, cityName: cityName, isCurrentLocation: isCurrentLocation,
                showKerahat: showKerahat, clockOffset: clockOffset, style: style
            ),
            debugStart: now
        )
        return CatalogOutsideState(
            widget: PrayerWidgetContent(
                state: state, cityName: cityName, isCurrentLocation: isCurrentLocation, clockOffset: clockOffset,
                showKerahat: showKerahat, style: style
            ),
            liveActivity: plan.first?.content
        )
    }

    /// Eine Fixture-Stadt am 10.11.2026 zur Uhrzeit `time` – die Uhr läuft ab jetzt weiter.
    public static func fixture(city: String = "berlin", time: String = "14:25:01") -> CatalogOutsideState {
        guard let fixture = FixtureTimes.city(city) else { preconditionFailure("Unbekannte Fixture-Stadt: \(city)") }
        let parts = time.split(separator: ":").map(String.init)
        guard (2...3).contains(parts.count), let clock = ClockTime(parts[0] + ":" + parts[1]),
              let seconds = parts.count == 3 ? Int(parts[2]) : 0
        else { preconditionFailure("Ungültige Uhrzeit: \(time)") }
        let place = fixture.place(named: city.prefix(1).uppercased() + city.dropFirst())
        let now = FixtureTimes.referenceDay.date(at: clock, in: place.timeZone).addingTimeInterval(TimeInterval(seconds))
        return make(
            source: FixtureTimesSource(), place: place, cityName: place.name, isCurrentLocation: true,
            settings: CalculationSettings(), showKerahat: true, now: now, clockOffset: now.timeIntervalSince(Date())
        )
    }
}

/// Lage der Bausteine im Katalog, in pt vom oberen Rand. Die Bausteine stehen dort, wo die Dynamic Island
/// des Simulators sie nicht verdeckt; `scripts/compare-system` schneidet an diesen Stellen aus.
public enum CatalogOutsideMetrics {
    /// Die Widgets wie in `system/91`: 26 pt vom Rand, oben das Widget „Live“ 66 pt von oben, darunter
    /// das mittlere und das kleine, jeweils nach Name (5 + 13 pt) und Abstand (16 pt).
    public static let homeLeft: CGFloat = 26
    public static let liveTop: CGFloat = 66
    public static let mediumTop: CGFloat = 258
    public static let smallTop: CGFloat = 446
    /// Die Widgets des Sperrbildschirms: die Zeile über der Uhr, darunter Ring und Rechteck wie in
    /// `system/90` mit 14 pt Abstand, mittig – unter den Widgets des Home-Bildschirms.
    public static let inlineTop: CGFloat = 640
    public static let accessoryTop: CGFloat = 690
    public static let accessoryGap: CGFloat = 14
    /// Die Insel kompakt und erweitert, und die Live-Aktivität auf dem Sperrbildschirm wie in `system/93`.
    public static let compactTop: CGFloat = 120
    public static let expandedTop: CGFloat = 180
    public static let lockScreenTop: CGFloat = 400
    /// Höhe der Insel (`.island`: 37 pt) und Breite kompakt (`.di-compact`: 212 pt); erweitert 9 pt vom
    /// Rand mit Radius 44 und `padding: 13px 24px 16px`.
    public static let islandHeight: CGFloat = 37
    public static let compactWidth: CGFloat = 212
    public static let compactPadding = EdgeInsets(top: 0, leading: 11, bottom: 0, trailing: 12)
    public static let expandedInset: CGFloat = 9
    public static let expandedRadius: CGFloat = 44
    public static let expandedPadding = EdgeInsets(top: 13, leading: 24, bottom: 16, trailing: 24)

    /// Phase 19 (Spec § 12.3): die Live-Aktivität „klein“ unter der des Sperrbildschirms, 12 pt vom Rand und 12 pt
    /// auseinander – 240 × 100, darunter 240 × 78, darunter 170 × 78 und daneben 194 × 80,5 (Smart Stack der Uhr).
    public static let smallActivityFrames: [CGRect] = [
        CGRect(x: 12, y: 567, width: 240, height: 100),
        CGRect(x: 12, y: 679, width: 240, height: 78),
        CGRect(x: 12, y: 769, width: 170, height: 78),
        CGRect(x: 194, y: 769, width: 194, height: 80.5),
    ]

    /// Phase 19 (Spec § 12.1, § 12.2): die kleinen Widgets in Originalgröße (158 × 158) wie auf der Tafel des Prototyps –
    /// oben mit Hintergrund („Nächstes Gebet“, „Tagesbogen“), darunter ohne.
    public static let smallWidgetFrames: [CGRect] = [
        CGRect(x: 26, y: 66, width: 158, height: 158),
        CGRect(x: 206, y: 66, width: 158, height: 158),
        CGRect(x: 26, y: 254, width: 158, height: 158),
        CGRect(x: 206, y: 254, width: 158, height: 158),
    ]
    /// Darunter die Live-Aktivität „klein“ nach dem Wechsel: 240 × 78 und 170 × 78.
    public static let endedActivityFrames: [CGRect] = [
        CGRect(x: 12, y: 446, width: 240, height: 78),
        CGRect(x: 12, y: 536, width: 170, height: 78),
    ]
}

/// Der Hintergrund des Sperr- und Home-Bildschirms im Prototyp (`.wall`), vereinfacht auf den Verlauf
/// von oben nach unten.
struct CatalogWallpaper: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(RGBA(hex: 0x2F7476)), location: 0),
                .init(color: Color(RGBA(hex: 0x1D4D5C)), location: 0.46),
                .init(color: Color(RGBA(hex: 0x24304F)), location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Die sechs Widgets: „Live“, mittleres und kleines wie auf dem Home-Bildschirm, darunter die drei des
/// Sperrbildschirms.
struct CatalogWidgets: View {
    let state: CatalogOutsideState

    var body: some View {
        let content = state.widget
        ZStack(alignment: .topLeading) {
            CatalogWallpaper()
            LivePrayerWidget(content: content)
                .frame(width: WidgetMetrics.liveSize.width, height: WidgetMetrics.liveSize.height)
                .background(LiveActivityBackground(look: LiveActivityLook(style: content.style)))
                .clipShape(.rect(cornerRadius: WidgetMetrics.cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.14), radius: 9, y: 4)
                .offset(x: CatalogOutsideMetrics.homeLeft, y: CatalogOutsideMetrics.liveTop)
            homeWidget(MediumPrayerWidget(content: content), size: WidgetMetrics.mediumSize)
                .offset(x: CatalogOutsideMetrics.homeLeft, y: CatalogOutsideMetrics.mediumTop)
            homeWidget(SmallPrayerWidget(content: content), size: WidgetMetrics.smallSize)
                .offset(x: CatalogOutsideMetrics.homeLeft, y: CatalogOutsideMetrics.smallTop)

            InlinePrayerWidget(content: content)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
                .frame(width: CatalogMetrics.referenceWidth)
                .offset(y: CatalogOutsideMetrics.inlineTop)

            HStack(spacing: CatalogOutsideMetrics.accessoryGap) {
                CircularPrayerWidget(content: content, drawsRing: true)
                    .foregroundStyle(.white)
                    .frame(width: WidgetMetrics.circularSize.width, height: WidgetMetrics.circularSize.height)
                    .background(.white.opacity(0.15), in: .circle)
                RectangularPrayerWidget(content: content)
                    .foregroundStyle(.white)
                    .frame(width: WidgetMetrics.rectangularSize.width, height: WidgetMetrics.rectangularSize.height)
                    .background(.white.opacity(0.15), in: .rect(cornerRadius: WidgetMetrics.rectangularRadius, style: .continuous))
            }
            .frame(width: CatalogMetrics.referenceWidth)
            .offset(y: CatalogOutsideMetrics.accessoryTop)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func homeWidget(_ widget: some View, size: CGSize) -> some View {
        widget
            .frame(width: size.width, height: size.height)
            .background(Palette.backgroundCell, in: .rect(cornerRadius: WidgetMetrics.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 9, y: 4)
    }
}

/// Die Live-Aktivität: Insel kompakt und erweitert, darunter der Sperrbildschirm.
struct CatalogLiveActivity: View {
    let state: CatalogOutsideState
    var isStale = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            CatalogWallpaper()
            if let content = state.liveActivity {
                HStack(spacing: 0) {
                    LiveActivityCompactLeading(content: content)
                    Spacer(minLength: 0)
                    LiveActivityCompactTrailing(content: content, isStale: isStale)
                }
                .padding(CatalogOutsideMetrics.compactPadding)
                .frame(width: CatalogOutsideMetrics.compactWidth, height: CatalogOutsideMetrics.islandHeight)
                .background(.black, in: .capsule)
                .frame(width: CatalogMetrics.referenceWidth)
                .offset(y: CatalogOutsideMetrics.compactTop)

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        LiveActivityExpandedLeading(content: content)
                        Spacer(minLength: 8)
                        LiveActivityExpandedTrailing(content: content)
                    }
                    LiveActivityExpandedBottom(content: content, isStale: isStale)
                        .padding(.top, LiveActivityMetrics.captionTop)
                }
                .padding(CatalogOutsideMetrics.expandedPadding)
                .frame(width: CatalogMetrics.referenceWidth - 2 * CatalogOutsideMetrics.expandedInset)
                .background(.black, in: .rect(cornerRadius: CatalogOutsideMetrics.expandedRadius, style: .continuous))
                .offset(x: CatalogOutsideMetrics.expandedInset, y: CatalogOutsideMetrics.expandedTop)

                LiveActivityLockScreen(content: content, isStale: isStale)
                    .frame(width: LiveActivityMetrics.lockScreenWidth)
                    // Im Stil der Aktivität, in der Verbotszeit orange bzw. violett (Spec § 10.3, § 11.7).
                    .background(LiveActivityBackground(look: LiveActivityLook(content: content)))
                    .clipShape(.rect(cornerRadius: LiveActivityMetrics.lockScreenRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 13, y: 8)
                    .frame(width: CatalogMetrics.referenceWidth)
                    .offset(y: CatalogOutsideMetrics.lockScreenTop)

                // Phase 19: die Live-Aktivität „klein“ in den vier Größen (CarPlay, Smart Stack), wie `carplay/cp-40`.
                ForEach(Array(CatalogOutsideMetrics.smallActivityFrames.enumerated()), id: \.offset) { _, frame in
                    CatalogSmallActivity(content: content, isStale: isStale, size: frame.size)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Die Live-Aktivität „klein“ in einer Größe der Familie (Spec § 12.3); die Ecken rundet im Auto und auf der Uhr das
/// System, hier der Katalog wie der Prototyp.
struct CatalogSmallActivity: View {
    let content: LiveActivityContent
    var isStale = false
    let size: CGSize

    var body: some View {
        LiveActivitySmall(content: content, isStale: isStale)
            .frame(width: size.width, height: size.height)
            .clipShape(.rect(cornerRadius: LiveActivityMetrics.smallRadius, style: .continuous))
    }
}

/// CarPlay und StandBy (Phase 19, Spec § 12): die kleinen Widgets in Originalgröße wie die Tafel `carplay/cp-50` – oben
/// mit Hintergrund (Home-Bildschirm), darunter ohne (StandBy, CarPlay) –, dazu die Live-Aktivität „klein“ nach dem
/// Wechsel. Der Grund ist der der Tafel (`--bg-grouped`); was StandBy und CarPlay hinter ein Widget legen, zeichnet
/// das System.
struct CatalogCarPlay: View {
    let state: CatalogOutsideState

    var body: some View {
        let content = state.widget
        let frames = CatalogOutsideMetrics.smallWidgetFrames
        ZStack(alignment: .topLeading) {
            Palette.backgroundGrouped
                .ignoresSafeArea()
            tile(SmallPrayerWidget(content: content), frame: frames[0], background: true)
            tile(SmallArcPrayerWidget(content: content), frame: frames[1], background: true)
            tile(SmallPrayerWidget(content: content, showsBackground: false), frame: frames[2], background: false)
            // Ohne Hintergrund zeigt der „Tagesbogen“ die Anordnung von „Nächstes Gebet“ (Spec § 12.2).
            tile(SmallArcPrayerWidget(content: content, showsBackground: false), frame: frames[3], background: false)
            if let activity = state.liveActivity {
                ForEach(Array(CatalogOutsideMetrics.endedActivityFrames.enumerated()), id: \.offset) { _, frame in
                    CatalogSmallActivity(content: activity, isStale: true, size: frame.size)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func tile(_ widget: some View, frame: CGRect, background: Bool) -> some View {
        widget
            .frame(width: frame.width, height: frame.height)
            .background {
                if background {
                    RoundedRectangle(cornerRadius: WidgetMetrics.cornerRadius, style: .continuous)
                        .fill(Palette.backgroundCell)
                        .shadow(color: .black.opacity(0.14), radius: 9, y: 4)
                }
            }
            .offset(x: frame.minX, y: frame.minY)
    }
}

#Preview("Widgets – 14:25") {
    CatalogWidgets(state: .fixture())
}

#Preview("Live-Aktivität – 14:25") {
    CatalogLiveActivity(state: .fixture())
}

#Preview("Live-Aktivität – ab Beginn") {
    CatalogLiveActivity(state: .fixture(time: "16:20:00"), isStale: true)
}

#Preview("CarPlay und StandBy – 14:25") {
    CatalogCarPlay(state: .fixture())
}

#Preview("CarPlay und StandBy – Verbotszeit") {
    CatalogCarPlay(state: .fixture(time: "16:05:00"))
}

#endif
