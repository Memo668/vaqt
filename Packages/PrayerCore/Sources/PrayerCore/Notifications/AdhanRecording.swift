/// Die Aufnahme des Adhan – `ADHAN_VOICE` im Prototyp (Spec § 11.2).
///
/// Die App hat genau eine: den Adhan von Ustadh Mmanga Muharram, aufgenommen von DARSA TV (Tansania),
/// CC BY, gekürzt auf die Länge eines Mitteilungstons. Eine Wahl der Stimme und eine eigene Fassung für
/// Fadschr gibt es nicht (entschieden am 24.11.2026). Quelle und Lizenz: docs/THIRD-PARTY.md.
public enum AdhanRecording {

    /// Der Muezzin, Titel im Adhan-Sheet (`ADHAN_VOICE.name`). In allen Sprachen gleich.
    public static let muezzin = "Ustadh Mmanga Muharram"

    /// Name der Datei im Bundle der App, ohne Endung (App/Sounds).
    public static let clipResource = "adhan"

    /// Endung der Datei: IMA4 in CAF, ein Format, das iOS auch für Mitteilungstöne annimmt.
    public static let clipExtension = "caf"

    /// Name der Datei mit Endung, „adhan.caf“ – so nennen ihn Mitteilungen und Wecker gegenüber iOS.
    public static let clipFile = clipResource + "." + clipExtension

    /// Länge der Aufnahme in Sekunden (`ADHAN_VOICE.dur`); der Player zeigt sie als „0:29“. So lange läuft
    /// er stumm, wenn die Datei fehlt.
    public static let clipDuration: Double = 29.5
}
