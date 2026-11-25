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
| Feedback-E-Mail | die Adresse aus der Datenschutzerklärung (eingetragen am 16.11.2026); sie ist auch die Antwortadresse der Einladungen |
| Marketing-URL | – |
| Datenschutzrichtlinie (URL) | `docs/DATENSCHUTZ.md` und `docs/PRIVACY.md` auf GitHub (oben) |
| Was testen (What to Test) | je Build, unten |
| Beta-App-Prüfung: Kontakt | Name, Telefon und E-Mail für Rückfragen von Apple, eingetragen am 16.11.2026 (die Telefonnummer steht nur in App Store Connect) |
| Beta-App-Prüfung: Anmeldung erforderlich | nein, die App hat kein Konto |
| Beta-App-Prüfung: Hinweise | unten, auf Englisch für Apple |
| Lizenzvereinbarung | die Standardvereinbarung von Apple |
| Exportkontrolle | beantwortet die Info.plist (oben) |

### Beta-Beschreibung

Deutsch:

```text
Vaqt ist eine gemeinnützige App für die fünf täglichen Gebete – werbefrei, ohne Tracking und ohne Konto. Sie rechnet die Zeiten auf dem iPhone, für deinen Standort oder eine gewählte Stadt, und zeigt sie als Tagesbogen mit Countdown. Dazu kommen die Qibla-Richtung mit Kompass, eine Anleitung zu jedem Gebet, ein Vers des Tages und eine Übersicht zum Nachholen. Mitteilungen mit Adhan, Widgets für Home- und Sperrbildschirm und eine Live-Aktivität zum nächsten Gebet sind dabei; auf dem iPhone Duo nutzt die App beide Hälften. Sprachen: Deutsch, Türkisch, Englisch, Spanisch, Französisch, Niederländisch, Bosnisch, Albanisch, Arabisch, Urdu, Indonesisch, Malaiisch, Bengali, Persisch, Russisch und Italienisch.

Dies ist die erste Beta. Einige Inhalte sind noch Platzhalter: die Übersetzungen der Verse, die Adhan-Aufnahmen und das App-Symbol. Die Texte der Anleitung hat noch niemand fachlich geprüft, und die Sprachen ab Französisch sind Entwürfe, die noch Muttersprachler durchsehen.
```

Englisch:

```text
Vaqt is a non-profit app for the five daily prayers – no ads, no tracking, no account. It calculates the times on your iPhone, for your location or a city you choose, and shows them as a day arc with a countdown. It also has the Qibla direction with a compass, a guide to each prayer, a verse of the day and an overview for making up missed prayers. Notifications with the adhan, widgets for the Home Screen and Lock Screen and a Live Activity for the next prayer are included; on iPhone Duo the app uses both halves. Languages: German, Turkish, English, Spanish, French, Dutch, Bosnian, Albanian, Arabic, Urdu, Indonesian, Malay, Bengali, Persian, Russian and Italian.

This is the first beta. Some content is still a placeholder: the verse translations, the adhan recordings and the app icon. Nobody has reviewed the guide texts for religious accuracy yet, and the languages from French on are drafts that native speakers have yet to review.
```

### Was testen – Build 0.1.0 (5)

Neu seit Build 4 (Phase 18, Spec § 11). Für jeden weiteren Build anpassen: Was ist neu, was soll geprüft werden?

Deutsch:

