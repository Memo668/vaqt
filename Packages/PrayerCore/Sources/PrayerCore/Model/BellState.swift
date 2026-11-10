/// Stand der Mitteilung für ein Tagesereignis – `S.notif[p]` im Prototyp.
///
/// Die Rohwerte sind die Kennungen des Prototyps. Die Glocke der Gebetskarte wechselt bei jedem
/// Tippen zum nächsten Stand: Ton → Lautlos → Aus → Ton (`BELL_ORDER`).
public enum BellState: String, CaseIterable, Codable, Sendable {
    /// Mitteilung mit Ton.
    case sound
    /// Mitteilung ohne Ton.
    case silent
    /// Keine Mitteilung.
    case off

    /// Der Stand nach dem nächsten Tippen auf die Glocke.
    public var next: BellState {
        switch self {
        case .sound: .silent
        case .silent: .off
        case .off: .sound
        }
    }

    /// Voreinstellung eines Ereignisses wie im Prototyp (`S.notif`): die Gebete mit Ton, Ischa lautlos,
    /// der Sonnenaufgang ohne Mitteilung.
    public static func standard(for prayer: Prayer) -> BellState {
        switch prayer {
        case .fajr, .dhuhr, .asr, .maghrib: .sound
        case .sunrise: .off
        case .isha: .silent
        }
    }
}
