import Foundation
import SwiftUI
import Testing
@testable import Features

/// Der Takt des Countdowns auf der Zeiten-Seite (Phase 11, Leistung): jede volle Sekunde, angehalten nur ein
/// Bild.
@Suite("Takt des Countdowns")
struct CountdownScheduleTests {

    private let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    @Test("läuft: jede volle Sekunde ab dem Beginn des Takts")
    func running() {
        let schedule = CountdownSchedule(start: start, isPaused: false)
        let now = start.addingTimeInterval(10.4)
        let entries = Array(schedule.entries(from: now, mode: .normal).prefix(3))
        #expect(entries.count == 3)
        for (first, second) in zip(entries, entries.dropFirst()) {
            #expect(second.timeIntervalSince(first) == 1)
        }
        // Alle Einträge liegen auf vollen Sekunden des Takts.
        for entry in entries {
            #expect(entry.timeIntervalSince(start).truncatingRemainder(dividingBy: 1) == 0)
        }
        // Der erste Eintrag liegt nicht später als eine Sekunde nach „jetzt“ – das erste Bild kommt sofort.
        #expect(entries[0].timeIntervalSince(now) <= 1)
    }

    @Test("angehalten: ein Bild, dann nichts mehr")
    func paused() {
        let schedule = CountdownSchedule(start: start, isPaused: true)
        let now = start.addingTimeInterval(42)
        let entries = Array(schedule.entries(from: now, mode: .normal).prefix(5))
        #expect(entries == [now])
    }
}
