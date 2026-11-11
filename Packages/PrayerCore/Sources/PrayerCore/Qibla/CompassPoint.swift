/// Eine der acht Himmelsrichtungen der Windrose, im Uhrzeigersinn ab Nord – die Reihenfolge von `dirs`
/// im Prototyp. Ihre Abkürzungen stehen im String Catalog.
public enum CompassPoint: Int, CaseIterable, Hashable, Sendable {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest

    /// Jede Richtung deckt 45° ab: 22,5° nach beiden Seiten.
    public static let sector = 45.0

    /// Die Himmelsrichtung zu einem Winkel in Grad ab Nord im Uhrzeigersinn – `dirName()` im Prototyp.
    /// Der Winkel darf negativ sein oder über 360 liegen.
    public init(degrees: Double) {
        let index = Int((Heading.normalized(degrees) / Self.sector).rounded()) % Self.allCases.count
        self = Self.allCases[index]
    }

    /// Die Mitte der Richtung in Grad: 0 für Nord, 45 für Nordost …
    public var degrees: Double {
        Double(rawValue) * Self.sector
    }

    /// Ob die Richtung eine der vier Haupthimmelsrichtungen ist. Sie stehen auf der Skala des Kompasses.
    public var isCardinal: Bool {
        rawValue.isMultiple(of: 2)
    }
}
