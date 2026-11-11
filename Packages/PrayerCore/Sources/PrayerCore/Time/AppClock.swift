import Foundation

/// Quelle für „jetzt“.
///
/// Views und Logik lesen die Zeit nur hierüber, nie direkt über `Date()`. So lässt sich jeder
/// Referenz-Screenshot mit `-debugDate` und `-debugTime` nachstellen.
/// (Der Name vermeidet die Verwechslung mit `Swift.Clock`.)
public protocol AppClock: Sendable {
    var now: Date { get }

    /// Der Zeitpunkt der Gerätezeit, zu dem diese Uhr `date` zeigt.
    ///
    /// Das System taktet nach der Gerätezeit (`TimelineView`, `Text(timerInterval:)`). Wer zu einem
    /// Zeitpunkt der App-Uhr etwas anstoßen will – etwa den Sekundentakt des Countdowns –, rechnet ihn
    /// hiermit um. Für die Uhr des Geräts ist es derselbe Zeitpunkt.
    func deviceDate(for date: Date) -> Date
}

extension AppClock {

    /// Ohne eigene Umrechnung läuft die Uhr mit der Gerätezeit.
    public func deviceDate(for date: Date) -> Date { date }

    /// Die nächste volle Sekunde dieser Uhr, als Zeitpunkt der Gerätezeit – der Beginn eines
    /// Sekundentakts, der genau dann schlägt, wenn die App-Uhr auf eine neue Sekunde springt.
    public var nextWholeSecondOnDevice: Date {
        let seconds = now.timeIntervalSinceReferenceDate.rounded(.up)
        return deviceDate(for: Date(timeIntervalSinceReferenceDate: seconds))
    }
}

/// Die echte Uhr des Geräts.
public struct SystemClock: AppClock {
    public init() {}

    public var now: Date { Date() }
}

/// Steht auf einem festen Zeitpunkt – für Tests und Previews.
public struct FixedClock: AppClock {
    public let now: Date

    public init(_ now: Date) {
        self.now = now
    }
}

/// Beginnt bei einem vorgegebenen Zeitpunkt und läuft von dort in Echtzeit weiter.
public struct DebugClock: AppClock {
    /// App-Zeit minus Gerätezeit, in Sekunden.
    public let offset: TimeInterval

    /// - Parameters:
    ///   - start: Zeitpunkt, den die Uhr im Moment des Erzeugens anzeigt.
    ///   - systemNow: Gerätezeit im Moment des Erzeugens.
    public init(startingAt start: Date, systemNow: Date = Date()) {
        offset = start.timeIntervalSince(systemNow)
    }

    public var now: Date { Date().addingTimeInterval(offset) }

    public func deviceDate(for date: Date) -> Date {
        date.addingTimeInterval(-offset)
    }
}
