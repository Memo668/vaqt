// scripts/compare-shot.swift
//
// Legt einen Ausschnitt einer Simulator-Aufnahme neben denselben Ausschnitt eines Referenzbilds aus
// design/screenshots/ – für den 1:1-Abgleich (CLAUDE.md, „Prüfen“).
//
// Die Referenzbilder sind 390 pt breit (2x), die Aufnahmen des iPhone 18 Pro 402 pt (3x). Verglichen
// werden deshalb Ausschnitte in pt, nicht ganze Bilder. Das Skript bringt beide Ausschnitte auf
// dieselbe Größe und schreibt sie untereinander in ein Bild:
//
//   oben    Referenz
//   Mitte   Aufnahme
//   unten   Unterschied – weiß heißt gleich, je dunkler, desto größer die Abweichung
//
// Aufruf über den Wrapper:
//
//   scripts/compare-shot --ref design/screenshots/iphone/10-home-asr-active.png --ref-rect 16,223.4,358,180 \
//                        --shot screenshots-out/phase-2/arc-1425.png --shot-rect 22,140,358,180 \
//                        --out screenshots-out/phase-2/compare-arc-1425.png
//
// Optionen:
//   --ref <png> --ref-rect x,y,b,h     Referenzbild und Ausschnitt in pt
//   --shot <png> --shot-rect x,y,b,h   Aufnahme und Ausschnitt in pt
//   --out <png>                        Ziel
//   --zoom <n>                         Pixel je pt im Ergebnis (Standard 4)
//   --ref-points <n>                   Breite des Referenzbilds in pt (Standard 390)
//   --shot-points <n>                  Breite der Aufnahme in pt (Standard 402)
//   --probe x,y                        Farbe beider Bilder an einem Punkt des Ausschnitts (pt), mehrfach möglich
//
// Fehlt --ref oder --shot, schreibt das Skript nur den vergrößerten Ausschnitt des anderen Bilds.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("compare-shot: \(message)\n".utf8))
    exit(1)
}

// MARK: - Argumente

struct Options {
    var ref: String?
    var shot: String?
    var out: String?
    var refRect: CGRect?
    var shotRect: CGRect?
    var zoom: CGFloat = 4
    var refPoints: CGFloat = 390
    var shotPoints: CGFloat = 402
    var probes: [CGPoint] = []
}

func numbers(_ text: String, count: Int, for option: String) -> [CGFloat] {
    let parts = text.split(separator: ",").map { Double($0) }
    guard parts.count == count, !parts.contains(where: { $0 == nil }) else {
        fail("\(option) erwartet \(count) Zahlen, durch Kommas getrennt – bekommen: \(text)")
    }
    return parts.map { CGFloat($0 ?? 0) }
}

var options = Options()
var arguments = Array(CommandLine.arguments.dropFirst())[...]
while let argument = arguments.popFirst() {
    guard let value = arguments.popFirst() else { fail("\(argument) braucht einen Wert") }
    switch argument {
    case "--ref": options.ref = value
    case "--shot": options.shot = value
    case "--out": options.out = value
    case "--ref-rect":
        let n = numbers(value, count: 4, for: argument)
        options.refRect = CGRect(x: n[0], y: n[1], width: n[2], height: n[3])
    case "--shot-rect":
        let n = numbers(value, count: 4, for: argument)
        options.shotRect = CGRect(x: n[0], y: n[1], width: n[2], height: n[3])
    case "--zoom": options.zoom = numbers(value, count: 1, for: argument)[0]
    case "--ref-points": options.refPoints = numbers(value, count: 1, for: argument)[0]
    case "--shot-points": options.shotPoints = numbers(value, count: 1, for: argument)[0]
    case "--probe":
        let n = numbers(value, count: 2, for: argument)
        options.probes.append(CGPoint(x: n[0], y: n[1]))
    default: fail("unbekannte Option \(argument)")
    }
}
guard let outPath = options.out else { fail("--out fehlt") }
guard options.ref != nil || options.shot != nil else { fail("--ref oder --shot fehlt") }

// MARK: - Bilder

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

/// Ein Bild als RGBA-Bytes, Zeile für Zeile von oben.
struct Bitmap {
    let width: Int
    let height: Int
    var pixels: [UInt8]

    init(width: Int, height: Int, fill: UInt8 = 255) {
        self.width = width
        self.height = height
        pixels = [UInt8](repeating: fill, count: width * height * 4)
    }

    func color(x: Int, y: Int) -> (r: Int, g: Int, b: Int) {
        let index = (min(max(y, 0), height - 1) * width + min(max(x, 0), width - 1)) * 4
        return (Int(pixels[index]), Int(pixels[index + 1]), Int(pixels[index + 2]))
    }

    var image: CGImage {
        var copy = pixels
        let context = CGContext(
            data: &copy, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return context.makeImage()!
    }
}

func load(_ path: String) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else { fail("\(path) lässt sich nicht lesen") }
    return image
}

