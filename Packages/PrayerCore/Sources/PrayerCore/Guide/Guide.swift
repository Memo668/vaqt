/// Die Daten der Anleitung – `RAKAH`, `NEXT_OF`, `GUIDE_STEPS` und `FORMULA` im Prototyp.
public enum Guide {

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

    /// Das Ereignis, mit dem die Zeit eines Gebets endet (`NEXT_OF`) – für das Zeitfenster in der
    /// Kopfkarte, z. B. „14:00–16:27“. Fadschr endet mit dem Sonnenaufgang, Ischa mit Fadschr.
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
