/// Der Stand der Anleitung – das Ergebnis von `guideState()` im Prototyp: welches Gebet sie zeigt und
/// wie es zur Uhrzeit steht.
public struct GuideState: Hashable, Sendable {

    /// Das Gebet, das die Anleitung zeigt (`p`): die manuelle Wahl, sonst `automatic`.
    public let prayer: Prayer

    /// Das Gebet, dem die Anleitung von selbst folgt (`auto`): das laufende; vor Fadschr noch Ischa;
    /// zwischen Sonnenaufgang und Dhuhr das nächste, also Dhuhr. Es trägt den Punkt in der Auswahl.
    public let automatic: Prayer

    /// Das gezeigte Gebet läuft gerade – Status „Jetzt“ (`isCur`).
    public let isCurrent: Bool

    /// Das gezeigte Gebet ist das nächste – Status „Als Nächstes“ (`isNext`).
    public let isNext: Bool

    /// Ob der Knopf „Zurück zum aktuellen Gebet“ erscheint: nach einer manuellen Wahl, die vom
    /// automatischen Gebet abweicht.
    public let showsReturnButton: Bool

    /// - Parameters:
    ///   - phase: die Tagesphase.
    ///   - pick: die manuelle Wahl (`S.guidePick`); `nil` heißt, die Anleitung folgt der Zeit. Der
    ///     Sonnenaufgang ist kein Gebet und zählt wie keine Wahl.
    public init(phase: DayPhase, pick: Prayer? = nil) {
        // Läuft kein Gebet, liegt „jetzt“ zwischen Sonnenaufgang und Dhuhr; das nächste Gebet ist dann Dhuhr.
        let automatic = phase.current?.prayer ?? .dhuhr
        let pick = pick == .sunrise ? nil : pick
        let prayer = pick ?? automatic
        let isCurrent = phase.current?.prayer == prayer

        self.prayer = prayer
        self.automatic = automatic
        self.isCurrent = isCurrent
        self.isNext = !isCurrent && prayer == automatic
        self.showsReturnButton = pick != nil && pick != automatic
    }
}

/// Die manuelle Wahl in der Anleitung (`S.guidePick`) und wann sie verfällt.
///
/// Die Wahl gilt, bis das Gebet wechselt, dem die Anleitung von selbst folgt, oder bis man die Seite
/// verlässt. Danach folgt die Anleitung wieder der Zeit (Spec § 4).
public struct GuideSelection: Hashable, Sendable {

    /// Das von Hand gewählte Gebet; `nil` heißt, die Anleitung folgt der Zeit.
    public private(set) var pick: Prayer?

    /// Das automatische Gebet beim letzten Abgleich (`S._guideAuto`).
    private var lastAutomatic: Prayer?

    public init() {}

    /// Der Stand der Anleitung zur Phase, mit der aktuellen Wahl.
    public func state(for phase: DayPhase) -> GuideState {
        GuideState(phase: phase, pick: pick)
    }

    /// Wählt ein Gebet von Hand – Aktion `guide-pick`. Wer das automatische Gebet antippt, hebt die
    /// manuelle Wahl auf.
    public mutating func choose(_ prayer: Prayer, in phase: DayPhase) {
        let automatic = GuideState(phase: phase).automatic
        pick = prayer == automatic || prayer == .sunrise ? nil : prayer
        // Die Wahl merkt sich, bei welchem Gebet sie getroffen wurde – auch ohne vorherigen Abgleich.
        lastAutomatic = automatic
    }

    /// Zurück zum aktuellen Gebet – Aktion `guide-now`. Gilt auch, wenn man die Seite verlässt.
    public mutating func followTime() {
        pick = nil
    }

    /// Gleicht die Wahl mit der Uhrzeit ab; aufzurufen, wenn sich die Phase ändert. Wechselt das
    /// automatische Gebet, verfällt die manuelle Wahl.
    public mutating func update(for phase: DayPhase) {
        let automatic = GuideState(phase: phase).automatic
        if let lastAutomatic, lastAutomatic != automatic {
            pick = nil
        }
        lastAutomatic = automatic
    }
}
