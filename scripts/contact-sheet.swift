// Legt Aufnahmen verkleinert in ein Raster, unter jede ihren Namen – ein Kontaktbogen für den Abgleich
// (Phase 11, scripts/capture-matrix).
//
//   swift scripts/contact-sheet.swift <ausgabe.png> <spalten> <titel> <name=pfad.png> …
//
// Jede Zelle ist 240 px breit; die Höhe folgt dem Seitenverhältnis der ersten Aufnahme.
import AppKit

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count >= 3, let columns = Int(arguments[arguments.startIndex + 1]) else {
    FileHandle.standardError.write(Data("Aufruf: contact-sheet.swift <ausgabe.png> <spalten> <titel> <name=pfad.png> …\n".utf8))
    exit(2)
}
let output = URL(fileURLWithPath: arguments[arguments.startIndex])
let title = arguments[arguments.startIndex + 2]
let cells: [(name: String, image: NSImage)] = arguments.dropFirst(3).compactMap { entry in
    guard let separator = entry.lastIndex(of: "=") else { return nil }
    let path = String(entry[entry.index(after: separator)...])
    guard let image = NSImage(contentsOfFile: path) else { return nil }
    return (String(entry[..<separator]), image)
}
guard let first = cells.first else { exit(0) }

let cellWidth: CGFloat = 240
let cellHeight = (cellWidth * first.image.size.height / first.image.size.width).rounded()
let labelHeight: CGFloat = 22
let gap: CGFloat = 16
let header: CGFloat = 44
let rows = (cells.count + columns - 1) / columns
let width = gap + CGFloat(columns) * (cellWidth + gap)
let height = header + CGFloat(rows) * (cellHeight + labelHeight + gap) + gap

guard let context = CGContext(
    data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }
NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
context.translateBy(x: 0, y: height)
context.scaleBy(x: 1, y: -1)
NSColor(white: 0.93, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

let titleAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 20), .foregroundColor: NSColor.black]
NSAttributedString(string: title, attributes: titleAttributes).draw(at: NSPoint(x: gap, y: 12))
let labelAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.darkGray]

for (index, cell) in cells.enumerated() {
    let x = gap + CGFloat(index % columns) * (cellWidth + gap)
    let y = header + CGFloat(index / columns) * (cellHeight + labelHeight + gap)
    let frame = NSRect(x: x, y: y, width: cellWidth, height: cellHeight)
    cell.image.draw(in: frame, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    NSColor(white: 0.75, alpha: 1).setStroke()
    NSBezierPath(rect: frame).stroke()
    NSAttributedString(string: cell.name, attributes: labelAttributes).draw(at: NSPoint(x: x, y: y + cellHeight + 3))
}

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(output as CFURL, "public.png" as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(destination, image, nil)
CGImageDestinationFinalize(destination)
