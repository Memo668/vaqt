/// Der Durchlauf „Gebet Schritt für Schritt“ durch ein ganzes Gebet (Design Spec § 9.6) – `walkSteps(p)`
/// und `WALK` im Prototyp.
///
/// Der Ablauf: eine Startseite, das Takbīr der ersten Rakʿa, dann je Rakʿa Stehen, Verbeugung,
/// Aufrichten, Niederwerfung, kurzes Sitzen und zweite Niederwerfung; nach der zweiten Rakʿa eines
/// Gebets mit drei oder vier Rakʿas das erste Sitzen; am Ende das letzte Sitzen, der Friedensgruß und
/// die Seite „Gebet beendet“. Dhuhr hat so 28 Schritte, dazu Start und Ende.
///
/// Die Texte der neuen Schritte (kurzes Sitzen, zweite Niederwerfung, erstes und letztes Sitzen) sind
/// Entwürfe und fachlich so ungeprüft wie die übrige Anleitung (Spec § 6.14).
public struct GuideWalk: Hashable, Sendable {

    /// Art eines Schritts. Die Rohwerte sind die Kennungen `k` aus `walkSteps()` im Prototyp.
    public enum Kind: String, CaseIterable, Sendable {
        /// Startseite: Symbol des Gebets, „{p} · {n} Rakʿas“, Waschung, Qibla und Absicht.
        case intro
        /// Eröffnendes Takbīr, nur in der ersten Rakʿa.
        case takbir
        /// Stehen und Rezitation (Qiyām).
        case qiyam
        /// Verbeugung (Rukūʿ).
        case ruku
        /// Aufrichten (Iʿtidāl).
        case itidal
        /// Erste Niederwerfung (Sudschūd).
        case sujud
        /// Kurzes Sitzen zwischen den Niederwerfungen (Dschalsa).
        case jalsa
        /// Zweite Niederwerfung.
        case sujud2
        /// Erstes Sitzen nach der zweiten Rakʿa, nur bei drei oder vier Rakʿas.
        case tashFirst
        /// Letztes Sitzen am Ende.
        case tashLast
        /// Friedensgruß (Salām).
        case salam
        /// Schlussseite „Gebet beendet“.
        case done

        /// Die Haltungsfigur des Schritts (`WALK[k][0]`). Start und Ende haben keine; dort steht das
        /// Symbol des Gebets bzw. ein Haken.
        public var pose: GuideStep.Pose? {
            switch self {
            case .intro, .done: nil
            case .takbir: .takbir
            case .qiyam: .qiyam
            case .ruku: .ruku
            case .itidal: .itidal
            case .sujud, .sujud2: .sujud
            case .jalsa, .tashFirst, .tashLast: .sit
            case .salam: .salam
            }
        }

        /// Der Schritt der Anleitung, dessen Formel hier gesprochen wird (`WALK[k][3]`): beide
        /// Niederwerfungen die der Niederwerfung, beide Sitzen at-Tahiyyāt. Stehen und kurzes Sitzen
        /// haben keine Formel.
        public var formulaStep: GuideStep.Kind? {
            switch self {
            case .intro, .qiyam, .jalsa, .done: nil
            case .takbir: .takbir
            case .ruku: .ruku
            case .itidal: .itidal
            case .sujud, .sujud2: .sujud
            case .tashFirst, .tashLast: .tash
            case .salam: .salam
            }
        }

        /// Die Formel des Schritts aus `Guide.steps` (`FORMULA`).
        public var formula: GuideStep.Formula? {
            guard let formulaStep else { return nil }
            return Guide.steps.first { $0.kind == formulaStep }?.formula
        }
    }

    /// Ein Schritt des Durchlaufs (ein Eintrag aus `walkSteps()`).
    public struct Step: Hashable, Sendable {
        public let kind: Kind
        /// Die Rakʿa, zu der der Schritt gehört, ab 1 (`r`). Start und Ende gehören zu keiner.
        public let rakah: Int?
        /// Nur beim Stehen: ob die Rakʿa laut rezitiert wird (`loud`).
        public let isAloud: Bool
        /// Nur beim Stehen: ab der dritten Rakʿa nur al-Fātiḥa (`only`), sonst al-Fātiḥa und eine
        /// weitere Sure.
        public let isOnlyFatiha: Bool

