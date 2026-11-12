import AVFoundation
import Foundation
import PrayerCore

/// Eine Wiedergabe des Adhan-Players: ein Ausschnitt von höchstens 30 Sekunden.
@MainActor
protocol AdhanPlayback: AnyObject {
    /// Länge in Sekunden.
    var duration: TimeInterval { get }
    /// Gespielte Sekunden; setzen springt dorthin.
    var currentTime: TimeInterval { get set }
    var isPlaying: Bool { get }
    /// Abspielen. Kehrt zurück, sobald die Wiedergabe läuft – oder feststeht, dass sie nicht laufen kann,
    /// etwa ohne Ausgabegerät; dann ist `isPlaying` falsch.
    func play() async
    func pause()
    /// Anhalten und zurück an den Anfang.
    func stop()
}

/// Welche Aufnahme eine Stimme hat – `VOICES` im Prototyp, mit Platzhaltern.
///
/// TODO(placeholder): Stimme 1 und 2 spielen freie Aufnahmen von Wikimedia Commons (App/Sounds,
/// scripts/adhan-clip.swift); Stimme 3 und die Fadschr-Varianten haben keine und laufen stumm wie im
/// Prototyp, 27 bzw. 30 Sekunden (`adhanDur()`). Spec § 6.5 ist offen.
enum AdhanClips {

    /// Name der Datei im Bundle der App, ohne Endung; `nil`, wenn es keine Aufnahme gibt. Dieselben
    /// Aufnahmen spielen die Mitteilungen (`AdhanVoice.clipResource(fajrVariant:)` in PrayerCore).
    static func resource(for voice: AdhanVoice, fajrVariant: Bool) -> String? {
        voice.clipResource(fajrVariant: fajrVariant)
    }

    /// Länge des stummen Ablaufs ohne Aufnahme (`adhanDur()`): 27 Sekunden, die Fadschr-Variante 30.
    static func silentDuration(fajrVariant: Bool) -> TimeInterval {
        fajrVariant ? 30 : 27
    }

    /// Die Wiedergabe einer Stimme: ihre Aufnahme aus dem Bundle der App, sonst stumm.
    @MainActor
    static func playback(for voice: AdhanVoice, fajrVariant: Bool, bundle: Bundle = .main) -> any AdhanPlayback {
        if let name = resource(for: voice, fajrVariant: fajrVariant),
           let url = bundle.url(forResource: name, withExtension: "caf"),
           let playback = AudioClipPlayback(url: url) {
            return playback
        }
        return SilentPlayback(duration: silentDuration(fajrVariant: fajrVariant))
    }
}

/// Eine Aufnahme über `AVAudioPlayer`. Abspielen ist eine Handlung des Nutzers: Der Ton kommt auch bei
/// stummgeschaltetem iPhone (`.playback`), andere Wiedergaben halten so lange an.
@MainActor
final class AudioClipPlayback: AdhanPlayback {
    private let player: AVAudioPlayer

    init?(url: URL) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        self.player = player
        player.prepareToPlay()
    }

    var duration: TimeInterval { player.duration }

    var currentTime: TimeInterval {
        get { player.currentTime }
        set { player.currentTime = min(max(0, newValue), duration) }
    }

    var isPlaying: Bool { player.isPlaying }

    func play() async {
        await AdhanAudioSession.activate()
        player.play()
    }

    func pause() {
        player.pause()
        AdhanAudioSession.deactivate()
    }

    func stop() {
        player.stop()
        player.currentTime = 0
        AdhanAudioSession.deactivate()
    }
}

/// Die Audio-Sitzung der App. Sie wird nicht auf dem Haupt-Thread umgeschaltet: `setActive` kann dort
/// hängen, solange das System die Ausgabe vorbereitet.
enum AdhanAudioSession {

    /// Ton auch bei stummgeschaltetem iPhone; andere Wiedergaben halten an.
    static func activate() async {
        await Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
        }.value
    }

    /// Gibt die Ausgabe frei; andere Wiedergaben dürfen weiterlaufen.
    static func deactivate() {
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

/// Ein stummer Ablauf ohne Aufnahme, wie der Player des Prototyps: Die Zeit läuft in Echtzeit.
@MainActor
final class SilentPlayback: AdhanPlayback {
    let duration: TimeInterval
    private var start: ContinuousClock.Instant?
    private var offset: TimeInterval = 0

    init(duration: TimeInterval) {
        self.duration = duration
    }

    var isPlaying: Bool {
        start != nil && elapsed < duration
    }

    var currentTime: TimeInterval {
        get { min(elapsed, duration) }
        set {
            offset = min(max(0, newValue), duration)
            if start != nil {
                start = .now
            }
        }
    }

    private var elapsed: TimeInterval {
        guard let start else { return offset }
        let running = ContinuousClock.now - start
        return offset + Double(running.components.seconds) + Double(running.components.attoseconds) / 1e18
    }

    func play() async {
        guard start == nil else { return }
        start = .now
    }

    func pause() {
        offset = min(elapsed, duration)
        start = nil
    }

    func stop() {
        start = nil
        offset = 0
    }
}
