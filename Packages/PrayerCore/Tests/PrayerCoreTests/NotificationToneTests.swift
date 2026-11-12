import Testing
@testable import PrayerCore

/// Der Ton einer Mitteilung folgt der Glocke und dem Klang: „Ton“ spielt den gewählten Klang, „Lautlos“
/// zeigt nur die Mitteilung, „Aus“ heißt keine (`perPrayerFooter` im Prototyp, Plan für Phase 8).
@Suite("Mitteilungen: Ton")
struct NotificationToneTests {

    private func preferences(_ sound: NotificationSound, voice: AdhanVoice = .one) -> NotificationPreferences {
        NotificationPreferences(sound: sound, voice: voice)
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
        #expect(NotificationTone.prayer(.dhuhr, bell: .sound, preferences: preferences(.adhan)) == .clip("adhan-voice1.caf"))
        #expect(NotificationTone.prayer(.dhuhr, bell: .sound, preferences: preferences(.silent)) == .silent)
    }

    @Test("der kurze Adhan ist die Aufnahme der gewählten Stimme; Stimme 3 hat keine und spielt den Systemton")
    func voices() {
        #expect(NotificationTone.prayer(.asr, bell: .sound, preferences: preferences(.adhan, voice: .one)) == .clip("adhan-voice1.caf"))
        #expect(NotificationTone.prayer(.asr, bell: .sound, preferences: preferences(.adhan, voice: .two)) == .clip("adhan-voice2.caf"))
        #expect(NotificationTone.prayer(.asr, bell: .sound, preferences: preferences(.adhan, voice: .three)) == .system)
    }

    @Test("Fadschr spielt den Ausschnitt der Stimme, solange es keine Fadschr-Variante gibt")
    func fajr() {
        #expect(NotificationTone.prayer(.fajr, bell: .sound, preferences: preferences(.adhan, voice: .one)) == .clip("adhan-voice1.caf"))
        #expect(NotificationTone.prayer(.fajr, bell: .sound, preferences: preferences(.adhan, voice: .two)) == .clip("adhan-voice2.caf"))
        #expect(NotificationTone.prayer(.fajr, bell: .sound, preferences: preferences(.adhan, voice: .three)) == .system)
        for voice in AdhanVoice.allCases {
            #expect(voice.clipResource(fajrVariant: true) == nil)
        }
    }

    @Test("der Sonnenaufgang hat keinen Adhan: Systemton, beim Klang „Lautlos“ keiner")
    func sunrise() {
        for voice in AdhanVoice.allCases {
            #expect(NotificationTone.prayer(.sunrise, bell: .sound, preferences: preferences(.adhan, voice: voice)) == .system)
        }
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

    @Test("die Aufnahmen heißen wie die Dateien in App/Sounds")
    func clipResources() {
        #expect(AdhanVoice.one.clipResource(fajrVariant: false) == "adhan-voice1")
        #expect(AdhanVoice.two.clipResource(fajrVariant: false) == "adhan-voice2")
        #expect(AdhanVoice.three.clipResource(fajrVariant: false) == nil)
        #expect(AdhanVoice.clipExtension == "caf")
    }
}
