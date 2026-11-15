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
    /// Der Schalter „Kerahat-Zeiten zeigen“: Kerahat im Bogen des Rechtecks und des Widgets „Live“.
    public let showKerahat: Bool

    public init(
        state: State, cityName: String, isCurrentLocation: Bool, clockOffset: TimeInterval = 0, showKerahat: Bool = true
    ) {
        self.state = state
        self.cityName = cityName
        self.isCurrentLocation = isCurrentLocation
        self.clockOffset = clockOffset
        self.showKerahat = showKerahat
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

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        HStack(spacing: WidgetMetrics.cityGap) {
            if showsArrow {
                Image(systemName: "location.fill")
                    .font(.system(size: WidgetMetrics.symbolSize(box: WidgetMetrics.locationBox) + 1, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)
            }
            Text(name)
                .font(WidgetMetrics.cityFont(scale))
                .tracking(WidgetMetrics.tracking)
                .lineHeight(WidgetMetrics.cityLineHeight, fontSize: 13 * scale)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// Name, Uhrzeit und Countdown des nächsten Ereignisses (`.w-name`, `.w-time`, `.w-count`).
struct WidgetNextBlock: View {
    let snapshot: WidgetSnapshot
    let content: PrayerWidgetContent

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(snapshot.next.prayer.localizedName)
                .font(WidgetMetrics.nameFont(scale))
                .tracking(WidgetMetrics.tracking)
                .lineHeight(WidgetMetrics.nameLineHeight, fontSize: 17 * scale)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(WidgetTexts.time(of: snapshot.next, in: snapshot))
                .font(WidgetMetrics.timeFont(scale))
                .tracking(WidgetMetrics.timeTracking)
                .lineHeight(WidgetMetrics.timeLineHeight, fontSize: WidgetMetrics.timeSize * scale)
                .foregroundStyle(Palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            TimerText.text(
                L10n.wIn(t:), until: content.deviceDate(snapshot.next.date), from: content.deviceDate(snapshot.now)
            )
            .font(WidgetMetrics.countFont(scale))
            .tracking(WidgetMetrics.tracking)
            .lineHeight(WidgetMetrics.countLineHeight, fontSize: 13 * scale)
            .foregroundStyle(Palette.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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
        WidgetTextScaling {
            smallContent
        }
        .padding(WidgetMetrics.smallPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private var smallContent: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        WidgetTextScaling {
            mediumContent
        }
        .padding(WidgetMetrics.mediumPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private var mediumContent: some View {
        HStack(alignment: .top, spacing: WidgetMetrics.mediumGap) {
            VStack(alignment: .leading, spacing: 0) {
                switch content.state {
                case .times(let snapshot):
                    WidgetCity(name: content.cityName, showsArrow: content.isCurrentLocation)
                    Spacer(minLength: 0)
                    WidgetCaption(text: L10n.wNext.uppercased(with: L10n.locale))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// „NÄCHSTES“ über dem nächsten Gebet im mittleren Widget (`.w-cap`).
struct WidgetCaption: View {
    let text: String

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        Text(text)
            .font(WidgetMetrics.captionFont(scale))
            .tracking(WidgetMetrics.captionTracking)
            .lineHeight(WidgetMetrics.captionLineHeight, fontSize: 11 * scale)
            .foregroundStyle(Palette.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

/// Die sechs Zeiten des Tages im mittleren Widget (`.wm-list`).
struct WidgetPrayerList: View {
    let snapshot: WidgetSnapshot

    @Environment(\.widgetTextScale) private var scale

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
        .font(WidgetMetrics.listFont(scale, isNext: isNext))
        .tracking(WidgetMetrics.tracking)
        .lineHeight(WidgetMetrics.listLineHeight, fontSize: 13 * scale)
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
    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        Text(L10n.citySheetTitle)
            .font(WidgetMetrics.nameFont(scale))
            .tracking(WidgetMetrics.tracking)
            .lineHeight(WidgetMetrics.nameLineHeight, fontSize: 17 * scale)
            .foregroundStyle(Palette.accent)
            .lineLimit(2)
    }
}

/// Ein Hinweis in der Schrift des Countdowns, z. B. `noTimes`.
struct WidgetMessage: View {
    let text: String

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        Text(text)
            .font(WidgetMetrics.countFont(scale))
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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
            // Das App-Symbol statt der Mondsichel (Spec § 9.1); iOS zeigt es auf dem Sperrbildschirm einfarbig.
            AppMark(size: .accessory)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.appName)
        }
    }

    private func label(_ snapshot: WidgetSnapshot) -> some View {
        VStack(spacing: WidgetMetrics.circularGap) {
            WidgetSymbol(name: snapshot.next.prayer.symbolName, box: WidgetMetrics.circularSymbolBox)
            // Im Ring ist Platz für das 1,2-Fache; die Höhe des Widgets begrenzt hier nichts.
            Text(WidgetTexts.time(of: snapshot.next, in: snapshot))
                .font(WidgetMetrics.circularTimeFont(WidgetMetrics.textScale(for: dynamicTypeSize)))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

/// Das Rechteck auf dem Sperrbildschirm: oben der Mini-Bogen des Tages mit Punkten und Jetzt-Punkt, darunter
/// das nächste Gebet mit Uhrzeit und der Countdown (`.acc-arcw` in `lockScreenHTML()`; Spec § 9.11). Der
/// Sperrbildschirm ist einfarbig: Kerahat ist deshalb gestrichelt statt golden.
///
/// Ohne Zeiten oder Ort stehen wie bisher der Name der App und der Hinweis da.
public struct RectangularPrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        WidgetTextScaling {
            RectangularPrayerWidgetLines(content: content)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}

/// Bogen und Zeilen des Rechtecks, in der Schrift, die `WidgetTextScaling` vorgibt.
struct RectangularPrayerWidgetLines: View {
    let content: PrayerWidgetContent

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        switch content.state {
        case .times(let snapshot):
            VStack(alignment: .leading, spacing: 0) {
                DayArc(phase: snapshot.phase, style: .lockScreen, showKerahat: content.showKerahat)
                    .accessibilityHidden(true)
                    .padding(.leading, WidgetMetrics.rectangularArcLeading)
                    .padding(.bottom, WidgetMetrics.rectangularArcBottom)
                HStack(spacing: WidgetMetrics.rectangularArcTitleGap) {
                    WidgetSymbol(name: snapshot.next.prayer.symbolName, box: WidgetMetrics.rectangularArcSymbolBox, weight: .bold)
                    Text(WidgetTexts.nameAndTime(of: snapshot.next, in: snapshot))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(WidgetMetrics.rectangularArcTitleFont(scale))
                .lineHeight(WidgetMetrics.rectangularLineHeight, fontSize: 14 * scale)
                TimerText.text(L10n.wIn(t:), until: content.deviceDate(snapshot.next.date), from: content.deviceDate(snapshot.now))
                    .font(WidgetMetrics.rectangularArcCountFont(scale))
                    .lineHeight(WidgetMetrics.rectangularLineHeight, fontSize: 12 * scale)
                    .opacity(WidgetMetrics.rectangularArcCountOpacity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(WidgetMetrics.rectangularArcPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .noTimes, .noPlace:
            VStack(alignment: .leading, spacing: WidgetMetrics.rectangularGap) {
                Text(L10n.appName)
                    .font(WidgetMetrics.rectangularTitleFont(scale))
                Text(content.state == .noTimes ? L10n.noTimes : L10n.citySheetTitle)
                    .font(WidgetMetrics.rectangularFont(scale))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .lineHeight(WidgetMetrics.rectangularLineHeight, fontSize: 13 * scale)
            .padding(WidgetMetrics.rectangularPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - systemMedium „Live“

/// Das mittlere Widget „Live“ im Stil der Live-Aktivität: Kopf mit App-Symbol, Name der App und Stadt,
/// darunter der Tagesbogen in Weiß auf Akzent, im Bogen „Maghrib · 16:27“ und der Countdown (`.w-la` in
/// `homeScreenHTML()`; Spec § 9.11). Den Verlauf dahinter setzt `LiveActivityBackground`.
///
/// Die Schrift wächst wie in der Live-Aktivität nicht mit Dynamic Type: Der Text steht im Bogen, und der
/// hat eine feste Größe.
public struct LivePrayerWidget: View {
    private let content: PrayerWidgetContent

    public init(content: PrayerWidgetContent) {
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch content.state {
            case .times(let snapshot):
                LiveHeader(cityName: content.cityName)
                DayArc(phase: snapshot.phase, style: .liveWidget, showKerahat: content.showKerahat) {
                    VStack(spacing: 0) {
                        Text(snapshot.next.prayer.localizedName + " · " + WidgetTexts.time(of: snapshot.next, in: snapshot))
                            .font(LiveActivityMetrics.nameFont)
                            .opacity(LiveActivityMetrics.nameOpacity)
                            .lineHeight(LiveActivityMetrics.nameLineHeight, fontSize: 13)
                        Text(timerInterval: countdown(snapshot), countsDown: true)
                            .font(LiveActivityMetrics.countFont)
                            .tracking(LiveActivityMetrics.countTracking)
                            .multilineTextAlignment(.center)
                            .lineHeight(LiveActivityMetrics.countLineHeight, fontSize: LiveActivityMetrics.countSize)
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.top, WidgetMetrics.liveArcTop)
            case .noTimes:
                LiveHeader(cityName: content.cityName)
                message(L10n.noTimes)
            case .noPlace:
                LiveHeader(cityName: "")
                message(L10n.citySheetTitle)
            }
        }
        .padding(WidgetMetrics.livePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }

    /// Countdown in Gerätezeit bis zum nächsten Ereignis.
    private func countdown(_ snapshot: WidgetSnapshot) -> ClosedRange<Date> {
        let end = content.deviceDate(snapshot.next.date)
        return min(content.deviceDate(snapshot.now), end)...end
    }

    /// Ein Hinweis mitten im Widget, wo sonst der Bogen steht – in der Schrift von „Maghrib · 16:27“.
    private func message(_ text: String) -> some View {
        Text(text)
            .font(LiveActivityMetrics.nameFont)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
