# Gebetszeiten

Gemeinnützige Gebetszeiten-App für iOS: werbefrei, ohne Tracking, ohne Konto. Die App wird nativ in SwiftUI gebaut, eins zu eins nach dem Prototyp in `design/`.

Die Regeln für die Arbeit stehen in `CLAUDE.md`, der Bauplan in `docs/BUILD-PLAN.md`, offene Punkte in `docs/OPEN-QUESTIONS.md`.

**Stand:** Phase 0 (Projektgerüst), Phase 1 (`PrayerCore`, die Logik ohne UI) und Phase 2 (`DesignSystem`: Tokens und Bausteine) sind fertig. Die App startet weiterhin mit einer leeren `TabView` (Gebete, Verse, Nachholen); die Bildschirme folgen ab Phase 3. Die Bausteine lassen sich schon ansehen: als Previews in Xcode und in der App mit `-debugCatalog`.

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
| `make compare` | Bausteine in den Zuständen der Referenzbilder aufnehmen und neben die Referenz legen |
| `make strings` | String Catalog und `L10n.swift` aus dem Prototyp neu erzeugen |

Simulator für Build, Tests und Abgleich ist das iPhone 18 Pro. Ein anderer lässt sich je Aufruf wählen, z. B. `make test SIM='iPhone 17'`.

Andere Zustände stellt `make run` über Variablen ein:

```bash
make run LANGUAGE=tr ARGS='-debugSkipOnboarding -debugFixtureTimes -debugCity istanbul -debugDate 2026-11-10 -debugTime 16:01'
```

```bash
make screenshot SHOT=screenshots-out/21-home-turkish-istanbul.png
```

Die Befehle dahinter, falls du ohne `make` arbeitest:

