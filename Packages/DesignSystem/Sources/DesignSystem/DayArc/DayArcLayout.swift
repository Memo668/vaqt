import CoreGraphics
import Foundation
import PrayerCore

/// Was der Tagesbogen zu einer Tagesphase – oder zu einem anderen Tag – zeigt: der Rechenteil von
/// `arcHTML()` im Prototyp.
///
/// Reine Geometrie ohne Ansicht: wo die fünf Marker und ihre Zeiten sitzen, wie weit der Bogen gefüllt
/// ist, wo der Knopf für „jetzt“ steht und welche Kerahat-Segmente es gibt. `DayArc` zeichnet das.
public struct DayArcLayout: Hashable, Sendable {

    /// Zustand eines Markers.
    public enum MarkerState: Hashable, Sendable {
        /// Das Gebet kommt noch: getönte Fläche, Symbol in Akzent.
        case upcoming
        /// Das Gebet hat begonnen: Fläche in Akzent, helles Symbol (`is-passed`).
        case passed
        /// Die Zeit dieses Gebets läuft: größer, mit Schein (`is-current`).
        case current
    }

    /// Ein Gebet auf dem Bogen.
    public struct Marker: Hashable, Sendable, Identifiable {
        public let prayer: Prayer
        /// Anteil des Gebetstages von Fadschr (0) bis Ischa (1), an dem der Marker sitzt (`f`).
        public let fraction: Double
        public let center: CGPoint
        public let radius: CGFloat
        /// Kantenlänge des Symbols.
        public let symbolSize: CGFloat
        public let state: MarkerState
        /// Ob der Marker eng an seinem Vorgänger liegt und deshalb einen Ring in Hintergrundfarbe
        /// bekommt (`is-tight`) – z. B. Ischa nach Maghrib in Jakarta.
        public let isTight: Bool
        /// Die Uhrzeit am Ort.
        public let time: ClockTime
        /// Mitte der Uhrzeit: außen am Bogen, bei Fadschr und Ischa unter dem Marker.
        public let timeCenter: CGPoint

        public var id: Prayer { prayer }
    }

    /// Zustand eines Kerahat-Fensters auf dem Bogen.
    public enum KerahatState: Hashable, Sendable {
        /// Das Fenster kommt noch.
        case upcoming
        /// Das Fenster ist heute schon vorbei; das Segment ist blasser (`is-past`).
        case past
        /// Das Fenster läuft; das Segment ist am kräftigsten (`is-now`).
        case active
    }

    /// Ein Kerahat-Fenster als Stück des Bogens – auf der Spur (Spec § 9.3) oder knapp innerhalb.
    public struct KerahatSegment: Hashable, Sendable, Identifiable {
        public let id: KerahatWindow.Kind
        /// Beginn als Anteil des Gebetstages, auf 0 bis 1 begrenzt (`f0`).
        public let start: Double
        /// Ende als Anteil des Gebetstages (`f1`).
        public let end: Double
        public let state: KerahatState
        /// Beginn und Ende als Uhrzeit am Ort – für VoiceOver (`kerahatArc`); im Bogen stehen keine Zeiten.
        public let startTime: ClockTime
        public let endTime: ClockTime

        /// Ob das Fenster gerade läuft.
        public var isActive: Bool { state == .active }
    }

    /// Zwei Marker gelten als eng, wenn zwischen ihren Rändern weniger als 6 pt liegen.
    public static let tightGap: CGFloat = 6
    /// Ist der Vorgänger der Marker des laufenden Gebets, gilt das schon unter 14 pt – sein Schein
    /// reicht weiter.
    public static let tightGapAfterCurrent: CGFloat = 14
    /// Kürzere Kerahat-Segmente werden nicht gezeichnet (`f1 - f0 < .001`).
    public static let shortestSegment = 0.001

    public let metrics: DayArcMetrics
    /// Ob Fadschr rechts beginnt.
    public let isRightToLeft: Bool
    /// Anteil des Gebetstages, der vorbei ist: 0 bis Fadschr, 1 ab Ischa (`dp.p`).
    public let progress: Double
    /// Ob „jetzt“ zwischen Fadschr und Ischa liegt. Nur dann ist der Knopf zu sehen (`dp.active`).
    public let showsKnob: Bool
    /// Die fünf Gebete und der Sonnenaufgang in ihrer Tagesfolge (Spec § 9.14). Spätere Marker liegen über
    /// früheren. Der Sonnenaufgang ist nie das laufende Gebet, wird aber gefüllt, sobald die Sonne aufgegangen ist.
    public let markers: [Marker]
    /// Die Kerahat-Segmente; leer, wenn die App Kerahat nicht zeigt.
    public let kerahat: [KerahatSegment]

