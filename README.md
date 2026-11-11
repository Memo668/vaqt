# Gebetszeiten

Gemeinnützige Gebetszeiten-App für iOS: werbefrei, ohne Tracking, ohne Konto. Die App wird nativ in SwiftUI gebaut, eins zu eins nach dem Prototyp in `design/`.

Die Regeln für die Arbeit stehen in `CLAUDE.md`, der Bauplan in `docs/BUILD-PLAN.md`, offene Punkte in `docs/OPEN-QUESTIONS.md`.

**Stand:** Phase 0 (Projektgerüst), Phase 1 (`PrayerCore`, die Logik ohne UI), Phase 2 (`DesignSystem`: Tokens und Bausteine) und Phase 3 (Gebete-Tab: Zeiten) sind fertig. Der Tab „Gebete“ zeigt die obere Leiste mit den Chips Zeiten, Qibla und Anleitung und die Zeiten-Seite: Stadt, Datum, Bogen mit laufendem Countdown, sechs Gebetskarten mit Glocke, Stadt-Sheet. Die Seiten Qibla und Anleitung, die Einstellungen und die Tabs Verse und Nachholen sind noch leer; sie folgen ab Phase 4. Die Bausteine lassen sich als Previews in Xcode ansehen und in der App mit `-debugCatalog`.

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
| `make compare-today` | Zeiten-Seite in den Zuständen der Referenzbilder `iphone/10` bis `22` aufnehmen und neben die Referenz legen |
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

Versteht die App ein Debug-Argument nicht, schreibt sie das beim Start in die Konsole (`Debug-Startargumente: …`). Was die Argumente bewirken:

| Argument | Wirkung |
|---|---|
| `-debugDate`, `-debugTime` | Die Uhr der App beginnt dort und läuft weiter. |
| `-debugFixtureTimes` | Mock-Zeiten statt echter Rechnung. Dazu: festes Netz, keine Ortssuche und flüchtige Einstellungen mit den Startwerten von `S` im Prototyp (Glocken, die fünf Städte) – so sieht jede Aufnahme gleich aus, egal was vorher angetippt wurde. |
| `-debugCity`, `-debugHighLatitude` | feste Standortquelle mit dieser Stadt, Standort erlaubt |
| `-debugLocationDenied` | Standort verweigert: Banner auf der Zeiten-Seite, „Aktueller Standort“ im Stadt-Sheet gesperrt |
| `-debugOffline` | fest „kein Netz“: Hinweis unter dem Datum, im Stadt-Sheet nur gespeicherte Städte |
| `-debugTab` | `verses` und `qada` wählen den Tab; `qibla` und `guide` die Seite im Tab „Gebete“; `settings` öffnet das (noch leere) Ziel der Einstellungen |
| `-debugCatalog` | Katalog der Bausteine statt der App |

`-debugSkipOnboarding` und `-debugQiblaHeading` werden gelesen und greifen, sobald ihre Bildschirme gebaut sind (Phase 7 und Phase 4). Ohne `-debugFixtureTimes` rechnet die App echt und behält ihre Einstellungen; ohne `-debugCity` fragt sie Core Location.

## Aufbau

