// Schneidet die Adhan-Ausschnitte für den Player und die Mitteilungen (Phase 7).
//
//   swift scripts/adhan-clip.swift envelope <eingabe> [sekunden]     Lautstärke je halbe Sekunde
//   swift scripts/adhan-clip.swift clip <eingabe> <ausgabe.caf> <start> <dauer> <ausblenden>
//
// Der Ausschnitt ist mono, 22,05 kHz, 16 Bit LPCM in CAF, mit 50 ms Einblenden und `ausblenden`
// Sekunden Ausblenden am Ende; die Spitze liegt bei −1 dBFS. Danach komprimiert `afconvert` ihn in IMA4,
// eines der Formate, die iOS für Mitteilungstöne annimmt (unter 30 Sekunden):
//
//   afconvert -f caff -d ima4 -c 1 <ausschnitt.caf> App/Sounds/adhan.caf
//
// Seit Phase 18 (Spec § 11.2) gibt es eine Aufnahme, den Adhan von Ustadh Mmanga Muharram (DARSA TV, auf
// YouTube unter CC BY). Quelle, Lizenz und Prüfsummen stehen in docs/THIRD-PARTY.md. Die MP3 hat der Inhaber
// geliefert; sie liegt nicht im Repo.
//
//   App/Sounds/adhan.caf   clip … 0.0 29.5 1.0   – die ersten 29,5 Sekunden, sie enden in der dritten
//                                                  Pause der Aufnahme (gemessen mit `envelope`)
//
// Bis Phase 17 lagen hier zwei Platzhalter von Wikimedia Commons (adhan-voice1.caf, adhan-voice2.caf).
import AVFoundation
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else { print("Aufruf: envelope|clip …"); exit(2) }
let input = URL(fileURLWithPath: args[2])
let file = try AVAudioFile(forReading: input)
let format = file.processingFormat
let rate = format.sampleRate
let total = AVAudioFrameCount(file.length)
guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: total) else { exit(1) }
try file.read(into: buffer)
let channels = Int(format.channelCount)
let frames = Int(buffer.frameLength)
// Mono-Mischung.
var mono = [Float](repeating: 0, count: frames)
for c in 0..<channels {
    let data = buffer.floatChannelData![c]
    for i in 0..<frames { mono[i] += data[i] / Float(channels) }
}

switch args[1] {
case "envelope":
    let seconds = args.count > 3 ? Double(args[3]) ?? 40 : 40
    let step = Int(rate * 0.5)
    var t = 0.0
    var i = 0
    while i < min(frames, Int(rate * seconds)) {
        let end = min(i + step, frames)
        var sum: Float = 0
        for j in i..<end { sum += mono[j] * mono[j] }
        let rms = sqrt(sum / Float(end - i))
        let db = 20 * log10(max(rms, 1e-6))
        let bar = String(repeating: "#", count: max(0, Int((db + 60) / 2)))
        print(String(format: "%5.1f s %6.1f dB ", t, db) + bar)
        i = end
        t += 0.5
    }
    print(String(format: "Länge: %.3f s, %d Kanäle, %.0f Hz", Double(frames) / rate, channels, rate))
case "clip":
    let output = URL(fileURLWithPath: args[3])
    let start = Double(args[4])!, duration = Double(args[5])!, fadeOut = Double(args[6])!
    let first = Int(start * rate)
    let count = min(Int(duration * rate), frames - first)
    var clip = Array(mono[first..<(first + count)])
    let fadeIn = Int(0.05 * rate)
    for i in 0..<min(fadeIn, count) { clip[i] *= Float(i) / Float(fadeIn) }
    let fadeFrames = Int(fadeOut * rate)
    for k in 0..<min(fadeFrames, count) {
        let i = count - 1 - k
        clip[i] *= Float(k) / Float(fadeFrames)
    }
    let peak = clip.map(abs).max() ?? 1
    let gain = peak > 0 ? Float(pow(10.0, -1.0 / 20.0)) / peak : 1
    for i in 0..<count { clip[i] *= gain }
    // Auf 22,05 kHz umrechnen.
    let targetRate = 22_050.0
    guard let source = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1),
          let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetRate, channels: 1, interleaved: false),
          let sourceBuffer = AVAudioPCMBuffer(pcmFormat: source, frameCapacity: AVAudioFrameCount(count)),
          let converter = AVAudioConverter(from: source, to: target)
    else { exit(1) }
    sourceBuffer.frameLength = AVAudioFrameCount(count)
    clip.withUnsafeBufferPointer { sourceBuffer.floatChannelData![0].update(from: $0.baseAddress!, count: count) }
    let capacity = AVAudioFrameCount(Double(count) * targetRate / rate) + 1024
    guard let targetBuffer = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else { exit(1) }
    var fed = false
    var error: NSError?
    converter.convert(to: targetBuffer, error: &error) { _, status in
        if fed { status.pointee = .endOfStream; return nil }
        fed = true
        status.pointee = .haveData
        return sourceBuffer
    }
    if let error { print(error); exit(1) }
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: targetRate, AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
    ]
    try? FileManager.default.removeItem(at: output)
    let out = try AVAudioFile(forWriting: output, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try out.write(from: targetBuffer)
    print(String(format: "geschrieben: %@, %.3f s", output.lastPathComponent, Double(targetBuffer.frameLength) / targetRate))
default:
    print("unbekannt")
}
