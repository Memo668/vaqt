import PrayerCore
import SwiftUI

// MARK: - Zeilen

/// Eine Zeile eines kleinen Widgets (Spec § 3, § 12.1, § 12.2): was in welchem Zustand steht – als Daten, damit die
/// Tests es prüfen können und die Ansichten nichts selbst entscheiden.
public enum SmallWidgetLine: Hashable, Sendable {
    /// Der Ort; mit dem Pfeil davor, wenn es der aktuelle Standort ist und das Widget den Pfeil zeigt.
    case city(String, showsArrow: Bool)
    /// Symbol und Name des nächsten Ereignisses.
    case prayer(Prayer)
    /// Die Uhrzeit des nächsten Ereignisses; im Tagesbogen „Maghrib · 16:27“.
    case time(String)
    /// Der Countdown bis zum nächsten Ereignis – „in 2:01:29“ bzw. im Tagesbogen „2:01:29“.
    case countdown
    /// „Verbotszeit bis 16:27“, solange eine Verbotszeit läuft (`kerahatNow`).
    case kerahat(String)
    /// Der Name der App, solange es keinen Ort gibt.
    case appName
    /// Ein Hinweis statt der Zeiten (`noTimes`, „Stadt wählen“).
    case message(String)
}

extension PrayerWidgetContent {

    /// „Verbotszeit bis 16:27“, solange eine Verbotszeit läuft und die App Verbotszeiten zeigt; sonst `nil`. Das Ende
    /// kommt aus den Fenstern der Rechtsschule (Spec § 11.6).
    public func prohibitedText(_ snapshot: WidgetSnapshot) -> String? {
        guard showKerahat, let window = snapshot.phase.activeKerahat else { return nil }
        return L10n.kerahatNow(b: L10n.time(ClockTime(window.end, in: snapshot.list.timeZone)))
    }
}

// MARK: - systemSmall „Nächstes Gebet“ ohne Hintergrund

extension SmallPrayerWidget {

    /// Die Zeilen des kleinen Widgets „Nächstes Gebet“ (Spec § 12.1). Mit Hintergrund (Home-Bildschirm) wie bisher:
    /// Stadt und Symbol oben, Name, Uhrzeit und Countdown unten – ohne Verbotszeit. Ohne Hintergrund (StandBy,
    /// CarPlay) Symbol und Name, Uhrzeit groß, Countdown und während einer Verbotszeit „Verbotszeit bis …“ – ohne Stadt.
    /// Reine Rechnung, an keinen Actor gebunden – die Ansicht ist es als `View`.
    public nonisolated static func lines(for content: PrayerWidgetContent, showsBackground: Bool) -> [SmallWidgetLine] {
        switch content.state {
        case .times(let snapshot):
            let time = WidgetTexts.time(of: snapshot.next, in: snapshot)
            if showsBackground {
                return [.city(content.cityName, showsArrow: false), .prayer(snapshot.next.prayer), .time(time), .countdown]
            }
            let lines: [SmallWidgetLine] = [.prayer(snapshot.next.prayer), .time(time), .countdown]
            return lines + (content.prohibitedText(snapshot).map { [.kerahat($0)] } ?? [])
        case .noTimes:
            return [.city(content.cityName, showsArrow: false), .message(L10n.noTimes)]
        case .noPlace:
            return [.appName, .message(L10n.citySheetTitle)]
        }
    }
}

/// Das kleine Widget ohne Hintergrund, wie StandBy und CarPlay es zeigen (`.cpw-next`, Spec § 12.1): links und
/// senkrecht mittig Symbol und Name des nächsten Gebets in Akzent, die Uhrzeit groß, „in 2:01:29“ und während einer
/// Verbotszeit der Punkt mit „Verbotszeit bis 16:27“. Die Stadt fällt weg – das Auto und der Nachttisch brauchen sie
/// nicht, und die Uhrzeit bekommt den Platz.
struct BareSmallPrayerWidget: View {
    let content: PrayerWidgetContent

