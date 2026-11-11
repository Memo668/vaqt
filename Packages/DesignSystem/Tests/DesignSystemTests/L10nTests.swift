import Foundation
import Testing
@testable import DesignSystem

/// Prüft den gebauten String Catalog: Die Texte müssen im Paket-Bundle liegen und in allen
/// vier Sprachen vollständig sein. Ob der Katalog zum Prototyp passt, prüft
/// `scripts/import-strings --check`.
@Suite("String Catalog")
struct L10nTests {

    static let languages = ["de", "tr", "en", "es"]

    /// Das Teil-Bundle einer Sprache – unabhängig von der Sprache des Simulators.
    private func bundle(for language: String) throws -> Bundle {
        let url = try #require(L10n.bundle.url(forResource: language, withExtension: "lproj"), "\(language).lproj fehlt")
        return try #require(Bundle(url: url))
    }

    private func text(_ key: String, in language: String) throws -> String {
        try bundle(for: language).localizedString(forKey: key, value: nil, table: nil)
    }

    @Test("Datum und Zahlen folgen der Sprache der Texte, mit der Region des Geräts, wenn sie passt", arguments: [
        ("de", "de_AT", "de_AT"),
        ("de", "fr_FR", "de_DE"),
        ("tr", "tr_TR", "tr_TR"),
        ("en", "en_US", "en_US"),
        ("en", "de_DE", "en_GB"),
        ("es", "it_IT", "es_ES"),
        ("xx", "it_IT", "de_DE"),
    ])
    func locale(language: String, device: String, expected: String) {
        let locale = L10n.locale(language: language, device: Locale(identifier: device))
        #expect(locale.identifier == expected)
    }

    @Test("die Sprache der Texte ist eine der vier der App")
    func currentLocale() {
        #expect(L10n.regions.keys.sorted() == ["de", "en", "es", "tr"])
        #expect(["de", "tr", "en", "es"].contains(L10n.locale.language.languageCode?.identifier ?? ""))
    }

    @Test("der Katalog hat 262 Schlüssel und keinen doppelt")
    func keyCount() {
        // 260 aus der Design-Übergabe v0.7, dazu `noTimes` (Phase 3) und `noCompass` (Phase 4,
        // docs/OPEN-QUESTIONS.md).
        #expect(L10n.allKeys.count == 262)
        #expect(Set(L10n.allKeys).count == L10n.allKeys.count)
    }

    @Test("jeder Schlüssel hat in jeder Sprache einen Text", arguments: languages)
    func complete(language: String) throws {
        let bundle = try bundle(for: language)
        let marker = "\u{1}fehlt"
        let missing = L10n.allKeys.filter { bundle.localizedString(forKey: $0, value: marker, table: nil) == marker }
        #expect(missing.isEmpty, "\(language): \(missing)")
    }

    @Test("kein Text enthält noch einen Platzhalter in geschweiften Klammern", arguments: languages)
    func noRawPlaceholders(language: String) throws {
        let bundle = try bundle(for: language)
        let leftovers = L10n.allKeys.filter {
            bundle.localizedString(forKey: $0, value: nil, table: nil).contains(/\{[A-Za-z0-9_]+\}/)
        }
        #expect(leftovers.isEmpty, "\(language): \(leftovers)")
    }

    @Test("die Tabs heißen wie im Prototyp", arguments: [
        ("de", ["Gebete", "Verse", "Nachholen"]),
        ("tr", ["Namaz", "Ayetler", "Kaza"]),
        ("en", ["Prayers", "Verses", "Make Up"]),
        ("es", ["Oraciones", "Versículos", "Recuperar"]),
    ])
    func tabTitles(language: String, expected: [String]) throws {
        let actual = try ["navPrayers", "navVerses", "navQada"].map { try text($0, in: language) }
        #expect(actual == expected)
    }

    @Test("der Hinweis für Geräte ohne Kompass steht in allen vier Sprachen", arguments: [
        ("de", "Kein Kompass verfügbar"),
        ("tr", "Pusula kullanılamıyor"),
        ("en", "No compass available"),
        ("es", "Brújula no disponible"),
    ])
    func noCompass(language: String, expected: String) throws {
        #expect(try text("noCompass", in: language) == expected)
    }

    @Test("ein Argument wird eingesetzt")
    func singleArgument() throws {
        #expect(String(format: try text("wIn", in: "de"), "2:01") == "in 2:01")
        #expect(String(format: try text("wIn", in: "tr"), "2:01") == "2:01 sonra")
    }

    @Test("mehrere Argumente behalten ihre Bedeutung, auch wenn eine Sprache sie umstellt")
    func argumentOrder() throws {
        let arguments = ["Asr", "Berlin"]
        #expect(String(format: try text("notifPrayerBody", in: "de"), arguments: arguments) == "Zeit für Asr in Berlin.")
        #expect(String(format: try text("notifPrayerBody", in: "tr"), arguments: arguments) == "Berlin için Asr vakti girdi.")
    }

    @Test("die Himmelsrichtungen stehen einzeln im Katalog")
    func directions() throws {
        let german = try (0..<8).map { try text("dirs.\($0)", in: "de") }
        #expect(german == ["N", "NO", "O", "SO", "S", "SW", "W", "NW"])
        let turkish = try (0..<8).map { try text("dirs.\($0)", in: "tr") }
        #expect(turkish == ["K", "KD", "D", "GD", "G", "GB", "B", "KB"])
    }

    @Test("L10n liest aus dem Katalog statt den Schlüssel zurückzugeben")
    func accessors() {
        #expect(!L10n.navPrayers.isEmpty)
        #expect(L10n.navPrayers != "navPrayers")
        #expect(L10n.dirs.count == 8)
        #expect(!L10n.dirs.contains { $0.hasPrefix("dirs.") })
    }

    @Test("L10n setzt Argumente ein")
    func accessorArguments() {
        #expect(L10n.wIn(t: "2:01").contains("2:01"))
        let body = L10n.notifPrayerBody(p: "Asr", city: "Berlin")
        #expect(body.contains("Asr") && body.contains("Berlin"))
        #expect(!body.contains("%"))
    }
}
