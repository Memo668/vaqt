import Foundation

/// Was ein Widget zu einem Zeitpunkt zeigt – der Rechenteil von `lockScreenHTML()` und
/// `homeScreenHTML()` im Prototyp (Spec § 3, „Widgets“).
///
/// Wie die Zeiten-Seite nennen die Widgets das nächste Ereignis, auch den Sonnenaufgang (`ph.next`). Das
/// mittlere Widget listet die sechs Zeiten des Tages, zu dem das nächste Ereignis gehört: nach Ischa die
/// von morgen, nichts abgeblendet; nach Mitternacht vor einem späten Ischa noch die von gestern. So steht
/// in der Liste dieselbe Uhrzeit wie links groß.
public struct WidgetSnapshot: Hashable, Sendable {
    /// Die Tagesphase zu diesem Zeitpunkt – für den Bogen im rechteckigen Widget und im Widget „Live“
    /// (`arcHTML(ph, 'acc')`, `arcHTML(ph, 'wla', 'la')`; Spec § 9.11).
    public let phase: DayPhase
    /// Die sechs Zeiten der Liste im mittleren Widget.
    public let list: DayTimes
    /// Zeilen der Liste, die vorbei sind und abgeblendet stehen (`passed`). Das nächste Ereignis zählt nie
    /// dazu.
    public let passed: Set<Prayer>

    /// Der Zeitpunkt, für den der Stand gilt (App-Uhr).
    public var now: Date { phase.now }
    /// Das letzte Ereignis, das schon begonnen hat (`ph.prev`) – Beginn des Rings.
    public var previous: DayPhase.Event { phase.previous }
    /// Das nächste Ereignis (`ph.next`).
    public var next: DayPhase.Event { phase.next }
    /// Das Ereignis danach (`ph.next2`).
    public var following: DayPhase.Event { phase.following }

