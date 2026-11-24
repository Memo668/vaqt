import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Der Adhan-Player verhält sich wie `S.adhan`, `adhanStep()` und `adhan-toggle` im Prototyp; er spielt die
/// eine Aufnahme der App (Spec § 11.2).
@MainActor
@Suite("Adhan-Player")
struct AdhanPlayerModelTests {

    /// Eine Wiedergabe, deren Zeit der Test stellt.
    @MainActor
    final class FakePlayback: AdhanPlayback {
        let duration: TimeInterval
        var currentTime: TimeInterval = 0
        var isPlaying = false
        var plays = 0
        /// Ob `play()` anläuft; ohne Ausgabegerät nicht.
        var canPlay = true

        init(duration: TimeInterval) {
            self.duration = duration
        }

        func play() async {
            isPlaying = canPlay
            plays += 1
        }

        func pause() {
            isPlaying = false
        }

        func stop() {
            isPlaying = false
            currentTime = 0
        }
    }

    /// Der Player mit einer Wiedergabe, so lang wie die Aufnahme: 29,5 Sekunden.
    private func model() -> (AdhanPlayerModel, FakePlayback) {
        let playback = FakePlayback(duration: AdhanRecording.clipDuration)
        return (AdhanPlayerModel { playback }, playback)
    }

    @Test("der Player beginnt bei 0:00 von 0:29, mit dem Muezzin als Titel, wie iphone/86")
    func start() {
        let (model, playback) = model()
        #expect(model.title == "Ustadh Mmanga Muharram")
        #expect(model.subtitle == L10n.shortAdhan)
        #expect(model.position == 0)
        #expect(model.duration == 29.5)
        #expect(!model.isPlaying)
        #expect(playback.plays == 0)
    }

    @Test("Play spielt, ein Takt liest die Stelle, Pause hält an")
    func playPause() async {
        let (model, playback) = model()
        model.togglePlay()
        #expect(model.isPlaying)
        await model.waitUntilStarted()
        #expect(model.isPlaying)
        #expect(playback.plays == 1)
        playback.currentTime = 12.4
        model.step()
        #expect(model.position == 12.4)
        model.togglePlay()
        #expect(!model.isPlaying)
        #expect(!playback.isPlaying)
        #expect(model.position == 12.4)
    }

    @Test("am Ende springt der Player zurück auf 0:00 (adhanStep)")
    func end() async {
        let (model, playback) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        playback.currentTime = AdhanRecording.clipDuration
        model.step()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("endet die Wiedergabe von selbst, steht der Player wieder am Anfang")
    func finishedByItself() async {
        let (model, playback) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        playback.isPlaying = false
        model.step()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("läuft die Wiedergabe nicht an – etwa ohne Ausgabegerät –, steht der Player still")
    func cannotPlay() async {
        let (model, playback) = model()
        playback.canPlay = false
        model.togglePlay()
        #expect(model.isPlaying)
        await model.waitUntilStarted()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("der Scrubber springt, höchstens bis ans Ende")
    func seek() {
        let (model, playback) = model()
        model.seek(to: 10)
        #expect(model.position == 10)
        #expect(playback.currentTime == 10)
        model.seek(to: 100)
        #expect(model.position == 29.5)
        model.seek(to: -3)
        #expect(model.position == 0)
    }

    @Test("das Schließen des Sheets hält an und springt an den Anfang (stopAdhan)")
    func stop() async {
        let (model, playback) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        playback.currentTime = 5
        model.step()
        #expect(model.position == 5)
        model.stop()
        #expect(!playback.isPlaying)
        #expect(playback.currentTime == 0)
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("nach dem Ende beginnt Play wieder vorn")
    func replayFromStart() {
        let (model, playback) = model()
        model.seek(to: 29.5)
        model.togglePlay()
        #expect(playback.currentTime == 0)
        #expect(model.position == 0)
    }

    // MARK: - Aufnahme

    @Test("ohne Aufnahme im Bundle läuft der Player stumm, 29,5 Sekunden wie die Aufnahme")
    func silentFallback() {
        let playback = AdhanClips.playback(bundle: Bundle(for: FakePlayback.self))
        #expect(playback is SilentPlayback)
        #expect(playback.duration == 29.5)
    }

    @Test("der stumme Ablauf zählt in Echtzeit und springt beim Setzen")
    func silentPlayback() async throws {
        let playback = SilentPlayback(duration: 30)
        #expect(!playback.isPlaying)
        playback.currentTime = 12
        #expect(playback.currentTime == 12)
        await playback.play()
        try await Task.sleep(for: .milliseconds(150))
        #expect(playback.isPlaying)
        #expect(playback.currentTime > 12.1)
        playback.pause()
        let paused = playback.currentTime
        try await Task.sleep(for: .milliseconds(100))
        #expect(playback.currentTime == paused)
        playback.stop()
        #expect(playback.currentTime == 0)
        playback.currentTime = 99
        #expect(playback.currentTime == 30)
    }
}
