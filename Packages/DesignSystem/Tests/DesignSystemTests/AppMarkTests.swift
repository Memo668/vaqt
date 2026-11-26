import Foundation
import PrayerCore
import Testing
import UIKit
@testable import DesignSystem

/// Das Zeichen der App in der Grundfarbe (Phase 20, Spec § 13.3): je Grundfarbe ein Bildsatz hell und dunkel aus den
/// Icon-Composer-Dateien (`scripts/app-mark`), gewählt nach Grundfarbe und Schalter „App-Icon in der Grundfarbe“.
@Suite("App-Zeichen in der Grundfarbe")
struct AppMarkTests {

    // MARK: - Rechnen

    private func linear(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ color: RGBA) -> Double {
        0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// Kontrast nach WCAG 2.
    private func contrast(_ a: RGBA, _ b: RGBA) -> Double {
        let (hi, lo) = (max(luminance(a), luminance(b)), min(luminance(a), luminance(b)))
        return (hi + 0.05) / (lo + 0.05)
    }

    /// Das Bild einer Grundfarbe im hellen oder dunklen Erscheinungsbild als RGBA-Pixel (8 Bit, nicht vormultipliziert
    /// gelesen über einen vormultiplizierten Kontext – für deckende Pixel gleich).
    private func pixels(_ accent: AccentColorID, dark: Bool) throws -> (width: Int, height: Int, data: [UInt8]) {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        let image = try #require(UIImage(named: AppMarkMetrics.imageName(for: accent), in: .module, compatibleWith: traits))
        let cgImage = try #require(image.cgImage)
        let (width, height) = (cgImage.width, cgImage.height)
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(
            data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (width, height, data)
    }

    private func pixel(_ image: (width: Int, height: Int, data: [UInt8]), x: Int, y: Int) -> [UInt8] {
        let offset = (y * image.width + x) * 4
        return Array(image.data[offset..<offset + 4])
    }

    // MARK: - Zuordnung

    @Test("der Bildsatz heißt AppMark für Petrol, sonst AppMark-<id> wie das Icon AppIcon-<id>")
    func imageNames() {
        #expect(AppMarkMetrics.imageName(for: .teal) == "AppMark")
        #expect(AppMarkMetrics.imageName(for: .ocean) == "AppMark-ocean")
        for accent in AccentColorID.allCases {
            let icon = AppIconName.alternate(for: accent)
            #expect(icon == nil ? accent == .standard : icon == "AppIcon-" + accent.rawValue)
            #expect(AppMarkMetrics.imageName(for: accent).replacingOccurrences(of: "AppMark", with: "AppIcon")
                == (icon ?? AppIconName.primary))
        }
    }

    @Test("der Speicher übernimmt Grundfarbe und Farbe des Icons aus dem Stil; Schalter aus heißt Petrol")
    func storeFollowsStyle() {
        let store = AccentStore()
        #expect(store.accent == .teal && store.iconAccent == .teal)
        store.apply(AppStyle(accent: .ocean))
        #expect(store.accent == .ocean && store.iconAccent == .ocean)
        store.apply(AppStyle(accent: .ocean, tintsAppIcon: false))
        #expect(store.accent == .ocean && store.iconAccent == .teal)
        store.apply(.standard)
        #expect(store.accent == .teal && store.iconAccent == .teal)
    }

    // MARK: - Bilder

    @Test("je Grundfarbe hell und dunkel, 360 px: oben in der Mitte weiß bzw. schwarz, die Ecke durchsichtig",
          arguments: AccentColorID.allCases)
    func images(accent: AccentColorID) throws {
        for dark in [false, true] {
            let image = try pixels(accent, dark: dark)
            #expect(image.width == 360 && image.height == 360)
            // Über der Linse: der Grund des Icons, hell weiß, dunkel schwarz (Spec § 13.1).
            let ground = pixel(image, x: 180, y: 30)
            #expect(ground[3] == 255)
            if dark {
                #expect(ground[0] < 8 && ground[1] < 8 && ground[2] < 8)
            } else {
                #expect(ground[0] > 247 && ground[1] > 247 && ground[2] > 247)
            }
            // ictool rendert mit der Maske des Home-Bildschirms; die Ecke bleibt frei.
            #expect(pixel(image, x: 2, y: 2)[3] == 0)
        }
    }

    @Test("die Bilder unterscheiden sich je Grundfarbe – keine Farbe zeigt das Bild einer anderen")
    func distinctImages() throws {
        for dark in [false, true] {
            var seen: [[UInt8]: AccentColorID] = [:]
            for accent in AccentColorID.allCases {
                let data = try pixels(accent, dark: dark).data
                #expect(seen[data] == nil, "\(accent) wie \(seen[data].map(\.rawValue) ?? "")")
                seen[data] = accent
            }
        }
    }

    // MARK: - Kontrast

    @Test("Kontrast des Bogens: Petrol #1F7A6D auf Weiß 5,2 : 1, #4CC2AE auf Schwarz 9,6 : 1")
    func petrolContrast() {
        let white = RGBA(hex: 0xFFFFFF), black = RGBA(hex: 0x000000)
        #expect(AccentColorID.teal.light == RGBA(hex: 0x1F7A6D))
        #expect(AccentColorID.teal.dark == RGBA(hex: 0x4CC2AE))
        #expect(abs(contrast(AccentColorID.teal.light, white) - 5.2) < 0.05)
        #expect(abs(contrast(AccentColorID.teal.dark, black) - 9.6) < 0.05)
    }

    @Test("Kontrast des Bogens in jeder Grundfarbe: hell mindestens 5,0 : 1 auf Weiß (Grün 5,05), dunkel 6,2 : 1 auf Schwarz (Bordeaux)",
          arguments: AccentColorID.allCases)
    func arcContrast(accent: AccentColorID) {
        #expect(contrast(accent.light, RGBA(hex: 0xFFFFFF)) >= 5.0)
        #expect(contrast(accent.dark, RGBA(hex: 0x000000)) >= 6.2)
    }
}