    /// Der Stand zum Zeitpunkt `now`; `nil`, wenn der Zeitstrahl `now` nicht einschließt.
    public init?(timeline: PrayerTimeline, at now: Date) {
        guard let phase = timeline.phase(at: now) else { return nil }
        self.phase = phase
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
///
/// Den Tagesbogen (Spec § 9.11) zeichnet iOS nicht von selbst weiter. Damit Knopf und gefüllter Teil
/// mitlaufen, kommen zwischen Fadschr und Ischa Einträge alle fünf Minuten dazu, und zu Beginn und Ende
/// jedes Kerahat-Fensters (`arcStep`; entschieden mit dem Plan für Phase 14: „Alle 5 Minuten“).
public enum WidgetTimeline {

    /// So weit reicht eine Zeitleiste.
    public static let horizon: TimeInterval = 24 * 60 * 60

    /// Abstand der Einträge für den Bogen im Widget „Live“: fünf Minuten, auf volle fünf Minuten der Uhr. Der
    /// Knopf rückt damit um gut 2 pt weiter.
    public static let arcStep: TimeInterval = 5 * 60

    /// Abstand der Einträge für den Bogen im rechteckigen Widget des Sperrbildschirms: zehn Minuten. Der
    /// Bogen ist dort kleiner, der Knopf rückt so ebenfalls um gut 2 pt. Mit fünf Minuten wurde das Archiv der
    /// Zeitleiste über 10 MB groß, und iOS lehnte sie ab („too large timeline archive“, im Simulator gemessen
    /// am 15.11.2026: 10,5 MB; mit zehn Minuten etwa die Hälfte).
    public static let lockScreenArcStep: TimeInterval = 10 * 60

    /// Abstand der Einträge für den Bogen im kleinen Widget „Tagesbogen“ (Spec § 12.2, seit Phase 19): zehn
    /// Minuten wie im Rechteck – der Bogen ist ähnlich groß (Radius 80 statt 88 pt), der Knopf rückt um gut 2 pt.
    public static let smallArcStep: TimeInterval = 10 * 60

    /// Die Widgets der App, so wie ihre Zeitleiste sie braucht (Spec § 3, § 9.11, § 12). Die Extension ordnet
    /// jedem Widget und jeder Größe eines davon zu.
    public enum Surface: Hashable, Sendable, CaseIterable {
        /// Das kleine Widget „Nächstes Gebet“. Ohne Hintergrund (StandBy, CarPlay) zeigt es „Verbotszeit bis …“
        /// (§ 12.1) – das braucht Einträge zu Beginn und Ende jeder Verbotszeit.
        case small
        /// Das mittlere Widget mit der Liste.
        case medium
        /// Das mittlere Widget „Live“ mit dem Bogen.
        case live
        /// Das kleine Widget „Tagesbogen“ (§ 12.2).
        case dayArc
        /// Der Ring auf dem Sperrbildschirm; läuft von selbst.
        case lockScreenCircular
        /// Das Rechteck auf dem Sperrbildschirm mit dem Bogen.
        case lockScreenRectangular
        /// Die Zeile über der Uhr.
        case lockScreenInline

        /// Abstand der Zwischeneinträge für den Bogen; `nil` ohne Bogen.
        public var arcStep: TimeInterval? {
            switch self {
            case .live: WidgetTimeline.arcStep
            case .lockScreenRectangular: WidgetTimeline.lockScreenArcStep
            case .dayArc: WidgetTimeline.smallArcStep
            case .small, .medium, .lockScreenCircular, .lockScreenInline: nil
            }
        }

        /// Ob das Widget Einträge zu Beginn und Ende jeder Verbotszeit braucht: wo es sie zeigt – auf der Spur
        /// des Bogens oder als „Verbotszeit bis …“.
        public var needsKerahatEdges: Bool {
            switch self {
            case .small, .live, .dayArc, .lockScreenRectangular: true
            case .medium, .lockScreenCircular, .lockScreenInline: false
            }
        }
    }

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
    ///   - arcStep: Abstand der Einträge für den Bogen (`WidgetTimeline.arcStep`); ohne Angabe nur ein
    ///     Eintrag je Ereignis. Mit Bogen kommen immer die Einträge zu Beginn und Ende der Verbotszeiten dazu.
    ///   - kerahatEdges: Einträge zu Beginn und Ende jeder Verbotszeit, auch ohne Bogen – für „Verbotszeit
    ///     bis …“ im kleinen Widget ohne Hintergrund (Spec § 12.1).
    public static func entries(
        from now: Date, source: any PrayerTimesSource, place: Place, settings: CalculationSettings,
        arcStep: TimeInterval? = nil, kerahatEdges: Bool = false
    ) -> Result {
        let result = eventEntries(from: now, source: source, place: place, settings: settings)
        let step = arcStep.flatMap { $0 > 0 ? $0 : nil }
        guard step != nil || kerahatEdges else { return result }
        return Result(
            entries: addingSteps(to: result.entries, arcStep: step, source: source, place: place, settings: settings),
            reloadDate: result.reloadDate
        )
    }

    /// Die Zeitleiste ab `now` für ein Widget: mit den Zwischeneinträgen, die es braucht (`Surface`).
    public static func entries(
        from now: Date, source: any PrayerTimesSource, place: Place, settings: CalculationSettings, surface: Surface
    ) -> Result {
        entries(
            from: now, source: source, place: place, settings: settings,
            arcStep: surface.arcStep, kerahatEdges: surface.needsKerahatEdges
        )
    }

    /// Ein Eintrag für jetzt und einer zu jedem Ereignis.
    static func eventEntries(
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

    /// Die Einträge mit den Zwischenschritten: Mit `arcStep` kommt zwischen zwei Einträgen alle `arcStep`
    /// Sekunden einer dazu – aber nur, solange der Bogen „jetzt“ zeigt, also zwischen Fadschr und Ischa. Immer
    /// kommt einer zu Beginn und Ende jedes Kerahat-Fensters dazu: Der Abschnitt auf der Spur wird pünktlich
    /// kräftiger und wieder blasser, „Verbotszeit bis …“ erscheint und verschwindet (Spec § 12.1).
    static func addingSteps(
        to entries: [Entry], arcStep: TimeInterval?, source: any PrayerTimesSource, place: Place, settings: CalculationSettings
    ) -> [Entry] {
        var result: [Entry] = []
        for (index, entry) in entries.enumerated() {
            result.append(entry)
            guard index + 1 < entries.count, case .times(let snapshot) = entry.content else { continue }
            let end = entries[index + 1].date
            let times = snapshot.phase.times
            var dates = Set<Date>()
            let from = max(entry.date, times.fajr)
            let to = min(end, times.isha)
            if let step = arcStep, from < to {
                var next = ((from.timeIntervalSinceReferenceDate / step).rounded(.down) + 1) * step
                while next < to.timeIntervalSinceReferenceDate {
                    dates.insert(Date(timeIntervalSinceReferenceDate: next))
                    next += step
                }
            }
            for window in Kerahat.windows(for: times) {
                for date in [window.start, window.end] where date > entry.date && date < end {
                    dates.insert(date)
                }
            }
            for date in dates.sorted() {
                guard let snapshot = Self.snapshot(at: date, source: source, place: place, settings: settings) else { continue }
                result.append(Entry(date: date, content: .times(snapshot)))
            }
        }
        return result
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