    /// - Parameters:
    ///   - phase: die Tagesphase aus `PrayerCore`.
    ///   - showKerahat: der Schalter „Kerahat-Zeiten zeigen“ (`S.kerahat`).
    ///   - isRightToLeft: die Leserichtung der Umgebung.
    public init(
        phase: DayPhase, metrics: DayArcMetrics = .home, showKerahat: Bool = true, isRightToLeft: Bool = false
    ) {
        let dayProgress = phase.dayProgress
        let active = phase.activeKerahat
        self.init(
            times: phase.times, metrics: metrics, showKerahat: showKerahat, isRightToLeft: isRightToLeft,
            progress: dayProgress.fraction, showsKnob: dayProgress.isActive,
            state: { prayer in
                phase.highlighted == prayer ? .current : phase.hasPassed(prayer) ? .passed : .upcoming
            },
            kerahatState: { window in
                // Vorbei ist ein Fenster, sobald „jetzt“ sein Ende erreicht hat (`nsMin >= w.b`).
                active?.id == window.id ? .active : phase.now >= window.end ? .past : .upcoming
            }
        )
    }

    /// Der Bogen eines anderen Tages (Spec § 9.4): die Zeiten und Kerahat-Fenster dieses Tages, ohne
    /// Fortschritt, ohne Knopf; nichts läuft und nichts ist vorbei (`ph.other` im Prototyp).
    public init(
        times: DayTimes, metrics: DayArcMetrics = .home, showKerahat: Bool = true, isRightToLeft: Bool = false
    ) {
        self.init(
            times: times, metrics: metrics, showKerahat: showKerahat, isRightToLeft: isRightToLeft,
            progress: 0, showsKnob: false, state: { _ in .upcoming }, kerahatState: { _ in .upcoming }
        )
    }

    private init(
        times: DayTimes, metrics: DayArcMetrics, showKerahat: Bool, isRightToLeft: Bool,
        progress: Double, showsKnob: Bool,
        state: (Prayer) -> MarkerState, kerahatState: (KerahatWindow) -> KerahatState
    ) {
        self.metrics = metrics
        self.isRightToLeft = isRightToLeft
        self.progress = progress
        self.showsKnob = showsKnob

        let span = times.isha.timeIntervalSince(times.fajr)
        func fraction(of date: Date) -> Double {
            span > 0 ? date.timeIntervalSince(times.fajr) / span : 0
        }

        var markers: [Marker] = []
        for prayer in Prayer.allCases {
            let fraction = fraction(of: times[prayer])
            let center = metrics.point(at: fraction, isRightToLeft: isRightToLeft)
            let markerState = state(prayer)
            let isCurrent = markerState == .current
            let radius = isCurrent ? metrics.currentMarkerRadius : metrics.markerRadius

            var isTight = false
            if let previous = markers.last {
                let distance = hypot(center.x - previous.center.x, center.y - previous.center.y)
                let gap = previous.state == .current ? Self.tightGapAfterCurrent : Self.tightGap
                isTight = distance < radius + previous.radius + gap
            }

            markers.append(Marker(
                prayer: prayer, fraction: fraction, center: center, radius: radius,
                symbolSize: isCurrent ? metrics.currentSymbolSize : metrics.symbolSize,
                state: markerState,
                isTight: isTight,
                time: times.clockTime(of: prayer),
                timeCenter: metrics.timeCenter(
                    for: center, markerRadius: radius, fraction: fraction,
                    isEnd: prayer == .fajr || prayer == .isha, isRightToLeft: isRightToLeft
                )
            ))
        }
        self.markers = markers

        if showKerahat {
            kerahat = Kerahat.windows(for: times).compactMap { window in
                let start = min(1, max(0, fraction(of: window.start)))
                let end = min(1, max(0, fraction(of: window.end)))
                guard end - start >= Self.shortestSegment else { return nil }
                return KerahatSegment(
                    id: window.id, start: start, end: end, state: kerahatState(window),
                    startTime: ClockTime(window.start, in: times.timeZone), endTime: ClockTime(window.end, in: times.timeZone)
                )
            }
        } else {
            kerahat = []
        }
    }

    /// Mitte des Knopfes für „jetzt“.
    public var knobCenter: CGPoint {
        metrics.point(at: progress, isRightToLeft: isRightToLeft)
    }

    /// Die Kerahat-Fenster für VoiceOver: „07:14–07:59, 11:42–11:52, 15:42–16:27“ (`kerahatArc`).
    public var kerahatList: String {
        kerahat.map { "\($0.startTime)–\($0.endTime)" }.joined(separator: ", ")
    }

    /// Wie viele der fünf Gebetszeiten heute begonnen haben – für den VoiceOver-Text `arcPrayers`. Der
    /// Sonnenaufgang zählt nicht mit.
    public var begunCount: Int {
        markers.count { $0.prayer != .sunrise && $0.state != .upcoming }
    }

    /// Radius, auf dem die Kerahat-Segmente liegen – auf der Spur der des Bogens.
    public var kerahatRadius: CGFloat {
        metrics.radius - metrics.kerahatInset
    }
}
