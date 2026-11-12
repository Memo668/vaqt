/// Ein Schritt des Onboardings – `S.obStep` im Prototyp (0 bis 2).
public enum OnboardingStep: Int, CaseIterable, Sendable {
    /// Willkommen (`ob1`).
    case welcome
    /// Vorab-Bildschirm für den Standort (`ob2`).
    case location
    /// Vorab-Bildschirm für die Mitteilungen (`ob3`).
    case notifications
}