```
App/                    App-Target: Einstieg, AccentColor, Info.plist, Entitlements
Widgets/                Widget-Extension für Widgets und Live-Aktivität (bis Phase 9 leer)
Packages/PrayerCore     reine Logik ohne UI, mit Adhan Swift als einziger Fremdabhängigkeit
Packages/DesignSystem   Tokens und Bausteine (ab Phase 2) und der String Catalog
Packages/Features       Bildschirme, AppEnvironment, Debug-Startargumente
scripts/import-strings  erzeugt den String Catalog und die Texte der Info.plist aus dem Prototyp
scripts/compare-catalog nimmt die Bausteine in den Zuständen der Referenzbilder auf
scripts/compare-today   nimmt die Zeiten-Seite in den Zuständen der Referenzbilder auf
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
| `ArcCountdown`, `CountdownFormat` | Zeile und Countdown unten im Bogen; der Countdown als Text wie `cdDigital()` und `cdText()` |
| `Toast`, `Banner`, `HintPill`, `NoteCard` | HUD-Toast, Banner mit Aktion, Hinweis-Pille, Hinweiskarte mit Link |
| `GlassSymbol`, `PrayerRugShape` | Symbol eines Chips: SF Symbol oder der Gebetsteppich des Prototyps für „Anleitung“ |
| `ComponentCatalog` (nur DEBUG) | alle Bausteine zum Ansehen: Previews hell und dunkel, in der App über `-debugCatalog` |

So kommt der Bogen auf eine Seite:

```swift
DayArc(phase: phase, showKerahat: settings.showKerahat) {
    // Zeile „Maghrib in“ und Countdown
}
```

## Gebete-Tab in Features

| Baustein | Aufgabe |
|---|---|
| `PrayersTab`, `TopBar`, `PrayersPager`, `PrayersPage` | obere Leiste (Einstellungskreis und drei Chips, `ViewThatFits`) über drei Seiten, die sich wischen lassen; die Einstellungen schieben sich darüber |
| `TodayModel` | Zustand der Zeiten-Seite: welcher Ort gilt, Zeitstrahl, die sechs Karten, Banner und Hinweise, Glocke, Stadtwahl |
| `TodayPage`, `TodayHeader`, `TodayHero` | die Seite; `TodayHero` holt die Tagesphase im Sekundentakt der App-Uhr, die Karten bauen sich nur beim Phasenwechsel neu auf |
| `CitySheet`, `CitySheetModel` | Stadt-Sheet: aktueller Standort, gespeicherte Städte, Ortssuche |
| `SettingsStore` | die Einstellungen in den UserDefaults der App Group: Glocke je Gebet, Standort oder Stadt, gespeicherte Städte, Rechen-Einstellungen, Kerahat-Schalter |
| `CoreLocationSource`, `MapKitPlaceResolver` | aktueller Ort über Core Location („Beim Verwenden der App“), Stadtname über `MKReverseGeocodingRequest` |
| `MapKitCitySearch` | Ortssuche mit `MKLocalSearchCompleter` |
| `NetworkConnectivity` | ob das Gerät ein Netz hat (`NWPathMonitor`) |
| `ToastCenter` | zeigt den Toast über der Tableiste, 1,7 Sekunden |

Alles, was nach außen geht, hängt in `AppEnvironment`: Uhr, Standortquelle, Zeitenquelle, Netz-Zustand, Ortssuche und der Ort der Einstellungen. Views sprechen nie selbst mit `Date()`, `CLLocationManager` oder MapKit.

Ins Netz geht die App nur über Apple-Dienste und nur dafür: die Koordinaten des Standorts an den Geocoder (für den Stadtnamen) und der Suchtext an die Ortssuche. Gerechnet wird auf dem Gerät; ohne Netz gilt der zuletzt bestimmte Ort weiter.

Solange es das Onboarding noch nicht gibt (Phase 7), fragt die Zeiten-Seite beim ersten Start selbst nach dem Standort.

### Abgleich mit den Referenzbildern

Previews lassen sich nicht mit `simctl` aufnehmen. Deshalb zeigt die App mit `-debugCatalog` den Katalog statt der Tabs: `arc` den Bogen und `rows` die Gebetskarten im Zustand der übrigen Debug-Argumente, `glass` und `cards` die übrigen Bausteine, `all` alles untereinander.

```bash
make run ARGS='-debugCatalog arc -debugFixtureTimes -debugCity jakarta -debugDate 2026-11-10 -debugTime 17:57'
```

`make compare` stellt die Zustände der Referenzbilder `iphone/10` bis `22` nach – die neun der Abnahme von Phase 2, dazu hohe Breiten (`18`) und Türkisch (`21`) – und schreibt je Zustand zwei Bilder nach `screenshots-out/phase-2/`, eines für den Bogen und eines für die Gebetskarten: oben die Referenz, in der Mitte die Aufnahme, unten der Unterschied.

```bash
make compare
```

```bash
make compare STATES='22 20'
```

`make compare-today` stellt die Zustände `iphone/10` bis `22` mit der ganzen Zeiten-Seite nach und schreibt je Zustand die Aufnahme (`today-<nr>.png`) und Ausschnitte von Leiste, Kopf, Bogen, Gebetskarten und Banner nach `screenshots-out/phase-3/`. Der Simulator ist 12 pt breiter und 30 pt höher als die Referenzbilder; verglichen werden deshalb Ausschnitte, die Karten in zwei Hälften.

```bash
make compare-today
```

```bash
make compare-today STATES='17 22'
```

`iphone/85` (Stadt-Sheet) entsteht mit den Argumenten von `iphone/10` und einem Tipp auf die Stadt; ein Debug-Argument dafür gibt es nicht.

Einzelne Ausschnitte vergleicht `scripts/compare-shot`; die Optionen stehen im Kopf von `scripts/compare-shot.swift`. Was vom Referenzbild abweicht und warum, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 2“ und „Annahmen in Phase 3“.

## Texte

Alle Texte stehen im Prototyp im Objekt `T` (DE, TR, EN, ES). `scripts/import-strings` erzeugt daraus `Localizable.xcstrings` und `L10n.swift` im Paket `DesignSystem` und `App/InfoPlist.xcstrings`. Die Dateien werden nicht von Hand geändert: Text im Prototyp ändern, dann `make strings`. Im Code heißt `t('navPrayers')` aus dem Prototyp `L10n.navPrayers`.

`App/InfoPlist.xcstrings` enthält die Begründung der Standortabfrage im System-Dialog (`NSLocationWhenInUseUsageDescription`) – der Text `alLocBody` aus `T`. Die Info.plist braucht ihn zusätzlich als Grundwert; der steht in `project.yml`, und `make check-strings` prüft, dass er dem deutschen Text entspricht.

`L10n.locale` nennt die Sprache, in der die Texte gerade erscheinen; mit ihr schreibt die App Datum und Ländernamen.

## Bundle-ID und App Group

`com.example.gebetszeiten` und `group.com.example.gebetszeiten` sind Platzhalter. Beide stehen oben in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`) und müssen vor dem ersten Archiv ersetzt werden; ein Entwicklerteam ist noch nicht eingetragen.