```text
Neu in Build 5:
– Verse: statt Platzhalter ein wörtlicher Ausschnitt einer veröffentlichten Übersetzung in deiner Sprache (Name darunter).
– Adhan: eine echte Aufnahme (Ustadh Mmanga Muharram, DARSA TV, CC BY) für Mitteilungen, Wecker und „Adhan anhören“, ohne Wahl der Stimme. Quellen: Einstellungen › Über › Lizenzen.
– Stil (Einstellungen › Stil): 24 Grundfarben, sechs Varianten der Live-Aktivität.
– Rechtsschule (Einstellungen › Berechnung, auch im Onboarding): Hanafi, Schafii, Hanbali oder Maliki bestimmen die Verbotszeiten.
– Onboarding: auch durch Wischen. Bei „Systemton“ steht jetzt, wo man den Ton wählt.
Bitte besonders prüfen: Klingt der Adhan gut, und endet der Ausschnitt (30 Sekunden) passend? Stimmen die Verbotszeiten für deine Rechtsschule? Sind Farben und Live-Aktivität auf deinem Hintergrundbild lesbar? Sind die Verse in deiner Sprache verständlich?
In Build 3 und 4 dazugekommen: Wecker zu Fadschr, Verbotszeiten mit Erklärung, durchscheinende Live-Aktivität, Nachholen für Mann oder Frau.

Außerdem im Alltag prüfen:
– Stimmen die Gebetszeiten für deinen Ort (Vergleich mit Moschee oder Kalender; Methode und Minuten in den Einstellungen)?
– Kommen Mitteilungen und Wecker pünktlich, auch bei gesperrtem iPhone, im Stummmodus und bei Fokus?
– Stimmen Widgets und Live-Aktivität (ab 30 Minuten vor jedem Gebet)?
– Zeigt der Qibla-Kompass ruhig in die richtige Richtung?
– Unverständlich, abgeschnitten oder falsch übersetzt? Arabisch, Urdu und Persisch laufen von rechts nach links.
Bekannt: Symbol ist ein Platzhalter; Anleitung und Verbotszeiten-Texte fachlich ungeprüft; Sprachen ab Französisch sind Entwürfe; Vers-Ausschnitte noch von niemandem mit Muttersprache gelesen; der Adhan hat keine Fadschr-Fassung.
Feedback am besten mit Screenshot direkt aus TestFlight.
```

Englisch:

```text
New in build 5:
– Verses: instead of placeholders, a literal excerpt of a published translation in your language (name below it).
– Adhan: a real recording (Ustadh Mmanga Muharram, DARSA TV, CC BY) for notifications, the alarm and "Preview Adhan", with no choice of voice. Sources: Settings › About › Licences.
– Style (Settings › Style): 24 accent colors, six variants of the Live Activity.
– Madhhab (Settings › Calculation, also in onboarding): Hanafi, Shafi‘i, Hanbali or Maliki set the makruh times.
– Onboarding: you can also swipe. With "System Sound" a note now says where to choose the tone.
Please check in particular: Does the adhan sound good, and does the excerpt (30 seconds) end in a fitting place? Are the makruh times right for your madhhab? Are colors and the Live Activity readable on your wallpaper? Are the verses understandable in your language?
Added in builds 3 and 4: Fajr alarm, makruh times with an explanation, translucent Live Activity, make-up prayers for men or women.

Also check in everyday life:
– Are the prayer times right for your location (compare with your mosque or calendar; method and minutes in Settings)?
– Do notifications and the alarm arrive on time, also with the iPhone locked, in silent mode and with a Focus on?
– Are widgets and Live Activity (from 30 minutes before each prayer) right?
– Does the Qibla compass point the right way, without jitter?
– Anything unclear, cut off or mistranslated? Arabic, Urdu and Persian run right to left.
Known: the icon is a placeholder; the guide and the makruh texts are not reviewed for religious accuracy yet; the languages from French on are drafts; nobody who speaks the language has read the verse excerpts yet; the adhan has no Fajr version.
Feedback ideally with a screenshot straight from TestFlight.
```

### Hinweise für die Beta-App-Prüfung

```text
No account or sign-in is needed. Location access is optional: without it, choose a city in the city sheet that opens on the Prayers tab. Prayer times are calculated on the device with the open-source Adhan library; notifications are local (bell icon next to each prayer). A Live Activity starts 30 minutes before each prayer (Settings › Live Activity). The app has no server and collects no data; it only uses Apple's MapKit for the city name and the city search.
```

## Mit dem Konto: Ablauf bis zum Upload

Was ohne Konto nicht geht, in der Reihenfolge, in der es dran ist. Durchlaufen am 16.11.2026 bis zum Upload von 0.1.0 (1) und zur internen Gruppe „Intern“; die Liste steht auch unter „Für die erste Beta“ in `docs/OPEN-QUESTIONS.md`.

