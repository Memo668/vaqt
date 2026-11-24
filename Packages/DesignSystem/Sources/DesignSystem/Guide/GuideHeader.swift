import Foundation
import PrayerCore

/// Was oben auf der Anleitung steht – die Auswahl der fünf Gebete und die Kopfkarte – zu einem Stand der
/// Anleitung. Der Rechenteil von `guidePage()` im Prototyp bis zum Ende der Kopfkarte.
public struct GuideHeader: Hashable, Sendable {

    /// Das gezeigte Gebet.
    public let prayer: Prayer
    /// Seine Fard-Rakʿas.
    public let rakahs: Rakahs
    /// „Jetzt“ oder „Als Nächstes“ links oben in der Karte; `nil`, wenn das Gebet von Hand gewählt ist
    /// und weder läuft noch als nächstes kommt.
    public let status: String?
    /// Das Zeitfenster rechts oben, z. B. „14:00–16:27“; `nil` ohne Zeiten.
    public let window: String?
    /// Das Gebet, das den Punkt in der Auswahl trägt; `nil` ohne Zeiten.
    public let automatic: Prayer?
    /// Was VoiceOver zum Punkt sagt: „Jetzt“ oder, zwischen Sonnenaufgang und Dhuhr, „Als Nächstes“.
    public let automaticStatus: String?
    /// Das Gebet des Knopfs „Zum aktuellen Gebet“; `nil`, solange der Knopf fehlt.
    public let returnPrayer: Prayer?
    /// Ob bei Asr der Hinweis auf die Verbotszeit steht (`gAsrKerahat`, Spec § 10.2): nur wenn die App
    /// Verbotszeiten zeigt und nach hanafitischer Lehre (§ 11.6).
    public let showsAsrKerahatNote: Bool

    public init(
        prayer: Prayer, status: String?, window: String?,
        automatic: Prayer?, automaticStatus: String?, returnPrayer: Prayer?, showsAsrKerahatNote: Bool = true
    ) {
        self.prayer = prayer
        rakahs = Guide.rakahs(for: prayer) ?? Rakahs(aloud: [])
        self.status = status
        self.window = window
        self.automatic = automatic
        self.automaticStatus = automaticStatus
        self.returnPrayer = returnPrayer
        self.showsAsrKerahatNote = showsAsrKerahatNote
    }

    /// - Parameters:
    ///   - window: das Zeitfenster des gezeigten Gebets (`Guide.window(of:in:at:)`); `nil` ohne Zeiten.
    ///   - timeZone: Zeitzone des Ortes; in ihr stehen die Uhrzeiten.
    ///   - showsAsrKerahatNote: ob bei Asr der Hinweis auf die Verbotszeit steht.
    public init(state: GuideState, window: Guide.Window?, timeZone: TimeZone, showsAsrKerahatNote: Bool = true) {
        self.init(
            prayer: state.prayer,
            status: state.isCurrent ? L10n.now : state.isNext ? L10n.guideNext : nil,
            window: window.map { Self.windowText($0, timeZone: timeZone) },
            automatic: state.automatic,
            automaticStatus: state.automatic == nil ? nil : state.isAutomaticCurrent ? L10n.now : L10n.guideNext,
            returnPrayer: state.showsReturnButton ? state.automatic : nil,
            showsAsrKerahatNote: showsAsrKerahatNote
        )
    }

    /// „14:00–16:27“: Beginn und Ende in der Zeitzone des Ortes. Wortverbinder um den Strich halten die
    /// Spanne in einer Zeile.
    static func windowText(_ window: Guide.Window, timeZone: TimeZone) -> String {
        L10n.timeRange(ClockTime(window.start, in: timeZone), ClockTime(window.end, in: timeZone))
    }

    /// Die fünf Teile der Auswahl; das automatische Gebet trägt den Punkt.
    public var segments: [SegmentedControl<Prayer>.Segment] {
        Prayer.five.map { prayer in
            SegmentedControl.Segment(
                value: prayer, title: prayer.localizedName,
                mark: prayer == automatic ? automaticStatus : nil
            )
        }
    }
}
