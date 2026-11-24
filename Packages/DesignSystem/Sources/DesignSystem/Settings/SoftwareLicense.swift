import Foundation

/// Fremde Teile der App und ihre Lizenzen – die Seite Einstellungen › Lizenzen (Spec § 9.7).
///
/// Die Lizenztexte und Hinweise liegen unverändert im Bündel (`Resources/Licenses/`) und stehen im
/// englischen Original; Namen von Software, Werken und Lizenzen werden nicht übersetzt. Seit Phase 18
/// stehen hier auch fremde Inhalte: die Adhan-Aufnahme, der arabische Text der Verse und ihre
/// Übersetzungen (Spec § 11). Herkunft, Versionen und Bedingungen: `docs/THIRD-PARTY.md`.
public enum SoftwareLicense: String, CaseIterable, Identifiable, Sendable {
    /// Amiri und Amiri Quran 1.003 (aliftype/amiri), SIL Open Font License 1.1 – Schrift der Verse und
    /// Formeln.
    case amiri
    /// Adhan Swift (batoulapps/adhan-swift), MIT – die Berechnung der Gebetszeiten.
    case adhanSwift
    /// Der Adhan von Ustadh Mmanga Muharram, aufgenommen von DARSA TV, CC BY – der kurze Adhan
    /// (Spec § 11.2).
    case adhanRecording
    /// Tanzil Quran Text, CC BY 3.0 – der arabische Text der Verse (Spec § 11.1).
    case tanzil
    /// Die Übersetzungen der Verse, je Sprache eine, in Auszügen (Spec § 11.1).
    case verseTranslations

    public var id: String { rawValue }

    /// Name des fremden Teils, wie ihn sein Projekt schreibt.
    public var component: String {
        switch self {
        case .amiri: "Amiri, Amiri Quran"
        case .adhanSwift: "Adhan Swift"
        case .adhanRecording: "Adhan: Ustadh Mmanga Muharram"
        case .tanzil: "Tanzil Quran Text"
        case .verseTranslations: "Quran Translations"
        }
    }

    /// Name der Lizenz; bei den Übersetzungen, die keine gemeinsame Lizenz haben, der Titel des Hinweises.
    public var licenseName: String {
        switch self {
        case .amiri: "SIL Open Font License 1.1"
        case .adhanSwift: "MIT License"
        case .adhanRecording: "Creative Commons Attribution (CC BY)"
        case .tanzil: "Creative Commons Attribution 3.0"
        case .verseTranslations: "Translators and sources"
        }
    }

    /// Wofür die App ihn braucht.
    public var localizedPurpose: String {
        switch self {
        case .amiri: L10n.licAmiriSub
        case .adhanSwift: L10n.licAdhanSub
        case .adhanRecording: L10n.licRecordingSub
        case .tanzil: L10n.licTanzilSub
        case .verseTranslations: L10n.licTranslationsSub
        }
    }

    /// Datei des Lizenztexts oder Hinweises im Bündel, ohne Endung `.txt`.
    var fileName: String {
        switch self {
        case .amiri: "Amiri-OFL"
        case .adhanSwift: "AdhanSwift-LICENSE"
        case .adhanRecording: "AdhanRecording-NOTICE"
        case .tanzil: "Tanzil-NOTICE"
        case .verseTranslations: "QuranTranslations-NOTICE"
        }
    }

    /// Der Lizenztext mit Copyright, wie ihn das Projekt mitliefert – oder der Hinweis mit Titel, Urheber,
    /// Quelle, Lizenz und Änderungen.
    public var text: String {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
