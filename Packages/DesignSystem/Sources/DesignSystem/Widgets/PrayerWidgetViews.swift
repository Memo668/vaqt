import PrayerCore
import SwiftUI

/// Was ein Widget zeigt: die Zeiten zu einem Eintrag der Zeitleiste, oder einen Hinweis, wenn es keinen
/// Ort oder keine Zeiten gibt (entschieden mit dem Plan für Phase 9).
public struct PrayerWidgetContent: Hashable, Sendable {

    public enum State: Hashable, Sendable {
        /// Die Zeiten zu einem Eintrag der Zeitleiste.
        case times(WidgetSnapshot)
        /// Für den Ort lassen sich keine Zeiten berechnen – der Hinweis der Zeiten-Seite (`noTimes`).
        case noTimes
        /// Die App kennt noch keinen Ort – „Stadt wählen“.
        case noPlace
    }

    public let state: State
    /// Name des Ortes wie auf der Zeiten-Seite.
    public let cityName: String
    /// Ob der Ort der aktuelle Standort ist; dann steht im mittleren Widget der Pfeil davor.
    public let isCurrentLocation: Bool
    /// Uhr der App minus Gerätezeit (`-debugTime`); sonst 0.
    public let clockOffset: TimeInterval

    public init(state: State, cityName: String, isCurrentLocation: Bool, clockOffset: TimeInterval = 0) {
        self.state = state
        self.cityName = cityName
        self.isCurrentLocation = isCurrentLocation
        self.clockOffset = clockOffset
    }

    /// Der Zeitpunkt der Gerätezeit zu einem der App-Uhr. Countdown und Ring laufen in Gerätezeit.
    func deviceDate(_ date: Date) -> Date {
        date.addingTimeInterval(-clockOffset)
    }
}

// MARK: - Texte

/// Texte der Widgets aus dem String Catalog.
enum WidgetTexts {

    /// Uhrzeit eines Ereignisses am Ort, z. B. „16:27“ (`fmt()`).
    static func time(of event: DayPhase.Event, in snapshot: WidgetSnapshot) -> String {
        ClockTime(event.date, in: snapshot.list.timeZone).description
    }

    /// „Ischa 18:17“ – Name und Uhrzeit.
    static func nameAndTime(of event: DayPhase.Event, in snapshot: WidgetSnapshot) -> String {
        event.prayer.localizedName + " " + time(of: event, in: snapshot)
    }
}

/// Ein Countdown, der von selbst läuft (`Text(timerInterval:)`), eingesetzt in einen Text des String
/// Catalogs mit Platzhalter – z. B. `wIn`: „in 2:01:29“, türkisch „2:01:29 sonra“.
public enum TimerText {

    /// Platzhalter, an dem der Text geteilt wird.
    static let marker = "\u{FFFC}"

    /// Der Text vor und nach dem Platzhalter.
    static func parts(_ format: (String) -> String) -> (prefix: String, suffix: String) {
        let text = format(marker)
        guard let range = text.range(of: marker) else { return (text + " ", "") }
        return (String(text[..<range.lowerBound]), String(text[range.upperBound...]))
    }

    /// Der Text mit dem laufenden Countdown an der Stelle des Platzhalters.
    public static func text(_ format: (String) -> String, until end: Date, from start: Date) -> Text {
        let (prefix, suffix) = parts(format)
        let timer = Text(timerInterval: min(start, end)...end, countsDown: true)
        return Text("\(Text(verbatim: prefix))\(timer)\(Text(verbatim: suffix))")
    }
}

// MARK: - Bausteine

/// Ein SF Symbol in der Größe eines Symbols des Prototyps.
struct WidgetSymbol: View {
    let name: String
    let box: CGFloat
    var weight: Font.Weight = .semibold

    var body: some View {
        Image(systemName: name)
            .font(.system(size: WidgetMetrics.symbolSize(box: box), weight: weight))
            .frame(width: box, height: box)
            .accessibilityHidden(true)
    }
}

