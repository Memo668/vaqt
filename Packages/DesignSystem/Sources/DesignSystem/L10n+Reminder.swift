import PrayerCore

extension L10n {

    /// `notifReminderBody` mit der Uhrzeit des Gebets: „Dhuhr beginnt um 11:52 Uhr.“ – im Türkischen trägt die
    /// Uhrzeit die Endung, die zu ihr passt: „Öğle vakti 12:53’te başlıyor.“ (entschieden mit dem Plan für
    /// Phase 11; `T` hat dafür im Türkischen kein festes „’de“ mehr). Für Mitteilungen und den Hinweis der
    /// Live-Aktivität.
    public static func notifReminderBody(p: String, at time: ClockTime) -> String {
        notifReminderBody(p: p, time: reminderTime(time, in: currentLanguage))
    }

    /// Die Uhrzeit, wie sie in `notifReminderBody` steht: „12:53“, im Türkischen „12:53’te“.
    static func reminderTime(_ time: ClockTime, in language: AppLanguage) -> String {
        guard language == .tr else { return time.description }
        return time.description + "’" + TurkishClockSuffix.locative(for: time)
    }
}
