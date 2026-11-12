import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Adhan-Player – `S.adhan` und die Aktionen `adhan-toggle`, `pick` (Stimme), `toggle-fajr` und der
/// Scrubber im Prototyp.
///
/// Die gewählte Stimme gilt auch für die Mitteilungen (Phase 8) und bleibt gespeichert. Die
/// Fadschr-Variante ist nur eine Vorschau im Player. Ein Wechsel der Stimme oder der Variante hält an und
/// springt an den Anfang; am Ende springt der Player zurück auf 0:00; das Schließen des Sheets hält an.
@MainActor
@Observable
final class AdhanPlayerModel {

    let settings: SettingsStore
    /// Die Vorschau der Fadschr-Variante (`S.adhan.fajr`).
    private(set) var isFajrVariant = false
    private(set) var isPlaying = false
    /// Gespielte Sekunden (`S.adhan.pos`).
    private(set) var position: TimeInterval = 0
    private(set) var duration: TimeInterval

    @ObservationIgnored private let makePlayback: @MainActor (AdhanVoice, Bool) -> any AdhanPlayback
    @ObservationIgnored private var playback: any AdhanPlayback
    /// Lässt die Wiedergabe anlaufen (`starting`) und liest dann alle 0,1 s die Stelle (`ticker`).
    @ObservationIgnored private var starting: Task<Void, Never>?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    /// - Parameter makePlayback: die Wiedergabe einer Stimme mit oder ohne Fadschr-Variante; ohne Angabe
    ///   die Aufnahme aus dem Bundle der App, sonst stumm (`AdhanClips`).
    init(
        settings: SettingsStore,
        makePlayback: @escaping @MainActor (AdhanVoice, Bool) -> any AdhanPlayback = { voice, fajr in
            AdhanClips.playback(for: voice, fajrVariant: fajr)
        }
    ) {
        self.settings = settings
        self.makePlayback = makePlayback
        let playback = makePlayback(settings.notifications.voice, false)
        self.playback = playback
        duration = playback.duration
    }

    /// Die gewählte Stimme (`S.adhan.voice`).
    var voice: AdhanVoice {
        settings.notifications.voice
    }

    /// „Stimme 1 · Makkah“.
    var title: String {
        "\(L10n.voiceN(n: String(voice.number))) · \(voice.place)"
    }

    /// „Kurzer Adhan · für Mitteilungen“, mit der Variante „… · Fadschr-Variante“.
    var subtitle: String {
        isFajrVariant ? L10n.shortAdhan + " · " + L10n.fajrVariant : L10n.shortAdhan
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

    /// Eine andere Stimme: anhalten, an den Anfang, die Wahl speichern.
    func selectVoice(_ voice: AdhanVoice) {
        stop()
        settings.updateNotifications { $0.voice = voice }
        replacePlayback()
    }

    /// Die Fadschr-Variante ein oder aus: anhalten, an den Anfang.
    func setFajrVariant(_ isOn: Bool) {
        stop()
        isFajrVariant = isOn
        replacePlayback()
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

    private func replacePlayback() {
        playback = makePlayback(voice, isFajrVariant)
        duration = playback.duration
        position = 0
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
