// swift-tools-version: 6.0
import PackageDescription

// Bildschirme: Today, Qibla, Guide, Verses, Qada, Settings, Onboarding.
let package = Package(
    name: "Features",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "Features", targets: ["Features"]),
    ],
    dependencies: [
        .package(path: "../PrayerCore"),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "Features",
            dependencies: ["PrayerCore", "DesignSystem"]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: ["Features"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
