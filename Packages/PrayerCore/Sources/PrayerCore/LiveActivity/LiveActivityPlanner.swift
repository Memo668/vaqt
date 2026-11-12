import Foundation

/// Eine geplante Live-Aktivität: eine je Gebet (Spec § 4, Frage 16 entschieden mit dem Plan für Phase 9).
public struct LiveActivityPlan: Hashable, Sendable, Identifiable {
    /// Kennung, die für dasselbe Gebet gleich bleibt, z. B. `live.2026-11-10.maghrib`.
    public let id: String
    public let prayer: Prayer
    /// Der Tag, zu dem das Gebet gehört. Ein Ischa nach Mitternacht gehört zum Vortag.
    public let day: CalendarDay
    /// Ab hier läuft die Aktivität (App-Uhr): so viele Minuten vor dem Gebet, wie eingestellt.
    public let start: Date
    /// Gebetsbeginn: Ab hier ist die Aktivität `isStale` und zeigt „Jetzt“.
    public let prayerDate: Date
    /// 15 Minuten nach Gebetsbeginn endet die Aktivität (Einstellungen › Live-Aktivität, `liveActFooter`).
    public let end: Date
    public let content: LiveActivityContent

    /// Minuten zwischen Start und Gebet, für den Hinweis beim Start („Maghrib in 30 Minuten“).
    public var leadMinutes: Int {
        Int((prayerDate.timeIntervalSince(start) / 60).rounded())
    }

    /// Die Kennung zu Gebet und Tag.
    public static func identifier(prayer: Prayer, day: CalendarDay) -> String {
        "live." + day.description + "." + prayer.rawValue
    }
}

/// Welche Live-Aktivitäten die App bei iOS anmeldet: je Pflichtgebet eine, ohne Sonnenaufgang (entschieden
/// mit dem Plan für Phase 9; Spec § 4, Frage 16).
///
/// Eine Aktivität beginnt so viele Minuten vor dem Gebet, wie unter Einstellungen › Live-Aktivität gewählt
/// (Standard 30), zählt bis zum Gebetsbeginn herunter, zeigt dann „Jetzt“ und endet 15 Minuten nach
/// Beginn. iOS startet sie selbst zum geplanten Zeitpunkt (`Activity.request(…, start:)`), auch wenn die
/// App nicht läuft.
///
/// Damit nicht zwei Aktivitäten zugleich laufen, beginnt eine Aktivität frühestens, wenn die des vorigen
/// Gebets endet – bei langem Vorlauf oder dicht folgenden Gebeten (Maghrib und Ischa) also etwas später.
/// Liegen zwei Gebete weniger als 15 Minuten auseinander (Regel „Nachtmitte“), überlappen sie.
public struct LiveActivityPlanner: Sendable {

    /// So lange nach Gebetsbeginn läuft eine Aktivität noch.
    public static let endDelay: TimeInterval = 15 * 60
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
            let end = next.date.addingTimeInterval(Self.endDelay)
            guard end > now,
                  let plan = makePlan(next, start: debugStart, now: now, place: place, settings: settings, options: options)
            else { return [] }
            return [plan]
        }

        let lead = TimeInterval(options.leadMinutes) * 60
        let latestStart = now.addingTimeInterval(Self.horizon)
        var plans: [LiveActivityPlan] = []
        // Eine Aktivität, deren Gebet schon begonnen hat, beendet die App sogleich (sie bleibt nur auf dem
        // Sperrbildschirm stehen); sie zählt deshalb nicht zur Höchstzahl.
        var upcoming = 0
        for (index, prayer) in prayers.enumerated() {
            if prayer.date > now {
                guard upcoming < limit else { break }
            }
            var start = prayer.date.addingTimeInterval(-lead)
            if index > 0 {
                // Frühestens, wenn die Aktivität des vorigen Gebets endet – außer die beiden liegen so dicht,
                // dass dann schon dieses Gebet begonnen hätte.
                let previousEnd = prayers[index - 1].date.addingTimeInterval(Self.endDelay)
                if previousEnd > start, previousEnd < prayer.date {
                    start = previousEnd
                }
            }
            let end = prayer.date.addingTimeInterval(Self.endDelay)
            guard end > now else { continue }
            guard start <= latestStart else { break }
            if let plan = makePlan(prayer, start: start, now: now, place: place, settings: settings, options: options) {
                plans.append(plan)
                if prayer.date > now {
                    upcoming += 1
                }
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

    /// Plan und Inhalt einer Aktivität. Der Bogen bis zum Beginn zeigt den Stand beim Start, oder jetzt,
    /// falls die Aktivität schon läuft. `nil`, wenn für einen der nötigen Tage Zeiten fehlen.
    func makePlan(
        _ prayer: PrayerDate, start: Date, now: Date, place: Place, settings: CalculationSettings, options: Options
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
            showKerahat: options.showKerahat, clockOffset: options.clockOffset
        )
        return LiveActivityPlan(
            id: LiveActivityPlan.identifier(prayer: prayer.prayer, day: prayer.day),
            prayer: prayer.prayer, day: prayer.day, start: start, prayerDate: prayer.date,
            end: prayer.date.addingTimeInterval(Self.endDelay), content: content
        )
    }
}
