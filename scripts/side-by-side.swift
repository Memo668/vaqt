// Legt zwei Aufnahmen in gleicher Höhe nebeneinander, darüber ihre Namen – für den Abgleich einer Sprache mit dem
// Prototyp in derselben Sprache (Phase 15, scripts/compare-language).
//
//   swift scripts/side-by-side.swift <ausgabe.png> <titel> <name=links.png> <name=rechts.png>
//
// Beide Bilder werden auf 1300 px Höhe gebracht; Ränder 24 px.
import AppKit

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 4 else {
    FileHandle.standardError.write(Data("Aufruf: side-by-side.swift <ausgabe.png> <titel> <name=links.png> <name=rechts.png>\n".utf8))
    exit(2)
}
let output = URL(fileURLWithPath: arguments[0])
let title = arguments[1]
let cells: [(name: String, image: NSImage)] = arguments[2...].map { entry in
    guard let separator = entry.lastIndex(of: "="),
          let image = NSImage(contentsOfFile: String(entry[entry.index(after: separator)...]))
    else {
        FileHandle.standardError.write(Data("side-by-side: Bild nicht lesbar: \(entry)\n".utf8))
        exit(1)
    }
    return (String(entry[..<separator]), image)
}

let height: CGFloat = 1300
let gap: CGFloat = 24
let header: CGFloat = 64
let widths = cells.map { (height * $0.image.size.width / $0.image.size.height).rounded() }
let size = NSSize(width: gap * 3 + widths.reduce(0, +), height: header + height + gap)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(white: 0.93, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()
let titleAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 22), .foregroundColor: NSColor.black]
let labelAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 18), .foregroundColor: NSColor.darkGray]
(title as NSString).draw(at: NSPoint(x: gap, y: size.height - 32), withAttributes: titleAttributes)
var x = gap
for (index, cell) in cells.enumerated() {
    (cell.name as NSString).draw(at: NSPoint(x: x, y: size.height - 58), withAttributes: labelAttributes)
    cell.image.draw(in: NSRect(x: x, y: gap, width: widths[index], height: height))
    x += widths[index] + gap
}
NSGraphicsContext.restoreGraphicsState()
guard let data = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try data.write(to: output)
