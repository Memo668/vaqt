import DesignSystem
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Der Adhan-Player verhält sich wie `S.adhan`, `adhanStep()` und die Aktionen des Prototyps.
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

    @MainActor
    final class Factory {
        var made: [(voice: AdhanVoice, fajr: Bool, playback: FakePlayback)] = []

        func make(_ voice: AdhanVoice, _ fajr: Bool) -> any AdhanPlayback {
            let playback = FakePlayback(duration: AdhanClips.resource(for: voice, fajrVariant: fajr) == nil
                ? AdhanClips.silentDuration(fajrVariant: fajr) : 27)
            made.append((voice, fajr, playback))
            return playback
        }

        var last: FakePlayback { made[made.count - 1].playback }
    }

    private func model(_ change: (inout SettingsStore.Snapshot) -> Void = { _ in }) -> (AdhanPlayerModel, Factory) {
        var snapshot = SettingsStore.Snapshot()
        change(&snapshot)
        let factory = Factory()
        let model = AdhanPlayerModel(settings: SettingsStore(storage: .ephemeral(snapshot)), makePlayback: factory.make)
        return (model, factory)
    }

    @Test("der Player beginnt mit Stimme 1 bei 0:00 von 0:27, wie iphone/86")
    func start() {
        let (model, factory) = model()
        #expect(model.voice == .one)
        #expect(model.title == "\(L10n.voiceN(n: "1")) · Makkah")
        #expect(model.subtitle == L10n.shortAdhan)
        #expect(model.position == 0)
        #expect(model.duration == 27)
        #expect(!model.isPlaying)
        #expect(factory.made.count == 1)
    }

    @Test("Play spielt, ein Takt liest die Stelle, Pause hält an")
    func playPause() async {
        let (model, factory) = model()
        model.togglePlay()
        #expect(model.isPlaying)
        await model.waitUntilStarted()
        #expect(model.isPlaying)
        #expect(factory.last.plays == 1)
        factory.last.currentTime = 12.4
        model.step()
        #expect(model.position == 12.4)
        model.togglePlay()
        #expect(!model.isPlaying)
        #expect(!factory.last.isPlaying)
        #expect(model.position == 12.4)
    }

    @Test("am Ende springt der Player zurück auf 0:00 (adhanStep)")
    func end() async {
        let (model, factory) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        factory.last.currentTime = 27
        model.step()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("endet die Wiedergabe von selbst, steht der Player wieder am Anfang")
    func finishedByItself() async {
        let (model, factory) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        factory.last.isPlaying = false
        model.step()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("läuft die Wiedergabe nicht an – etwa ohne Ausgabegerät –, steht der Player still")
    func cannotPlay() async {
        let (model, factory) = model()
        factory.last.canPlay = false
        model.togglePlay()
        #expect(model.isPlaying)
        await model.waitUntilStarted()
        #expect(!model.isPlaying)
        #expect(model.position == 0)
    }

    @Test("der Scrubber springt, höchstens bis ans Ende")
    func seek() {
        let (model, factory) = model()
        model.seek(to: 10)
        #expect(model.position == 10)
        #expect(factory.last.currentTime == 10)
        model.seek(to: 100)
        #expect(model.position == 27)
        model.seek(to: -3)
        #expect(model.position == 0)
    }

    @Test("eine andere Stimme hält an, springt an den Anfang und bleibt gespeichert")
    func selectVoice() async {
        let (model, factory) = model()
        model.togglePlay()
        await model.waitUntilStarted()
        factory.last.currentTime = 5
        model.step()
        let first = factory.last
        model.selectVoice(.three)
        #expect(!first.isPlaying)
        #expect(!model.isPlaying)
        #expect(model.position == 0)
        #expect(model.voice == .three)
        #expect(model.settings.notifications.voice == .three)
        #expect(model.title == "\(L10n.voiceN(n: "3")) · Istanbul")
        // Stimme 3 hat keine Aufnahme: stumm, 27 Sekunden.
        #expect(model.duration == 27)
        #expect(factory.made.last?.voice == .three)
    }

    @Test("die Fadschr-Variante ist eine Vorschau: 30 Sekunden, nicht gespeichert")
    func fajrVariant() {
        let (model, factory) = model()
        model.setFajrVariant(true)
        #expect(model.isFajrVariant)
        #expect(model.duration == 30)
        #expect(model.subtitle == L10n.shortAdhan + " · " + L10n.fajrVariant)
        #expect(factory.made.last?.fajr == true)
        #expect(model.settings.notifications == NotificationPreferences())
        model.setFajrVariant(false)
        #expect(model.duration == 27)
    }

    @Test("die gespeicherte Stimme gilt beim Öffnen")
    func savedVoice() {
        let (model, factory) = model { $0.notifications.voice = .two }
        #expect(model.voice == .two)
        #expect(factory.made.first?.voice == .two)
    }

    @Test("nach dem Ende beginnt Play wieder vorn")
    func replayFromStart() {
        let (model, factory) = model()
        model.seek(to: 27)
        model.togglePlay()
        #expect(factory.last.currentTime == 0)
        #expect(model.position == 0)
    }

    // MARK: - Aufnahmen

    @Test("Stimme 1 und 2 haben Aufnahmen, Stimme 3 und die Fadschr-Varianten nicht")
    func clips() {
        #expect(AdhanClips.resource(for: .one, fajrVariant: false) == "adhan-voice1")
        #expect(AdhanClips.resource(for: .two, fajrVariant: false) == "adhan-voice2")
        #expect(AdhanClips.resource(for: .three, fajrVariant: false) == nil)
        for voice in AdhanVoice.allCases {
            #expect(AdhanClips.resource(for: voice, fajrVariant: true) == nil)
        }
        #expect(AdhanClips.silentDuration(fajrVariant: false) == 27)
        #expect(AdhanClips.silentDuration(fajrVariant: true) == 30)
    }

    @Test("ohne Aufnahme im Bundle läuft der Player stumm")
    func silentFallback() {
        let playback = AdhanClips.playback(for: .one, fajrVariant: false, bundle: Bundle(for: FakePlayback.self))
        #expect(playback is SilentPlayback)
        #expect(playback.duration == 27)
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
