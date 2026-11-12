# Gebetszeiten

Gemeinnützige Gebetszeiten-App für iOS: werbefrei, ohne Tracking, ohne Konto. Die App wird nativ in SwiftUI gebaut, eins zu eins nach dem Prototyp in `design/`.

Die Regeln für die Arbeit stehen in `CLAUDE.md`, der Bauplan in `docs/BUILD-PLAN.md`, offene Punkte in `docs/OPEN-QUESTIONS.md`.

**Stand:** Phase 0 (Projektgerüst), Phase 1 (`PrayerCore`, die Logik ohne UI), Phase 2 (`DesignSystem`: Tokens und Bausteine), Phase 3 (Gebete-Tab: Zeiten), Phase 4 (Qibla) und Phase 5 (Anleitung) sind fertig. Der Tab „Gebete“ zeigt die obere Leiste mit den Chips Zeiten, Qibla und Anleitung, die Zeiten-Seite – Stadt, Datum, Bogen mit laufendem Countdown, sechs Gebetskarten mit Glocke, Stadt-Sheet –, die Qibla-Seite mit Kompass, Statuszeile, Richtung und Entfernung zur Kaaba und die Anleitung mit der Auswahl der fünf Gebete, der Kopfkarte (Status, Zeitfenster, Fakten, Rakʿa-Folge), „Vorher“ und „Ablauf“ mit Haltungsfiguren und arabischen Formeln. Die Einstellungen und die Tabs Verse und Nachholen sind noch leer; sie folgen ab Phase 6. Die Bausteine lassen sich als Previews in Xcode ansehen und in der App mit `-debugCatalog`.

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
| `make compare-qibla` | Qibla-Seite in den Zuständen der Referenzbilder `iphone/30` bis `32` aufnehmen und neben die Referenz legen |
| `make compare-guide` | Anleitung im Zustand von `iphone/40` aufnehmen und neben die Referenz legen, dazu `41` und `42`, wenn aufgenommen |
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
-debugQiblaAccuracy 40        Genauigkeit des Kompasses in Grad; über 25 erscheint die Kalibrierungskarte
-debugCatalog arc|rows|glass|cards|compass|guide|steps|all   Katalog der Bausteine statt der App, für den Abgleich
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
| `-debugQiblaHeading` | fester Kompasskurs statt des Kompasses des Geräts. Mit `-debugFixtureTimes` gilt ohne Angabe 99°, der Startwert des Prototyps (`S.qibla.heading`) |
| `-debugQiblaAccuracy` | Genauigkeit dieses Kurses in Grad, wie `CLHeading.headingAccuracy` (negativ heißt ungültig). Über 25° erscheint die Karte „Kompass kalibrieren“ – die Referenzbilder zeigen sie immer, die App nur bei ungenauem Kompass |
| `-debugCatalog` | Katalog der Bausteine statt der App |

