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

## TestFlight

Einzutragen in App Store Connect › TestFlight › Testinformationen, auf Deutsch und Englisch (entschieden am 14.11.2026: „Deutsch und Englisch“). Apple nennt für „Was testen“ keine Höchstlänge; nach einem [Beitrag im Entwicklerforum](https://developer.apple.com/forums/thread/810627) erschienen Texte über etwa 2 KB bei den Testern nicht. Alle Texte hier bleiben deshalb unter 1 000 Zeichen.

| Feld | Inhalt |
|---|---|
| Beta-Beschreibung (Beta App Description) | unten, Pflicht |
| Feedback-E-Mail | TODO(placeholder): trägst du ein; sie ist auch die Antwortadresse der Einladungen |
| Marketing-URL | – |
| Datenschutzrichtlinie (URL) | `docs/DATENSCHUTZ.md` und `docs/PRIVACY.md` auf GitHub (oben) |
| Was testen (What to Test) | je Build, unten |
| Beta-App-Prüfung: Kontakt | TODO(placeholder): Name, Telefon und E-Mail für Rückfragen von Apple |
| Beta-App-Prüfung: Anmeldung erforderlich | nein, die App hat kein Konto |
| Beta-App-Prüfung: Hinweise | unten, auf Englisch für Apple |
| Lizenzvereinbarung | die Standardvereinbarung von Apple |
| Exportkontrolle | beantwortet die Info.plist (oben) |

### Beta-Beschreibung

Deutsch:

```text
Gebetszeiten ist eine gemeinnützige App für die fünf täglichen Gebete – werbefrei, ohne Tracking und ohne Konto. Sie rechnet die Zeiten auf dem iPhone, für deinen Standort oder eine gewählte Stadt, und zeigt sie als Tagesbogen mit Countdown. Dazu kommen die Qibla-Richtung mit Kompass, eine Anleitung zu jedem Gebet, ein Vers des Tages und eine Übersicht zum Nachholen. Mitteilungen mit Adhan, Widgets für Home- und Sperrbildschirm und eine Live-Aktivität zum nächsten Gebet sind dabei; auf dem iPhone Duo nutzt die App beide Hälften. Sprachen: Deutsch, Türkisch, Englisch und Spanisch.

Dies ist die erste Beta. Einige Inhalte sind noch Platzhalter: die Übersetzungen der Verse, die Adhan-Aufnahmen und das App-Symbol. Die Texte der Anleitung hat noch niemand fachlich geprüft.
```

Englisch:

```text
Gebetszeiten (Prayer Times) is a non-profit app for the five daily prayers – no ads, no tracking, no account. It calculates the times on your iPhone, for your location or a city you choose, and shows them as a day arc with a countdown. It also has the Qibla direction with a compass, a guide to each prayer, a verse of the day and an overview for making up missed prayers. Notifications with the adhan, widgets for the Home Screen and Lock Screen and a Live Activity for the next prayer are included; on iPhone Duo the app uses both halves. Languages: German, Turkish, English and Spanish.

This is the first beta. Some content is still a placeholder: the verse translations, the adhan recordings and the app icon. Nobody has reviewed the guide texts for religious accuracy yet.
```

### Was testen – Build 0.1.0 (1)

Für jeden weiteren Build anpassen: Was ist neu, was soll geprüft werden?

Deutsch:

```text
Erste Beta. Bitte im Alltag ausprobieren, vor allem:
– Stimmen die Gebetszeiten für deinen Ort? Vergleiche mit deiner Moschee oder deinem Kalender; Methode und Minuten lassen sich in den Einstellungen ändern.
– Kommen die Mitteilungen pünktlich, auch über mehrere Tage, bei gesperrtem iPhone und geschlossener App? Ist der Adhan zu hören?
– Zeigen Widgets und Live-Aktivität (ab 30 Minuten vor jedem Gebet) die richtigen Zeiten?
– Dreht der Qibla-Kompass ruhig und in die richtige Richtung?
– Ist etwas unverständlich, abgeschnitten oder falsch übersetzt?
Bekannt: Verse, Adhan-Aufnahmen und Symbol sind Platzhalter, die Anleitung ist ungeprüft, „Quellcode“ führt noch ins Leere.
Feedback am besten mit Screenshot direkt aus TestFlight.
```

Englisch:

```text
First beta. Please use it in everyday life and check in particular:
– Are the prayer times right for your location? Compare with your mosque or calendar; method and minutes can be changed in Settings.
– Do notifications arrive on time, also over several days, with the iPhone locked and the app closed? Can you hear the adhan?
– Do the widgets and the Live Activity (from 30 minutes before each prayer) show the right times?
– Does the Qibla compass turn smoothly and point the right way?
– Is anything unclear, cut off or mistranslated?
Known: verses, adhan recordings and icon are placeholders, the guide has not been reviewed yet, “Source Code” does not lead anywhere yet.
Feedback ideally with a screenshot straight from TestFlight.
```

### Hinweise für die Beta-App-Prüfung

```text
No account or sign-in is needed. Location access is optional: without it, choose a city in the city sheet that opens on the Prayers tab. Prayer times are calculated on the device with the open-source Adhan library; notifications are local (bell icon next to each prayer). A Live Activity starts 30 minutes before each prayer (Settings › Live Activity). The app has no server and collects no data; it only uses Apple's MapKit for the city name and the city search.
```

## Mit dem Konto: Ablauf bis zum Upload

Was ohne Konto nicht geht, in der Reihenfolge, in der es dran ist. Noch nicht ausprobiert; die Liste steht auch unter „Für die erste Beta“ in `docs/OPEN-QUESTIONS.md`.

1. **Konto und Team:** Apple Developer Program, als Person oder als Organisation (die braucht eine D-U-N-S-Nummer). Die Team-ID kommt nach `DEVELOPMENT_TEAM` in `project.yml`.
2. **Kennungen:** Bundle-ID und App Group festlegen (umgekehrte Domain des Kontoinhabers) und in `project.yml` eintragen (`APP_BUNDLE_ID`, `APP_GROUP_ID`), danach `make project`. Registriert werden die App-ID, die der Extension (`<Bundle-ID>.widgets`) und die App Group beim ersten signierten Build mit automatischer Signatur oder von Hand unter Certificates, Identifiers & Profiles. Als Fähigkeit brauchen beide nur App Groups; Mitteilungen und Live-Aktivität kommen ohne Push aus.
3. **App Store Connect:** die App anlegen – iOS, Name, Primärsprache Deutsch, Bundle-ID, SKU. Der Name muss im Store eindeutig sein; „Gebetszeiten“ ist vermutlich vergeben (auf dem Home-Bildschirm bleibt `CFBundleDisplayName`). Dann App-Datenschutz „Keine Daten erfasst“, die Adressen der Datenschutzerklärung und die Testinformationen von oben.
4. **Signiertes Archiv** und Prüfung, auch der App Group in den Entitlements:

   ```bash
   xcodebuild archive -project Gebetszeiten.xcodeproj -scheme Gebetszeiten -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /Volumes/Extern/Builds/NamazVakti/DerivedData -archivePath /Volumes/Extern/Builds/NamazVakti/Archives/Gebetszeiten-signiert.xcarchive -allowProvisioningUpdates
   ```

   ```bash
   scripts/check-archive /Volumes/Extern/Builds/NamazVakti/Archives/Gebetszeiten-signiert.xcarchive
   ```

5. **Upload:** in Xcode über Organizer › Distribute App › App Store Connect, oder mit `xcodebuild -exportArchive` und einer Export-Liste mit `method` = `app-store-connect` und `destination` = `upload`. Jeder weitere Upload braucht eine höhere Build-Nummer (`CURRENT_PROJECT_VERSION` in `project.yml`).
6. **Testen:** zuerst intern (Mitglieder des Teams, ohne Prüfung durch Apple), dann externe Tester; der erste Build für externe Tester geht durch die Beta-App-Prüfung.