```bash
xcodebuild test -project Gebetszeiten.xcodeproj -scheme Gebetszeiten -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

```bash
xcrun simctl launch --terminate-running-process 'iPhone 18 Pro' com.example.gebetszeiten -AppleLanguages '(de)' -AppleLocale de_DE -debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25
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
-debugCatalog arc|rows|glass|cards|all   Katalog der Bausteine statt der App, für den Abgleich
```

Die Sprache kommt über die Systemargumente `-AppleLanguages '(tr)' -AppleLocale tr_TR`. Welche Argumente zu welchem Screenshot gehören, steht in `docs/PROMPTS.md`.

Versteht die App ein Debug-Argument nicht, schreibt sie das beim Start in die Konsole (`Debug-Startargumente: …`). Bisher wirken `-debugTab` (Tab), `-debugDate`, `-debugTime`, `-debugCity`, `-debugHighLatitude` und `-debugLocationDenied` (Uhr und Standortquelle) sowie `-debugCatalog`; die übrigen werden gelesen und greifen, sobald ihre Bildschirme gebaut sind. Für `-debugFixtureTimes` gibt es seit Phase 1 die Quelle `FixtureTimesSource`; eingehängt wird sie mit der Zeiten-Seite in Phase 3.

## Aufbau

```
App/                    App-Target: Einstieg, AccentColor, Info.plist, Entitlements
Widgets/                Widget-Extension für Widgets und Live-Aktivität (bis Phase 9 leer)
Packages/PrayerCore     reine Logik ohne UI, mit Adhan Swift als einziger Fremdabhängigkeit
Packages/DesignSystem   Tokens und Bausteine (ab Phase 2) und der String Catalog
Packages/Features       Bildschirme, AppEnvironment, Debug-Startargumente
scripts/import-strings  erzeugt den String Catalog aus dem Prototyp
scripts/compare-catalog nimmt die Bausteine in den Zuständen der Referenzbilder auf
scripts/compare-shot    legt einen Ausschnitt einer Aufnahme neben die Referenz
project.yml             Beschreibung des Xcode-Projekts für XcodeGen
design/                 Prototyp, Design Spec, Referenz-Screenshots
docs/                   Bauplan, Prompts, offene Fragen
```

## Logik in PrayerCore

| Baustein | Aufgabe |
|---|---|
| `CalculationMethod`, `CalculationSettings` | die elf Methoden aus `METHODS`, automatische Methode je Land, Asr, hohe Breiten, Minutenkorrekturen ±30 |
| `PrayerTimesSource` | Zeiten eines Tages: `AdhanTimesSource` rechnet echt, `FixtureTimesSource` liefert die Mock-Zeiten des Prototyps (nur DEBUG) |
| `PrayerTimeline`, `DayPhase` | Zeitstrahl über drei Tage; laufendes und nächstes Ereignis, Restzeit, Tagesfortschritt, Schlüssel für den Neuaufbau |
| `Kerahat` | die drei Kerahat-Fenster eines Tages |
| `BellState` | Stand der Mitteilung je Ereignis: Ton, Lautlos, Aus |
| `Qibla` | Richtung und Entfernung zur Kaaba, „in Mekka“ |
| `HijriDate` | Datum nach Umm al-Qura und sein Text je Sprache |
| `Guide`, `GuideState`, `GuideSelection` | Daten der Anleitung, gezeigtes Gebet, manuelle Wahl |
| `QadaLedger` | Stand des Nachholens: offen, nachgeholt, Anteil, voraussichtliches Ende |

So kommt eine Seite an die Tagesphase:

```swift
let source: any PrayerTimesSource = AdhanTimesSource()
let timeline = source.timeline(at: clock.now, place: place, settings: settings)
let phase = timeline?.phase(at: clock.now)   // phase?.highlighted, phase?.next, phase?.remaining
```

Die Referenzwerte für die Berechnung liegen unter `Packages/PrayerCore/Tests/PrayerCoreTests/Resources/AdhanTimes/`. Was Phase 1 angenommen hat und was noch eine Entscheidung braucht, steht in `docs/OPEN-QUESTIONS.md`.

## Bausteine im DesignSystem

| Baustein | Aufgabe |
|---|---|
| `Palette`, `Spacing`, `Layout`, `Radius`, `ShadowToken` | Farben hell und dunkel, Abstände, Maße, Radien und Schatten aus dem `:root`-CSS des Prototyps |
| `TypeScale`, `Typography`, `textStyle(_:lineHeight:)` | die Schriftskala als Textstile des Systems, Countdown-Größen, Zeilenhöhen wie `line-height` im CSS |
| `GlassCircleButton`, `GlassChip`, `FloatingBar` | die Glass-Elemente der oberen Leiste, mit echtem Liquid Glass |
| `DayArc`, `DayArcLayout`, `DayArcMetrics` | der Tagesbogen (`ARCS.home`) und seine kleine Variante für die Live-Aktivität (`ARCS.la`) |
| `PrayerRow`, `PrayerRowModel`, `BellButton` | Gebetskarte mit Glocke und Kerahat-Zeile |
| `Card`, `FactTile`, `StepperPill` | Karte, Fakten-Kachel, Stepper |
| `ComponentCatalog` (nur DEBUG) | alle Bausteine zum Ansehen: Previews hell und dunkel, in der App über `-debugCatalog` |

So kommt der Bogen auf eine Seite:

```swift
DayArc(phase: phase, showKerahat: settings.showKerahat) {
    // Zeile „Maghrib in“ und Countdown
}
```

### Abgleich mit den Referenzbildern

Previews lassen sich nicht mit `simctl` aufnehmen. Deshalb zeigt die App mit `-debugCatalog` den Katalog statt der Tabs: `arc` den Bogen und `rows` die Gebetskarten im Zustand der übrigen Debug-Argumente, `glass` und `cards` die übrigen Bausteine, `all` alles untereinander.

```bash
make run ARGS='-debugCatalog arc -debugFixtureTimes -debugCity jakarta -debugDate 2026-11-10 -debugTime 17:57'
```

`make compare` stellt die neun Zustände der Referenzbilder `iphone/10` bis `22` nach und schreibt je Zustand ein Bild nach `screenshots-out/phase-2/`: oben die Referenz, in der Mitte die Aufnahme, unten der Unterschied.

```bash
make compare
```

```bash
make compare STATES='22 20'
```

Einzelne Ausschnitte vergleicht `scripts/compare-shot`; die Optionen stehen im Kopf von `scripts/compare-shot.swift`. Was vom Referenzbild abweicht und warum, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 2“.

## Texte

Alle Texte stehen im Prototyp im Objekt `T` (DE, TR, EN, ES). `scripts/import-strings` erzeugt daraus `Localizable.xcstrings` und `L10n.swift` im Paket `DesignSystem`. Beide Dateien werden nicht von Hand geändert: Text im Prototyp ändern, dann `make strings`. Im Code heißt `t('navPrayers')` aus dem Prototyp `L10n.navPrayers`.

## Bundle-ID und App Group

`com.example.gebetszeiten` und `group.com.example.gebetszeiten` sind Platzhalter. Beide stehen oben in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`) und müssen vor dem ersten Archiv ersetzt werden; ein Entwicklerteam ist noch nicht eingetragen.
