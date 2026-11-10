# Gebetszeiten

Gemeinnützige Gebetszeiten-App für iOS: werbefrei, ohne Tracking, ohne Konto. Die App wird nativ in SwiftUI gebaut, eins zu eins nach dem Prototyp in `design/`.

Die Regeln für die Arbeit stehen in `CLAUDE.md`, der Bauplan in `docs/BUILD-PLAN.md`, offene Punkte in `docs/OPEN-QUESTIONS.md`.

**Stand:** Phase 0 (Projektgerüst) ist fertig. Die App startet mit einer leeren `TabView` (Gebete, Verse, Nachholen).

## Voraussetzungen

- Xcode 27 mit Swift 6 und einer iOS-Simulator-Runtime (Mindestversion der App ist iOS 26; geprüft wird derzeit mit iOS 27.2)
- XcodeGen: `brew install xcodegen`
- optional die externe Platte „Extern“ – ist sie angesteckt, landen die Build-Daten dort statt auf der internen Platte

## Erste Schritte

Das Xcode-Projekt liegt nicht in Git. Es wird aus `project.yml` erzeugt:

```bash
make project
```

```bash
open Gebetszeiten.xcodeproj
```

## Bauen, testen, starten

`make help` zeigt alle Befehle. Die wichtigsten:

| Befehl | Wirkung |
|---|---|
| `make build` | App für den Simulator bauen |
| `make test` | prüfen, ob die Texte zum Prototyp passen, dann alle Tests im Simulator |
| `make test-core` | nur `PrayerCore`, ohne Simulator |
| `make coverage` | Testabdeckung von `PrayerCore` je Datei |
| `make run` | App im Simulator starten, im Zustand des Haupt-Screenshots `iphone/10` |
| `make statusbar` | Statusleiste wie in den Referenzbildern (14:25, volles Netz, voller Akku) |
| `make screenshot` | Screenshot nach `screenshots-out/screenshot.png` |
| `make strings` | String Catalog und `L10n.swift` aus dem Prototyp neu erzeugen |

Andere Zustände stellt `make run` über Variablen ein:

```bash
make run LANGUAGE=tr ARGS='-debugSkipOnboarding -debugFixtureTimes -debugCity istanbul -debugDate 2026-11-10 -debugTime 16:01'
```

```bash
make screenshot SHOT=screenshots-out/21-home-turkish-istanbul.png
```

Die Befehle dahinter, falls du ohne `make` arbeitest:

```bash
xcodebuild test -project Gebetszeiten.xcodeproj -scheme Gebetszeiten -destination 'platform=iOS Simulator,name=iPhone 17'
```

```bash
xcrun simctl launch --terminate-running-process 'iPhone 17' com.example.gebetszeiten -AppleLanguages '(de)' -AppleLocale de_DE -debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25
```

```bash
xcrun simctl io booted screenshot screenshots-out/screenshot.png
```

## Debug-Startargumente

Nur in DEBUG-Builds. Damit lässt sich jeder Referenz-Screenshot nachstellen:

```
-debugSkipOnboarding
-debugFixtureTimes            Mock-Zeiten aus dem Prototyp statt echter Berechnung; ohne -debugCity gilt Berlin
-debugDate 2026-11-10
-debugTime 14:25              Uhr läuft ab hier weiter, in der Zeitzone der Stadt
-debugCity berlin|istanbul|madrid|mecca|jakarta
-debugHighLatitude            Berlin, 21. Juni 2027
-debugLocationDenied  -debugOffline
-debugTab today|qibla|guide|verses|qada|settings
-debugQiblaHeading 137
```

Die Sprache kommt über die Systemargumente `-AppleLanguages '(tr)' -AppleLocale tr_TR`. Welche Argumente zu welchem Screenshot gehören, steht in `docs/PROMPTS.md`.

Versteht die App ein Debug-Argument nicht, schreibt sie das beim Start in die Konsole (`Debug-Startargumente: …`). In Phase 0 wirken `-debugTab` (Tab), `-debugDate`, `-debugTime`, `-debugCity`, `-debugHighLatitude` und `-debugLocationDenied` (Uhr und Standortquelle); die übrigen werden gelesen und greifen, sobald ihre Bildschirme gebaut sind.

## Aufbau

```
App/                    App-Target: Einstieg, AccentColor, Info.plist, Entitlements
Widgets/                Widget-Extension für Widgets und Live-Aktivität (bis Phase 9 leer)
Packages/PrayerCore     reine Logik ohne UI, mit Adhan Swift als einziger Fremdabhängigkeit
Packages/DesignSystem   Tokens und Bausteine (ab Phase 2) und der String Catalog
Packages/Features       Bildschirme, AppEnvironment, Debug-Startargumente
scripts/import-strings  erzeugt den String Catalog aus dem Prototyp
project.yml             Beschreibung des Xcode-Projekts für XcodeGen
design/                 Prototyp, Design Spec, Referenz-Screenshots
docs/                   Bauplan, Prompts, offene Fragen
```

## Texte

Alle Texte stehen im Prototyp im Objekt `T` (DE, TR, EN, ES). `scripts/import-strings` erzeugt daraus `Localizable.xcstrings` und `L10n.swift` im Paket `DesignSystem`. Beide Dateien werden nicht von Hand geändert: Text im Prototyp ändern, dann `make strings`. Im Code heißt `t('navPrayers')` aus dem Prototyp `L10n.navPrayers`.

## Bundle-ID und App Group

`com.example.gebetszeiten` und `group.com.example.gebetszeiten` sind Platzhalter. Beide stehen oben in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`) und müssen vor dem ersten Archiv ersetzt werden; ein Entwicklerteam ist noch nicht eingetragen.
