import ActivityKit
import Foundation
import PrayerCore

/// Die Live-Aktivität zu einem Gebet (Spec § 3, „Live Activity“). App und Extension teilen diesen Typ:
/// Die App meldet die Aktivität an, die Extension zeichnet sie.
///
/// Fest bleibt, zu welchem Plan sie gehört und ab wann sie laufen sollte; der Inhalt (`ContentState`) kann
/// die App auffrischen, solange sie läuft.
public struct PrayerActivityAttributes: ActivityAttributes {
    public typealias ContentState = LiveActivityContent

    /// Kennung im Plan, z. B. `live.2026-11-10.maghrib`.
    public let planID: String
    /// Ab wann die Aktivität laufen sollte (Uhr der App).
    public let start: Date

    public init(planID: String, start: Date) {
        self.planID = planID
        self.start = start
    }
}
