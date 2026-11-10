import Foundation

// `L10n` selbst steht in Generated/L10n.swift und wird von scripts/import-strings erzeugt.
// Hier steht nur, wie die Texte aus dem String Catalog gelesen werden.
extension L10n {

    /// Bundle mit dem String Catalog `Localizable.xcstrings`.
    public static var bundle: Bundle { .module }

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
