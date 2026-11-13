import Foundation
import SwiftUI
import Synchronization

/// Silbentrennung – Design Spec § 5 („labels hyphenate/wrap“), im Prototyp `hyphens: auto` auf den Zeilen
/// der Listen (`.row-label`).
///
/// SwiftUI trennt nicht selbst; das SDK hat dafür keine Einstellung. Die App setzt deshalb weiche Trennstriche
/// (U+00AD) an die Stellen, die das Trennwörterbuch des Systems für die Sprache kennt. Bricht eine Zeile dort
/// um, zeichnet SwiftUI einen Bindestrich; sonst bleibt der Trennstrich unsichtbar. Der String Catalog bleibt
/// unverändert. Für Türkisch hat iOS kein Trennwörterbuch; dort bricht SwiftUI nur zwischen Wörtern
/// (entschieden mit dem Plan für Phase 11: „Wörterbuch von iOS“).
public enum Hyphenation {

    /// Weicher Trennstrich.
    public static let softHyphen: Character = "\u{AD}"

    /// Kürzere Wörter bleiben ganz.
    static let minimumWordLength = 6

    /// Der Text mit weichen Trennstrichen an den Trennstellen der Sprache von `locale`; ohne Trennwörterbuch
    /// für die Sprache unverändert.
    public static func softHyphenated(_ text: String, locale: Locale) -> String {
        let key = CacheKey(text: text, locale: locale.identifier)
        if let cached = cache.withLock({ $0[key] }) {
            return cached
        }
        let result = hyphenate(text, locale: locale)
        cache.withLock { cache in
            if cache.count >= cacheLimit { cache.removeAll() }
            cache[key] = result
        }
        return result
    }

    /// Ob das System für die Sprache Trennstellen kennt.
    public static func isAvailable(for locale: Locale) -> Bool {
        CFStringIsHyphenationAvailableForLocale(locale as CFLocale)
    }

    private static func hyphenate(_ text: String, locale: Locale) -> String {
        guard isAvailable(for: locale), text.count >= minimumWordLength else { return text }
        let cfLocale = locale as CFLocale
        let string = text as NSString
        var result = ""
        var copied = 0
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length), options: .byWords
        ) { word, range, _, _ in
            guard let word else { return }
            result += string.substring(with: NSRange(location: copied, length: range.location - copied))
            result += hyphenatedWord(word, locale: cfLocale)
            copied = range.location + range.length
        }
        result += string.substring(from: copied)
        return result
    }

    /// Ein Wort mit weichen Trennstrichen; die Stellen kommen von hinten nach vorn aus dem Wörterbuch.
    private static func hyphenatedWord(_ word: String, locale: CFLocale) -> String {
        let length = (word as NSString).length
        guard word.count >= minimumWordLength else { return word }
        var points: [Int] = []
        var index = length
        while index > 0 {
            let point = CFStringGetHyphenationLocationBeforeIndex(
                word as CFString, index, CFRange(location: 0, length: length), 0, locale, nil
            )
            guard point != kCFNotFound, point > 0, point < index else { break }
            points.append(point)
            index = point
        }
        guard !points.isEmpty else { return word }
        let units = Array(word.utf16)
        var pieces: [String] = []
        var start = length
        for point in points {
            pieces.append(String(decoding: units[point..<start], as: UTF16.self))
            start = point
        }
        pieces.append(String(decoding: units[0..<start], as: UTF16.self))
        return pieces.reversed().joined(separator: String(softHyphen))
    }

    private struct CacheKey: Hashable {
        let text: String
        let locale: String
    }

    private static let cacheLimit = 512
    private static let cache = Mutex<[CacheKey: String]>([:])
}

extension Text {

    /// Ein Text, der an den Trennstellen der Sprache der App umbrechen darf (`Hyphenation`). VoiceOver liest
    /// ihn ohne Trennstriche.
    public init(hyphenating text: String) {
        self = Text(verbatim: Hyphenation.softHyphenated(text, locale: L10n.locale))
            .accessibilityLabel(text)
    }
}
