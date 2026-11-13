# App Store – Datenschutz und Angaben zum Upload

Vorbereitet in Phase 11. Eintragen lässt sich das erst in App Store Connect, wenn es das Entwicklerkonto gibt (Schritt „Erste Beta“ in `docs/OPEN-QUESTIONS.md`).

## App-Datenschutz: „Keine Daten erfasst“

In App Store Connect › App › App-Datenschutz gilt für diese App: **„Nein, wir erfassen keine Daten aus dieser App“** (Data Not Collected).

Apple versteht unter „erfassen“, dass Daten das Gerät so verlassen, dass der Anbieter oder seine Partner länger darauf zugreifen können, als es die Antwort auf eine Anfrage in Echtzeit braucht. Die App hat:

- keinen eigenen Server, kein Konto, keine Werbung, keine Analytics und keine Crash-Reporter von Dritten (`CLAUDE.md`);
- als einzigen fremden Code Adhan Swift, das auf dem Gerät rechnet und nichts sendet;
- Netz nur über Apple-Dienste: den Geocoder und die Ortssuche von MapKit.

| Datenart in App Store Connect | Was die App damit tut | Erfasst |
|---|---|---|
| Standort (genau und ungefähr) | Core Location „Beim Verwenden der App“ für Gebetszeiten und Qibla. Der Ort bleibt auf dem Gerät (UserDefaults der App Group). Für den Stadtnamen gehen die Koordinaten an Apples Geocoder (`MKReverseGeocodingRequest`), mit drei Kilometern Genauigkeit. | Nein: Die Koordinaten gehen nur an Apple und nur, um die Anfrage zu beantworten; beim Anbieter kommt nichts an. |
| Suchverlauf | Der Suchtext der Ortssuche geht an `MKLocalSearchCompleter` (Apple). | Nein, aus demselben Grund. |
| Nutzerinhalte und sonstige Daten | Zahlen des Nachholens, Einstellungen, gespeicherte Städte, Glocken | Nein: nur in den UserDefaults auf dem Gerät. |
| Kennungen, Nutzungsdaten, Diagnose, Kontaktdaten, Gesundheit, Finanzen, Käufe | – | Nein: Die App hat nichts davon. |

**Tracking:** nein. Das Manifest sagt `NSPrivacyTracking = false` und nennt keine Tracking-Domains.

**Vor dem Eintragen zu prüfen:** ob Apple die Anfragen an den Geocoder und die Ortssuche von MapKit beim Anbieter als „erfasst“ ansieht. Nach Apples Definition werden Daten, die nur zur Antwort an Apple gehen, nicht beim Anbieter erfasst. Die Seite „Datenschutz“ in der App (`PAGES.privacy`) sagt dasselbe: „Diese App erhebt keine Daten.“

## Datenschutz-Manifest

| Datei | Inhalt |
|---|---|
| `App/PrivacyInfo.xcprivacy` | kein Tracking, keine erfassten Datentypen; UserDefaults mit den Gründen `CA92.1` (eigene Daten der App, das Nachholen) und `1C8F.1` (App Group: Einstellungen, Stand für Widgets und Live-Aktivität) |
| `Widgets/PrivacyInfo.xcprivacy` | dasselbe, nur `1C8F.1`: Die Extension liest den Stand der App aus der App Group |

Beide liegen in den Ressourcen ihres Targets (XcodeGen nimmt sie aus `App/` und `Widgets/`).

Weitere Schnittstellen, für die Apple einen Grund verlangt – Zeitstempel von Dateien, Laufzeit des Systems, freier Speicher, aktive Tastaturen –, nutzt die App nicht (Codesuche in Phase 11). Adhan Swift steht nicht auf Apples Liste der SDKs, die ein eigenes Manifest brauchen.

## Was der erste Upload sonst braucht

Gehört zum Schritt „Erste Beta“, nicht zu Phase 11:

- **Exportkontrolle:** Die App nutzt nur die Verschlüsselung des Systems (HTTPS über MapKit). Mit `ITSAppUsesNonExemptEncryption = NO` in der Info.plist entfällt die Frage bei jedem Upload.
- **Datenschutzerklärung (URL):** Für den App Store Pflicht, für TestFlight mit externen Testern ebenfalls. Der Text der Seite „Datenschutz“ in der App kann die Grundlage sein; eine Adresse gibt es noch nicht.
- **App-Icon:** Für die Beta reicht der Platzhalter (`App/Assets.xcassets/AppIcon.appiconset`, erzeugt von `scripts/app-icon.swift`); das helle Bild hat keinen Alphakanal, wie App Store Connect es verlangt.