/// Die Stadt oben im Widget (`.w-city`), im mittleren Widget mit dem Pfeil davor.
struct WidgetCity: View {
    let name: String
    var showsArrow = false

    var body: some View {
        HStack(spacing: WidgetMetrics.cityGap) {
            if showsArrow {
                Image(systemName: "location.fill")
                    .font(.system(size: WidgetMetrics.symbolSize(box: WidgetMetrics.locationBox) + 1, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)
            }
            Text(name)
                .font(WidgetMetrics.cityFont)
                .tracking(WidgetMetrics.tracking)
                .lineHeight(WidgetMetrics.cityLineHeight, fontSize: 13)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
        }
    }
}

/// Name, Uhrzeit und Countdown des nächsten Ereignisses (`.w-name`, `.w-time`, `.w-count`).
struct WidgetNextBlock: View {
    let snapshot: WidgetSnapshot
    let content: PrayerWidgetContent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(snapshot.next.prayer.localizedName)
                .font(WidgetMetrics.nameFont)
                .tracking(WidgetMetrics.tracking)
                .lineHeight(WidgetMetrics.nameLineHeight, fontSize: 17)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(WidgetTexts.time(of: snapshot.next, in: snapshot))
                .font(WidgetMetrics.timeFont)
                .tracking(WidgetMetrics.timeTracking)
                .lineHeight(WidgetMetrics.timeLineHeight, fontSize: WidgetMetrics.timeSize)
                .foregroundStyle(Palette.label)
            TimerText.text(
                L10n.wIn(t:), until: content.deviceDate(snapshot.next.date), from: content.deviceDate(snapshot.now)
            )
            .font(WidgetMetrics.countFont)
            .tracking(WidgetMetrics.tracking)
            .lineHeight(WidgetMetrics.countLineHeight, fontSize: 13)
            .foregroundStyle(Palette.textSecondary)
            .lineLimit(1)
        }
    }
}

// MARK: - systemSmall

/// Das kleine Widget: Stadt und Symbol oben, unten das nächste Ereignis mit Uhrzeit und Countdown
/// (`.w-small` in `homeScreenHTML()`).
public struct SmallPrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch content.state {
            case .times(let snapshot):
                HStack(spacing: 0) {
                    WidgetCity(name: content.cityName)
                    Spacer(minLength: 4)
                    WidgetSymbol(name: snapshot.next.prayer.symbolName, box: WidgetMetrics.smallSymbolBox)
                        .foregroundStyle(Palette.accent)
                }
                Spacer(minLength: 0)
                WidgetNextBlock(snapshot: snapshot, content: content)
            case .noTimes:
                WidgetCity(name: content.cityName)
                Spacer(minLength: 0)
                WidgetMessage(text: L10n.noTimes)
            case .noPlace:
                WidgetCity(name: L10n.appName)
                Spacer(minLength: 0)
                WidgetChooseCity()
            }
        }
        .padding(WidgetMetrics.smallPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - systemMedium

/// Das mittlere Widget: links Stadt, „NÄCHSTES“, Name, Uhrzeit und Countdown, rechts die sechs Zeiten des
/// Tages mit dem nächsten Ereignis hervorgehoben (`.w-medium` in `homeScreenHTML()`; Spec § 7, Variante 6:
/// die Widgets heben das nächste Gebet hervor).
public struct MediumPrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        HStack(alignment: .top, spacing: WidgetMetrics.mediumGap) {
            VStack(alignment: .leading, spacing: 0) {
                switch content.state {
                case .times(let snapshot):
                    WidgetCity(name: content.cityName, showsArrow: content.isCurrentLocation)
                    Spacer(minLength: 0)
                    Text(L10n.wNext.uppercased(with: L10n.locale))
                        .font(WidgetMetrics.captionFont)
                        .tracking(WidgetMetrics.captionTracking)
                        .lineHeight(WidgetMetrics.captionLineHeight, fontSize: 11)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                    WidgetNextBlock(snapshot: snapshot, content: content)
                case .noTimes:
                    WidgetCity(name: content.cityName, showsArrow: content.isCurrentLocation)
                    Spacer(minLength: 0)
                case .noPlace:
                    WidgetCity(name: L10n.appName)
                    Spacer(minLength: 0)
                    WidgetChooseCity()
                }
            }
            .frame(width: WidgetMetrics.mediumLeftWidth, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .topLeading)

            switch content.state {
            case .times(let snapshot):
                WidgetPrayerList(snapshot: snapshot)
            case .noTimes:
                WidgetMessage(text: L10n.noTimes)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            case .noPlace:
                Spacer(minLength: 0)
            }
        }
        .padding(WidgetMetrics.mediumPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}

/// Die sechs Zeiten des Tages im mittleren Widget (`.wm-list`).
struct WidgetPrayerList: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(Prayer.allCases.enumerated()), id: \.element) { index, prayer in
                if index > 0 {
                    Spacer(minLength: 0)
                }
                row(prayer)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func row(_ prayer: Prayer) -> some View {
        let isNext = snapshot.isNext(prayer)
        let isPassed = snapshot.passed.contains(prayer)
        return HStack(spacing: WidgetMetrics.listRowGap) {
            Text(prayer.localizedName)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Text(snapshot.list.clockTime(of: prayer).description)
        }
        .font(isNext ? WidgetMetrics.listNextFont : WidgetMetrics.listFont)
        .tracking(WidgetMetrics.tracking)
        .lineHeight(WidgetMetrics.listLineHeight, fontSize: 13)
        .foregroundStyle(isNext ? Palette.accent : isPassed ? Palette.labelTertiary : Palette.label)
        .padding(WidgetMetrics.listRowPadding)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: WidgetMetrics.listRowRadius, style: .continuous)
                    .fill(Palette.accentTint)
            }
        }
    }
}

