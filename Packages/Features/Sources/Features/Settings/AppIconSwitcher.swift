import PrayerCore
import SwiftUI
import UIKit

/// Was die App zum Wechsel ihres Icons braucht – `UIApplication` erfüllt es (Phase 20, Spec § 13.2). Für Tests und
/// Aufnahmen gibt es Fassungen ohne Wirkung nach außen.
@MainActor
public protocol AlternateIconSetting: AnyObject, Sendable {
    /// Ob das Gerät alternative Icons kann; sonst fehlt der Schalter unter Stil.
    var supportsAlternateIcons: Bool { get }
    /// Das alternative Icon, das gerade gilt; `nil` ist das Haupt-Icon.
    var alternateIconName: String? { get }
    /// Wechselt das Icon. iOS zeigt dazu einen Hinweis, den die App nicht abschalten kann.
    func setAlternateIconName(_ alternateIconName: String?) async throws
}

extension UIApplication: AlternateIconSetting {}

/// Ein Icon ohne Wirkung nach außen: merkt sich nur den Namen. Für Tests, Previews und die Aufnahmen mit
/// `-debugFixtureTimes`, damit sie das Icon auf dem Simulator nicht ändern und kein Hinweis von iOS erscheint.
@MainActor
public final class FixedAlternateIcons: AlternateIconSetting {
    public let supportsAlternateIcons: Bool
    public private(set) var alternateIconName: String?
    /// Jeder Aufruf von `setAlternateIconName`, in der Reihenfolge.
    public private(set) var requests: [String?] = []

    public init(supportsAlternateIcons: Bool = true, alternateIconName: String? = nil) {
        self.supportsAlternateIcons = supportsAlternateIcons
        self.alternateIconName = alternateIconName
    }

    public func setAlternateIconName(_ alternateIconName: String?) async throws {
        requests.append(alternateIconName)
        self.alternateIconName = alternateIconName
    }
}

/// Wohin der Wechsel des Icons geht: ans System oder nur in den Speicher (Tests, Previews, Aufnahmen mit Mock-Zeiten).
/// Die Umgebung trägt nur diese Angabe; das Ziel selbst entsteht auf dem Main Actor (`make()`).
public enum AppIconTarget: Sendable, Equatable {
    case system
    case memory(supportsAlternateIcons: Bool = true)

    @MainActor
    func make() -> any AlternateIconSetting {
        switch self {
        case .system: UIApplication.shared
        case .memory(let supports): FixedAlternateIcons(supportsAlternateIcons: supports)
        }
    }
}

/// Wechselt das App-Icon passend zum Stil (Spec § 13.2): beim Verlassen der Seite Stil und wenn die App in den
/// Hintergrund geht, nicht bei jedem Antippen einer Farbe – iOS zeigt bei jedem Wechsel einen Hinweis, so kommt er
/// einmal. Gerufen wird nur, wenn sich der Name ändert: `nil` (Haupt-Icon) bei Petrol oder ausgeschaltetem
/// Schalter, sonst `AppIcon-<id>`.
@MainActor
public final class AppIconSwitcher {
    private let target: any AlternateIconSetting
    /// Der Name, der gerade gesetzt wird – solange iOS ihn noch nicht meldet; so ruft ein zweiter Anlass während
    /// des Wechsels nicht noch einmal.
    private var pending: String??

    public init(target: any AlternateIconSetting) {
        self.target = target
    }

    /// Ob es den Schalter „App-Icon in der Grundfarbe“ gibt.
    public var isAvailable: Bool {
        target.supportsAlternateIcons
    }

    /// Bringt das Icon auf den Stand des Stils. Gibt zurück, ob die App das Icon gewechselt hat.
    @discardableResult
    public func apply(_ style: AppStyle) async -> Bool {
        guard target.supportsAlternateIcons else { return false }
        let wanted = style.alternateIconName
        let current = pending ?? target.alternateIconName
        guard current != wanted else { return false }
        pending = .some(wanted)
        defer { pending = nil }
        do {
            try await target.setAlternateIconName(wanted)
            return true
        } catch {
            // Etwa im Hintergrund abgelehnt: Beim nächsten Anlass versucht die App es wieder.
            return false
        }
    }
}

/// Bringt das App-Icon auf den Stand des Stils, sobald die App nicht mehr vorn ist (`inactive`, dann `background`) –
/// der zweite Anlass neben dem Verlassen der Seite Stil (Spec § 13.2). Hat sich nichts geändert, ruft sie iOS nicht.
struct AppIconPlanning: View {
    let model: SettingsModel

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Color.clear
            .accessibilityHidden(true)
            .onChange(of: scenePhase) { _, phase in
                guard phase != .active else { return }
                Task { await model.applyAppIcon() }
            }
    }
}
