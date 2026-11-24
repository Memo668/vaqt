import Testing
@testable import PrayerCore

/// Der Ton einer Mitteilung folgt der Glocke und dem Klang: „Ton“ spielt den gewählten Klang, „Lautlos“
/// zeigt nur die Mitteilung, „Aus“ heißt keine (`perPrayerFooter` im Prototyp, Plan für Phase 8).
@Suite("Mitteilungen: Ton")
struct NotificationToneTests {

    private func preferences(_ sound: NotificationSound) -> NotificationPreferences {
        NotificationPreferences(sound: sound)
    }

    @Test("„Aus“ heißt keine Mitteilung und keine Erinnerung", arguments: Prayer.allCases)
    func off(prayer: Prayer) {
        for sound in NotificationSound.allCases {
            #expect(NotificationTone.prayer(prayer, bell: .off, preferences: preferences(sound)) == nil)
            #expect(NotificationTone.reminder(bell: .off, preferences: preferences(sound)) == nil)
        }
    }

    @Test("„Lautlos“ kommt ohne Ton, bei jedem Klang", arguments: Prayer.allCases)
    func silentBell(prayer: Prayer) {
        for sound in NotificationSound.allCases {
            #expect(NotificationTone.prayer(prayer, bell: .silent, preferences: preferences(sound)) == .silent)
            #expect(NotificationTone.reminder(bell: .silent, preferences: preferences(sound)) == .silent)
        }
    }

    @Test("„Ton“ spielt den gewählten Klang: Systemton, kurzer Adhan oder keiner")
    func soundBell() {
        #expect(NotificationTone.prayer(.dhuhr, bell: .sound, preferences: preferences(.system)) == .system)
        #expect(NotificationTone.prayer(.dhuhr, bell: .sound, preferences: preferences(.adhan)) == .clip("adhan.caf"))
        #expect(NotificationTone.prayer(.dhuhr, bell: .sound, preferences: preferences(.silent)) == .silent)
    }

    @Test("der kurze Adhan ist zu allen fünf Gebeten dieselbe Aufnahme, auch zu Fadschr (Spec § 11.2)", arguments: Prayer.five)
    func adhan(prayer: Prayer) {
        #expect(NotificationTone.prayer(prayer, bell: .sound, preferences: preferences(.adhan)) == .clip("adhan.caf"))
    }

    @Test("der Sonnenaufgang hat keinen Adhan: Systemton, beim Klang „Lautlos“ keiner")
    func sunrise() {
        #expect(NotificationTone.prayer(.sunrise, bell: .sound, preferences: preferences(.adhan)) == .system)
        #expect(NotificationTone.prayer(.sunrise, bell: .sound, preferences: preferences(.system)) == .system)
        #expect(NotificationTone.prayer(.sunrise, bell: .sound, preferences: preferences(.silent)) == .silent)
        #expect(NotificationTone.prayer(.sunrise, bell: .silent, preferences: preferences(.adhan)) == .silent)
        #expect(NotificationTone.prayer(.sunrise, bell: .off, preferences: preferences(.adhan)) == nil)
    }

    @Test("die Erinnerung spielt nie den Adhan: Systemton bei „Ton“, keiner beim Klang „Lautlos“")
    func reminder() {
        #expect(NotificationTone.reminder(bell: .sound, preferences: preferences(.adhan)) == .system)
        #expect(NotificationTone.reminder(bell: .sound, preferences: preferences(.system)) == .system)
        #expect(NotificationTone.reminder(bell: .sound, preferences: preferences(.silent)) == .silent)
    }

    @Test("die Aufnahme: Name wie im Prototyp, Datei wie in App/Sounds, 29,5 Sekunden (ADHAN_VOICE)")
    func recording() {
        #expect(AdhanRecording.muezzin == "Ustadh Mmanga Muharram")
        #expect(AdhanRecording.clipResource == "adhan")
        #expect(AdhanRecording.clipExtension == "caf")
        #expect(AdhanRecording.clipFile == "adhan.caf")
        #expect(AdhanRecording.clipDuration == 29.5)
    }
}
