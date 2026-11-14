# App Store – Datenschutz und Angaben zum Upload

Vorbereitet in Phase 11 und für die erste Beta am 14.11.2026 (ohne Konto). Eintragen lässt sich das erst in App Store Connect, wenn es das Entwicklerkonto gibt („Für die erste Beta“ in `docs/OPEN-QUESTIONS.md`). Den Ablauf bis zum Upload beschreibt der letzte Abschnitt, „Mit dem Konto“.

## App-Datenschutz: „Keine Daten erfasst“

In App Store Connect › App › App-Datenschutz gilt für diese App: **„Nein, wir erfassen keine Daten aus dieser App“** (Data Not Collected).

Apple versteht unter „erfassen“, dass Daten das Gerät so verlassen, dass der Anbieter oder seine Partner länger darauf zugreifen können, als es die Antwort auf eine Anfrage in Echtzeit braucht. Die App hat:

- keinen eigenen Server, kein Konto, keine Werbung, keine Analytics und keine Crash-Reporter von Dritten (`CLAUDE.md`);
- als einzigen fremden Code Adhan Swift, das auf dem Gerät rechnet und nichts sendet;
- Netz nur über Apple-Dienste: den Geocoder und die Ortssuche von MapKit.

| Datenart in App Store Connect | Was die App damit tut | Erfasst |
|---|---|---|
| Standort (genau und ungefähr) | Core Location „Beim Verwenden der App“ für Gebetszeiten und Qibla, angefragt mit drei Kilometern Genauigkeit (iOS kann genauer liefern). Der Ort bleibt auf dem Gerät (UserDefaults der App Group). Für den Stadtnamen gehen die Koordinaten an Apples Geocoder (`MKReverseGeocodingRequest`). | Nein: Die Koordinaten gehen nur an Apple und nur, um die Anfrage zu beantworten; beim Anbieter kommt nichts an. |
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

## Datenschutzerklärung

Für den App Store Pflicht, für TestFlight mit externen Testern ebenfalls. Der Text liegt in `docs/DATENSCHUTZ.md` (Deutsch, maßgeblich) und `docs/PRIVACY.md` (Englisch), geschrieben am 14.11.2026 auf Grundlage der Seite „Datenschutz“ in der App (`PAGES.privacy`) und dieser Datei, genauer gefasst nach dem Code: was auf dem Gerät bleibt, Standort und Ortssuche über MapKit, Mitteilungen, Widgets und Live-Aktivität ohne Server, Teilen und Links, was Apple erhebt, was TestFlight an den Anbieter gibt, die Rechte nach der DSGVO.

- **Adresse:** die beiden Dateien auf GitHub, sobald das Repo öffentlich ist (entschieden am 14.11.2026: „GitHub, beim Quellcode“) – dort, wohin auch „Quellcode“ zeigen soll. In App Store Connect gehört die deutsche Adresse zur deutschen Lokalisierung, die englische zur englischen.
- **Vor dem Veröffentlichen ausfüllen:** den Verantwortlichen (Name, Anschrift, E-Mail) und wie lange die Angaben aus TestFlight aufbewahrt werden; beides steht als `TODO(placeholder)` im Text. Danach den Text prüfen lassen.
- **Genauer als die Seite in der App:** Die Seite „Datenschutz“ sagt wie im Prototyp: „Dein Standort wird nur auf diesem Gerät zur Berechnung verwendet und verlässt es nie.“ Für den Stadtnamen gehen die Koordinaten aber an Apple, ebenso der Suchtext der Ortssuche. Die Erklärung sagt das so; der Text in der App ist eine Frage für den App Store (`docs/OPEN-QUESTIONS.md`, „Vor dem App Store“).

## Exportkontrolle

`ITSAppUsesNonExemptEncryption = NO` steht seit dem 14.11.2026 in der Info.plist der App (`project.yml`). Die App verschlüsselt nicht selbst – keine Kryptografie im Code, auch nicht in Adhan Swift – und geht nur über MapKit ins Netz, mit dem HTTPS des Systems. Damit fragt App Store Connect beim Upload nicht mehr nach der Exportkontrolle.

## Archiv

`make archive` baut das Release-Archiv ohne Signatur und prüft es mit `scripts/check-archive` (README, Abschnitt „App Store“). Stand 14.11.2026: in Ordnung, mit Hinweisen nur auf die Platzhalter (Bundle-ID, App Group, Link „Quellcode“) und die fehlende Signatur. Für die Beta reicht das Platzhalter-Icon (`App/Assets.xcassets/AppIcon.appiconset`, erzeugt von `scripts/app-icon.swift`); das helle Bild hat keinen Alphakanal.

Beim ersten Release-Archiv fiel auf: App und Extension waren als iPhone- und iPad-App gebaut, weil XcodeGen an iOS-Targets „1,2“ setzt. Mit nur Hochformat hätte Apple den Upload abgelehnt (iPad-Multitasking verlangt alle vier Ausrichtungen), und App Store Connect hätte iPad-Bilder verlangt. Seitdem steht „1“ an beiden Targets.
