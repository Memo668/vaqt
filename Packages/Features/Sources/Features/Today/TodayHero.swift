import DesignSystem
import PrayerCore
import SwiftUI

/// Der Bogen mit dem laufenden Countdown – `.hero` im Prototyp.
///
/// Ein Sekundentakt holt die Tagesphase neu aus dem Zeitstrahl: Der Countdown zählt, Knopf und
/// gefüllter Teil des Bogens wandern (Design Spec § 4). Der Takt schlägt, wenn die App-Uhr auf eine
/// neue Sekunde springt – auch bei der verschobenen Debug-Uhr. Wechselt die Phase oder der Tag, meldet
/// die Ansicht das über `onPhaseChange`; erst dann baut die Seite ihre Karten neu auf.
struct TodayHero: View {
    private let timeline: PrayerTimeline
    private let clock: any AppClock
    private let showKerahat: Bool
    private let onPhaseChange: () -> Void

    /// Beginn des Takts in Gerätezeit: die nächste volle Sekunde der App-Uhr, einmal festgelegt.
    @State private var tickStart: Date

    init(
        timeline: PrayerTimeline, clock: any AppClock, showKerahat: Bool,
        onPhaseChange: @escaping () -> Void
    ) {
        self.timeline = timeline
        self.clock = clock
        self.showKerahat = showKerahat
        self.onPhaseChange = onPhaseChange
        _tickStart = State(initialValue: clock.nextWholeSecondOnDevice)
    }

    var body: some View {
        TimelineView(.periodic(from: tickStart, by: 1)) { _ in
            let phase = timeline.phase(at: clock.now)
            Group {
                if let phase {
                    DayArc(phase: phase, showKerahat: showKerahat) {
                        ArcCountdown(phase: phase)
                    }
                } else {
                    // Der Zeitstrahl deckt „jetzt“ nicht mehr ab (Mitternacht): Die Seite baut gleich
                    // einen neuen. Bis dahin bleibt der Platz frei, damit nichts springt.
                    Color.clear
                        .frame(width: DayArcMetrics.home.size.width, height: DayArcMetrics.home.size.height)
                }
            }
            .onChange(of: phaseKey(of: phase)) {
                onPhaseChange()
            }
        }
    }

    /// Der Schlüssel der Phase wie `phaseKey()`; ohne Phase `nil`.
    private func phaseKey(of phase: DayPhase?) -> String? {
        guard let phase else { return nil }
        return phase.key(showKerahat: showKerahat)
    }
}
