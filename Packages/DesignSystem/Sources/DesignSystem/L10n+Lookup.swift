import Foundation
import Synchronization

/// Die Sprachen der App – die Schlüssel von `T` und `LANG_NAMES` im Prototyp.
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case de
    case tr
    case en
    case es

    /// Name der Sprache in ihr selbst (`LANG_NAMES`), in jeder Sprache der App gleich.
    public var name: String {
        switch self {
        case .de: "Deutsch"
        case .tr: "Türkçe"
        case .en: "English"
        case .es: "Español"
        }
    }
}

// `L10n` selbst steht in Generated/L10n.swift und wird von scripts/import-strings erzeugt.
// Hier steht nur, wie die Texte aus dem String Catalog gelesen werden.
extension L10n {

    /// Bundle mit dem String Catalog `Localizable.xcstrings`.
    public static var bundle: Bundle { .module }

    /// Die in der App gewählte Sprache (Einstellungen › Sprache); `nil` heißt: wie das Gerät. Die Texte
    /// folgen der Wahl sofort; die Seiten bauen sich dafür neu auf.
    ///
    /// Texte des Systems – die Dialoge für Standort und Mitteilungen, das Teilen-Menü – folgen ihr nicht
    /// (entschieden mit dem Plan für Phase 7).
    public static var chosenLanguage: AppLanguage? {
        get { chosen.withLock { $0 } }
        set { chosen.withLock { $0 = newValue } }
    }

    private static let chosen = Mutex<AppLanguage?>(nil)

    /// Die Sprache, die iOS für die App gewählt hat: die erste der Sprachen des Geräts, die die App
    /// spricht, sonst Deutsch.
    public static var systemLanguage: AppLanguage {
        bundle.preferredLocalizations.first.flatMap(AppLanguage.init(rawValue:)) ?? .de
    }

    /// Die Sprache, in der die Texte gerade erscheinen.
    public static var currentLanguage: AppLanguage {
        chosenLanguage ?? systemLanguage
    }

    /// Die Sprache, in der die Texte gerade erscheinen – für Datum, Ländernamen und Zahlen, die neben
    /// den Texten stehen.
    ///
    /// Spricht das Gerät die Sprache der Texte, gilt seine Region. Sonst – etwa wenn das Gerät auf
    /// Französisch steht und die App deshalb deutsch erscheint – gilt die Region aus `LOC` im Prototyp.
    public static var locale: Locale {
        locale(language: currentLanguage.rawValue, device: .current)
    }

    /// Die Sprachen der App mit ihrer Region wie `LOC` im Prototyp.
    static let regions = ["de": "de_DE", "tr": "tr_TR", "en": "en_GB", "es": "es_ES"]
    static let fallbackLanguage = "de"

    static func locale(language: String, device: Locale) -> Locale {
        if device.language.languageCode?.identifier == language {
            return device
        }
        return Locale(identifier: regions[language] ?? regions[fallbackLanguage] ?? fallbackLanguage)
    }

    /// Das Bundle, aus dem die Texte kommen: ohne eigene Wahl das des Pakets – iOS nimmt dann die Sprache
    /// des Geräts –, sonst das Teil-Bundle der gewählten Sprache.
    static var textBundle: Bundle {
        textBundle(for: chosenLanguage)
    }

    /// Das Bundle mit den Texten einer Sprache; ohne Sprache das des Pakets.
    static func textBundle(for language: AppLanguage?) -> Bundle {
        guard let language,
              let url = bundle.url(forResource: language.rawValue, withExtension: "lproj"),
              let localized = Bundle(url: url)
        else { return bundle }
        return localized
    }

    /// Text zum Schlüssel in der Sprache der App.
    static func text(_ key: String) -> String {
        textBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Text mit eingesetzten Argumenten.
    ///
    /// Die Reihenfolge der Argumente ist für jeden Schlüssel fest und steht im Katalog als Kommentar.
    /// Wo eine Sprache sie umstellt, benutzt ihr Text `%2$@ … %1$@`.
    static func text(_ key: String, _ arguments: String...) -> String {
        String(format: text(key), arguments: arguments)
    }
}
