// swift-tools-version: 6.0
import PackageDescription

// Tokens (Palette, Layout, Typography), Glass-Bausteine, DayArc, Karten – und der String Catalog,
// damit App, Features und Widgets dieselben Texte lesen.
let package = Package(
    name: "DesignSystem",
    defaultLocalization: "de",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    dependencies: [
        .package(path: "../PrayerCore"),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: ["PrayerCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
