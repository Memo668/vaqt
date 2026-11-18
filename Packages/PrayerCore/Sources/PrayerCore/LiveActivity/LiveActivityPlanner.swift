import Foundation

/// Eine geplante Live-Aktivität: eine je Gebet (Spec § 4, Frage 16 entschieden mit dem Plan für Phase 9),
/// bei Dhuhr und Maghrib mit Verbotszeit zwei (Spec § 10.3).
public struct LiveActivityPlan: Hashable, Sendable, Identifiable {
    /// Kennung, die für dasselbe Gebet gleich bleibt, z. B. `live.2026-11-10.maghrib`; der orange Teil in der
    /// Verbotszeit hängt `.verbot` an.
    public let id: String
    public let prayer: Prayer
    /// Der Tag, zu dem das Gebet gehört. Ein Ischa nach Mitternacht gehört zum Vortag.
    public let day: CalendarDay
    /// Ab hier läuft die Aktivität (App-Uhr): so viele Minuten vor dem Gebet, wie eingestellt.
    public let start: Date
    /// Gebetsbeginn.
    public let prayerDate: Date
    /// Ab hier ist die Aktivität `isStale` und zeigt nur noch eine schmale Zeile; läuft die App, beendet sie
    /// sie dann (Spec § 10.3). Gebetsbeginn oder, beim grünen Teil vor einer Verbotszeit, deren Beginn.
    public let end: Date
    public let content: LiveActivityContent

    /// Gewicht für iOS (`relevanceScore`): je später der Start, desto höher – so steht die neueste Aktivität
    /// oben auf dem Sperrbildschirm und in der Dynamic Island (Spec § 10.3).
    public var relevance: Double {
        start.timeIntervalSince1970 / 60
    }

    /// Minuten zwischen Start und Gebet, für den Hinweis beim Start („Maghrib in 30 Minuten“).
    public var leadMinutes: Int {
        Int((prayerDate.timeIntervalSince(start) / 60).rounded())
    }

    /// Die Kennung zu Gebet und Tag.
    public static func identifier(prayer: Prayer, day: CalendarDay, prohibited: Bool = false) -> String {
        "live." + day.description + "." + prayer.rawValue + (prohibited ? ".verbot" : "")
    }
}

/// Welche Live-Aktivitäten die App bei iOS anmeldet: je Pflichtgebet eine, ohne Sonnenaufgang (entschieden
/// mit dem Plan für Phase 9; Spec § 4, Frage 16).
///
/// Eine Aktivität beginnt so viele Minuten vor dem Gebet, wie unter Einstellungen › Live-Aktivität gewählt
/// (Standard 30), und zählt bis zum Gebetsbeginn herunter. iOS startet sie selbst zum geplanten Zeitpunkt
/// (`Activity.request(…, start:)`), auch wenn die App nicht läuft.
///
/// Seit Spec § 10.3: Zum Gebetsbeginn wird sie `stale` und schrumpft auf eine Zeile; die App beendet sie,
/// sobald sie läuft. Fällt die Verbotszeit vor Dhuhr oder Maghrib in die Strecke, gibt es zwei Aktivitäten:
/// die grüne bis zum Beginn der Verbotszeit, die orange von dort bis zum Gebet. Eine Aktivität beginnt
/// frühestens mit dem vorigen Gebet.
public struct LiveActivityPlanner: Sendable {

    /// So lange nach ihrem Wechsel (`staleDate`) bleibt eine Aktivität im Plan. Seit Spec § 10.3 keine Zeit
    /// mehr: Die App beendet sie sofort, auf dem Sperrbildschirm steht bis dahin die schmale Zeile.
    public static let endDelay: TimeInterval = 0
    /// So weit voraus plant die App: Aktivitäten, die in dieser Zeit beginnen.
    public static let horizon: TimeInterval = 24 * 60 * 60
    /// So viele Aktivitäten nimmt iOS je App an, geplante mitgezählt; die sechste lehnt es ab
    /// (`targetMaximumExceeded`, im Simulator mit iOS 27.2 beobachtet). Wie bei den Mitteilungen rollt das
    /// Fenster weiter, wenn die App wieder plant.
    public static let systemLimit = 5

    public let source: any PrayerTimesSource
    /// Höchstzahl der Aktivitäten im Plan, deren Gebet noch nicht begonnen hat.
    public let limit: Int

