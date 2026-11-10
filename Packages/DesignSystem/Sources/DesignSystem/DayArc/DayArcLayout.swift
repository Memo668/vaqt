import CoreGraphics
import Foundation
import PrayerCore

/// Was der Tagesbogen zu einer Tagesphase zeigt – der Rechenteil von `arcHTML()` im Prototyp.
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

    /// Ein Kerahat-Fenster als Stück eines Bogens knapp innerhalb der Spur.
    public struct KerahatSegment: Hashable, Sendable, Identifiable {
        public let id: KerahatWindow.Kind
        /// Beginn als Anteil des Gebetstages, auf 0 bis 1 begrenzt (`f0`).
        public let start: Double
        /// Ende als Anteil des Gebetstages (`f1`).
        public let end: Double
        /// Ob das Fenster gerade läuft; dann ist das Segment kräftiger (`is-now`).
        public let isActive: Bool
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
    /// Die fünf Gebete in ihrer Tagesfolge. Spätere Marker liegen über früheren.
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
        self.metrics = metrics
        self.isRightToLeft = isRightToLeft

        let times = phase.times
        let span = times.isha.timeIntervalSince(times.fajr)
        func fraction(of date: Date) -> Double {
            span > 0 ? date.timeIntervalSince(times.fajr) / span : 0
        }

        let dayProgress = phase.dayProgress
        progress = dayProgress.fraction
        showsKnob = dayProgress.isActive

        var markers: [Marker] = []
        for prayer in Prayer.five {
            let fraction = fraction(of: times[prayer])
            let center = metrics.point(at: fraction, isRightToLeft: isRightToLeft)
            let isCurrent = phase.highlighted == prayer
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
                state: isCurrent ? .current : phase.hasPassed(prayer) ? .passed : .upcoming,
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
            let active = phase.activeKerahat
            kerahat = Kerahat.windows(for: times).compactMap { window in
                let start = min(1, max(0, fraction(of: window.start)))
                let end = min(1, max(0, fraction(of: window.end)))
                guard end - start >= Self.shortestSegment else { return nil }
                return KerahatSegment(id: window.id, start: start, end: end, isActive: active?.id == window.id)
            }
        } else {
            kerahat = []
        }
    }

    /// Mitte des Knopfes für „jetzt“.
    public var knobCenter: CGPoint {
        metrics.point(at: progress, isRightToLeft: isRightToLeft)
    }

    /// Wie viele der fünf Gebetszeiten heute begonnen haben – für den VoiceOver-Text `arcPrayers`.
    public var begunCount: Int {
        markers.count { $0.state != .upcoming }
    }

    /// Radius, auf dem die Kerahat-Segmente liegen.
    public var kerahatRadius: CGFloat {
        metrics.radius - metrics.kerahatInset
    }
}
