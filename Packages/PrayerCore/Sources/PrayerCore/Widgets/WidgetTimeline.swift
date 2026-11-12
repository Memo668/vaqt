import Foundation

/// Was ein Widget zu einem Zeitpunkt zeigt – der Rechenteil von `lockScreenHTML()` und
/// `homeScreenHTML()` im Prototyp (Spec § 3, „Widgets“).
///
/// Wie die Zeiten-Seite nennen die Widgets das nächste Ereignis, auch den Sonnenaufgang (`ph.next`). Das
/// mittlere Widget listet die sechs Zeiten des Tages, zu dem das nächste Ereignis gehört: nach Ischa die
/// von morgen, nichts abgeblendet; nach Mitternacht vor einem späten Ischa noch die von gestern. So steht
/// in der Liste dieselbe Uhrzeit wie links groß.
public struct WidgetSnapshot: Hashable, Sendable {
    /// Der Zeitpunkt, für den der Stand gilt (App-Uhr).
    public let now: Date
    /// Das letzte Ereignis, das schon begonnen hat (`ph.prev`) – Beginn des Rings.
    public let previous: DayPhase.Event
    /// Das nächste Ereignis (`ph.next`).
    public let next: DayPhase.Event
    /// Das Ereignis danach (`ph.next2`) – dritte Zeile des rechteckigen Widgets.
    public let following: DayPhase.Event
    /// Die sechs Zeiten der Liste im mittleren Widget.
    public let list: DayTimes
    /// Zeilen der Liste, die vorbei sind und abgeblendet stehen (`passed`). Das nächste Ereignis zählt nie
    /// dazu.
    public let passed: Set<Prayer>

    /// Der Stand zum Zeitpunkt `now`; `nil`, wenn der Zeitstrahl `now` nicht einschließt.
    public init?(timeline: PrayerTimeline, at now: Date) {
        guard let phase = timeline.phase(at: now) else { return nil }
        self.now = now
        previous = phase.previous
        next = phase.next
        following = phase.following
        let list = timeline.times(dayOffset: phase.next.dayOffset)
        self.list = list
        passed = Set(Prayer.allCases.filter { $0 != phase.next.prayer && list[$0] <= now })
    }

    /// Ob ein Ereignis der Liste das nächste ist (`li.next`).
    public func isNext(_ prayer: Prayer) -> Bool {
        prayer == next.prayer
    }

    /// Sekunden bis zum nächsten Ereignis.
    public var remaining: TimeInterval {
        next.date.timeIntervalSince(now)
    }
}

/// Die Zeitleiste der Widgets: ein Eintrag für jetzt, dann einer zu jedem Ereignis der nächsten 24 Stunden
/// (Spec § 1, „Outside the app“).
///
/// WidgetKit zeigt jeden Eintrag ab seinem Zeitpunkt; dazwischen laufen nur Countdown und Ring weiter
/// (`Text(timerInterval:)`, `ProgressView(timerInterval:)`). Nach dem letzten Eintrag holt das Widget eine
/// neue Zeitleiste. Gerechnet wird mit den Einstellungen der App, Minutenkorrekturen eingerechnet (Spec § 4).
public enum WidgetTimeline {

    /// So weit reicht eine Zeitleiste.
    public static let horizon: TimeInterval = 24 * 60 * 60

    /// Was ein Eintrag zeigt.
    public enum Content: Hashable, Sendable {
        /// Die Zeiten.
        case times(WidgetSnapshot)
        /// Für den Ort lassen sich keine Zeiten berechnen – etwa wo die Sonne nicht auf- oder untergeht.
        /// Die Widgets zeigen dann den Hinweis der Zeiten-Seite (`noTimes`), entschieden mit dem Plan für
        /// Phase 9.
        case noTimes
    }

    /// Ein Eintrag: ab `date` (App-Uhr) gilt `content`.
    public struct Entry: Hashable, Sendable {
        public let date: Date
        public let content: Content
    }

    /// Die Einträge ab `now` und der Zeitpunkt, zu dem das Widget eine neue Zeitleiste holen soll: der
    /// letzte Eintrag. So liegt die neue Zeitleiste vor, bevor der letzte Eintrag veraltet, auch wenn
    /// WidgetKit etwas später fragt. Gibt es nur den Eintrag für jetzt, ist es das nächste Ereignis.
    public struct Result: Hashable, Sendable {
        public let entries: [Entry]
        public let reloadDate: Date
    }

    /// Die Zeitleiste ab `now`.
    ///
    /// - Parameters:
    ///   - now: jetzt, auf der Uhr der App.
    ///   - source: woher die Zeiten kommen.
    ///   - place: der Ort, der in der App gilt.
    ///   - settings: Methode, Asr, Regel für hohe Breiten, Minutenkorrekturen.
    public static func entries(
        from now: Date, source: any PrayerTimesSource, place: Place, settings: CalculationSettings
    ) -> Result {
        guard let first = snapshot(at: now, source: source, place: place, settings: settings) else {
            return Result(entries: [Entry(date: now, content: .noTimes)], reloadDate: nextMidnight(after: now, in: place.timeZone))
        }
        var entries = [Entry(date: now, content: .times(first))]
        let end = now.addingTimeInterval(horizon)
        var date = first.next.date
        while date <= end {
            guard let snapshot = snapshot(at: date, source: source, place: place, settings: settings) else {
                // Ab hier gibt es keine Zeiten mehr: Das Widget sagt es, und morgen wird neu gerechnet.
                entries.append(Entry(date: date, content: .noTimes))
                return Result(entries: entries, reloadDate: nextMidnight(after: date, in: place.timeZone))
            }
            entries.append(Entry(date: date, content: .times(snapshot)))
            // Fallen zwei Ereignisse auf denselben Zeitpunkt, zeigt der Eintrag schon das spätere als laufend;
            // das nächste liegt dann immer später. Nur zur Sicherheit: Rückt es nicht vor, endet die Leiste.
            guard snapshot.next.date > date else { break }
            date = snapshot.next.date
        }
        let reloadDate = entries.count > 1 ? entries[entries.count - 1].date : first.next.date
        return Result(entries: entries, reloadDate: reloadDate)
    }

    /// Der Stand zu einem Zeitpunkt, mit dem Zeitstrahl um den Tag, auf den er am Ort fällt.
    static func snapshot(
        at date: Date, source: any PrayerTimesSource, place: Place, settings: CalculationSettings
    ) -> WidgetSnapshot? {
        source.timeline(at: date, place: place, settings: settings).flatMap { WidgetSnapshot(timeline: $0, at: date) }
    }

    /// Die nächste Mitternacht am Ort nach `date`.
    static func nextMidnight(after date: Date, in timeZone: TimeZone) -> Date {
        CalendarDay(date, in: timeZone).adding(days: 1).date(at: .midnight, in: timeZone)
    }
}
