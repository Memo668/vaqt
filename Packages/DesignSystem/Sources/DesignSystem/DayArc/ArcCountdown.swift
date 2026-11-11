import PrayerCore
import SwiftUI

/// Der Countdown als Text – `cdDigital()` und `cdText()` im Prototyp.
public enum CountdownFormat {

    /// Digital wie „2:01:59“; unter einer Stunde „1:14“, unter einer Minute „0:05“. Angebrochene
    /// Sekunden fallen weg.
    public static func digital(_ remaining: TimeInterval) -> String {
        let total = max(0, Int(remaining.rounded(.down)))
        let hours = total / 3600, minutes = total % 3600 / 60, seconds = total % 60
        return hours > 0 ? "\(hours):\(pad(minutes)):\(pad(seconds))" : "\(minutes):\(pad(seconds))"
    }

    /// In Worten wie „2 Std. 2 Min.“ – auf volle Minuten aufgerundet, mindestens eine. So liest
    /// VoiceOver den Countdown vor, ohne jede Sekunde anzusagen.
    public static func spoken(_ remaining: TimeInterval) -> String {
        let total = max(1, Int((remaining / 60).rounded(.up)))
        let hours = total / 60, minutes = total % 60
        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours) \(L10n.hShort)")
        }
        if minutes > 0 || hours == 0 {
            parts.append("\(minutes) \(L10n.mShort)")
        }
        return parts.joined(separator: " ")
    }

    private static func pad(_ value: Int) -> String {
        (value < 10 ? "0" : "") + String(value)
    }
}

/// Zeile und Countdown unten im Bogen: „Maghrib in“ über „2:01:59“.
///
/// Der Baustein zeigt die Restzeit, die er bekommt; den Sekundentakt gibt die Seite vor
/// (`TimelineView`). Die Schrift ist 56 pt thin mit Ziffern gleicher Breite, ab zehn Stunden 50 pt,
/// und wächst mit Dynamic Type höchstens auf das 1,05-Fache. Für VoiceOver ist beides ein Element:
/// „Maghrib in 2 Std. 2 Min.“ Design Spec § 3 („Countdown“), `.hero-text` im Prototyp.
public struct ArcCountdown: View {
    private let label: String
    private let remaining: TimeInterval

    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// - Parameters:
    ///   - label: Zeile über dem Countdown, z. B. `L10n.nextIn(p:)`.
    ///   - remaining: Sekunden bis zum nächsten Ereignis.
    public init(label: String, remaining: TimeInterval) {
        self.label = label
        self.remaining = remaining
    }

    /// Zeile und Countdown zur Tagesphase: „Maghrib in“, nach Ischa „Fadschr (morgen) in“.
    public init(phase: DayPhase) {
        let name = phase.next.prayer.localizedName
        self.init(
            label: phase.isNextTomorrow ? L10n.nextInTomorrow(p: name) : L10n.nextIn(p: name),
            remaining: phase.remaining
        )
    }

    public var body: some View {
        let isWide = remaining >= Typography.countdownWideThreshold
        let size = Typography.countdownSize(inArc: true, isWide: isWide, typeScale: typeScale)
        VStack(spacing: 0) {
            Text(label)
                .textStyle(
                    .subheadline, weight: Typography.countdownLabelWeight,
                    lineHeight: Typography.countdownLabelLineHeight
                )
                .foregroundStyle(Palette.textSecondary)
            Text(CountdownFormat.digital(remaining))
                .font(Typography.countdown(inArc: true, isWide: isWide, typeScale: typeScale))
                .tracking(Typography.countdownTracking)
                .foregroundStyle(Palette.label)
                .fixedSize()
                .lineHeight(Typography.countdownLineHeight, fontSize: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label + " " + CountdownFormat.spoken(remaining))
        .accessibilityAddTraits(.updatesFrequently)
    }
}
