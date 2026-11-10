/// Ein Schritt im Ablauf des Gebets – ein Eintrag aus `GUIDE_STEPS` mit seiner Formel aus `FORMULA`.
public struct GuideStep: Hashable, Sendable, Identifiable {

    /// Der Schritt. Die Rohwerte sind die Kennungen des Prototyps; die Texte dazu stehen im String
    /// Catalog unter `s_<Kennung>` (Titel) und `s_<Kennung>D` (Beschreibung).
    public enum Kind: String, CaseIterable, Sendable {
        case takbir
        case qiyam
        case ruku
        case itidal
        case sujud
        case tash
        case salam
    }

    /// Die Haltungsfigur zum Schritt. Die Rohwerte sind die Kennungen aus `POSE` im Prototyp.
    public enum Pose: String, CaseIterable, Sendable {
        case takbir
        case qiyam
        case ruku
        case itidal
        case sujud
        case sit
        case salam
    }

    /// Was in dem Schritt gesprochen wird: arabisch und in Umschrift.
    public struct Formula: Hashable, Sendable {
        /// Arabischer Text (`ar`).
        public let arabic: String
        /// Umschrift in lateinischer Schrift (`lat`).
        public let transliteration: String
    }

    public let kind: Kind
    public let pose: Pose
    /// Die Formel des Schritts; das Stehen (`qiyam`) hat keine.
    public let formula: Formula?

    public var id: Kind { kind }

    /// Nach der Niederwerfung steht der Hinweis, die Schritte 2–5 für jede weitere Rakʿa zu wiederholen
    /// (`k === 'sujud'` in `guidePage()`).
    public var isFollowedByRepeatNote: Bool {
        kind == .sujud
    }
}