    public init(source: any PrayerTimesSource, limit: Int = LiveActivityPlanner.systemLimit) {
        self.source = source
        self.limit = limit
    }

    /// Was in die Aktivitäten eingeht, außer Zeit und Ort.
    public struct Options: Hashable, Sendable {
        /// Vorlauf in Minuten; 0 heißt keine Live-Aktivität.
        public var leadMinutes: Int
        public var cityName: String
        public var isCurrentLocation: Bool
        public var showKerahat: Bool
        /// Uhr der App minus Gerätezeit (`-debugTime`); sonst 0.
        public var clockOffset: TimeInterval

        public init(
            leadMinutes: Int, cityName: String, isCurrentLocation: Bool, showKerahat: Bool, clockOffset: TimeInterval = 0
        ) {
            self.leadMinutes = leadMinutes
            self.cityName = cityName
            self.isCurrentLocation = isCurrentLocation
            self.showKerahat = showKerahat
            self.clockOffset = clockOffset
        }
    }

    /// Die Aktivitäten, die jetzt laufen oder in den nächsten 24 Stunden beginnen, in zeitlicher Folge –
    /// höchstens fünf, deren Gebet noch kommt (`systemLimit`).
    ///
    /// Dazu gehören auch Aktivitäten, deren Gebet schon begonnen hat und die noch keine 15 Minuten alt
    /// sind – an ihnen erkennt die App, was sie noch stehen lässt (`LiveActivityLifecycle`).
    ///
    /// - Parameters:
    ///   - now: jetzt, auf der Uhr der App.
    ///   - place: der Ort, der gilt. Seine Zeitzone bestimmt die Tage und Uhrzeiten.
    ///   - settings: Methode, Asr, Regel für hohe Breiten, Minutenkorrekturen.
    ///   - options: Vorlauf, Ort im Kopf, Kerahat, Abstand der Debug-Uhr.
    ///   - debugStart: nur für `-debugLiveActivity`: Dann gibt es genau eine Aktivität, die zum ersten
    ///     Gebet nach diesem Zeitpunkt, und sie beginnt dort – auch außerhalb des Vorlaufs. So lassen sich
    ///     `system/93`–`96` mit denselben Zahlen nachstellen.
    public func plan(
        at now: Date, place: Place, settings: CalculationSettings, options: Options, debugStart: Date? = nil
    ) -> [LiveActivityPlan] {
        guard options.leadMinutes > 0 || debugStart != nil else { return [] }
        let prayers = prayerDates(around: now, place: place, settings: settings)

        if let debugStart {
            guard let next = prayers.first(where: { $0.date > debugStart }) else { return [] }
            return makePlans(next, start: debugStart, now: now, place: place, settings: settings, options: options)
                .filter { $0.end > now }
        }

        let lead = TimeInterval(options.leadMinutes) * 60
        let latestStart = now.addingTimeInterval(Self.horizon)
        var plans: [LiveActivityPlan] = []
        prayers: for (index, prayer) in prayers.enumerated() {
            var start = prayer.date.addingTimeInterval(-lead)
            if index > 0 {
                // Frühestens mit dem vorigen Gebet – außer die beiden liegen so dicht, dass dann schon dieses
                // Gebet begonnen hätte.
                let previous = prayers[index - 1].date
                if previous > start, previous < prayer.date {
                    start = previous
                }
            }
            guard prayer.date > now else { continue }
            guard start <= latestStart else { break }
            // Was schon gewechselt hat, kommt nicht mehr in den Plan; die App beendet es (`LiveActivityLifecycle`).
            for plan in makePlans(prayer, start: start, now: now, place: place, settings: settings, options: options)
            where plan.end > now {
                guard plans.count < limit else { break prayers }
                plans.append(plan)
            }
        }
        return plans
    }

    // MARK: - Bausteine

    /// Ein Pflichtgebet an einem Tag.
    struct PrayerDate: Hashable {
        let prayer: Prayer
        let day: CalendarDay
        let date: Date
    }

    /// Die fünf Gebete von gestern bis übermorgen in zeitlicher Folge. Tage ohne Zeiten fallen aus.
    /// Gestern zählt mit, weil ein Ischa nach Mitternacht zum Vortag gehört.
    func prayerDates(around now: Date, place: Place, settings: CalculationSettings) -> [PrayerDate] {
        let today = CalendarDay(now, in: place.timeZone)
        return (-1...2).flatMap { offset -> [PrayerDate] in
            guard let times = source.times(on: today.adding(days: offset), at: place, settings: settings) else { return [] }
            return Prayer.five.map { PrayerDate(prayer: $0, day: times.day, date: times[$0]) }
        }
        .sorted { ($0.date, $0.day) < ($1.date, $1.day) }
    }

