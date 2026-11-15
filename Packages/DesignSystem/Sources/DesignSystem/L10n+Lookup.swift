import Foundation
import Synchronization

/// Die Sprachen der App – die Schlüssel von `T` und `LANG_NAMES` im Prototyp, in ihrer Reihenfolge (Spec § 9.10).
/// Die zwölf Sprachen ab Französisch sind KI-Entwürfe vom 15.11.2026 (im String Catalog „Needs Review“).
public enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case de
    case tr
    case en
    case es
    case fr
    case nl
    case bs
    case sq
    case ar
    case ur
    case id
    case ms
    case bn
    case fa
    case ru
    case it

    /// Name der Sprache in ihr selbst (`LANG_NAMES`), in jeder Sprache der App gleich.
    public var name: String {
        switch self {
        case .de: "Deutsch"
        case .tr: "Türkçe"
        case .en: "English"
        case .es: "Español"
        case .fr: "Français"
        case .nl: "Nederlands"
        case .bs: "Bosanski"
        case .sq: "Shqip"
        case .ar: "العربية"
        case .ur: "اردو"
        case .id: "Bahasa Indonesia"
        case .ms: "Bahasa Melayu"
        case .bn: "বাংলা"
        case .fa: "فارسی"
        case .ru: "Русский"
        case .it: "Italiano"
        }
    }

    /// Arabisch, Urdu und Persisch laufen von rechts nach links (`RTL_LANGS`).
    public var isRightToLeft: Bool {
        switch self {
        case .ar, .ur, .fa: true
        default: false
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
    /// den Texten stehen, und für die Mehrzahl in den Texten selbst.
    ///
    /// Spricht das Gerät die Sprache der Texte, gilt seine Region, samt ihren Ziffern und ihrem Kalender. Sonst –
    /// etwa wenn das Gerät auf Japanisch steht und die App deshalb deutsch erscheint – gilt die Region aus `LOC`
    /// im Prototyp.
    public static var locale: Locale {
        locale(language: currentLanguage.rawValue, device: .current)
    }

    /// Die Sprachen der App mit ihrer Region wie `LOC` im Prototyp; Arabisch ohne Region wie dort.
    static let regions = [
        "de": "de_DE", "tr": "tr_TR", "en": "en_GB", "es": "es_ES", "fr": "fr_FR", "nl": "nl_NL", "bs": "bs_BA",
        "sq": "sq_AL", "ar": "ar", "ur": "ur_PK", "id": "id_ID", "ms": "ms_MY", "bn": "bn_BD", "fa": "fa_IR",
        "ru": "ru_RU", "it": "it_IT",
    ]
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

    /// Text zum Schlüssel in der Sprache der App, mit den Ziffern ihrer Region (Spec § 9.10).
    static func text(_ key: String) -> String {
        LocalizedDigits.apply(to: textBundle.localizedString(forKey: key, value: nil, table: nil), locale: locale)
    }

    /// Text mit eingesetzten Argumenten: Texte als `String`, Zahlen mit Mehrzahl als `Int`.
    ///
    /// Die Reihenfolge der Argumente ist für jeden Schlüssel fest und steht im Katalog als Kommentar.
    /// Wo eine Sprache sie umstellt, benutzt ihr Text `%2$@ … %1$@`. Geschrieben wird mit der Locale der
    /// Textsprache: Nur mit ihr wählt iOS die richtige Form der Mehrzahl (`PLURAL` im Prototyp) und die Ziffern
    /// der Region; die Ziffern im übrigen Text folgen danach (`LocalizedDigits`).
    static func text(_ key: String, _ arguments: any CVarArg...) -> String {
        text(key, arguments: arguments, bundle: textBundle, locale: locale)
    }

    /// `text(_:_:)` mit Bundle und Locale von außen – für die Tests einer Sprache, ohne die Wahl der App zu ändern.
    static func text(_ key: String, arguments: [any CVarArg], bundle: Bundle, locale: Locale) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return LocalizedDigits.apply(to: String(format: format, locale: locale, arguments: arguments), locale: locale)
    }
}