    @Environment(\.widgetTextScale) private var scale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(SmallPrayerWidget.lines(for: content, showsBackground: false).enumerated()), id: \.offset) { index, line in
                row(line, isFirst: index == 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func row(_ line: SmallWidgetLine, isFirst: Bool) -> some View {
        switch line {
        case .prayer(let prayer):
            HStack(spacing: WidgetMetrics.bareSymbolGap) {
                WidgetSymbol(name: prayer.symbolName, box: WidgetMetrics.bareSymbolBox)
                Text(prayer.localizedName)
                    .font(WidgetMetrics.bareNameFont(scale))
                    .tracking(WidgetMetrics.bareNameTracking)
                    .lineHeight(WidgetMetrics.bareNameLineHeight, fontSize: WidgetMetrics.bareNameSize * scale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Palette.accent)
        case .appName:
            Text(L10n.appName)
                .font(WidgetMetrics.bareNameFont(scale))
                .tracking(WidgetMetrics.bareNameTracking)
                .lineHeight(WidgetMetrics.bareNameLineHeight, fontSize: WidgetMetrics.bareNameSize * scale)
                .foregroundStyle(Palette.accent)
                .lineLimit(1)
        case .time(let time):
            Text(time)
                .font(WidgetMetrics.bareTimeFont(scale))
                .tracking(WidgetMetrics.bareTimeTracking)
                .lineHeight(WidgetMetrics.bareTimeLineHeight, fontSize: WidgetMetrics.bareTimeSize * scale)
                .foregroundStyle(Palette.label)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, WidgetMetrics.bareTimeTop)
        case .countdown:
            if case .times(let snapshot) = content.state {
                TimerText.text(
                    L10n.wIn(t:), until: content.deviceDate(snapshot.next.date), from: content.deviceDate(snapshot.now)
                )
                .font(WidgetMetrics.bareCountFont(scale))
                .lineHeight(WidgetMetrics.bareCountLineHeight, fontSize: WidgetMetrics.bareCountSize * scale)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, WidgetMetrics.bareCountTop)
            }
        case .kerahat(let text):
            HStack(spacing: WidgetMetrics.bareKerahatGap) {
                Circle()
                    .fill(Palette.kerahat)
                    .frame(width: WidgetMetrics.kerahatDot, height: WidgetMetrics.kerahatDot)
                    .accessibilityHidden(true)
                Text(text)
                    .font(WidgetMetrics.bareKerahatFont(scale))
                    .tracking(WidgetMetrics.bareKerahatTracking)
                    .lineHeight(WidgetMetrics.bareKerahatLineHeight, fontSize: WidgetMetrics.bareKerahatSize * scale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.kerahatText)
            .padding(.top, WidgetMetrics.bareKerahatTop)
        case .city(let name, _):
            WidgetCity(name: name)
        case .message(let text):
            WidgetMessage(text: text)
                .padding(.top, isFirst ? 0 : WidgetMetrics.bareCountTop)
        }
    }
}

// MARK: - systemSmall „Tagesbogen“

/// Das kleine Widget „Tagesbogen“ (`.cpw-arcw`, Spec § 12.2, seit Phase 19): der Tagesbogen mit Sonnenaufgang und
/// Verbotszeiten (§ 9.11, § 9.14, § 10.1), darin „Maghrib · 16:27“ und der Countdown, darunter der Ort – während
/// einer Verbotszeit „Verbotszeit bis …“. Den Bogen zeigt es nur mit Hintergrund, auf dem Home-Bildschirm; den
/// Hintergrund setzt die Extension.
///
/// Ohne Hintergrund – in StandBy und CarPlay – zeigt es dieselbe große Anordnung wie „Nächstes Gebet“ (§ 12.1):
/// Aus der Entfernung sagen der Halbkreis und seine sieben Punkte nichts (entschieden am 25.11.2026 nach dem Test am
/// Gerät).
///
/// Die Schrift im Bogen wächst wie im Rechteck des Sperrbildschirms nicht mit Dynamic Type: Der Text steht im Bogen, und
/// der hat eine feste Größe.
public struct SmallArcPrayerWidget: View {
    private let content: PrayerWidgetContent
    private let showsBackground: Bool

    /// - Parameter showsBackground: ob das Widget mit seinem Hintergrund erscheint – in der Extension
    ///   `showsWidgetContainerBackground`; ohne (StandBy, CarPlay) die Anordnung von „Nächstes Gebet“.
    public init(content: PrayerWidgetContent, showsBackground: Bool = true) {
        self.content = content
        self.showsBackground = showsBackground
    }

    /// Die Zeilen (Spec § 12.2): im Bogen Gebet und Uhrzeit und der Countdown, darunter der Ort mit dem Pfeil beim
    /// aktuellen Standort – oder während einer Verbotszeit „Verbotszeit bis …“. Ohne Zeiten oder Ort der Hinweis. Ohne
    /// Hintergrund dieselben Zeilen wie „Nächstes Gebet“ ohne Hintergrund.
    public nonisolated static func lines(for content: PrayerWidgetContent, showsBackground: Bool = true) -> [SmallWidgetLine] {
        if !showsBackground {
            return SmallPrayerWidget.lines(for: content, showsBackground: false)
        }
        switch content.state {
        case .times(let snapshot):
            let name = snapshot.next.prayer.localizedName + " · " + WidgetTexts.time(of: snapshot.next, in: snapshot)
            let footer: SmallWidgetLine = content.prohibitedText(snapshot).map { .kerahat($0) }
                ?? .city(content.cityName, showsArrow: content.isCurrentLocation)
            return [.prayer(snapshot.next.prayer), .time(name), .countdown, footer]
        case .noTimes:
            return [.city(content.cityName, showsArrow: content.isCurrentLocation), .message(L10n.noTimes)]
        case .noPlace:
            return [.appName, .message(L10n.citySheetTitle)]
        }
    }

    public var body: some View {
        if showsBackground {
            arcBody
        } else {
            SmallPrayerWidget(content: content, showsBackground: false)
        }
    }

    private var arcBody: some View {
        Group {
            switch content.state {
            case .times(let snapshot):
                VStack(spacing: 0) {
                    DayArc(phase: snapshot.phase, style: .smallWidget, showKerahat: content.showKerahat) {
                        VStack(spacing: 0) {
                            Text(snapshot.next.prayer.localizedName + " · " + WidgetTexts.time(of: snapshot.next, in: snapshot))
                                .font(WidgetMetrics.arcNameFont)
                                .foregroundStyle(Palette.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: WidgetMetrics.arcNameMaxWidth)
                                .lineHeight(WidgetMetrics.arcNameLineHeight, fontSize: 12)
                            Text(timerInterval: countdown(snapshot), countsDown: true)
                                .font(WidgetMetrics.arcCountFont)
                                .tracking(WidgetMetrics.arcCountTracking)
                                .foregroundStyle(Palette.label)
                                .multilineTextAlignment(.center)
                                .lineHeight(WidgetMetrics.arcCountLineHeight, fontSize: WidgetMetrics.arcCountSize)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if let footer = Self.lines(for: content).last {
                        SmallArcFooter(line: footer)
                            .padding(.top, WidgetMetrics.arcFooterTop)
                    }
                }
            case .noTimes, .noPlace:
                VStack(spacing: WidgetMetrics.arcFooterGap) {
                    ForEach(Array(Self.lines(for: content).enumerated()), id: \.offset) { _, line in
                        SmallArcFooter(line: line)
                    }
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding(WidgetMetrics.arcPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// Countdown in Gerätezeit bis zum nächsten Ereignis.
    private func countdown(_ snapshot: WidgetSnapshot) -> ClosedRange<Date> {
        let end = content.deviceDate(snapshot.next.date)
        return min(content.deviceDate(snapshot.now), end)...end
    }
}

/// Die Zeile unter dem Bogen (`.cpw-sub`): Pfeil und Ort in der Zweitschrift, oder Punkt und „Verbotszeit bis …“ in der
/// Schrift der Verbotszeit; ohne Zeiten der Name der App bzw. der Hinweis.
struct SmallArcFooter: View {
    let line: SmallWidgetLine

    var body: some View {
        switch line {
        case .city(let name, let showsArrow):
            HStack(spacing: WidgetMetrics.arcFooterGap) {
                if showsArrow {
                    Image(systemName: "location.fill")
                        .font(.system(size: WidgetMetrics.symbolSize(box: WidgetMetrics.arcLocationBox) + 1, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                }
                text(name)
            }
            .foregroundStyle(Palette.textSecondary)
        case .kerahat(let text):
            HStack(spacing: WidgetMetrics.arcFooterGap) {
                Circle()
                    .fill(Palette.kerahat)
                    .frame(width: WidgetMetrics.kerahatDot, height: WidgetMetrics.kerahatDot)
                    .accessibilityHidden(true)
                self.text(text)
            }
            .foregroundStyle(Palette.kerahatText)
        case .appName:
            text(L10n.appName)
                .foregroundStyle(Palette.accent)
        case .message(let message):
            Text(message)
                .font(WidgetMetrics.arcNameFont)
                .foregroundStyle(Palette.textSecondary)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        case .prayer, .time, .countdown:
            EmptyView()
        }
    }

    private func text(_ string: String) -> some View {
        Text(string)
            .font(WidgetMetrics.arcFooterFont)
            .lineHeight(WidgetMetrics.arcFooterLineHeight, fontSize: WidgetMetrics.arcFooterSize)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
