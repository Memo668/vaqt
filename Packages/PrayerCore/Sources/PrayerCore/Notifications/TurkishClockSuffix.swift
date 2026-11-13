/// Die Endung des Lokativs hinter einer Uhrzeit im Türkischen: „15:36’da“, „12:53’te“, „14:00’te“ – für die
/// Vorab-Erinnerung „Öğle vakti 12:53’te başlıyor.“ (`notifReminderBody`, entschieden mit dem Plan für
/// Phase 11: „Endung berechnen“).
///
/// Die Endung hängt am letzten Zahlwort, so wie man die Uhrzeit spricht: bei vollen Stunden an der Stunde
/// („on dört“ → 14:00’te), sonst an den Minuten („otuz altı“ → 15:36’da, „elli üç“ → 12:53’te). Der Vokal
/// folgt der Vokalharmonie (a, ı, o, u → a; e, i, ö, ü → e), der Anlaut wird nach einem stimmlosen Laut zu
/// „t“ (ç, f, h, k, p, s, ş, t).
public enum TurkishClockSuffix {

    /// „da“, „de“, „ta“ oder „te“ – ohne Apostroph.
    public static func locative(for time: ClockTime) -> String {
        locative(afterNumber: time.minute == 0 ? time.hour : time.minute)
    }

    /// Die Endung nach einer Zahl von 0 bis 59, wie sie gesprochen wird: Es zählt das letzte Zahlwort –
    /// die Einer, bei vollen Zehnern die Zehner, bei 0 „sıfır“.
    static func locative(afterNumber number: Int) -> String {
        let ones = number % 10
        let tens = number / 10
        let word: Word
        if ones != 0 {
            word = onesWords[ones]
        } else if tens != 0 {
            word = tensWords[tens]
        } else {
            word = Word(frontVowel: false, voicelessEnd: false) // sıfır
        }
        return (word.voicelessEnd ? "t" : "d") + (word.frontVowel ? "e" : "a")
    }

    /// Was am Ende eines Zahlworts für die Endung zählt: der letzte Vokal (vorn: e, i, ö, ü) und ob es auf
    /// einen stimmlosen Laut endet.
    struct Word {
        let frontVowel: Bool
        let voicelessEnd: Bool
    }

    /// 1 bir, 2 iki, 3 üç, 4 dört, 5 beş, 6 altı, 7 yedi, 8 sekiz, 9 dokuz (Index 0 bleibt frei).
    static let onesWords: [Word] = [
        Word(frontVowel: false, voicelessEnd: false),
        Word(frontVowel: true, voicelessEnd: false), // bir
        Word(frontVowel: true, voicelessEnd: false), // iki
        Word(frontVowel: true, voicelessEnd: true), // üç
        Word(frontVowel: true, voicelessEnd: true), // dört
        Word(frontVowel: true, voicelessEnd: true), // beş
        Word(frontVowel: false, voicelessEnd: false), // altı
        Word(frontVowel: true, voicelessEnd: false), // yedi
        Word(frontVowel: true, voicelessEnd: false), // sekiz
        Word(frontVowel: false, voicelessEnd: false), // dokuz
    ]

    /// 10 on, 20 yirmi, 30 otuz, 40 kırk, 50 elli (Index 0 bleibt frei).
    static let tensWords: [Word] = [
        Word(frontVowel: false, voicelessEnd: false),
        Word(frontVowel: false, voicelessEnd: false), // on
        Word(frontVowel: true, voicelessEnd: false), // yirmi
        Word(frontVowel: false, voicelessEnd: false), // otuz
        Word(frontVowel: false, voicelessEnd: true), // kırk
        Word(frontVowel: true, voicelessEnd: false), // elli
    ]
}
