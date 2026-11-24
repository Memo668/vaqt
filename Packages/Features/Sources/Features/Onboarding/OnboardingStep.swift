/// Ein Schritt des Onboardings – `S.obStep` im Prototyp (0 bis 4; seit dem Nachtrag zu Phase 18 mit der
/// Rechtsschule als drittem Schritt, Spec § 11.5).
public enum OnboardingStep: Int, CaseIterable, Sendable {
    /// Willkommen (`ob1`).
    case welcome
    /// Vorab-Bildschirm für den Standort (`ob2`).
    case location
    /// „Deine Rechtsschule“ (`obMadhab`): Auswahlmenü, Hanafi vorgewählt.
    case madhab
    /// Vorab-Bildschirm für die Mitteilungen (`ob3`).
    case notifications
    /// „Kostenlos. Ohne Werbung.“ (`ob4`, Spec § 9.9) – vor dem Start in die App.
    case free
}
