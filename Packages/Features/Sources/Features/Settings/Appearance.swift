import DesignSystem
import SwiftUI

/// Erscheinungsbild der App – `S.appearance` im Prototyp (`AP_KEY`): wie das System, immer hell oder
/// immer dunkel (Spec § 5, „Appearance“).
public enum Appearance: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case dark

    /// Name in den Einstellungen.
    public var title: String {
        switch self {
        case .system: L10n.apSystem
        case .light: L10n.apLight
        case .dark: L10n.apDark
        }
    }

    /// Das Farbschema, das die App erzwingt; `nil` folgt dem System.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
