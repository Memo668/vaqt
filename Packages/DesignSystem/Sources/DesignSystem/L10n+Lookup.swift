import Foundation

// `L10n` selbst steht in Generated/L10n.swift und wird von scripts/import-strings erzeugt.
// Hier steht nur, wie die Texte aus dem String Catalog gelesen werden.
extension L10n {

    /// Bundle mit dem String Catalog `Localizable.xcstrings`.
    public static var bundle: Bundle { .module }

    /// Die Sprache, in der die Texte gerade erscheinen – für Datum, Ländernamen und Zahlen, die neben
    /// den Texten stehen.
    ///
    /// Spricht das Gerät die Sprache der Texte, gilt seine Region. Sonst – etwa wenn das Gerät auf
    /// Französisch steht und die App deshalb deutsch erscheint – gilt die Region aus `LOC` im Prototyp.
    public static var locale: Locale {
        locale(language: bundle.preferredLocalizations.first ?? fallbackLanguage, device: .current)
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

    /// Text zum Schlüssel in der Sprache der App.
    static func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Text mit eingesetzten Argumenten.
    ///
    /// Die Reihenfolge der Argumente ist für jeden Schlüssel fest und steht im Katalog als Kommentar.
    /// Wo eine Sprache sie umstellt, benutzt ihr Text `%2$@ … %1$@`.
    static func text(_ key: String, _ arguments: String...) -> String {
        String(format: text(key), arguments: arguments)
    }
}
