// Zeichnet das Platzhalter-Icon (Phase 11): den Tagesbogen mit den fünf Gebeten, wie auf der Zeiten-Seite –
// entschieden mit dem Plan für Phase 11 („A Tagesbogen“, aus drei Entwürfen). TODO(placeholder): Das
// endgültige Icon folgt (Spec § 6.9).
//
//   swift scripts/app-icon.swift [Ordner]     Standard: App/Assets.xcassets/AppIcon.appiconset
//
// Schreibt drei Bilder mit 1024 × 1024 px und Contents.json:
//   AppIcon.png         hell, deckend und ohne Alphakanal (verlangt App Store Connect)
//   AppIcon-dark.png    dunkel, auf durchsichtigem Grund – den dunklen Hintergrund setzt iOS
//   AppIcon-tinted.png  getönt, in Graustufen auf durchsichtigem Grund – die Farbe setzt iOS
//
// Farben wie das Zeichen der App (AppMark): Verlauf aus dem Akzent #1F7A6D, Symbole wie die Gebetskarten.
import AppKit
import SwiftUI

let folder = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "App/Assets.xcassets/AppIcon.appiconset"
let side: CGFloat = 1024

// MARK: - Farben

func rgb(_ hex: UInt32) -> (Double, Double, Double) {
    (Double((hex >> 16) & 0xFF) / 255, Double((hex >> 8) & 0xFF) / 255, Double(hex & 0xFF) / 255)
}
func color(_ c: (Double, Double, Double), _ opacity: Double = 1) -> Color {
    Color(.sRGB, red: c.0, green: c.1, blue: c.2, opacity: opacity)
}
func mix(_ a: (Double, Double, Double), _ fraction: Double, _ b: (Double, Double, Double)) -> (Double, Double, Double) {
    (a.0 * fraction + b.0 * (1 - fraction), a.1 * fraction + b.1 * (1 - fraction), a.2 * fraction + b.2 * (1 - fraction))
}
let accent = rgb(0x1F7A6D)
let accentDark = rgb(0x4CC2AE)
let onAccentDark = rgb(0x04221D)
let white = (1.0, 1.0, 1.0)
let black = (0.0, 0.0, 0.0)

/// Der Verlauf von AppMark: `linear-gradient(165deg, mix(accent 62 %, #fff), accent 52 %, mix(accent 68 %, #000))`.
let gradient = LinearGradient(
    stops: [
        .init(color: color(mix(accent, 0.62, white)), location: 0),
        .init(color: color(accent), location: 0.52),
        .init(color: color(mix(accent, 0.68, black)), location: 1),
    ],
    startPoint: UnitPoint(x: 0.37, y: -0.02), endPoint: UnitPoint(x: 0.63, y: 1.02)
)

// MARK: - Bogen

/// Fadschr, Dhuhr, Asr, Maghrib, Ischa – die Symbole der Gebetskarten.
let symbols = ["sun.horizon", "sun.max", "sun.min", "sunset", "moon.stars"]
/// Die Marker stehen gleichmäßig auf dem Bogen; Asr in der Mitte läuft, Fadschr und Dhuhr haben begonnen.
let fractions = [0.0, 0.25, 0.5, 0.75, 1.0]
let current = 2
let filled = 0.62
let center = CGPoint(x: 512, y: 772)
let radius: CGFloat = 380
let endAngle = 0.42

func point(_ fraction: Double) -> CGPoint {
    let angle = endAngle + fraction * (.pi - 2 * endAngle)
    return CGPoint(x: center.x - radius * cos(angle), y: center.y - radius * sin(angle))
}

struct Arc: Shape {
    let from: Double
    let to: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for step in 0...120 {
            let p = point(from + (to - from) * Double(step) / 120)
            if step == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
}

/// Farben einer Fassung.
struct Style {
    var background: AnyShapeStyle?
    var track: Color
    var fill: Color
    var glow: Color
    var begunMarker: Color
    var begunSymbol: Color
    var upcomingMarker: Color
    var upcomingSymbol: Color
}

struct Icon: View {
    let style: Style

    var body: some View {
        ZStack {
            if let background = style.background {
                Rectangle().fill(background)
            }
            Arc(from: 0, to: 1).stroke(style.track, style: StrokeStyle(lineWidth: 46, lineCap: .round))
            Arc(from: 0, to: filled).stroke(style.fill, style: StrokeStyle(lineWidth: 46, lineCap: .round))
            ForEach(0..<5, id: \.self) { index in
                let begun = fractions[index] <= fractions[current]
                let isCurrent = index == current
                ZStack {
                    if isCurrent {
                        Circle().fill(style.glow).frame(width: 200, height: 200)
                    }
                    Circle()
                        .fill(begun ? style.begunMarker : style.upcomingMarker)
                        .frame(width: isCurrent ? 142 : 118, height: isCurrent ? 142 : 118)
                    Image(systemName: symbols[index])
                        .font(.system(size: isCurrent ? 66 : 54, weight: .bold))
                        .foregroundStyle(begun ? style.begunSymbol : style.upcomingSymbol)
                }
                .position(point(fractions[index]))
            }
        }
        .frame(width: side, height: side)
    }
}

let light = Style(
    background: AnyShapeStyle(gradient), track: color(white, 0.32), fill: color(white), glow: color(white, 0.28),
    begunMarker: color(white), begunSymbol: color(accent),
    upcomingMarker: color(mix(accent, 0.30, white)), upcomingSymbol: color(accent)
)
let dark = Style(
    background: nil, track: color(accentDark, 0.32), fill: color(accentDark), glow: color(accentDark, 0.28),
    begunMarker: color(accentDark), begunSymbol: color(onAccentDark),
    upcomingMarker: color(mix(accentDark, 0.35, black)), upcomingSymbol: color(accentDark)
)
let tinted = Style(
    background: nil, track: color(white, 0.35), fill: color(white), glow: color(white, 0.25),
    begunMarker: color(white), begunSymbol: color((0.25, 0.25, 0.25)),
    upcomingMarker: color(white, 0.45), upcomingSymbol: color(white)
)

// MARK: - Schreiben

@MainActor
func write(_ style: Style, to name: String, opaque: Bool) {
    let renderer = ImageRenderer(content: Icon(style: style))
    renderer.scale = 1
    guard let image = renderer.cgImage else { fatalError("kein Bild für \(name)") }
    var output = image
    if opaque {
        // Ohne Alphakanal: auf eine deckende Fläche ohne Alpha zeichnen.
        let context = CGContext(
            data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        output = context.makeImage()!
    }
    let url = URL(fileURLWithPath: folder).appendingPathComponent(name)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, output, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("\(name) nicht geschrieben") }
    print(url.path)
}

let contents = """
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "AppIcon-dark.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "filename" : "AppIcon-tinted.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""

try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
try contents.write(toFile: folder + "/Contents.json", atomically: true, encoding: .utf8)
MainActor.assumeIsolated {
    write(light, to: "AppIcon.png", opaque: true)
    write(dark, to: "AppIcon-dark.png", opaque: false)
    write(tinted, to: "AppIcon-tinted.png", opaque: false)
}
