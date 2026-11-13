import DesignSystem
import PrayerCore
import SwiftUI

/// Der Bogen mit dem laufenden Countdown – `.hero` im Prototyp.
///
/// Ein Sekundentakt holt die Tagesphase neu aus dem Zeitstrahl: Der Countdown zählt, Knopf und
/// gefüllter Teil des Bogens wandern (Design Spec § 4). Der Takt schlägt, wenn die App-Uhr auf eine
/// neue Sekunde springt – auch bei der verschobenen Debug-Uhr. Wechselt die Phase oder der Tag, meldet
/// die Ansicht das über `onPhaseChange`; erst dann baut die Seite ihre Karten neu auf.
///
/// Der Takt ruht, solange die Seite nicht zu sehen ist – im Pager steht Qibla oder die Anleitung – oder die
/// App nicht aktiv ist (Phase 11, Leistung). Kommt die Seite zurück, zeigt das erste Bild sofort den Stand.
struct TodayHero: View {
    private let timeline: PrayerTimeline
    private let clock: any AppClock
    private let showKerahat: Bool
    private let onPhaseChange: () -> Void

    /// Beginn des Takts in Gerätezeit: die nächste volle Sekunde der App-Uhr, einmal festgelegt.
    @State private var tickStart: Date

    @Environment(\.isPagerPageVisible) private var isPageVisible
    @Environment(\.scenePhase) private var scenePhase

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
        TimelineView(CountdownSchedule(start: tickStart, isPaused: !isPageVisible || scenePhase != .active)) { _ in
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

/// Der Takt des Countdowns: jede volle Sekunde ab `start` (wie `.periodic(from:by:)`); angehalten nur ein
/// Bild, dann nichts mehr, bis der Takt wieder läuft.
struct CountdownSchedule: TimelineSchedule {
    let start: Date
    let isPaused: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        if isPaused {
            return AnyIterator([startDate].makeIterator())
        }
        var periodic = PeriodicTimelineSchedule(from: start, by: 1).entries(from: startDate, mode: mode).makeIterator()
        return AnyIterator { periodic.next() }
    }
}
