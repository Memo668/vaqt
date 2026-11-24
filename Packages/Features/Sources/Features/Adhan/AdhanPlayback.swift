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

/// Die Aufnahme des Adhan im Player – `ADHAN_VOICE` im Prototyp (Spec § 11.2). Es ist dieselbe Datei, die
/// Mitteilungen und Wecker spielen (`AdhanRecording` in PrayerCore).
enum AdhanClips {

    /// Die Wiedergabe der Aufnahme aus dem Bundle der App. Fehlt die Datei oder lässt sie sich nicht
    /// öffnen – etwa im Bundle der Tests –, läuft der Player stumm über ihre Länge (`adhanDur()`).
    @MainActor
    static func playback(bundle: Bundle = .main) -> any AdhanPlayback {
        if let url = bundle.url(forResource: AdhanRecording.clipResource, withExtension: AdhanRecording.clipExtension),
           let playback = AudioClipPlayback(url: url) {
            return playback
        }
        return SilentPlayback(duration: AdhanRecording.clipDuration)
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