        public init(kind: Kind, rakah: Int?, isAloud: Bool = false, isOnlyFatiha: Bool = false) {
            self.kind = kind
            self.rakah = rakah
            self.isAloud = isAloud
            self.isOnlyFatiha = isOnlyFatiha
        }
    }

    /// Das Gebet des Durchlaufs.
    public let prayer: Prayer
    /// Seine Fard-Rakʿas.
    public let rakahs: Rakahs
    /// Alle Seiten in ihrer Folge, mit Start (Index 0) und Ende (letzter Index).
    public let steps: [Step]

    /// Der Durchlauf eines der fünf Gebete; `nil` für den Sonnenaufgang, er ist kein Gebet.
    public init?(prayer: Prayer) {
        guard let rakahs = Guide.rakahs(for: prayer) else { return nil }
        self.init(prayer: prayer, rakahs: rakahs)
    }

    public init(prayer: Prayer, rakahs: Rakahs) {
        self.prayer = prayer
        self.rakahs = rakahs
        var steps = [Step(kind: .intro, rakah: nil)]
        for (index, isAloud) in rakahs.aloud.enumerated() {
            let rakah = index + 1
            if index == 0 {
                steps.append(Step(kind: .takbir, rakah: rakah))
            }
            steps.append(Step(kind: .qiyam, rakah: rakah, isAloud: isAloud, isOnlyFatiha: index >= 2))
            for kind in [Kind.ruku, .itidal, .sujud, .jalsa, .sujud2] {
                steps.append(Step(kind: kind, rakah: rakah))
            }
            if index == 1, rakahs.hasMoreThanTwo {
                steps.append(Step(kind: .tashFirst, rakah: rakah))
            }
        }
        steps.append(Step(kind: .tashLast, rakah: rakahs.count))
        steps.append(Step(kind: .salam, rakah: rakahs.count))
        steps.append(Step(kind: .done, rakah: nil))
        self.steps = steps
    }

    /// Zahl der Schritte ohne Start und Ende (`k`): Fadschr 15, Maghrib 22, Dhuhr 28.
    public var stepCount: Int {
        steps.count - 2
    }

    /// Index der letzten Seite („Gebet beendet“).
    public var lastIndex: Int {
        steps.count - 1
    }

    /// Die Seite an einem Index; außerhalb der Grenzen die nächstliegende.
    public func step(at index: Int) -> Step {
        steps[clamped(index)]
    }

    /// Nummer des Schritts ab 1 für „Schritt {i} von {k}“ (`idx`); Start und Ende zählen nicht mit.
    public func stepNumber(at index: Int) -> Int? {
        let index = clamped(index)
        return index == 0 || index == lastIndex ? nil : index
    }

    /// Fortschritt für den Balken, 0 bis 1 (`pct`): auf der Startseite 0, auf der Schlussseite 1,
    /// dazwischen Schritt ÷ Zahl der Schritte.
    public func progress(at index: Int) -> Double {
        let index = clamped(index)
        if index == 0 { return 0 }
        if index == lastIndex { return 1 }
        return Double(index) / Double(stepCount)
    }

    /// Index der nächsten Seite; auf der letzten bleibt es dabei (`walk-next`).
    public func index(after index: Int) -> Int {
        clamped(index + 1)
    }

    /// Index der vorigen Seite; auf der Startseite bleibt es dabei (`walk-prev`).
    public func index(before index: Int) -> Int {
        clamped(index - 1)
    }

    /// Ob die Seite die letzte ist; ihr Knopf heißt „Fertig“ und schließt den Durchlauf.
    public func isLast(_ index: Int) -> Bool {
        clamped(index) == lastIndex
    }

    /// Ein Index innerhalb der Seiten.
    public func clamped(_ index: Int) -> Int {
        min(max(index, 0), lastIndex)
    }
}
