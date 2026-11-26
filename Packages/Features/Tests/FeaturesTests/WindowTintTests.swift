import DesignSystem
import PrayerCore
import Testing
import UIKit
@testable import Features

/// Die Farbe der Fenster (`WindowTint`): Für das Teilen-Blatt kodiert UIKit sie auf einer Warteschlange des
/// Systems, nicht auf dem Hauptthread. Gehört ihre Closure zum Main Actor, bricht Swift 6 dort ab – so stürzte
/// „App weiterempfehlen“ am 25. und 26.11.2026 auf dem iPhone Duo ab, mit einer anderen Grundfarbe als Petrol.
@Suite("Farbe der Fenster")
struct WindowTintTests {

    @Test("auf dem Main Actor erzeugt, außerhalb aufgelöst – hell und dunkel", arguments: [AccentColorID.green, .orange, .sand])
    @MainActor
    func resolvesOffTheMainActor(accent: AccentColorID) async {
        // Wie `apply(_:)`: Die Farbe entsteht auf dem Main Actor …
        let color = WindowTint.color(for: accent)
        // … und wird wie beim Teilen-Blatt auf einer anderen Warteschlange aufgelöst.
        let (light, dark) = await Task.detached {
            (Self.resolve(color, style: .light), Self.resolve(color, style: .dark))
        }.value
        #expect(Self.isClose(light, accent.light))
        #expect(Self.isClose(dark, accent.dark))
    }

    private nonisolated static func resolve(_ color: UIColor, style: UIUserInterfaceStyle) -> RGBA {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBA(red: red, green: green, blue: blue, alpha: alpha)
    }

    private nonisolated static func isClose(_ lhs: RGBA, _ rhs: RGBA) -> Bool {
        [lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue, lhs.alpha - rhs.alpha]
            .allSatisfy { abs($0) < 0.000_001 }
    }
}
