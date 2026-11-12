import DesignSystem
import Foundation
import os
import PrayerCore
import WidgetKit

/// Wohin der Stand für die Widgets geht.
public protocol WidgetPublishing: Sendable {
    /// Schreibt den Stand und lässt die Widgets neu laden, wenn er sich geändert hat.
    @MainActor func publish(_ state: WidgetState)
}

/// In die App Group, aus der die Extension liest; danach lädt WidgetKit die Zeitleisten neu.
public struct AppGroupWidgetPublisher: WidgetPublishing {
    /// Kennung der App Group; ohne sie schreibt der Publisher nichts.
    public let suiteName: String?

    public init(suiteName: String?) {
        self.suiteName = suiteName
    }

    @MainActor
    public func publish(_ state: WidgetState) {
        guard let defaults = suiteName.flatMap({ UserDefaults(suiteName: $0) }) else { return }
        guard state.save(to: defaults) else { return }
        // Aus der App im Vordergrund zählt das Neuladen nicht gegen das Budget von WidgetKit.
        WidgetCenter.shared.reloadAllTimelines()
        WidgetSync.log.notice("Widgets neu geladen: \(state.cityName, privacy: .public), \(state.language.rawValue, privacy: .public)")
    }
}

/// Schreibt nichts – für Tests und Previews.
public struct NoWidgetPublisher: WidgetPublishing {
    public init() {}

    @MainActor
    public func publish(_ state: WidgetState) {}
}

/// Hält den Stand der Widgets aktuell (Spec § 1, „Outside the app“; § 4: Minutenkorrekturen gelten auch
/// für die Widgets).
///
/// Die Widgets rechnen selbst mit PrayerCore; die App schreibt ihnen nur, was in der App gilt: Ort, Name
/// des Ortes, Rechen-Einstellungen, Kerahat-Schalter und Sprache. Ändert sich davon etwas, laden die
/// Widgets neu.
@MainActor
public final class WidgetSync {

    static let log = Logger(subsystem: "com.example.gebetszeiten", category: "widgets")

    public let settings: SettingsStore
    public let location: PlaceModel

    private let clock: any AppClock
    private let publisher: any WidgetPublishing
    private let debug: Debug?

    /// Was die Debug-Startargumente an den Zeiten ändern (nur DEBUG).
    public struct Debug: Hashable, Sendable {
        public var fixtureTimes: Bool
        public var highLatitude: Bool

        public init(fixtureTimes: Bool, highLatitude: Bool) {
            self.fixtureTimes = fixtureTimes
            self.highLatitude = highLatitude
        }
    }

    public init(
        settings: SettingsStore, location: PlaceModel, clock: any AppClock, publisher: any WidgetPublishing,
        debug: Debug? = nil
    ) {
        self.settings = settings
        self.location = location
        self.clock = clock
        self.publisher = publisher
        self.debug = debug
    }

    /// Der Stand, wie er gerade in der App gilt.
    public var state: WidgetState {
        let offset = Self.clockOffset(of: clock)
        var debugState: WidgetState.Debug?
        if debug != nil || offset != 0 {
            debugState = WidgetState.Debug(
                fixtureTimes: debug?.fixtureTimes ?? false, highLatitude: debug?.highLatitude ?? false, clockOffset: offset
            )
        }
        return WidgetState(
            place: location.place, cityName: location.cityTitle,
            isCurrentLocation: location.isAutomatic && location.place != nil,
            calculation: settings.calculation, showKerahat: settings.showKerahat,
            language: L10n.currentLanguage, debug: debugState
        )
    }

    /// Schreibt den Stand; die Widgets laden neu, wenn er sich geändert hat.
    public func publish() {
        publisher.publish(state)
    }

    /// Uhr der App minus Gerätezeit, auf Millisekunden gerundet – sonst sähe jeder Aufruf einen winzig
    /// anderen Wert, und die Widgets lüden jedes Mal neu. Für die Uhr des Geräts 0.
    nonisolated static func clockOffset(of clock: any AppClock) -> TimeInterval {
        let now = clock.now
        let offset = now.timeIntervalSince(clock.deviceDate(for: now))
        return (offset * 1000).rounded() / 1000
    }
}
