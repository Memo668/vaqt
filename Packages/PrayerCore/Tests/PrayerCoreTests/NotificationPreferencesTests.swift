import Foundation
import Testing
@testable import PrayerCore

/// Klang, Erinnerung und Live-Aktivität müssen sich verhalten wie `S`, `REMINDERS`, `LIVE_OPTS` und
/// `SOUND_KEY` im Prototyp.
@Suite("Mitteilungen: Einstellungen")
struct NotificationPreferencesTests {

    @Test("die Kennungen des Klangs sind die des Prototyps, in der Reihenfolge der Seite „Klang“")
    func soundRawValues() {
        #expect(NotificationSound.allCases.map(\.rawValue) == ["system", "adhan", "silent"])
    }

    @Test("die Wahlmöglichkeiten sind REMINDERS und die längere Liste der Live-Aktivität (Plan für Phase 9)")
    func choices() {
        #expect(NotificationPreferences.reminderChoices == [0, 5, 10, 15, 20, 30])
        // Der Prototyp bietet Aus, 30 und 60 (`LIVE_OPTS`); der Nutzer wollte den Vorlauf freier wählen.
        #expect(NotificationPreferences.liveActivityChoices == [0, 10, 15, 20, 30, 45, 60, 90, 120])
    }

    @Test("die Startwerte sind die von S: 10 Min., 30 Min., kurzer Adhan")
    func standard() {
        let preferences = NotificationPreferences()
        #expect(preferences.reminderMinutes == 10)
        #expect(preferences.liveActivityMinutes == 30)
        #expect(preferences.sound == .adhan)
    }

    @Test("Werte außerhalb der Wahlmöglichkeiten gelten als nicht gesetzt", arguments: [7, -5, 25, 1000])
    func invalidValues(minutes: Int) {
        var preferences = NotificationPreferences(reminderMinutes: minutes, liveActivityMinutes: minutes)
        #expect(preferences.reminderMinutes == 10)
        #expect(preferences.liveActivityMinutes == 30)

        preferences.reminderMinutes = 20
        preferences.reminderMinutes = minutes
        #expect(preferences.reminderMinutes == 10)
        preferences.liveActivityMinutes = 60
        preferences.liveActivityMinutes = minutes
        #expect(preferences.liveActivityMinutes == 30)
    }

    @Test("jede Wahlmöglichkeit lässt sich setzen")
    func validValues() {
        for minutes in NotificationPreferences.reminderChoices {
            var preferences = NotificationPreferences()
            preferences.reminderMinutes = minutes
            #expect(preferences.reminderMinutes == minutes)
        }
        for minutes in NotificationPreferences.liveActivityChoices {
            var preferences = NotificationPreferences()
            preferences.liveActivityMinutes = minutes
            #expect(preferences.liveActivityMinutes == minutes)
        }
    }

    @Test("gespeichert wird mit den Kennungen des Prototyps, und es kommt dasselbe zurück")
    func roundTrip() throws {
        let preferences = NotificationPreferences(reminderMinutes: 0, liveActivityMinutes: 60, sound: .system)
        let data = try JSONEncoder().encode(preferences)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["reminder"] as? Int == 0)
        #expect(object["liveAct"] as? Int == 60)
        #expect(object["sound"] as? String == "system")
        #expect(Set(object.keys) == ["reminder", "liveAct", "sound"])
        #expect(try JSONDecoder().decode(NotificationPreferences.self, from: data) == preferences)
    }

    @Test("fehlende oder unpassende gespeicherte Werte ergeben die Startwerte")
    func decodingFallbacks() throws {
        let stored = Data(#"{"reminder": 7, "sound": "trumpet"}"#.utf8)
        let preferences = try JSONDecoder().decode(NotificationPreferences.self, from: stored)
        #expect(preferences == NotificationPreferences())
    }

    @Test("ein Stand aus der Zeit vor Phase 18 mit „voice“ lässt sich lesen; die Stimme wird überlesen (Spec § 11.2)")
    func storedVoice() throws {
        let stored = Data(#"{"reminder": 5, "liveAct": 60, "sound": "system", "voice": 2}"#.utf8)
        let preferences = try JSONDecoder().decode(NotificationPreferences.self, from: stored)
        #expect(preferences == NotificationPreferences(reminderMinutes: 5, liveActivityMinutes: 60, sound: .system))
    }
}
