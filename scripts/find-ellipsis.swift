// Sucht in Aufnahmen per Texterkennung (Vision) nach Auslassungspunkten „…“ – Zeichen dafür, dass SwiftUI einen
// Text abgeschnitten hat (Phase 11 von Hand, seit Phase 15 als Skript für scripts/capture-matrix).
//
//   swift scripts/find-ellipsis.swift <sprache> <bild.png> …
//
// Gibt je Fund „<bild>: <Zeile>“ aus. Vision erkennt Lateinisch und Kyrillisch sicher, Arabisch nur zum Teil,
// Bengali nicht: Für ar, ur, fa und bn die Kontaktbögen zusätzlich von Auge ansehen.
import Foundation
import Vision

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 2 else {
    FileHandle.standardError.write(Data("Aufruf: find-ellipsis.swift <sprache> <bild.png> …\n".utf8))
    exit(2)
}
let language = arguments[0]
// Ausnahmen: Auslassungspunkte, die im Text selbst stehen – die Formel des Sitzens „At-taḥiyyātu li-llāh …“ und ihr
// arabischer Text (`FORMULA`), den Vision als Latein liest. Alle übrigen Funde von Auge prüfen.
let allowed = ["tahiyy", "taḥiyy", "li-llā", "li-Ilā"]

var findings = 0
for path in arguments.dropFirst() {
    guard let image = NSImageRepLoader.cgImage(path) else { continue }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    if let supported = try? request.supportedRecognitionLanguages(),
       let match = supported.first(where: { $0.hasPrefix(language) }) {
        request.recognitionLanguages = [match, "en-US"]
    }
    try? VNImageRequestHandler(cgImage: image).perform([request])
    for observation in request.results ?? [] {
        guard let text = observation.topCandidates(1).first?.string else { continue }
        guard text.contains("…") || text.contains("...") else { continue }
        guard !allowed.contains(where: { text.contains($0) }) else { continue }
        print("\(URL(fileURLWithPath: path).lastPathComponent): \(text)")
        findings += 1
    }
}
FileHandle.standardError.write(Data("\(findings) Fund(e) in \(arguments.count - 1) Aufnahmen (\(language))\n".utf8))

enum NSImageRepLoader {
    static func cgImage(_ path: String) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
