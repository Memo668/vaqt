import DesignSystem
import PrayerCore
import SwiftUI
import WidgetKit

/// Ein Eintrag der Zeitleiste: ab `date` (Gerätezeit) zeigen die Widgets `content`, in der Sprache der App.
struct PrayerEntry: TimelineEntry {
    let date: Date
    let content: PrayerWidgetContent
    let language: AppLanguage?
}

/// Die Zeitleiste der Widgets (Spec § 3, „Widgets“).
///
/// Sie rechnet mit PrayerCore aus dem, was die App in die App Group geschrieben hat (`WidgetState`): Ort,
/// Rechen-Einstellungen samt Minutenkorrektur und Sprache. Hat die App noch nichts geschrieben oder kennt
/// sie keinen Ort, zeigen die Widgets „Stadt wählen“; die App lädt sie neu, sobald es einen Ort gibt.
struct PrayerTimelineProvider: TimelineProvider {

    /// Das Widget, für das die Zeitleiste ist (`PrayerTimesWidget.kind`, `PrayerLiveWidget.kind`).
    let kind: String

    /// Abstand der Einträge für den Bogen je Widget und Größe: im Widget „Live“ alle 5 Minuten, im Rechteck
    /// des Sperrbildschirms alle 10 Minuten, sonst nur zu den Ereignissen – die übrigen Größen zeigen keinen
    /// Bogen, und jeder Eintrag vergrößert das Archiv, das iOS bei 10 MB ablehnt (Phase 14).
    static func arcStep(kind: String, family: WidgetFamily) -> TimeInterval? {
        if kind == PrayerLiveWidget.kind { return WidgetTimeline.arcStep }
        if family == .accessoryRectangular { return WidgetTimeline.lockScreenArcStep }
        return nil
    }

