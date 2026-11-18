// swift-tools-version: 6.0
import PackageDescription

// Reine Logik ohne UI: Berechnung, Tagesphase, Kerahat, Qibla, Hijri, Nachholen, Daten der Anleitung.
// macOS steht nur in der Liste, damit `swift test` ohne Simulator läuft.
let package = Package(
    name: "PrayerCore",
    platforms: [.iOS("26.0"), .macOS(.v14)],
    products: [
        .library(name: "PrayerCore", targets: ["PrayerCore"]),
    ],
    dependencies: [
        // Einzige Fremdabhängigkeit des Projekts (MIT). Genau diese Fassung, damit jeder Build dieselben Zeiten
        // rechnet: Das Package.resolved der App liegt im erzeugten Xcode-Projekt und ist nicht eingecheckt
        // (Sicherheitsprüfung vom 17.11.2026). Neue Fassung: hier, in docs/THIRD-PARTY.md und die Tests prüfen.
        .package(url: "https://github.com/batoulapps/adhan-swift", exact: "1.5.0"),
    ],
    targets: [
        .target(
            name: "PrayerCore",
            dependencies: [.product(name: "Adhan", package: "adhan-swift")]
        ),
        .testTarget(
            name: "PrayerCoreTests",
            dependencies: ["PrayerCore", .product(name: "Adhan", package: "adhan-swift")],
            // Referenztabellen aus den Testdaten von Adhan Swift (MIT), siehe README im Ordner.
            resources: [.copy("Resources/AdhanTimes")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
