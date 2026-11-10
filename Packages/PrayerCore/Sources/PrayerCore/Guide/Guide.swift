import Foundation

/// Die Daten der Anleitung – `RAKAH`, `NEXT_OF`, `GUIDE_STEPS` und `FORMULA` im Prototyp.
public enum Guide {

    /// Das Zeitfenster eines Gebets in der Kopfkarte der Anleitung, z. B. 14:00–16:27.
    public struct Window: Hashable, Sendable {
        /// Beginn des Gebets.
        public let start: Date
        /// Beginn des Ereignisses, das die Zeit des Gebets beendet.
        public let end: Date
    }

    /// Die Fard-Rakʿas eines Gebets (`RAKAH`). Der Sonnenaufgang ist kein Gebet und hat keine.
    public static func rakahs(for prayer: Prayer) -> Rakahs? {
        switch prayer {
        case .fajr: Rakahs(aloud: [true, true])
        case .sunrise: nil
        case .dhuhr: Rakahs(aloud: [false, false, false, false])
        case .asr: Rakahs(aloud: [false, false, false, false])
        case .maghrib: Rakahs(aloud: [true, true, false])
        case .isha: Rakahs(aloud: [true, true, false, false])
        }
    }

    /// Das Ereignis, mit dem die Zeit eines Gebets endet (`NEXT_OF`). Fadschr endet mit dem
    /// Sonnenaufgang, Ischa mit Fadschr des Folgetags.
    public static func end(of prayer: Prayer) -> Prayer? {
        switch prayer {
        case .fajr: .sunrise
        case .sunrise: nil
        case .dhuhr: .asr
        case .asr: .maghrib
        case .maghrib: .isha
        case .isha: .fajr
        }
    }

    /// Das Zeitfenster eines Gebets für die Kopfkarte: von seinem Beginn bis zu dem Ereignis, das seine
    /// Zeit beendet.
    ///
    /// Ischa endet mit Fadschr von morgen – so entschieden am 10.11.2026 (docs/OPEN-QUESTIONS.md). Der
    /// Prototyp nimmt Fadschr von heute, was mit echter Rechnung ein bis zwei Minuten danebenliegt.
    /// Läuft vor Fadschr noch Ischa von gestern, ist dieses Ischa gemeint: von gestern Abend bis Fadschr
    /// heute. So endet das Fenster immer dort, wohin auch der Countdown zählt.
    ///
    /// - Returns: `nil` für den Sonnenaufgang; er ist kein Gebet.
    public static func window(of prayer: Prayer, in timeline: PrayerTimeline, at now: Date) -> Window? {
        guard let end = end(of: prayer) else { return nil }
        guard prayer == .isha else {
            return Window(start: timeline.today[prayer], end: timeline.today[end])
        }
        if let current = timeline.phase(at: now)?.current, current.prayer == .isha, current.dayOffset == -1 {
            return Window(start: timeline.yesterday.isha, end: timeline.today.fajr)
        }
        return Window(start: timeline.today.isha, end: timeline.tomorrow.fajr)
    }

    /// Die sieben Schritte des Ablaufs in ihrer Reihenfolge (`GUIDE_STEPS`), jeder mit seiner Formel
    /// (`FORMULA`). Die Formeln stammen Zeichen für Zeichen aus dem Prototyp.
    public static let steps: [GuideStep] = [
        GuideStep(
            kind: .takbir, pose: .takbir,
            formula: GuideStep.Formula(arabic: "اللّٰهُ أَكْبَرُ", transliteration: "Allāhu akbar")
        ),
        GuideStep(kind: .qiyam, pose: .qiyam, formula: nil),
        GuideStep(
            kind: .ruku, pose: .ruku,
            formula: GuideStep.Formula(arabic: "سُبْحَانَ رَبِّيَ الْعَظِيمِ", transliteration: "Subḥāna rabbiya l-ʿaẓīm")
        ),
        GuideStep(
            kind: .itidal, pose: .itidal,
            formula: GuideStep.Formula(arabic: "سَمِعَ اللّٰهُ لِمَنْ حَمِدَهُ · رَبَّنَا لَكَ الْحَمْدُ", transliteration: "Samiʿa llāhu li-man ḥamidah · Rabbanā laka l-ḥamd")
        ),
        GuideStep(
            kind: .sujud, pose: .sujud,
            formula: GuideStep.Formula(arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى", transliteration: "Subḥāna rabbiya l-aʿlā")
        ),
        GuideStep(
            kind: .tash, pose: .sit,
            formula: GuideStep.Formula(arabic: "التَّحِيَّاتُ لِلّٰهِ …", transliteration: "At-taḥiyyātu li-llāh …")
        ),
        GuideStep(
            kind: .salam, pose: .salam,
            formula: GuideStep.Formula(arabic: "السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللّٰهِ", transliteration: "As-salāmu ʿalaikum wa raḥmatu llāh")
        ),
    ]
}