`-debugSkipOnboarding` wird gelesen und greift, sobald es das Onboarding gibt (Phase 7). Ohne `-debugFixtureTimes` rechnet die App echt und behält ihre Einstellungen; ohne `-debugCity` fragt sie Core Location, ohne festen Kurs den Kompass des Geräts – den hat der Simulator nicht, die Qibla-Seite zeigt dort „Kein Kompass verfügbar“.

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
scripts/compare-qibla   nimmt die Qibla-Seite in den Zuständen der Referenzbilder auf
scripts/compare-guide   nimmt die Anleitung in den Zuständen der Referenzbilder auf
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
| `Qibla` | Richtung und Entfernung zur Kaaba, „in Mekka“, Anzeige in ganzen Grad und auf 10 km gerundet |
| `Heading`, `HeadingSource` | Kompasskurs mit Genauigkeit und Bezug (geografisch oder magnetisch Nord); die Quelle des Kurses, `FixedHeadingSource` für Debug und Tests |
| `CompassPoint`, `QiblaAlignment` | acht Himmelsrichtungen wie `dirName()`; wie das Gerät zur Qibla steht – ausgerichtet bis 3°, sonst links oder rechts und um wie viel |
| `HijriDate` | Datum nach Umm al-Qura und sein Text je Sprache |
| `Guide`, `GuideState`, `GuideSelection`, `Rakahs` | Daten der Anleitung, gezeigtes Gebet, manuelle Wahl und wann sie verfällt, Rakʿa-Folge; ohne Zeiten Fadschr ohne Status |
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
| `Compass`, `CompassLayout`, `CompassMetrics` | der Kompass der Qibla-Seite (`dialSVG()`): Skala, aufrechte Himmelsrichtungen, Nadel, Kaaba-Marke, Peilmarke, Puls beim Ausrichten |
| `CalibrationCard` | die Karte „Kompass kalibrieren“ |
| `SegmentedControl` | Segmente wie `.seg` im Prototyp, mit Punkt unter einem Teil; Tippziel 44 pt |
| `PillButton`, `PillButtonStyle`, `FlowLayout` | Kapsel-Knopf mit Symbol (`.pill-btn`); Reihen, die umbrechen (`flex-wrap`) |
| `SectionHeader`, `CardEyebrow`, `CardFootnote`, `SymbolBadge` | Abschnittsüberschrift, Zeile in Großbuchstaben oben in einer Karte, Fußnote, Symbol im getönten Kreis |
| `GuideHeader`, `GuideHeaderCard`, `RakahSequence` | Auswahl und Kopfkarte der Anleitung: Status, Zeitfenster, Fakten-Kacheln, Rakʿa-Folge, „Zum aktuellen Gebet“ |
| `PoseFigure`, `PoseShape`, `StepCard`, `FormulaBox`, `RepeatNoteCard` | Haltungsfiguren aus `POSE`, Karte eines Schritts, arabische Formel mit Umschrift, gestrichelte Karte |
| `GuideOverview`, `GuideSteps`, `GuidePreparationList`, `GuideStepList` | die beiden Teile der Anleitung (`.col-a`, `.col-b`), „Vorher“ und „Ablauf“ |
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
| `PrayersTab`, `TopBar`, `PrayersPager`, `PrayersPage` | obere Leiste (Einstellungskreis und drei Chips, `ViewThatFits`) über drei Seiten, die sich wischen lassen; die Einstellungen schieben sich darüber. Der Tab bestimmt den Ort und trägt das Stadt-Sheet |
| `PlaceModel` | welcher Ort gilt – aktueller Standort oder gewählte Stadt, Freigabe, Stadtname; Zeiten- und Qibla-Seite teilen es sich |
| `TodayModel` | Zustand der Zeiten-Seite: Zeitstrahl, die sechs Karten, Banner und Hinweise, Glocke, Stadtwahl |
| `TodayPage`, `TodayHeader`, `TodayHero` | die Seite; `TodayHero` holt die Tagesphase im Sekundentakt der App-Uhr, die Karten bauen sich nur beim Phasenwechsel neu auf |
| `CitySheet`, `CitySheetModel` | Stadt-Sheet: aktueller Standort, gespeicherte Städte, Ortssuche |
| `QiblaModel`, `QiblaPage` | Qibla-Seite: Kursanzeige, Kompass, Statuszeile („Nach rechts drehen 39°“, ausgerichtet mit Haptik), Richtung und Entfernung, in Mekka die Meldung, ohne Ort „Stadt wählen“, ohne Kompass „Kein Kompass verfügbar“, Kalibrierungskarte nur bei ungenauem Kompass |
| `GuideModel`, `GuidePage` | Anleitung: öffnet beim aktuellen Gebet, manuelle Wahl bis zum nächsten Gebetswechsel oder bis man die Seite verlässt, „Qibla öffnen“ wechselt zur Qibla-Seite; gleicht sich nur beim nächsten Ereignis ab, nicht im Sekundentakt |
| `SettingsStore` | die Einstellungen in den UserDefaults der App Group: Glocke je Gebet, Standort oder Stadt, gespeicherte Städte, Rechen-Einstellungen, Kerahat-Schalter |
| `CoreLocationSource`, `MapKitPlaceResolver` | aktueller Ort über Core Location („Beim Verwenden der App“), Stadtname über `MKReverseGeocodingRequest` |
| `CoreLocationHeadingSource` | Kompasskurs über Core Location: geografisch Nord, ohne Standortfreigabe magnetisch Nord; läuft nur, solange die Qibla-Seite zu sehen ist |
| `MapKitCitySearch` | Ortssuche mit `MKLocalSearchCompleter` |
| `NetworkConnectivity` | ob das Gerät ein Netz hat (`NWPathMonitor`) |
| `ToastCenter` | zeigt den Toast über der Tableiste, 1,7 Sekunden |

