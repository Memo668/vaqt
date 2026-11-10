/// Rechenmethode für Fadschr und Ischa – ein Eintrag aus `METHODS` im Prototyp.
///
/// Die Rohwerte sind die Kennungen des Prototyps (`S.method`). Die Fälle stehen in der Reihenfolge,
/// in der die Einstellungen sie auflisten.
public enum CalculationMethod: String, CaseIterable, Codable, Sendable, Identifiable {
    case mwl
    case isna
    case egyptian
    case ummAlQura = "ummalqura"
    case karachi
    case diyanet
    case jakim
    case kemenag
    case singapore
    case tehran
    case moonsighting

    /// Wie eine Methode Ischa bestimmt.
    public enum Isha: Hashable, Sendable {
        /// Sonnenstand unter dem Horizont in Grad (`i`).
        case angle(Double)
        /// Feste Zahl von Minuten nach Maghrib (`iMin`).
        case minutesAfterMaghrib(Int)
    }

    public var id: String { rawValue }

    /// Kurzname, z. B. „MWL“ (`short`).
    public var shortName: String {
        switch self {
        case .mwl: "MWL"
        case .isna: "ISNA"
        case .egyptian: "Egyptian"
        case .ummAlQura: "Umm al-Qura"
        case .karachi: "Karachi"
        case .diyanet: "Diyanet"
        case .jakim: "JAKIM"
        case .kemenag: "Kemenag"
        case .singapore: "Singapore"
        case .tehran: "Tehran"
        case .moonsighting: "Moonsighting"
        }
    }

    /// Voller Name (`name`). Eigennamen der Stellen; sie werden nicht übersetzt.
    public var name: String {
        switch self {
        case .mwl: "Muslim World League"
        case .isna: "Islamic Society of North America"
        case .egyptian: "Egyptian General Authority of Survey"
        case .ummAlQura: "Umm al-Qura University, Makkah"
        case .karachi: "University of Islamic Sciences, Karachi"
        case .diyanet: "Diyanet İşleri Başkanlığı (Türkiye)"
        case .jakim: "JAKIM (Malaysia)"
        case .kemenag: "Kemenag (Indonesia)"
        case .singapore: "MUIS (Singapore)"
        case .tehran: "Institute of Geophysics, Tehran"
        case .moonsighting: "Moonsighting Committee Worldwide"
        }
    }

    /// Sonnenstand unter dem Horizont, bei dem Fadschr beginnt, in Grad (`f`).
    public var fajrAngle: Double {
        switch self {
        case .mwl, .karachi, .diyanet, .moonsighting: 18
        case .isna: 15
        case .egyptian: 19.5
        case .ummAlQura: 18.5
        case .jakim, .kemenag, .singapore: 20
        case .tehran: 17.7
        }
    }

    /// Ischa: ein Winkel (`i`) oder Minuten nach Maghrib (`iMin`).
    public var isha: Isha {
        switch self {
        case .mwl, .diyanet: .angle(17)
        case .isna: .angle(15)
        case .egyptian: .angle(17.5)
        case .ummAlQura: .minutesAfterMaghrib(90)
        case .karachi, .jakim, .kemenag, .singapore, .moonsighting: .angle(18)
        case .tehran: .angle(14)
        }
    }

    /// Die Methode passt Fadschr und Ischa an die Jahreszeit an (`seasonal`).
    public var isSeasonal: Bool {
        self == .moonsighting
    }

    /// Die Methode, die ohne eigene Wahl für ein Land gilt (`S.method == null`).
    ///
    /// DE → MWL, TR → Diyanet, ES → MWL, SA → Umm al-Qura, ID → Kemenag (Spec § 5). Für alle
    /// anderen Länder und ohne Land gilt MWL (docs/OPEN-QUESTIONS.md, Punkt 3).
    ///
    /// - Parameter countryCode: ISO-3166-1-Code mit zwei Buchstaben; Groß- und Kleinschreibung zählt nicht.
    public static func automatic(forCountryCode countryCode: String?) -> CalculationMethod {
        switch countryCode?.uppercased() {
        case "TR": .diyanet
        case "SA": .ummAlQura
        case "ID": .kemenag
        default: .mwl
        }
    }
}
