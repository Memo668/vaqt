import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Zustand der Anleitung: welches Gebet sie zeigt, die manuelle Wahl und wann sie verfällt – der
/// Rechenteil von `guidePage()` und `guideState()` im Prototyp.
///
/// Die Zeiten kommen aus dem Zeitstrahl von `TodayModel`, demselben wie auf der Zeiten-Seite. Einen
/// Sekundentakt braucht die Seite nicht: `run()` wacht auf, wenn das nächste Ereignis beginnt, und
/// gleicht dann die Wahl ab. Die Wahl gilt, bis das aktuelle Gebet wechselt oder man die Seite verlässt
/// (`followTime()`, Design Spec § 4).
@MainActor
@Observable
public final class GuideModel {

    @ObservationIgnored private let today: TodayModel

    /// Die manuelle Wahl (`S.guidePick`).
    public private(set) var selection = GuideSelection()
    /// Der laufende Durchlauf „Gebet Schritt für Schritt“ (`S.walk`); `nil`, wenn keiner offen ist.
    public var walk: WalkSession?
    /// Die Tagesphase beim letzten Abgleich.
    private var checkedPhase: DayPhase?

    public init(today: TodayModel) {
        self.today = today
    }

    /// Die Tagesphase: die beim letzten Abgleich; bevor der erste lief, die zur Uhrzeit – so steht schon
    /// beim ersten Bild das richtige Gebet da. `nil` ohne Zeiten: ohne Ort oder wo die Sonne nicht auf-
    /// oder untergeht.
    public var phase: DayPhase? {
        checkedPhase ?? today.timeline?.phase(at: today.clock.now)
    }

    /// Der Zeitstrahl, aus dem die Anleitung ihre Zeiten nimmt. Ändert er sich – anderer Ort, neuer Tag –,
    /// gleicht die Seite neu ab.
    public var timeline: PrayerTimeline? {
        today.timeline
    }

    /// Welches Gebet die Anleitung zeigt und wie es zur Uhrzeit steht.
    public var state: GuideState {
        selection.state(for: phase)
    }

    /// Auswahl und Kopfkarte.
    public var header: GuideHeader {
        let state = state
        // Spec § 11.6: der Hinweis zum Farḍ von Asr nur hanafitisch, und nur wenn die App Verbotszeiten zeigt.
        let asrNote = today.settings.showKerahat && today.settings.calculation.madhab.hasAsrNote
        guard let phase, let timeline else {
            return GuideHeader(state: state, window: nil, timeZone: .gmt, showsAsrKerahatNote: asrNote)
        }
        return GuideHeader(
            state: state, window: Guide.window(of: state.prayer, in: timeline, at: phase.now),
            timeZone: phase.times.timeZone, showsAsrKerahatNote: asrNote
        )
    }

    // MARK: - Aktionen

    /// Ein Gebet in der Auswahl antippen (`guide-pick`). Das aktuelle anzutippen hebt die Wahl auf.
    public func choose(_ prayer: Prayer) {
        selection.choose(prayer, in: phase)
    }

    /// „Zum aktuellen Gebet“ (`guide-now`) – und wenn man die Seite verlässt (`goPane()`).
    public func followTime() {
        selection.followTime()
    }

    // MARK: - Schritt für Schritt

    /// „Gebet Schritt für Schritt“ (`walk-start`): öffnet den Durchlauf für das Gebet, das die Anleitung
    /// gerade zeigt, auf der Startseite. Er bleibt bei diesem Gebet, auch wenn währenddessen das aktuelle
    /// wechselt.
    public func startWalk() {
        startWalk(prayer: state.prayer)
    }

    /// Öffnet den Durchlauf für ein Gebet ab einer Seite – für `-debugWalk` und `-debugWalkStep`.
    public func startWalk(prayer: Prayer, at index: Int = 0) {
        guard let guideWalk = GuideWalk(prayer: prayer) else { return }
        walk = WalkSession(walk: guideWalk, index: guideWalk.clamped(index))
    }

    /// „Beginnen“ und „Weiter“ (`walk-next`); auf der letzten Seite bleibt es dabei.
    public func nextWalkStep() {
        guard var session = walk else { return }
        session.index = session.walk.index(after: session.index)
        session.direction = .forward
        walk = session
    }

    /// „Zurück“ (`walk-prev`); auf der Startseite bleibt es dabei.
    public func previousWalkStep() {
        guard var session = walk else { return }
        session.index = session.walk.index(before: session.index)
        session.direction = .backward
        walk = session
    }

    /// Der Kreis oben und „Fertig“ (`walk-close`).
    public func closeWalk() {
        walk = nil
    }

    // MARK: - Ablauf

    /// Holt die Tagesphase zur Uhrzeit und gleicht die Wahl ab: Wechselt das aktuelle Gebet, verfällt sie.
    ///
    /// Deckt der Zeitstrahl „jetzt“ nicht mehr ab (nach Mitternacht), baut die Zeiten-Seite einen neuen.
    public func refresh() {
        let now = today.clock.now
        var phase = today.timeline?.phase(at: now)
        if phase == nil, today.timeline != nil {
            today.refresh()
            phase = today.timeline?.phase(at: now)
        }
        checkedPhase = phase
        if let phase {
            selection.update(for: phase)
        }
    }

    /// Gleicht sofort ab und dann jedes Mal, wenn das nächste Ereignis beginnt – bis die Aufgabe
    /// abgebrochen wird. Ohne Zeiten endet sie gleich; kommen Zeiten, startet die Seite sie neu.
    public func run() async {
        while !Task.isCancelled {
            refresh()
            guard let phase else { return }
            let wait = max(phase.next.date.timeIntervalSince(today.clock.now), 0) + GuideModel.wakeDelay
            try? await Task.sleep(for: .seconds(wait))
        }
    }

    /// So lange nach dem Beginn eines Ereignisses wacht `run()` auf – knapp danach, damit die Phase sicher
    /// schon die neue ist.
    nonisolated static let wakeDelay: TimeInterval = 0.5
}

/// Ein offener Durchlauf „Gebet Schritt für Schritt“: das Gebet, die Seite und die Richtung, in die
/// zuletzt geblättert wurde (`S.walk = {p, i, dir}`).
public struct WalkSession: Identifiable, Hashable, Sendable {
    public let walk: GuideWalk
    /// Die Seite, 0 = Start (`i`).
    public var index: Int
    /// Wohin zuletzt geblättert wurde (`dir`); davon hängt ab, von welcher Seite die neue hereingleitet.
    public var direction: GuideWalkScreen.Direction = .forward

    /// Ein Durchlauf je Gebet: Wechselt das Gebet, ist es ein neues Vollbild.
    public var id: Prayer { walk.prayer }

    public init(walk: GuideWalk, index: Int = 0) {
        self.walk = walk
        self.index = walk.clamped(index)
    }
}