Alles, was nach außen geht, hängt in `AppEnvironment`: Uhr, Standortquelle, Kursquelle, Zeitenquelle, Netz-Zustand, Ortssuche und der Ort der Einstellungen. Views sprechen nie selbst mit `Date()`, `CLLocationManager` oder MapKit.

Ins Netz geht die App nur über Apple-Dienste und nur dafür: die Koordinaten des Standorts an den Geocoder (für den Stadtnamen) und der Suchtext an die Ortssuche. Gerechnet wird auf dem Gerät; ohne Netz gilt der zuletzt bestimmte Ort weiter. Der Kompass braucht kein Netz. Für geografisch Nord bestimmt Core Location nebenbei grob den Standort, solange die Qibla-Seite zu sehen ist; der bleibt auf dem Gerät.

Solange es das Onboarding noch nicht gibt (Phase 7), fragt die Zeiten-Seite beim ersten Start selbst nach dem Standort.

### Abgleich mit den Referenzbildern

Previews lassen sich nicht mit `simctl` aufnehmen. Deshalb zeigt die App mit `-debugCatalog` den Katalog statt der Tabs: `arc` den Bogen, `rows` die Gebetskarten, `compass` den Kompass mit der Kalibrierungskarte und `guide` Auswahl, Kopfkarte und „Vorher“ der Anleitung im Zustand der übrigen Debug-Argumente, `steps` den Ablauf der Anleitung, `glass` und `cards` die übrigen Bausteine, `all` alles untereinander.

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

`make compare-qibla` stellt die Zustände `iphone/30` bis `32` der Qibla-Seite nach – mit festem Kurs, weil der Simulator keinen Kompass hat, und mit `-debugQiblaAccuracy 40`, damit die Kalibrierungskarte erscheint – und schreibt je Zustand die Aufnahme (`qibla-<nr>.png`) und Ausschnitte von Leiste, Kopf, Kompass, Status- und Info-Zeile und Kalibrierungskarte nach `screenshots-out/phase-4/`. Die Karte kommt zusätzlich aus dem Katalog (`-debugCatalog compass`), dort in der Breite der Referenzbilder.

```bash
make compare-qibla
```

`make compare-guide` stellt `iphone/40` nach (Anleitung, 14:25, Asr läuft) und schreibt die Aufnahme (`guide-40.png`) und Ausschnitte von Leiste, Auswahl, Kopfkarte und „Vorher“ nach `screenshots-out/phase-5/`, dazu die Bausteine aus dem Katalog (`-debugCatalog guide` und `steps`) in der Breite der Referenzbilder. `iphone/41` (gescrollt) und `42` (Maghrib angetippt) brauchen Wischen und Tippen; liegen ihre Aufnahmen `guide-41.png` und `guide-42.png` dort, vergleicht das Skript sie mit. Aufgenommen werden sie mit dem UI-Hilfsprojekt (siehe `docs/OPEN-QUESTIONS.md`, „Antippen beim Abgleich“).

```bash
make compare-guide
```

Einzelne Ausschnitte vergleicht `scripts/compare-shot`; die Optionen stehen im Kopf von `scripts/compare-shot.swift`. Was vom Referenzbild abweicht und warum, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 2“ bis „Annahmen in Phase 5“.

## Texte

Alle Texte stehen im Prototyp im Objekt `T` (DE, TR, EN, ES). `scripts/import-strings` erzeugt daraus `Localizable.xcstrings` und `L10n.swift` im Paket `DesignSystem` und `App/InfoPlist.xcstrings`. Die Dateien werden nicht von Hand geändert: Text im Prototyp ändern, dann `make strings`. Im Code heißt `t('navPrayers')` aus dem Prototyp `L10n.navPrayers`.

`App/InfoPlist.xcstrings` enthält die Begründung der Standortabfrage im System-Dialog (`NSLocationWhenInUseUsageDescription`) – der Text `alLocBody` aus `T`. Die Info.plist braucht ihn zusätzlich als Grundwert; der steht in `project.yml`, und `make check-strings` prüft, dass er dem deutschen Text entspricht.

`L10n.locale` nennt die Sprache, in der die Texte gerade erscheinen; mit ihr schreibt die App Datum und Ländernamen.

## Bundle-ID und App Group

`com.example.gebetszeiten` und `group.com.example.gebetszeiten` sind Platzhalter. Beide stehen oben in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`) und müssen vor dem ersten Archiv ersetzt werden; ein Entwicklerteam ist noch nicht eingetragen.
