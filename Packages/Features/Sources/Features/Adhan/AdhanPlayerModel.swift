import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Adhan-Player – `S.adhan`, die Aktion `adhan-toggle` und der Scrubber im Prototyp.
///
/// Er spielt die eine Aufnahme der App, dieselbe wie Mitteilungen und Wecker (`AdhanRecording`,
/// Spec § 11.2). Am Ende springt der Player zurück auf 0:00; das Schließen des Sheets hält an.
@MainActor
@Observable
final class AdhanPlayerModel {

    private(set) var isPlaying = false
    /// Gespielte Sekunden (`S.adhan.pos`).
    private(set) var position: TimeInterval = 0
    /// Länge der Aufnahme in Sekunden (`adhanDur()`).
    let duration: TimeInterval

    @ObservationIgnored private let playback: any AdhanPlayback
    /// Lässt die Wiedergabe anlaufen (`starting`) und liest dann alle 0,1 s die Stelle (`ticker`).
    @ObservationIgnored private var starting: Task<Void, Never>?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    /// - Parameter makePlayback: die Wiedergabe der Aufnahme; ohne Angabe aus dem Bundle der App, sonst
    ///   stumm (`AdhanClips`).
    init(makePlayback: @MainActor () -> any AdhanPlayback = { AdhanClips.playback() }) {
        let playback = makePlayback()
        self.playback = playback
        duration = playback.duration
    }

    /// Der Muezzin der Aufnahme (`ADHAN_VOICE.name`).
    var title: String {
        AdhanRecording.muezzin
    }

    /// „Kurzer Adhan · für Mitteilungen“.
    var subtitle: String {
        L10n.shortAdhan
    }

    // MARK: - Aktionen

    /// Play/Pause (`adhan-toggle`). Am Ende beginnt Abspielen wieder vorn. Der Knopf zeigt sofort „Pause“;
    /// kann die Wiedergabe nicht laufen – etwa ohne Ausgabegerät –, steht der Player danach wieder still.
    func togglePlay() {
        if isPlaying {
            pause()
        } else {
            if position >= duration - 0.05 {
                playback.currentTime = 0
            }
            isPlaying = true
            sync()
            start()
        }
    }

    /// Der Scrubber: an diese Stelle springen.
    func seek(to time: TimeInterval) {
        playback.currentTime = min(max(0, time), duration)
        sync()
    }

    /// Anhalten und an den Anfang – beim Schließen des Sheets (`stopAdhan()`; `pos` bleibt im Prototyp
    /// stehen, die App beginnt beim nächsten Öffnen vorn).
    func stop() {
        cancelTasks()
        playback.stop()
        isPlaying = false
        position = 0
    }

    private func pause() {
        cancelTasks()
        playback.pause()
        isPlaying = false
        sync()
    }

    private func cancelTasks() {
        starting?.cancel()
        starting = nil
        ticker?.cancel()
        ticker = nil
    }

    // MARK: - Ablauf

    /// Startet die Wiedergabe, dann alle 0,1 s ein Takt (`setInterval(adhanStep, 100)`); am Ende zurück
    /// auf 0:00. Wird während des Anlaufens angehalten, hält auch die Wiedergabe gleich wieder an.
    private func start() {
        cancelTasks()
        let playback = playback
        starting = Task { [weak self] in
            await playback.play()
            guard let self else { return }
            guard !Task.isCancelled else {
                playback.pause()
                return
            }
            self.step()
            if self.isPlaying {
                self.startTicker()
            }
        }
    }

    private func startTicker() {
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                self.step()
            }
        }
    }

    /// Wartet, bis die Wiedergabe angelaufen ist oder feststeht, dass sie nicht läuft – für Tests.
    func waitUntilStarted() async {
        await starting?.value
    }

    /// Ein Takt: Stelle lesen; ist die Wiedergabe zu Ende, anhalten und zurück an den Anfang
    /// (`adhanStep()`).
    func step() {
        if !playback.isPlaying || playback.currentTime >= duration {
            stop()
        } else {
            sync()
        }
    }

    private func sync() {
        position = min(playback.currentTime, duration)
    }
}