/// „Stadt wählen“ in der Schrift des Gebetsnamens – das Widget, solange die App keinen Ort kennt.
struct WidgetChooseCity: View {
    var body: some View {
        Text(L10n.citySheetTitle)
            .font(WidgetMetrics.nameFont)
            .tracking(WidgetMetrics.tracking)
            .lineHeight(WidgetMetrics.nameLineHeight, fontSize: 17)
            .foregroundStyle(Palette.accent)
            .lineLimit(2)
    }
}

/// Ein Hinweis in der Schrift des Countdowns, z. B. `noTimes`.
struct WidgetMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(WidgetMetrics.countFont)
            .tracking(WidgetMetrics.tracking)
            .foregroundStyle(Palette.textSecondary)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - accessoryCircular

/// Der Ring auf dem Sperrbildschirm: läuft vom vorigen bis zum nächsten Ereignis, innen Symbol und Uhrzeit
/// des nächsten (`.acc-circ`; Spec § 3: „Gauge from previous → next“).
///
/// Der Ring ist eine `ProgressView` mit Zeitspanne: iOS lässt ihn selbst weiterlaufen. Den Hintergrund
/// (`AccessoryWidgetBackground`) setzt die Extension.
public struct CircularPrayerWidget: View {
    private let content: PrayerWidgetContent
    private let drawsRing: Bool

    /// - Parameter drawsRing: den Ring selbst zeichnen, im Stand des Eintrags – für den Katalog. In der
    ///   App zeichnet iOS eine kreisförmige `ProgressView` als Kreisel statt als Ring.
    public init(content: PrayerWidgetContent, drawsRing: Bool = false) {
        self.content = content
        self.drawsRing = drawsRing
    }