    /// Die Aktivitäten zu einem Gebet: eine, oder bei einer Verbotszeit vor dem Gebet zwei – die grüne bis zu
    /// ihrem Beginn und die orange bis zum Gebet (Spec § 10.3). Beginnt die Strecke schon in der Verbotszeit,
    /// nur die orange. Ohne den Schalter „Kerahat-Zeiten zeigen“ bleibt es bei einer grünen.
    func makePlans(
        _ prayer: PrayerDate, start: Date, now: Date, place: Place, settings: CalculationSettings, options: Options
    ) -> [LiveActivityPlan] {
        let window = options.showKerahat ? prohibitedWindow(before: prayer, place: place, settings: settings) : nil
        guard let window, window.start < prayer.date else {
            return makePlan(prayer, start: start, now: now, place: place, settings: settings, options: options)
                .map { [$0] } ?? []
        }
        if window.start <= start {
            return makePlan(
                prayer, start: start, now: now, place: place, settings: settings, options: options,
                segment: .prohibited, prohibitedStart: window.start
            ).map { [$0] } ?? []
        }
        return [
            makePlan(
                prayer, start: start, now: now, place: place, settings: settings, options: options,
                segment: .beforeProhibited, prohibitedStart: window.start
            ),
            makePlan(
                prayer, start: window.start, now: now, place: place, settings: settings, options: options,
                segment: .prohibited, prohibitedStart: window.start
            ),
        ].compactMap { $0 }
    }

    /// Die Verbotszeit, die mit dem Gebet endet: vor Dhuhr (Zenit) und vor Maghrib (Sonnenuntergang).
    func prohibitedWindow(before prayer: PrayerDate, place: Place, settings: CalculationSettings) -> KerahatWindow? {
        let kind: KerahatWindow.Kind
        switch prayer.prayer {
        case .dhuhr: kind = .zenith
        case .maghrib: kind = .sunset
        default: return nil
        }
        guard let times = source.times(on: prayer.day, at: place, settings: settings) else { return nil }
        return Kerahat.windows(for: times).first { $0.id == kind && abs($0.end.timeIntervalSince(prayer.date)) < 60 }
    }

    /// Plan und Inhalt einer Aktivität. Der Bogen bis zum Beginn zeigt den Stand beim Start, oder jetzt,
    /// falls die Aktivität schon läuft. `nil`, wenn für einen der nötigen Tage Zeiten fehlen.
    func makePlan(
        _ prayer: PrayerDate, start: Date, now: Date, place: Place, settings: CalculationSettings, options: Options,
        segment: LiveActivityContent.Segment = .regular, prohibitedStart: Date? = nil
    ) -> LiveActivityPlan? {
        let shownAt = min(max(start, now), prayer.date)
        guard let timeline = source.timeline(at: shownAt, place: place, settings: settings),
              let countdown = timeline.phase(at: shownAt),
              let index = timeline.events.firstIndex(where: { $0.prayer == prayer.prayer && $0.date == prayer.date }),
              index > 0,
              let begun = source.timeline(at: prayer.date, place: place, settings: settings)?.phase(at: prayer.date)
        else { return nil }

        let event = timeline.events[index]
        let previous = timeline.events[index - 1]
        let windows = [timeline.yesterday, timeline.today, timeline.tomorrow].flatMap(Kerahat.windows(for:))
        let content = LiveActivityContent(
            prayer: event, previous: previous, countdown: countdown, begun: begun,
            kerahat: options.showKerahat
                ? LiveActivityContent.kerahatMarks(between: previous.date, and: event.date, windows: windows) : [],
            cityName: options.cityName, isCurrentLocation: options.isCurrentLocation,
            showKerahat: options.showKerahat, clockOffset: options.clockOffset,
            segment: segment, prohibitedStart: prohibitedStart
        )
        return LiveActivityPlan(
            id: LiveActivityPlan.identifier(prayer: prayer.prayer, day: prayer.day, prohibited: segment == .prohibited),
            prayer: prayer.prayer, day: prayer.day, start: start, prayerDate: prayer.date,
            end: content.staleDate.addingTimeInterval(Self.endDelay), content: content
        )
    }
}
