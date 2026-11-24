import DesignSystem
import SwiftUI

/// Eine Seite im Stapel der Einstellungen – die Kennungen aus `PAGES` im Prototyp.
///
/// Jeder Tab hat seinen eigenen Stapel; der Einstellungskreis legt `settings` darauf, „Regel ändern“ auf
/// der Zeiten-Seite `settings` und `highLatitude`.
public enum SettingsRoute: String, CaseIterable, Hashable, Sendable {
    /// Die Einstellungen selbst (`settings`).
    case settings
    /// Einstellungen › Berechnungsmethode (`method`).
    case method
    /// Einstellungen › Asr (`asr`).
    case asr
    /// Einstellungen › Rechtsschule (`madhab`, Spec § 11.6).
    case madhab
    /// Einstellungen › Hohe Breitengrade (`hl`).
    case highLatitude = "hl"
    /// Einstellungen › Minutenkorrektur (`adjust`).
    case adjustments = "adjust"
    /// Einstellungen › Pro Gebet (`perPrayer`).
    case perPrayer
    /// Einstellungen › Vorab-Erinnerung (`reminder`).
    case reminder
    /// Einstellungen › Live-Aktivität (`live`).
    case liveActivity = "live"
    /// Einstellungen › Wecker zu Fadschr (`alarm`, Spec § 10.8).
    case alarm
    /// Einstellungen › Klang (`sound`).
    case sound
    /// Einstellungen › Erscheinungsbild (`appearance`).
    case appearance
    /// Einstellungen › Stil (`style`, Spec § 11.7): Grundfarbe und Aussehen der Live-Aktivität.
    case style
    /// Einstellungen › Sprache (`language`).
    case language
    /// Einstellungen › Datenschutz (`privacy`).
    case privacy
    /// Einstellungen › Lizenzen (Spec § 9.7) – nur in der App, der Prototyp hat die Seite nicht.
    case licenses
    /// Einstellungen › Unterstützen (`support`, Spec § 9.9).
    case support

    /// Titel der Seite aus dem String Catalog (`PAGE_TITLE`).
    public var title: String {
        switch self {
        case .settings: L10n.settings
        case .method: L10n.methodTitle
        case .asr: L10n.asr
        case .madhab: L10n.madhab
        case .highLatitude: L10n.highLat
        case .adjustments: L10n.adjustments
        case .perPrayer: L10n.perPrayer
        case .reminder: L10n.reminder
        case .liveActivity: L10n.liveAct
        case .alarm: L10n.alarmRow
        case .sound: L10n.sound
        case .appearance: L10n.appearance
        case .style: L10n.style
        case .language: L10n.language
        case .privacy: L10n.privacy
        case .licenses: L10n.licenses
        case .support: L10n.supportTitle
        }
    }

    /// Der Stapel bis zu dieser Seite: die Einstellungen, darüber die Unterseite.
    public var path: [SettingsRoute] {
        self == .settings ? [.settings] : [.settings, self]
    }
}