/// Der Ausschnitt `rect` (in pt) von `image`, auf `zoom` Pixel je pt gebracht.
func crop(_ image: CGImage, rect: CGRect, widthInPoints: CGFloat, zoom: CGFloat) -> Bitmap {
    let scale = CGFloat(image.width) / widthInPoints
    let width = Int((rect.width * zoom).rounded()), height = Int((rect.height * zoom).rounded())
    var bitmap = Bitmap(width: width, height: height)
    bitmap.pixels.withUnsafeMutableBytes { buffer in
        let context = CGContext(
            data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .high
        // Das ganze Bild so legen, dass der Ausschnitt den Kontext füllt. CoreGraphics zählt y von unten.
        let factor = zoom / scale
        let drawWidth = CGFloat(image.width) * factor, drawHeight = CGFloat(image.height) * factor
        let originX = -rect.minX * zoom
        let originY = CGFloat(height) - drawHeight + rect.minY * zoom
        context.draw(image, in: CGRect(x: originX, y: originY, width: drawWidth, height: drawHeight))
    }
    return bitmap
}

func hex(_ color: (r: Int, g: Int, b: Int)) -> String {
    String(format: "#%02X%02X%02X", color.r, color.g, color.b)
}

// MARK: - Vergleich

let zoom = options.zoom
var panels: [Bitmap] = []
var reference: Bitmap?
var shot: Bitmap?

if let path = options.ref {
    guard let rect = options.refRect else { fail("--ref-rect fehlt") }
    reference = crop(load(path), rect: rect, widthInPoints: options.refPoints, zoom: zoom)
    panels.append(reference!)
}
if let path = options.shot {
    guard let rect = options.shotRect else { fail("--shot-rect fehlt") }
    shot = crop(load(path), rect: rect, widthInPoints: options.shotPoints, zoom: zoom)
    panels.append(shot!)
}

if let reference, let shot {
    guard reference.width == shot.width, reference.height == shot.height else {
        fail("die Ausschnitte sind verschieden groß: \(reference.width)×\(reference.height) und \(shot.width)×\(shot.height)")
    }
    var difference = Bitmap(width: reference.width, height: reference.height)
    var sum = 0, over = 0
    for index in stride(from: 0, to: reference.pixels.count, by: 4) {
        let d = max(
            abs(Int(reference.pixels[index]) - Int(shot.pixels[index])),
            abs(Int(reference.pixels[index + 1]) - Int(shot.pixels[index + 1])),
            abs(Int(reference.pixels[index + 2]) - Int(shot.pixels[index + 2]))
        )
        sum += d
        if d > 24 { over += 1 }
        let value = UInt8(255 - min(255, d * 3))
        difference.pixels[index] = value
        difference.pixels[index + 1] = value
        difference.pixels[index + 2] = value
        difference.pixels[index + 3] = 255
    }
    panels.append(difference)
    let count = reference.width * reference.height
    print(String(
        format: "Abweichung: im Mittel %.2f von 255, %.2f %% der Pixel über 24",
        Double(sum) / Double(count), Double(over) * 100 / Double(count)
    ))
}

for probe in options.probes {
    let x = Int((probe.x * zoom).rounded()), y = Int((probe.y * zoom).rounded())
    var line = String(format: "Punkt %.1f,%.1f:", Double(probe.x), Double(probe.y))
    if let reference { line += " Referenz " + hex(reference.color(x: x, y: y)) }
    if let shot { line += " Aufnahme " + hex(shot.color(x: x, y: y)) }
    print(line)
}

// MARK: - Ausgabe

let gap = Int(zoom * 2)
let width = panels.map(\.width).max() ?? 0
let height = panels.map(\.height).reduce(0, +) + gap * (panels.count - 1)
var output = Bitmap(width: width, height: height, fill: 255)
// Trennstreifen zwischen den Feldern in Magenta, damit sie nicht mit dem Inhalt verwechselt werden.
var top = 0
for (number, panel) in panels.enumerated() {
    for y in 0..<panel.height {
        let source = y * panel.width * 4
        let target = ((top + y) * width) * 4
        output.pixels.replaceSubrange(target..<(target + panel.width * 4), with: panel.pixels[source..<(source + panel.width * 4)])
    }
    top += panel.height
    if number < panels.count - 1 {
        for y in top..<(top + gap) {
            for x in 0..<width {
                let index = (y * width + x) * 4
                output.pixels[index] = 255
                output.pixels[index + 1] = 0
                output.pixels[index + 2] = 255
                output.pixels[index + 3] = 255
            }
        }
        top += gap
    }
}

let url = URL(fileURLWithPath: outPath)
try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fail("\(outPath) lässt sich nicht schreiben")
}
CGImageDestinationAddImage(destination, output.image, nil)
guard CGImageDestinationFinalize(destination) else { fail("\(outPath) lässt sich nicht schreiben") }
print("geschrieben: \(outPath) (\(width)×\(height) px, \(Int(zoom)) px je pt)")
