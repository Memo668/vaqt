import Foundation
import PrayerCore

/// Was eine Gebetskarte zu einer Tagesphase zeigt – der Rechenteil von `prayerRow()` und
/// `kerahatSub()` im Prototyp.
public struct PrayerRowModel: Hashable, Sendable, Identifiable {

    /// Zustand der Karte.
    public enum Status: Hashable, Sendable {
        /// Das Ereignis kommt noch.
        case upcoming
        /// Die Zeit dieses Gebets läuft: Karte mit Akzent gemischt, Schrift in Akzent, Chip „Jetzt“.
        case current
        /// Das Ereignis ist vorbei: Schrift in Sekundärfarbe.
        case passed
    }

    /// Das Kerahat-Fenster, das unter dem Namen steht.
    public struct KerahatCaption: Hashable, Sendable {
        public let start: ClockTime
        public let end: ClockTime
        /// Ob das Fenster gerade läuft. Dann heißt es „Kerahat bis 16:27“ statt „Kerahat 15:42–16:27“.
        public let isActive: Bool

        public init(start: ClockTime, end: ClockTime, isActive: Bool) {
            self.start = start
            self.end = end
            self.isActive = isActive
        }

        /// Die Spanne „15:42–16:27“. Wortverbinder um den Strich halten sie in einer Zeile.
        public var range: String {
            L10n.time(start) + "\u{2060}–\u{2060}" + L10n.time(end)
        }

        /// Der Text der Zeile aus dem String Catalog (`kerahatNow`, `kerahatRow`).
        public var text: String {
            isActive ? L10n.kerahatNow(b: L10n.time(end)) : L10n.kerahatRow(r: range)
        }
    }

    public let prayer: Prayer
    /// Uhrzeit am Ort.
    public let time: ClockTime
    public let status: Status
    /// Die Kerahat-Zeile; `nil`, wenn zu dieser Karte kein Fenster gehört oder die App Kerahat nicht zeigt.
    public let kerahat: KerahatCaption?
    /// Ob die Karte die Info-Marke für hohe Breiten trägt (nur Fadschr und Ischa).
    public let showsHighLatitudeMark: Bool

    public var id: Prayer { prayer }

    public init(
        prayer: Prayer, time: ClockTime, status: Status,
        kerahat: KerahatCaption? = nil, showsHighLatitudeMark: Bool = false
    ) {
        self.prayer = prayer
        self.time = time
        self.status = status
        self.kerahat = kerahat
        self.showsHighLatitudeMark = showsHighLatitudeMark
    }

    /// Die Karte eines Ereignisses zur Tagesphase.
    ///
    /// - Parameters:
    ///   - showKerahat: der Schalter „Kerahat-Zeiten zeigen“ (`S.kerahat`).
    ///   - isHighLatitude: ob für den Ort die Regel für hohe Breiten greift (`S.highLat`).
    public init(prayer: Prayer, phase: DayPhase, showKerahat: Bool = true, isHighLatitude: Bool = false) {
        let isCurrent = phase.highlighted == prayer
        let times = phase.times
        var caption: KerahatCaption?
        if showKerahat, let window = Kerahat.windows(for: times).first(where: { $0.row == prayer }) {
            caption = KerahatCaption(
                start: ClockTime(window.start, in: times.timeZone),
                end: ClockTime(window.end, in: times.timeZone),
                isActive: phase.activeKerahat?.id == window.id
            )
        }
        self.init(
            prayer: prayer,
            time: times.clockTime(of: prayer),
            status: isCurrent ? .current : phase.hasPassed(prayer) ? .passed : .upcoming,
            kerahat: caption,
            showsHighLatitudeMark: isHighLatitude && (prayer == .fajr || prayer == .isha)
        )
    }

    /// Die Karte eines Ereignisses an einem anderen Tag (Spec § 9.4): dessen Uhrzeit und Kerahat-Fenster,
    /// ohne „jetzt“ und ohne „vorbei“.
    public init(prayer: Prayer, times: DayTimes, showKerahat: Bool = true, isHighLatitude: Bool = false) {
        var caption: KerahatCaption?
        if showKerahat, let window = Kerahat.windows(for: times).first(where: { $0.row == prayer }) {
            caption = KerahatCaption(
                start: ClockTime(window.start, in: times.timeZone),
                end: ClockTime(window.end, in: times.timeZone),
                isActive: false
            )
        }
        self.init(
            prayer: prayer, time: times.clockTime(of: prayer), status: .upcoming, kerahat: caption,
            showsHighLatitudeMark: isHighLatitude && (prayer == .fajr || prayer == .isha)
        )
    }

    /// Die sechs Karten eines Tages in der Reihenfolge der Liste (`PRAYERS`).
    public static func rows(
        for phase: DayPhase, showKerahat: Bool = true, isHighLatitude: Bool = false
    ) -> [PrayerRowModel] {
        Prayer.allCases.map {
            PrayerRowModel(prayer: $0, phase: phase, showKerahat: showKerahat, isHighLatitude: isHighLatitude)
        }
    }

    /// Die sechs Karten eines anderen Tages.
    public static func rows(
        for times: DayTimes, showKerahat: Bool = true, isHighLatitude: Bool = false
    ) -> [PrayerRowModel] {
        Prayer.allCases.map {
            PrayerRowModel(prayer: $0, times: times, showKerahat: showKerahat, isHighLatitude: isHighLatitude)
        }
    }
}
