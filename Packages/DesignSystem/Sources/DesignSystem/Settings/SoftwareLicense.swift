import Foundation

/// Fremde Teile der App und ihre Lizenzen – die Seite Einstellungen › Lizenzen (Spec § 9.7).
///
/// Die Lizenztexte liegen unverändert im Bündel (`Resources/Licenses/`) und stehen im englischen Original;
/// Namen von Software und Lizenz werden nicht übersetzt. Herkunft und Versionen: `docs/THIRD-PARTY.md`.
public enum SoftwareLicense: String, CaseIterable, Identifiable, Sendable {
    /// Amiri und Amiri Quran 1.003 (aliftype/amiri), SIL Open Font License 1.1 – Schrift der Verse und
    /// Formeln.
    case amiri
    /// Adhan Swift (batoulapps/adhan-swift), MIT – die Berechnung der Gebetszeiten.
    case adhanSwift

    public var id: String { rawValue }

    /// Name des fremden Teils, wie ihn sein Projekt schreibt.
    public var component: String {
        switch self {
        case .amiri: "Amiri, Amiri Quran"
        case .adhanSwift: "Adhan Swift"
        }
    }

    /// Name der Lizenz.
    public var licenseName: String {
        switch self {
        case .amiri: "SIL Open Font License 1.1"
        case .adhanSwift: "MIT License"
        }
    }

    /// Wofür die App ihn braucht.
    public var localizedPurpose: String {
        switch self {
        case .amiri: L10n.licAmiriSub
        case .adhanSwift: L10n.licAdhanSub
        }
    }

    /// Datei des Lizenztexts im Bündel, ohne Endung `.txt`.
    var fileName: String {
        switch self {
        case .amiri: "Amiri-OFL"
        case .adhanSwift: "AdhanSwift-LICENSE"
        }
    }

    /// Der Lizenztext mit Copyright, wie ihn das Projekt mitliefert.
    public var text: String {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