    func placeholder(in context: Context) -> PrayerEntry {
        timeline(at: Date()).entries.first ?? Self.noPlace(at: Date(), language: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(timeline(at: Date()).entries.first ?? Self.noPlace(at: Date(), language: nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        completion(timeline(at: Date(), arcStep: Self.arcStep(kind: kind, family: context.family)))
    }

    /// Die Zeitleiste ab `deviceNow`.
    func timeline(at deviceNow: Date, arcStep: TimeInterval? = nil) -> Timeline<PrayerEntry> {
        guard let state = WidgetState.sharedDefaults.flatMap(WidgetState.load(from:)) else {
            return Timeline(entries: [Self.noPlace(at: deviceNow, language: nil)], policy: .never)
        }
        guard let place = state.place else {
            return Timeline(entries: [Self.noPlace(at: deviceNow, language: state.language)], policy: .never)
        }
        // Mit `-debugTime` läuft die Uhr der App anders als die des Geräts: gerechnet wird in App-Zeit,
        // die Einträge stehen in Gerätezeit.
        let offset = state.clockOffset
        // Mit Zwischenschritten für den Bogen im Rechteck und im Widget „Live“ (Phase 14).
        let result = WidgetTimeline.entries(
            from: deviceNow.addingTimeInterval(offset), source: Self.timesSource(for: state), place: place,
            settings: state.calculation, arcStep: arcStep
        )
        let entries = result.entries.map { entry in
            PrayerEntry(
                date: entry.date.addingTimeInterval(-offset),
                content: PrayerWidgetContent(
                    state: Self.widgetState(entry.content), cityName: state.cityName,
                    isCurrentLocation: state.isCurrentLocation, clockOffset: offset, showKerahat: state.showKerahat
                ),
                language: state.language
            )
        }
        return Timeline(entries: entries, policy: .after(result.reloadDate.addingTimeInterval(-offset)))
    }

    /// Woher die Zeiten kommen: die echte Rechnung, in DEBUG mit `-debugFixtureTimes` die Mock-Zeiten.
    static func timesSource(for state: WidgetState) -> any PrayerTimesSource {
        #if DEBUG
        if let debug = state.debug, debug.fixtureTimes {
            return FixtureTimesSource(highLatitude: debug.highLatitude)
        }
        #endif
        return AdhanTimesSource()
    }

    static func widgetState(_ content: WidgetTimeline.Content) -> PrayerWidgetContent.State {
        switch content {
        case .times(let snapshot): .times(snapshot)
        case .noTimes: .noTimes
        }
    }

    static func noPlace(at date: Date, language: AppLanguage?) -> PrayerEntry {
        PrayerEntry(
            date: date, content: PrayerWidgetContent(state: .noPlace, cityName: "", isCurrentLocation: false),
            language: language
        )
    }
}

/// Die Ansicht je Größe.
struct PrayerTimesWidgetView: View {
    let entry: PrayerEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        // Die Texte in der Sprache der App, bevor die Ansichten sie lesen.
        L10n.chosenLanguage = entry.language
        return content
            .environment(\.locale, L10n.locale)
            .environment(\.layoutDirection, L10n.layoutDirection)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:
            MediumPrayerWidget(content: entry.content)
                .containerBackground(Palette.backgroundCell, for: .widget)
        // Die helle, durchscheinende Fläche des Prototyps (`.acc`) liegt im Inhalt: Als Hintergrund des
        // Containers ließe iOS sie auf dem Sperrbildschirm weg.
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                CircularPrayerWidget(content: entry.content)
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryRectangular:
            ZStack {
                AccessoryWidgetBackground()
                    .clipShape(.rect(cornerRadius: WidgetMetrics.rectangularRadius, style: .continuous))
                RectangularPrayerWidget(content: entry.content)
            }
            .containerBackground(for: .widget) { Color.clear }
        case .accessoryInline:
            InlinePrayerWidget(content: entry.content)
                .containerBackground(for: .widget) { Color.clear }
        default:
            SmallPrayerWidget(content: entry.content)
                .containerBackground(Palette.backgroundCell, for: .widget)
        }
    }
}

/// Das Widget der App in fünf Größen: klein und mittel auf dem Home-Bildschirm, rund, rechteckig und als
/// Zeile auf dem Sperrbildschirm (Spec § 3). Das Rechteck zeigt seit Phase 14 den Mini-Bogen (§ 9.11).
struct PrayerTimesWidget: Widget {
    nonisolated static let kind = "PrayerTimes"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerTimelineProvider(kind: Self.kind)) { entry in
            PrayerTimesWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.appName)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        // Die Abstände setzt das Widget selbst, wie im Prototyp.
        .contentMarginsDisabled()
    }
}

/// Das mittlere Widget „Live“ im Stil der Live-Aktivität: Akzentverlauf, Tagesbogen, nächstes Gebet und
/// Countdown (Spec § 9.11, seit Phase 14). Ein eigenes Widget neben `PrayerTimesWidget`, weil es von jeder
/// Größe nur eine Ansicht je Widget gibt; in der Galerie heißt es wie die anderen nach der App
/// (entschieden mit dem Plan für Phase 14).
struct PrayerLiveWidget: Widget {
    nonisolated static let kind = "PrayerLive"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerTimelineProvider(kind: Self.kind)) { entry in
            PrayerLiveWidgetView(entry: entry)
        }
        .configurationDisplayName(L10n.appName)
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

/// Die Ansicht des Widgets „Live“: der Verlauf der Live-Aktivität als Hintergrund des Containers.
struct PrayerLiveWidgetView: View {
    let entry: PrayerEntry

    var body: some View {
        // Die Texte in der Sprache der App, bevor die Ansichten sie lesen.
        L10n.chosenLanguage = entry.language
        return LivePrayerWidget(content: entry.content)
            .environment(\.locale, L10n.locale)
            .environment(\.layoutDirection, L10n.layoutDirection)
            .containerBackground(for: .widget) { LiveActivityBackground() }
    }
}
