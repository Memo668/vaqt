import Foundation
import Testing
@testable import DesignSystem

/// Silbentrennung mit dem Trennwörterbuch des Systems (Phase 11, „Wörterbuch von iOS“).
@Suite("Silbentrennung")
struct HyphenationTests {

    private let germanLocale = Locale(identifier: "de_DE")

    /// Der Text mit „·“ statt der unsichtbaren weichen Trennstriche.
    private func marked(_ text: String, _ locale: Locale) -> String {
        Hyphenation.softHyphenated(text, locale: locale).replacingOccurrences(of: "\u{AD}", with: "·")
    }

    @Test("Deutsch: Trennstellen wie im Wörterbuch, der Text bleibt sonst gleich")
    func german() {
        #expect(marked("Sonnenaufgang", germanLocale) == "Son·nen·auf·gang")
        #expect(marked("Minutenkorrektur", germanLocale) == "Mi·nu·ten·kor·rek·tur")
        #expect(marked("Standortzugriff aus – Stadt manuell gewählt", germanLocale)
            == "Stand·ort·zu·griff aus – Stadt ma·nu·ell ge·wählt")
    }

    @Test("ohne die weichen Trennstriche ist es derselbe Text", arguments: [
        "Hohe Breitengrade", "Mitteilung für Fadschr: Ton. Tippen zum Ändern.", "Asr", "Rakʿa Fard",
        "„Ton“ spielt den gewählten Klang, „Lautlos“ zeigt nur die Mitteilung.",
    ])
    func unchanged(text: String) {
        let hyphenated = Hyphenation.softHyphenated(text, locale: germanLocale)
        #expect(hyphenated.replacingOccurrences(of: "\u{AD}", with: "") == text)
    }

    @Test("kurze Wörter bleiben ganz")
    func shortWords() {
        #expect(marked("Asr Dhuhr Ischa", germanLocale) == "Asr Dhuhr Ischa")
    }

    @Test("Englisch und Spanisch haben ein Wörterbuch, Türkisch nicht")
    func availability() {
        #expect(Hyphenation.isAvailable(for: Locale(identifier: "en_GB")))
        #expect(Hyphenation.isAvailable(for: Locale(identifier: "es_ES")))
        #expect(!Hyphenation.isAvailable(for: Locale(identifier: "tr_TR")))
        #expect(marked("Bildirimler", Locale(identifier: "tr_TR")) == "Bildirimler")
        #expect(marked("Notificaciones", Locale(identifier: "es_ES")) == "No·ti·fi·ca·cio·nes")
    }
}