1. **Konto und Team (erledigt am 15.11.2026):** Apple Developer Program als Einzelperson, Team `V7652FBKMY` in `DEVELOPMENT_TEAM` (`project.yml`).
2. **Kennungen (eingetragen am 15.11.2026):** `de.mehmetyilmaz.gebetszeiten`, `.widgets` und `group.de.mehmetyilmaz.gebetszeiten` in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`), danach `make project`. Registriert werden die App-ID, die der Extension (`<Bundle-ID>.widgets`) und die App Group beim ersten signierten Build mit automatischer Signatur oder von Hand unter Certificates, Identifiers & Profiles. Als Fähigkeit brauchen beide nur App Groups; Mitteilungen und Live-Aktivität kommen ohne Push aus.
3. **App Store Connect:** die App anlegen – iOS, Name „Vaqt – Prayer Time“ (Arbeitsname, entschieden am 15.11.2026, Spec § 9.13; „Vaqt“ allein ist vergeben, auf dem Home-Bildschirm steht `CFBundleDisplayName` „Vaqt“; den endgültigen Namen vorher noch einmal festlegen, `docs/OPEN-QUESTIONS.md`), Primärsprache Deutsch, Bundle-ID, SKU. Dann App-Datenschutz „Keine Daten erfasst“, die Adressen der Datenschutzerklärung und die Testinformationen von oben.
4. **Signiertes Archiv** und Prüfung, auch der App Group in den Entitlements:

   ```bash
   xcodebuild archive -project Gebetszeiten.xcodeproj -scheme Gebetszeiten -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /Volumes/Extern/Builds/NamazVakti/DerivedData -archivePath /Volumes/Extern/Builds/NamazVakti/Archives/Gebetszeiten-signiert.xcarchive -allowProvisioningUpdates
   ```

   ```bash
   scripts/check-archive /Volumes/Extern/Builds/NamazVakti/Archives/Gebetszeiten-signiert.xcarchive
   ```

5. **Upload:** in Xcode über Organizer › Distribute App › App Store Connect, oder mit `xcodebuild -exportArchive` und einer Export-Liste mit `method` = `app-store-connect` und `destination` = `upload`. Jeder weitere Upload braucht eine höhere Build-Nummer (`CURRENT_PROJECT_VERSION` in `project.yml`).

   **Stolperstein (16.11.2026):** Nach der Hochstufung des persönlichen Teams scheiterte der Upload mit „Failed to Use Accounts – App Store Connect access for "V7652FBKMY" is required“, auch über den Organizer. Xcode hatte das Team noch als kostenloses „Personal Team“ gespeichert (`defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier`). Ein Neustart von Xcode half nicht. Erst Abmelden und neu Anmelden unter Xcode › Einstellungen › Apple Accounts hat es behoben, danach stand dort `teamType = Individual`. Am 25.11.2026 kam derselbe Fehler noch einmal, bei Build 5: Die Kontenliste von Xcode war leer (`defaults read com.apple.dt.Xcode DVTDeveloperAccountManagerAppleIDLists` ohne Eintrag unter `IDE.Identifiers.Prod`), das Team stand richtig als `Individual` da. Wieder half nur die Anmeldung unter Xcode › Einstellungen › Apple Accounts, die der Nutzer selbst macht; danach lief derselbe Export durch.

   ```bash
   xcodebuild -exportArchive -archivePath /Volumes/Extern/Builds/NamazVakti/Archives/Vaqt-0.1.0-1.xcarchive -exportOptionsPlist ExportOptions-upload.plist -exportPath /Volumes/Extern/Builds/NamazVakti/Export/Vaqt-0.1.0-1 -allowProvisioningUpdates
   ```

   Die Export-Liste: `method` = `app-store-connect`, `destination` = `upload`, `teamID` = `V7652FBKMY`, `signingStyle` = `automatic`, `uploadSymbols` = ja, `manageAppVersionAndBuildNumber` = nein.
6. **Testen:** zuerst intern (Mitglieder des Teams, ohne Prüfung durch Apple), dann externe Tester; der erste Build für externe Tester geht durch die Beta-App-Prüfung.
