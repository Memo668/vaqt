import CoreLocation
import Foundation
import PrayerCore
import Testing
@testable import Features

/// Der Kurs von Core Location: geografisch Nord, ohne Standort magnetisch Nord.
@Suite("CoreLocationHeadingSource")
struct CoreLocationHeadingSourceTests {

    @Test("mit Standort gilt geografisch Nord")
    func trueNorth() {
        let heading = CoreLocationHeadingSource.heading(trueHeading: 137, magneticHeading: 132.4, accuracy: 10)
        #expect(heading == Heading(degrees: 137, accuracy: 10, reference: .trueNorth))
        #expect(CoreLocationHeadingSource.heading(trueHeading: 0, magneticHeading: 355, accuracy: 5).degrees == 0)
    }

    @Test("ohne Standort meldet Core Location einen negativen Wert: Dann gilt magnetisch Nord")
    func magneticNorth() {
        let heading = CoreLocationHeadingSource.heading(trueHeading: -1, magneticHeading: 132.4, accuracy: 10)
        #expect(heading == Heading(degrees: 132.4, accuracy: 10, reference: .magneticNorth))
    }

    @Test("ein ungültiger Kurs behält seine negative Genauigkeit")
    func invalid() {
        let heading = CoreLocationHeadingSource.heading(trueHeading: -1, magneticHeading: 20, accuracy: -1)
        #expect(!heading.isValid)
        #expect(heading.needsCalibration)
    }

    @Test("ohne Kompass – wie im Simulator – endet die Folge, ohne etwas zu liefern")
    func withoutCompass() async {
        let source = CoreLocationHeadingSource()
        #expect(await source.isAvailable() == CLLocationManager.headingAvailable())
        guard !CLLocationManager.headingAvailable() else { return }
        var count = 0
        for await _ in await source.updates() {
            count += 1
        }
        #expect(count == 0)
    }
}
