/// Die Fard-Rakʿas eines Gebets und welche davon laut rezitiert werden – ein Eintrag aus `RAKAH`
/// im Prototyp.
public struct Rakahs: Hashable, Sendable {

    /// Rezitation über das ganze Gebet – die mittlere Fakten-Kachel der Anleitung.
    public enum Recitation: Sendable {
        /// Jede Rakʿa laut (`recAloud`).
        case aloud
        /// Die ersten laut, die übrigen leise (`recMixed`).
        case mixed
        /// Jede Rakʿa leise (`recSilent`).
        case silent
    }

    /// Je Rakʿa: `true`, wenn sie laut rezitiert wird – in der Gemeinschaft, vom Imam (`loud`).
    public let aloud: [Bool]

    public init(aloud: [Bool]) {
        self.aloud = aloud
    }

    /// Zahl der Fard-Rakʿas (`n`).
    public var count: Int {
        aloud.count
    }

    /// Rezitation über das ganze Gebet.
    public var recitation: Recitation {
        if aloud.allSatisfy({ $0 }) { return .aloud }
        return aloud.contains(true) ? .mixed : .silent
    }

    /// Ob das Gebet mehr als zwei Rakʿas hat. Dann wird nach der zweiten gesessen, und ab der dritten
    /// wird nur al-Fātiḥa rezitiert (`r.n > 2`).
    public var hasMoreThanTwo: Bool {
        count > 2
    }
}
