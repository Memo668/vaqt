/// Regel, nach der Fadschr und Ischa geschätzt werden, wenn es nachts nicht ganz dunkel wird.
///
/// Die Rohwerte sind die Kennungen des Prototyps (`S.hlRule`).
public enum HighLatitudeRule: String, CaseIterable, Codable, Sendable {
    /// Winkelbasiert – Standard.
    case angle
    /// Siebtel der Nacht.
    case seventh
    /// Nachtmitte.
    case middle
    /// Manuelle Winkel: eigene Dämmerungswinkel für Fadschr und Ischa (`CalculationSettings.manualAngles`),
    /// der Nachtanteil Winkel ÷ 60 als Grenze (Spec § 9.12). Sie gelten nur an Tagen, an denen die Sonne
    /// den Winkel der Methode nicht erreicht – sonst rechnet die Methode wie bei „Winkelbasiert“
    /// (entschieden am 15.11.2026, „Nur in hellen Nächten“).
    case manual
}
