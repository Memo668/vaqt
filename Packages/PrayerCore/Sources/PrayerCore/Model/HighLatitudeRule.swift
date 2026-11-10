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
}