    public var body: some View {
        switch content.state {
        case .times(let snapshot):
            Group {
                if drawsRing {
                    ZStack {
                        CatalogRing(fraction: fraction(snapshot))
                        label(snapshot)
                    }
                } else {
                    ProgressView(
                        timerInterval: interval(snapshot), countsDown: false,
                        label: { EmptyView() },
                        currentValueLabel: { label(snapshot) }
                    )
                    .progressViewStyle(.circular)
                    .tint(.white)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(WidgetTexts.nameAndTime(of: snapshot.next, in: snapshot))
        case .noTimes, .noPlace:
            AppGlyph()
                .frame(width: 24, height: 24)
                .accessibilityLabel(L10n.appName)
        }
    }

    private func label(_ snapshot: WidgetSnapshot) -> some View {
        VStack(spacing: WidgetMetrics.circularGap) {
            WidgetSymbol(name: snapshot.next.prayer.symbolName, box: WidgetMetrics.circularSymbolBox)
            Text(WidgetTexts.time(of: snapshot.next, in: snapshot))
                .font(WidgetMetrics.circularTimeFont)
        }
    }

    /// Anteil des Rings im Stand des Eintrags (`prog` in `lockScreenHTML()`).
    private func fraction(_ snapshot: WidgetSnapshot) -> Double {
        let span = snapshot.next.date.timeIntervalSince(snapshot.previous.date)
        guard span > 0 else { return 1 }
        return min(1, max(0, 1 - snapshot.remaining / span))
    }

    private func interval(_ snapshot: WidgetSnapshot) -> ClosedRange<Date> {
        let start = content.deviceDate(snapshot.previous.date)
        let end = content.deviceDate(snapshot.next.date)
        return min(start, end)...end
    }
}

/// Der Ring des Prototyps zum Zeichnen von Hand – für den Katalog, der ihn ohne WidgetKit zeigt
/// (`.ring-bg`, `.ring-fg`).
public struct CatalogRing: View {
    private let fraction: Double

    public init(fraction: Double) {
        self.fraction = fraction
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(WidgetMetrics.ringTrackOpacity), lineWidth: WidgetMetrics.ringWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(.white, style: StrokeStyle(lineWidth: WidgetMetrics.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: WidgetMetrics.ringRadius * 2, height: WidgetMetrics.ringRadius * 2)
    }
}

// MARK: - accessoryRectangular

/// Das Rechteck auf dem Sperrbildschirm: nächstes Gebet, Uhrzeit mit Countdown, das Gebet danach
/// (`.acc-rect`).
public struct RectangularPrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WidgetMetrics.rectangularGap) {
            switch content.state {
            case .times(let snapshot):
                HStack(spacing: WidgetMetrics.rectangularTitleGap) {
                    WidgetSymbol(name: snapshot.next.prayer.symbolName, box: WidgetMetrics.rectangularSymbolBox, weight: .bold)
                    Text(snapshot.next.prayer.localizedName)
                        .font(WidgetMetrics.rectangularTitleFont)
                        .lineLimit(1)
                }
                Text("\(Text(verbatim: WidgetTexts.time(of: snapshot.next, in: snapshot) + " · "))\(TimerText.text(L10n.wIn(t:), until: content.deviceDate(snapshot.next.date), from: content.deviceDate(snapshot.now)))")
                    .font(WidgetMetrics.rectangularFont)
                    .lineLimit(1)
                Text(WidgetTexts.nameAndTime(of: snapshot.following, in: snapshot))
                    .font(WidgetMetrics.rectangularFont)
                    .opacity(WidgetMetrics.followingOpacity)
                    .lineLimit(1)
            case .noTimes:
                Text(L10n.appName)
                    .font(WidgetMetrics.rectangularTitleFont)
                Text(L10n.noTimes)
                    .font(WidgetMetrics.rectangularFont)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            case .noPlace:
                Text(L10n.appName)
                    .font(WidgetMetrics.rectangularTitleFont)
                Text(L10n.citySheetTitle)
                    .font(WidgetMetrics.rectangularFont)
            }
        }
        .lineHeight(WidgetMetrics.rectangularLineHeight, fontSize: 13)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - accessoryInline

/// Die Zeile über der Uhr: Symbol und „Maghrib 16:27“ (`.ls-inline`). Schrift und Farbe gibt iOS vor.
public struct InlinePrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        switch content.state {
        case .times(let snapshot):
            Label {
                Text(WidgetTexts.nameAndTime(of: snapshot.next, in: snapshot))
            } icon: {
                Image(systemName: snapshot.next.prayer.symbolName)
            }
        case .noTimes, .noPlace:
            Text(L10n.appName)
        }
    }
}
