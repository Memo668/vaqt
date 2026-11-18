# Vaqt

Gemeinnützige Gebetszeiten-App für iOS: werbefrei, ohne Tracking, ohne Konto. Die App wird nativ in SwiftUI gebaut, eins zu eins nach dem Prototyp in `design/`.

Unter dem Symbol und in der App heißt sie seit dem 15.11.2026 **„Vaqt“** (Arbeitsname, in allen Sprachen gleich; im App Store „Vaqt – Prayer Time“, Spec § 9.13). Bundle-ID, App Group, Targets, Schema, Ordner und Typen heißen weiter „Gebetszeiten“ – Nutzer sehen sie nicht.

Die Regeln für die Arbeit stehen in `CLAUDE.md`, der Bauplan in `docs/BUILD-PLAN.md`, offene Punkte in `docs/OPEN-QUESTIONS.md`.

**Stand:** Phase 0 (Projektgerüst), Phase 1 (`PrayerCore`, die Logik ohne UI), Phase 2 (`DesignSystem`: Tokens und Bausteine), Phase 3 (Gebete-Tab: Zeiten), Phase 4 (Qibla), Phase 5 (Anleitung), Phase 6 (Verse und Nachholen), Phase 7 (Einstellungen, Onboarding, Adhan), Phase 8 (Mitteilungen), Phase 9 (Widgets und Live-Aktivität), Phase 10 (iPhone Duo) und Phase 11 (Feinschliff: Sprachen, große Schrift, Barrierefreiheit, Leistung, App Store) sind fertig. Der Tab „Gebete“ zeigt die obere Leiste mit den Chips Zeiten, Qibla und Anleitung, die Zeiten-Seite – Stadt, Datum, Bogen mit laufendem Countdown, sechs Gebetskarten mit Glocke, Stadt-Sheet –, die Qibla-Seite mit Kompass, Statuszeile, Richtung und Entfernung zur Kaaba und die Anleitung mit der Auswahl der fünf Gebete, der Kopfkarte (Status, Zeitfenster, Fakten, Rakʿa-Folge), „Vorher“ und „Ablauf“ mit Haltungsfiguren und arabischen Formeln. Der Tab „Verse“ zeigt den Vers des Tages auf Arabisch mit Übersetzung (Platzhalter) und Quelle, Teilen und Kopieren und die letzten Tage; der Tab „Nachholen“ den Anteil nachgeholt, je Gebet einen Stepper, den Plan pro Tag mit voraussichtlichem Ende und den Rechner für einen verpassten Zeitraum. Der Einstellungskreis jedes Tabs öffnet die Einstellungen mit allen Unterseiten – Standort, Berechnung, Mitteilungen, Darstellung samt Sprache, Über –; Änderungen wirken sofort in der ganzen App. Beim ersten Start führt das Onboarding in drei Schritten zu Standort und Mitteilungen. „Adhan anhören“ öffnet den Player mit Wellenform und drei Stimmen (Platzhalter). Die App plant lokale Mitteilungen zu jedem Gebet nach seiner Glocke, dazu die Vorab-Erinnerung, im rollierenden Fenster der nächsten 64 und neu nach jeder Änderung. Das Widget gibt es in fünf Größen – klein und mittel auf dem Home-Bildschirm, rund, als Rechteck und als Zeile auf dem Sperrbildschirm –, dazu die Live-Aktivität zu jedem Gebet auf dem Sperrbildschirm und in der Dynamic Island. Auf dem iPhone Duo zeigt die App außen die iPhone-Seiten neben der senkrechten Leiste des Systems und innen quer zwei Spalten, die sich am Falz treffen; Einstellungen stehen innen als mittige Spalte, Sheets als mittige Karte, hochkant und in der Tischhaltung passen sich die Seiten an. Die Bausteine lassen sich als Previews in Xcode ansehen und in der App mit `-debugCatalog`.

Die erste Beta über TestFlight ist ohne Entwicklerkonto vorbereitet: `make archive` baut und prüft das Release-Archiv, die Datenschutzerklärung liegt in `docs/DATENSCHUTZ.md` und `docs/PRIVACY.md`, die Texte für TestFlight und der Ablauf mit Konto stehen in `docs/APP-STORE.md`. Was noch fehlt, steht in `docs/OPEN-QUESTIONS.md` unter „Für die erste Beta“.

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
| `make compare-today` | Zeiten-Seite in den Zuständen der Referenzbilder `iphone/10` bis `23` aufnehmen und neben die Referenz legen |
| `make compare-qibla` | Qibla-Seite in den Zuständen der Referenzbilder `iphone/30` bis `34` aufnehmen und neben die Referenz legen |
| `make compare-guide` | Anleitung im Zustand von `iphone/40` aufnehmen und neben die Referenz legen, dazu `41` und `42`, wenn aufgenommen |
| `make compare-walk` | „Gebet Schritt für Schritt“ in den Zuständen von `iphone/43`–`49` aufnehmen und neben die Referenz legen (`STATES='47 49-dark'` für einzelne) |
| `make compare-verses` | Verse in den Zuständen von `iphone/50` (hell) und `51` (dunkel) aufnehmen und neben die Referenz legen |
| `make compare-qada` | Nachholen im Zustand von `iphone/60` aufnehmen und neben die Referenz legen, dazu `61`, wenn aufgenommen |
| `make compare-settings` | Einstellungen, Onboarding und Adhan-Sheet in den Zuständen von `iphone/01`–`03`, `05`, `70`, `73`–`81`, `83` und `86` aufnehmen und neben die Referenz legen, dazu `71`, `72` und `82`, wenn aufgenommen |
| `make compare-system` | Widgets und Live-Aktivität im Katalog in den Zuständen von `system/90`, `91` und `93`–`96` aufnehmen und neben die Referenz legen |
| `make compare-language` | eine Sprache gegen den Prototyp in derselben Sprache: 20 Zustände (Onboarding, Zeiten, Qibla, Anleitung, Durchlauf, Verse, Nachholen, Einstellungen, Widgets, Live-Aktivität) aus dem Prototyp und der App nebeneinander (`LANGUAGE=ar STATES='10 43'`, `REGION=ar_SA` für eine andere Region; Phase 15) |
| `make compare-duo` | auf dem Simulator „iPhone Duo“ die Zustände von `duo/open-*` (`MODE=open`, aufgeklappt und quer) oder `duo/closed-*` (`MODE=closed`) aufnehmen und neben die Referenz legen; auf- und zuklappen in Device Hub |
| `make harness` | Skripte des UI-Hilfsprojekts ausführen, das antippt, wischt und aufnimmt (`SCRIPTS='scripts/ui-harness/scripts/iphone-61-qada.txt'`) – für Zustände mit Tipp |
| `make capture` | jeden Bildschirm ganz aufnehmen, in allen 16 Sprachen, Schriftgrößen, hell und dunkel, RTL, mit der Prüfung der Bedienungshilfen von Xcode und einem Kontaktbogen (`VARIANTS='de tr-ax5 ar fa-dark de-rtl'`) |
| `make strings` | String Catalog und `L10n.swift` aus dem Prototyp neu erzeugen |
| `make archive` | Release-Archiv für das iPhone ohne Signatur bauen und mit `scripts/check-archive` prüfen (Abschnitt „App Store“) |

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
xcrun simctl launch --terminate-running-process 'iPhone 18 Pro' "$(scripts/bundle-id)" -AppleLanguages '(de)' -AppleLocale de_DE -debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25
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
          method|asr|hl|adjust|perPrayer|reminder|live|sound|appearance|language|privacy|licenses|support|adhan|city
-debugOnboarding 1|2|3|4      Onboarding ab diesem Schritt, auch wenn es schon durchlaufen ist
-debugDayOffset 1             Zeiten-Seite zeigt einen anderen Tag, −365 bis 365
-debugWalk dhuhr              „Gebet Schritt für Schritt“ für dieses Gebet offen, über der Anleitung
-debugWalkStep 9              Seite des Durchlaufs wie S.walk.i im Prototyp: 0 = Start, die letzte = „Gebet beendet“
-debugQiblaHeading 137
-debugQiblaAccuracy 40        Genauigkeit des Kompasses in Grad; über 25 erscheint die Kalibrierungskarte
-debugNotifications           echte Mitteilungen auch mit Mock-Zeiten; fragt beim Start nach der Erlaubnis
-debugLiveActivity            Live-Aktivität zum nächsten Gebet sofort, auch außerhalb des Vorlaufs und mit Mock-Zeiten
-debugAlarm before|fixed|denied   Wecker zu Fadschr an oder Erlaubnis abgelehnt, nur mit -debugFixtureTimes
-debugAlarmIn 2               ein echter Wecker (AlarmKit) so viele Minuten nach dem Start
-debugCatalog arc|rows|glass|cards|compass|guide|steps|verses|qada|settings|onboarding|adhan|widgets|live|all   Katalog der Bausteine statt der App, für den Abgleich
```

Die Sprache kommt über die Systemargumente `-AppleLanguages '(tr)' -AppleLocale tr_TR` – für jede der 16 Sprachen mit der Region aus `LOC` im Prototyp (`make run LANGUAGE=ar`; Arabisch, Urdu und Persisch laufen dann von rechts nach links). Welche Argumente zu welchem Screenshot gehören, steht in `docs/PROMPTS.md`.

Versteht die App ein Debug-Argument nicht, schreibt sie das beim Start in die Konsole (`Debug-Startargumente: …`). Was die Argumente bewirken:

| Argument | Wirkung |
|---|---|
| `-debugDate`, `-debugTime` | Die Uhr der App beginnt dort und läuft weiter. |
| `-debugFixtureTimes` | Mock-Zeiten statt echter Rechnung. Dazu: festes Netz, keine Ortssuche und flüchtige Einstellungen mit den Startwerten von `S` im Prototyp (Glocken, die fünf Städte, Erinnerung, Klang, Sprache wie das Gerät) – so sieht jede Aufnahme gleich aus, egal was vorher angetippt wurde. Das Nachholen zeigt die Zahlen des Prototyps (`iphone/60`), ebenfalls nur im Speicher. Die Methode „Automatisch“ ist die der Fixture-Stadt (Berlin → MWL). Mitteilungen gelten als noch nicht erfragt, und vorgemerkt wird keine. |
| `-debugNotifications` | Erlaubnis und Mitteilungen über das System, auch mit `-debugFixtureTimes`: Die App merkt die Mitteilungen zu den Mock-Zeiten bei iOS vor, gemessen an der Debug-Uhr. Beim Start räumt sie zugestellte Mitteilungen ab und fragt nach der Erlaubnis, falls iOS noch nie gefragt hat. Damit lässt sich `system/92` nachstellen. |
| `-debugLiveActivity` | Genau eine Live-Aktivität: die zum nächsten Gebet, ab dem Start der App – auch außerhalb des Vorlaufs, auch bei „Aus“ und mit `-debugFixtureTimes`. Damit lassen sich `system/93`–`96` mit denselben Zahlen nachstellen. Mit `-debugFixtureTimes`, aber ohne dieses Argument, plant die App keine Live-Aktivität und beendet, was noch läuft. Die Widgets bekommen Mock-Zeiten und Debug-Uhr in DEBUG immer über die App Group. |
| `-debugAlarm` | Wecker zu Fadschr im Speicher: `before` an, 45 Min. vor Sonnenaufgang, Systemton; `fixed` an, feste Uhrzeit 05:30, kurzer Adhan; `denied` Erlaubnis abgelehnt. Ohne Dialog des Systems und ohne echte Wecker, nur mit `-debugFixtureTimes` (`iphone/24`, `iphone/84`). |
| `-debugAlarmIn` | Ein echter Wecker über AlarmKit so viele Minuten (1–120) nach dem Start, auch mit `-debugFixtureTimes`. Er braucht die Erlaubnis: einmal den Schalter unter Einstellungen › Wecker zu Fadschr einschalten. Nur am Gerät – im Simulator lehnt iOS die Erlaubnis ohne Dialog ab (siehe `docs/OPEN-QUESTIONS.md`, „Annahmen in Phase 17“). |
| `-debugCity`, `-debugHighLatitude` | feste Standortquelle mit dieser Stadt, Standort erlaubt |
| `-debugLocationDenied` | Standort verweigert: Banner auf der Zeiten-Seite, „Aktueller Standort“ im Stadt-Sheet gesperrt |
| `-debugOffline` | fest „kein Netz“: Hinweis unter dem Datum, im Stadt-Sheet nur gespeicherte Städte |
| `-debugTab` | `verses` und `qada` wählen den Tab; `qibla` und `guide` die Seite im Tab „Gebete“; `settings` öffnet dort die Einstellungen, die Kennungen aus `PAGES` im Prototyp (`method`, `asr`, `hl`, `adjust`, `perPrayer`, `reminder`, `live`, `sound`, `appearance`, `language`, `privacy`, `support`) und `licenses` (nur in der App, Spec § 9.7) eine ihrer Seiten darüber; `adhan` öffnet das Adhan-Sheet über den Einstellungen, `city` das Stadt-Sheet über der Zeiten-Seite |
| `-debugOnboarding` | zeigt das Onboarding ab Schritt 1, 2, 3 oder 4, auch wenn es schon durchlaufen ist; geht vor `-debugSkipOnboarding` |
| `-debugDayOffset` | die Zeiten-Seite zeigt beim Start den Tag mit diesem Abstand zu heute, −365 bis 365 (Spec § 9.4); Mitteilungen, Widgets und Countdown bleiben bei heute. Mit `-debugFixtureTimes` verschiebt das Sonnenmodell des Prototyps die Mock-Zeiten wie `dayTimes()` |
| `-debugWalk`, `-debugWalkStep` | öffnet beim Start den Durchlauf „Gebet Schritt für Schritt“ (Spec § 9.6) für `fajr`, `dhuhr`, `asr`, `maghrib` oder `isha` auf dieser Seite (0 = Start; zu große Werte zeigen „Gebet beendet“), über der Anleitung – ohne `-debugTab` ist sie die Seite darunter. Die Zustände von `iphone/43`–`49` |
| `-debugQiblaHeading` | fester Kompasskurs statt des Kompasses des Geräts. Mit `-debugFixtureTimes` gilt ohne Angabe 99°, der Startwert des Prototyps (`S.qibla.heading`) |
| `-debugQiblaAccuracy` | Genauigkeit dieses Kurses in Grad, wie `CLHeading.headingAccuracy` (negativ heißt ungültig). Über 25° erscheint die Karte „Kompass kalibrieren“ – die Referenzbilder zeigen sie immer, die App nur bei ungenauem Kompass |
| `-debugCatalog` | Katalog der Bausteine statt der App |

`-debugSkipOnboarding` übergeht das Onboarding; ohne das Argument erscheint es, solange es nicht durchlaufen ist – mit `-debugFixtureTimes` also bei jedem Start. Ohne `-debugFixtureTimes` rechnet die App echt und behält ihre Einstellungen; ohne `-debugCity` fragt sie Core Location, ohne festen Kurs den Kompass des Geräts – den hat der Simulator nicht, die Qibla-Seite zeigt dort „Kein Kompass verfügbar“.

## Aufbau

```
App/                    App-Target: Einstieg, AccentColor, Info.plist, Entitlements, Sounds (Adhan-Ausschnitte)
Widgets/                Widget-Extension: das Widget in fünf Größen, das Widget „Live“, die Zeitleiste und die Live-Aktivität
Packages/PrayerCore     reine Logik ohne UI, mit Adhan Swift als einziger Fremdabhängigkeit
Packages/DesignSystem   Tokens und Bausteine (ab Phase 2) und der String Catalog
Packages/Features       Bildschirme, AppEnvironment, Debug-Startargumente
scripts/import-strings  erzeugt den String Catalog, die Texte der Info.plist und die Liste der Verse aus dem Prototyp
scripts/compare-catalog nimmt die Bausteine in den Zuständen der Referenzbilder auf
scripts/compare-today   nimmt die Zeiten-Seite in den Zuständen der Referenzbilder auf
scripts/compare-qibla   nimmt die Qibla-Seite in den Zuständen der Referenzbilder auf
scripts/compare-guide   nimmt die Anleitung in den Zuständen der Referenzbilder auf
scripts/compare-verses  nimmt die Seite „Verse“ in den Zuständen der Referenzbilder auf
scripts/compare-qada    nimmt die Seite „Nachholen“ in den Zuständen der Referenzbilder auf
scripts/compare-settings nimmt Einstellungen, Onboarding und Adhan-Sheet in den Zuständen der Referenzbilder auf
scripts/compare-system  nimmt Widgets und Live-Aktivität im Katalog in den Zuständen der Referenzbilder auf
scripts/compare-duo     nimmt die Seiten auf dem iPhone Duo (außen oder innen) in den Zuständen der Referenzbilder auf
scripts/compare-shot    legt einen Ausschnitt einer Aufnahme neben die Referenz
scripts/ui-harness      UI-Hilfsprojekt: ein UI-Test, der die App antippt, wischt, aufnimmt und prüft; Skripte für die Referenzbilder mit Tipp
scripts/capture-prototype nimmt die Referenzbilder aus dem Prototyp auf (Playwright, 2x, ohne Rahmen; Zustände in scripts/capture-prototype.mjs)
scripts/capture-matrix  nimmt jeden Bildschirm in Varianten auf (Sprache, Schriftgröße, hell/dunkel, RTL), mit Prüfung der Bedienungshilfen
scripts/contact-sheet.swift legt Aufnahmen als Kontaktbogen in ein Raster
scripts/app-icon.swift  zeichnet das Platzhalter-Icon (hell, dunkel, getönt) nach App/Assets.xcassets/AppIcon.appiconset
scripts/adhan-clip.swift schneidet die Adhan-Ausschnitte für Player und Mitteilungen (Quellen im Kopf der Datei)
project.yml             Beschreibung des Xcode-Projekts für XcodeGen
design/                 Prototyp, Design Spec, Referenz-Screenshots
docs/                   Bauplan, Prompts, offene Fragen
```

## Logik in PrayerCore

| Baustein | Aufgabe |
|---|---|
| `CalculationMethod`, `CalculationSettings` | die elf Methoden aus `METHODS`, automatische Methode je Land, Asr, hohe Breiten, Minutenkorrekturen ±30 |
| `PrayerTimesSource` | Zeiten eines Tages: `AdhanTimesSource` rechnet echt, `FixtureTimesSource` liefert die Mock-Zeiten des Prototyps (nur DEBUG); dazu die Methode „Automatisch“ für einen Ort (`automaticMethod(for:)`) |
| `NotificationPreferences`, `NotificationSound`, `AdhanVoice` | Vorab-Erinnerung (`REMINDERS`), Vorlauf der Live-Aktivität (`LIVE_OPTS`), Klang, Stimme des Adhan (`VOICES`, Platzhalter) und der Name ihrer Aufnahme |
| `NotificationPlanner`, `PrayerNotification`, `NotificationTone`, `NotificationWording` | welche Mitteilungen die App vormerkt: die nächsten 64 ab jetzt, je Ereignis nach seiner Glocke zur Gebetszeit und als Vorab-Erinnerung, mit Texten und Ton (Adhan der Stimme, Systemton oder keiner) |
| `PrayerTimeline`, `DayPhase` | Zeitstrahl über drei Tage; laufendes und nächstes Ereignis, Restzeit, Tagesfortschritt, Schlüssel für den Neuaufbau |
| `Kerahat` | die drei Kerahat-Fenster eines Tages |
| `BellState` | Stand der Mitteilung je Ereignis: Ton, Lautlos, Aus |
| `Qibla` | Richtung und Entfernung zur Kaaba, „in Mekka“, Anzeige in ganzen Grad und auf 10 km gerundet |
| `Heading`, `HeadingSource` | Kompasskurs mit Genauigkeit und Bezug (geografisch oder magnetisch Nord); die Quelle des Kurses, `FixedHeadingSource` für Debug und Tests |
| `CompassPoint`, `QiblaAlignment` | acht Himmelsrichtungen wie `dirName()`; wie das Gerät zur Qibla steht – ausgerichtet bis 3°, sonst links oder rechts und um wie viel |
| `HijriDate` | Datum nach Umm al-Qura und sein Text je Sprache |
| `Guide`, `GuideState`, `GuideSelection`, `Rakahs` | Daten der Anleitung, gezeigtes Gebet, manuelle Wahl und wann sie verfällt, Rakʿa-Folge; ohne Zeiten Fadschr ohne Status |
| `QadaLedger` | Stand des Nachholens: offen, nachgeholt, Anteil, voraussichtliches Ende, ob etwas eingetragen ist; hält beim Lesen die Grenzen der Stepper ein |
| `Verse` | Stelle und arabischer Text der Verse (`VERSES`, Liste erzeugt von `scripts/import-strings`), Vers des Tages im Kreis – am 10.11.2026 der erste –, die Tage der Liste „Letzte Tage“ |
| `WidgetTimeline`, `WidgetSnapshot` | Zeitleiste der Widgets: ein Eintrag für jetzt und einer zu jedem Ereignis der nächsten 24 Stunden – nächstes, übernächstes und voriges Ereignis, die Liste des Tages, was vorbei ist; ohne Zeiten der Hinweis |
| `LiveActivityPlanner`, `LiveActivityPlan`, `LiveActivityContent` | welche Live-Aktivitäten die App anmeldet: je Pflichtgebet eine, Vorlauf wie gewählt, `staleDate` zum Gebetsbeginn, Ende 15 Minuten danach, höchstens fünf; ihr Inhalt mit dem Bogen vor und ab Beginn und dem Balken mit Kerahat |
| `LiveActivityLifecycle` | was mit Aktivitäten geschieht, die iOS schon kennt: behalten, auffrischen, ersetzen, beenden – ab Gebetsbeginn bis 15 Minuten danach auf dem Sperrbildschirm |

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
| `SegmentedControl` | Segmente wie `.seg` im Prototyp, mit Punkt unter einem Teil oder mit Symbol statt Titel; Tippziel 44 pt |
| `PillButton`, `PillButtonStyle`, `FlowLayout` | Kapsel-Knopf mit Symbol (`.pill-btn`); Reihen, die umbrechen (`flex-wrap`) |
| `SectionHeader`, `CardEyebrow`, `CardFootnote`, `SymbolBadge` | Abschnittsüberschrift, Zeile in Großbuchstaben oben in einer Karte, Fußnote, Symbol im getönten Kreis |
| `GuideHeader`, `GuideHeaderCard`, `RakahSequence` | Auswahl und Kopfkarte der Anleitung: Status, Zeitfenster, Fakten-Kacheln, Rakʿa-Folge, „Zum aktuellen Gebet“ |
| `PoseFigure`, `PoseShape`, `StepCard`, `FormulaBox`, `RepeatNoteCard` | Haltungsfiguren aus `POSE`, Karte eines Schritts, arabische Formel mit Umschrift, gestrichelte Karte |
| `GuideOverview`, `GuideSteps`, `GuidePreparationList`, `GuideStepList` | die beiden Teile der Anleitung (`.col-a`, `.col-b`), „Vorher“ und „Ablauf“ |
| `PageTitle`, `PageLede` | großer Titel einer Seite der Tabs Verse und Nachholen (`.page-title`), Einleitung darunter (`.lede`) |
| `InsetGroup`, `StepperRow`, `SwitchRow`, `LinkRow` | Gruppe mit Kopf, Zeilen mit Haarlinie und Fußzeile (`group()`); Zeile mit Wert und Stepper, mit dem Schalter des Systems, als Link in Akzentfarbe |
| `VerseDay`, `VerseCard`, `VerseListItem`, `VersesOverview`, `RecentVerses` | ein Tag der Seite „Verse“ mit Namen und Datum (`relDay()`, `shortDate()`), die Karte mit dem Vers, Teilen und Kopieren, ein Eintrag der letzten Tage, die beiden Teile der Seite |
| `QadaSummary`, `QadaSummaryCard`, `QadaPrayerRow`, `QadaOverview`, `QadaDetails`, `QadaAction` | Texte der Zusammenfassung und des Plans (`num()`, Monat und Jahr), die Prozentkarte mit Balken, die Zeile je Gebet, die beiden Teile der Seite „Nachholen“, die Aktionen der Seite |
| `RowTitle`, `ValueRowLabel`, `CheckRow`, `ListSwitchRow`, `ListLinkRow`, `ExternalLinkRow`, `ListSectionHeader`, `ListSectionFooter`, `groupedListMetrics()` | Zeilen für die Liste des Systems wie `group()` im Prototyp: Titel mit Zusatz, Wert (höchstens 52 %), Häkchen, Schalter, Link in Akzent oder Rot, Link nach außen mit ↗, Kopf und Fuß, Abstände der Gruppen |
| `PrayerNotificationRow`, `AdjustmentRow`, `PrivacyNote` | Zeile „Pro Gebet“ mit den Glocken, Zeile der Minutenkorrektur mit Uhrzeit und Stepper, die Seite „Datenschutz“ |
| `AppMark`, `IconBadge`, `Tagline` | das App-Symbol (120, 34, 24 und 16 pt; seit Phase 14 auch in Live-Aktivität und Widgets statt der Mondsichel), Symbol auf getöntem Kreis, Zeichen über „Gemeinnützig · Werbefrei · Ohne Tracking“ |
| `OnboardingPage`, `PageDots` | Seite des Onboardings mit Zeichen, Titel und Text; die Punkte darunter |
| `AdhanPlayerCard`, `AdhanWaveform`, `PlayPauseButton`, `AdhanTime` | Karte des Adhan-Players: Wellenform mit 44 Balken (gespielter Teil in Akzent), Schieberegler, Zeiten wie `fmtDur()`, Play/Pause 72 pt |
| `WidgetState` | was die App für Widgets und Live-Aktivität in die App Group schreibt: Ort, Name, Berechnung, Kerahat, Sprache, in DEBUG Mock-Zeiten und Debug-Uhr |
| `PrayerActivityAttributes` | die Live-Aktivität für ActivityKit; ihr Inhalt ist `LiveActivityContent` |
| `SmallPrayerWidget`, `MediumPrayerWidget`, `CircularPrayerWidget`, `RectangularPrayerWidget`, `InlinePrayerWidget`, `PrayerWidgetContent`, `WidgetMetrics` | die fünf Widgets (`.w-*`, `.acc-*` im Prototyp) und was sie zeigen; `TimerText` setzt den laufenden Countdown in `wIn` ein |
| `LiveActivityLockScreen`, `LiveActivityBackground`, `LiveActivityCompactLeading`/`Trailing`, `LiveActivityMinimal`, `LiveActivityExpanded…`, `LiveActivityMetrics` | die Live-Aktivität auf dem Sperrbildschirm (Bogen in Weiß auf Akzent) und in der Dynamic Island (`.la-*`, `.di-*`) |
| `PageArrangement`, `Fold`, `FoldColumns`, `readsPageArrangement()` | wie eine Seite ihre beiden Teile zeigt (`.cols`, `.col-a`, `.col-b`): untereinander, innen quer als zwei Spalten am Falz (auch in RTL), in der Tischhaltung über und unter dem Falz; Platz und Falz (`ReservedRegion` `.division`, iOS 27.1) misst `readsPageArrangement()` |
| `readsVerticalBarEdge()`, `verticalBarEdge` | wo das System die senkrechte Leiste hinlegt (iPhone Duo, `toolbarVerticalEdge`, iOS 27.1); `nil` bei waagerechten Leisten |
| `centeredColumn()`, `centeredSheetCard(isRegular:)`, `CenteredColumn` | innen die Einstellungen als mittige 600-pt-Spalte, Sheets als mittige Karte, 600 pt breit |
| `GlassSymbol.barImage` | Symbol eines Chips als Bild für die Leisten des Systems, auch der Gebetsteppich |
| `Hyphenation`, `Text(hyphenating:)` | Silbentrennung mit dem Trennwörterbuch des Systems: weiche Trennstriche in den Zeilen der Listen und, bei großer Schrift, in Gebetskarte und Stepper-Zeilen (Phase 11); VoiceOver liest ohne sie |
| `WidgetTextScaling`, `WidgetMetrics.textScale` | Schrift der Widgets bei Dynamic Type: wächst wie Fließtext, höchstens auf das 1,2-Fache und nur so weit, wie der Inhalt passt (Phase 11) |
| `Palette.currentRowAccent`, `currentRowTextSecondary`, `currentRowKerahatText` | Schrift auf der Karte des laufenden Gebets, hell 8 % dunkler – Kontrast 4,5 : 1 (Phase 11) |
| `ComponentCatalog` (nur DEBUG) | alle Bausteine zum Ansehen: Previews hell und dunkel, in der App über `-debugCatalog`; Widgets und Live-Aktivität über `CatalogOutsideState` |

So kommt der Bogen auf eine Seite:

```swift
DayArc(phase: phase, showKerahat: settings.showKerahat) {
    // Zeile „Maghrib in“ und Countdown
}
```

## Gebete-Tab in Features

| Baustein | Aufgabe |
|---|---|
| `RootView`, `AppContent`, `AppNavigation` | Wurzel mit Einstellungen, Sprache und Erscheinungsbild; darunter Onboarding oder Tabs, Stadt- und Adhan-Sheet, Toast. Wo man steht (Tab, Seite, Stapel je Tab), liegt in `AppNavigation` und bleibt beim Wechsel der Sprache |
| `PrayersTab`, `TopBar`, `PrayersPager`, `PrayersPage` | obere Leiste (Einstellungskreis und drei Chips, `ViewThatFits`) über drei Seiten, die sich wischen lassen; die Einstellungen schieben sich darüber. Der Tab bestimmt den Ort |
| `PlaceModel` | welcher Ort gilt – aktueller Standort oder gewählte Stadt, Freigabe, Stadtname; Zeiten- und Qibla-Seite teilen es sich |
| `TodayModel` | Zustand der Zeiten-Seite: Zeitstrahl, die sechs Karten, Banner und Hinweise, Glocke, Stadtwahl |
| `TodayPage`, `TodayHeader`, `TodayHero`, `CountdownSchedule` | die Seite; `TodayHero` holt die Tagesphase im Sekundentakt der App-Uhr, die Karten bauen sich nur beim Phasenwechsel neu auf. Der Takt ruht, solange die Seite nicht zu sehen (`isPagerPageVisible`) oder die App nicht aktiv ist |
| `CitySheet`, `CitySheetModel` | Stadt-Sheet: aktueller Standort, gespeicherte Städte, Ortssuche |
| `QiblaModel`, `QiblaPage` | Qibla-Seite: Kursanzeige, Kompass, Statuszeile („Nach rechts drehen 39°“, ausgerichtet mit Haptik), Richtung und Entfernung, in Mekka die Meldung, ohne Ort „Stadt wählen“, ohne Kompass „Kein Kompass verfügbar“, Kalibrierungskarte nur bei ungenauem Kompass |
| `GuideModel`, `GuidePage` | Anleitung: öffnet beim aktuellen Gebet, manuelle Wahl bis zum nächsten Gebetswechsel oder bis man die Seite verlässt, „Qibla öffnen“ wechselt zur Qibla-Seite; gleicht sich nur beim nächsten Ereignis ab, nicht im Sekundentakt |
| `SettingsStore` | die Einstellungen in den UserDefaults der App Group: Glocke je Gebet, Standort oder Stadt, gespeicherte Städte, Rechen-Einstellungen, Kerahat-Schalter, Mitteilungen, Erscheinungsbild, Sprache, ob das Onboarding durchlaufen ist |
| `SettingsBar` | die obere Leiste der Tabs Verse und Nachholen: nur der Einstellungskreis; er öffnet die Einstellungen im Stapel des Tabs |
| `SettingsModel`, `SettingsRoute`, `SettingsDestination` | Einstellungen (`PAGES`): Startseite und elf Unterseiten als Liste des Systems, Methode durchsuchbar; jede Änderung wirkt sofort auf Zeiten, Bogen, Karten und Anleitung |
| `OnboardingModel`, `OnboardingView`, `OnboardingStep` | Onboarding beim ersten Start: Willkommen, Standort und Mitteilungen erst nach dem jeweiligen Vorab-Bildschirm, „Überspringen“ auf Schritt 1 und 2 |
| `AdhanPlayerModel`, `AdhanSheet`, `AdhanClips`, `AdhanPlayback` | Adhan-Sheet: Stimme (gespeichert), Fadschr-Variante als Vorschau, Abspielen über `AVAudioPlayer` oder stumm, wo es keine Aufnahme gibt |
| `NotificationAuthorizing` | Erlaubnis für Mitteilungen lesen und erfragen (`UNUserNotificationCenter`; fest in Tests und mit `-debugFixtureTimes`) |
| `NotificationModel`, `NotificationPlanning` | plant die Mitteilungen für den Ort, der gilt – nur mit Erlaubnis; neu beim Start, wenn die App nach vorn kommt, und nach jeder Änderung an Ort, Rechnung, Glocken, Erinnerung, Klang, Stimme und Sprache. Nach „Später“ im Onboarding fragt die erste Änderung an Glocke oder Mitteilungen |
| `NotificationScheduling`, `SystemNotificationScheduler` | merkt die Mitteilungen bei iOS vor: ersetzt alle ausstehenden, Auslöser nach Zeitabstand von der App-Uhr, Ton nach Glocke und Klang; mit `-debugFixtureTimes` merkt `NoNotificationScheduler` nichts vor |
| `BackgroundRefresh`, `NotificationPresenter` | Hintergrundaktualisierung (`BGAppRefreshTask`, etwa einmal am Tag) plant neu; bei offener App erscheint eine Mitteilung als Banner mit Ton |
| `VersesModel`, `VersesTab`, `VersesPage` | Seite „Verse“: Vers des Tages (wechselt um Mitternacht am Ort), Antippen eines Eintrags zeigt ihn oben und springt nach oben, Teilen über `ShareLink`, Kopieren mit Toast |
| `QadaModel`, `QadaTab`, `QadaPage` | Seite „Nachholen“: Stand des Nachholens, jede Änderung sofort als JSON in den UserDefaults der App (nicht in der App Group), Toast nach „Als offen übernehmen“; ohne Einträge ohne Zusammenfassung und Plan |
| `CoreLocationSource`, `MapKitPlaceResolver` | aktueller Ort über Core Location („Beim Verwenden der App“), Stadtname über `MKReverseGeocodingRequest` |
| `CoreLocationHeadingSource` | Kompasskurs über Core Location: geografisch Nord, ohne Standortfreigabe magnetisch Nord; läuft nur, solange die Qibla-Seite zu sehen ist |
| `MapKitCitySearch` | Ortssuche mit `MKLocalSearchCompleter` |
| `NetworkConnectivity` | ob das Gerät ein Netz hat (`NWPathMonitor`) |
| `ToastCenter` | zeigt den Toast über der Tableiste, 1,7 Sekunden; neben einer senkrechten Leiste 28 pt über dem Rand, mittig über dem Inhalt |
| `PageScroll` | die scrollende Seite mit ihren beiden Teilen: untereinander, in Spalten oder in der Tischhaltung in zwei Bereichen; Abstand oben unter der Leiste oder neben der senkrechten Leiste |
| `TopBar`, `VerticalTopBar`, `prayersTopBar`, `settingsBar` | die obere Leiste auf dem iPhone, mit senkrechter Leiste ihre Einträge in der Leiste des Systems |

Alles, was nach außen geht, hängt in `AppEnvironment`: Uhr, Standortquelle, Kursquelle, Zeitenquelle, Netz-Zustand, Ortssuche, Erlaubnis für Mitteilungen und wo sie vorgemerkt werden, der Ort der Einstellungen und der des Nachholens. Views sprechen nie selbst mit `Date()`, `CLLocationManager`, MapKit oder `UNUserNotificationCenter`.

Die Zahlen des Nachholens bleiben auf dem Gerät: ein JSON-Eintrag (`qada.ledger`) in den UserDefaults der App, nicht in der App Group, weil Widgets sie nicht brauchen. Die App startet leer; mit `-debugFixtureTimes` zeigt sie die Zahlen des Prototyps und speichert nichts.

Ins Netz geht die App nur über Apple-Dienste und nur dafür: die Koordinaten des Standorts an den Geocoder (für den Stadtnamen) und der Suchtext an die Ortssuche. Gerechnet wird auf dem Gerät; ohne Netz gilt der zuletzt bestimmte Ort weiter. Der Kompass braucht kein Netz. Für geografisch Nord bestimmt Core Location nebenbei grob den Standort, solange die Qibla-Seite zu sehen ist; der bleibt auf dem Gerät.

Nach dem Standort fragt das Onboarding im zweiten Schritt, nach den Mitteilungen im dritten – jeweils erst nach dem Vorab-Bildschirm. Wurde es übersprungen, fragt die Zeiten-Seite beim ersten Erscheinen selbst nach dem Standort, weil sie ohne Ort nichts zeigen kann.

## Einstellungen, Sprache und Adhan

Die Einstellungen schieben sich im Stapel des Tabs über die Seite, aus dem der Einstellungskreis sie öffnet. Jede Änderung liegt sofort im `SettingsStore` und wirkt in der ganzen App: Methode, Asr, Regel für hohe Breiten und Minutenkorrektur rechnen die Zeiten neu, der Kerahat-Schalter wirkt auf Bogen und Karten, das Erscheinungsbild auf alle Seiten und Sheets.

Die Sprache wählt man in der App (Einstellungen › Sprache, 16 Sprachen seit Phase 15). Ohne eigene Wahl gilt die, die iOS für die App wählt. Nach einer Wahl liest `L10n` die Texte aus dem Teil-Bundle dieser Sprache; die Seiten bauen sich neu auf, man bleibt dort, wo man war. Arabisch, Urdu und Persisch laufen von rechts nach links, auch wenn das Gerät eine andere Sprache spricht – `RootView`, Widgets und Live-Aktivität setzen die Leserichtung aus der Sprache der App (`L10n.layoutDirection`). Texte des Systems – die Dialoge für Standort und Mitteilungen, das Teilen-Menü – erscheinen weiter in der Sprache des Geräts.

Der Adhan-Player spielt die Ausschnitte in `App/Sounds/` über `AVAudioPlayer`. TODO(placeholder): Stimme 1 und 2 sind freie Aufnahmen von Wikimedia Commons (CC0 bzw. gemeinfrei, Quellen im Kopf von `scripts/adhan-clip.swift`), Stimme 3 und die Fadschr-Variante haben keine Aufnahme und laufen stumm wie im Prototyp. Die Ausschnitte sind kürzer als 30 Sekunden und liegen in einem Format, das iOS auch für Mitteilungstöne annimmt (IMA4 in CAF). Hat der Simulator kein Ausgabegerät, bleibt der Player beim Abspielen einer Aufnahme stehen.

### Abgleich mit den Referenzbildern

Previews lassen sich nicht mit `simctl` aufnehmen. Deshalb zeigt die App mit `-debugCatalog` den Katalog statt der Tabs: `arc` den Bogen, `rows` die Gebetskarten, `compass` den Kompass mit der Kalibrierungskarte und `guide` Auswahl, Kopfkarte und „Vorher“ der Anleitung im Zustand der übrigen Debug-Argumente, `steps` den Ablauf der Anleitung, `verses` und `qada` die Seiten „Verse“ und „Nachholen“ am Tag der Debug-Uhr (das Nachholen mit den Zahlen des Prototyps), `settings` die Zeilen der Einstellungen, `onboarding` die drei Seiten des Onboardings, `adhan` die Karte des Players still und beim Abspielen, `glass` und `cards` die übrigen Bausteine, `all` alles untereinander.

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

`iphone/85` (Stadt-Sheet) entsteht mit den Argumenten von `iphone/10` und einem Tipp auf die Stadt, seit Phase 10 auch mit `-debugTab city`.

`make compare-qibla` stellt die Zustände `iphone/30` bis `32` der Qibla-Seite nach – mit festem Kurs, weil der Simulator keinen Kompass hat, und mit `-debugQiblaAccuracy 40`, damit die Kalibrierungskarte erscheint – und schreibt je Zustand die Aufnahme (`qibla-<nr>.png`) und Ausschnitte von Leiste, Kopf, Kompass, Status- und Info-Zeile und Kalibrierungskarte nach `screenshots-out/phase-4/`. Die Karte kommt zusätzlich aus dem Katalog (`-debugCatalog compass`), dort in der Breite der Referenzbilder.

```bash
make compare-qibla
```

`make compare-guide` stellt `iphone/40` nach (Anleitung, 14:25, Asr läuft) und schreibt die Aufnahme (`guide-40.png`) und Ausschnitte von Leiste, Auswahl, Kopfkarte, Knopf „Gebet Schritt für Schritt“ und „Vorher“ nach `screenshots-out/phase-5/`, dazu die Bausteine aus dem Katalog (`-debugCatalog guide` und `steps`) in der Breite der Referenzbilder. Seit Phase 13 gelten die Ausschnitte für v0.8 (Kopfkarte mit Knopf); die Lagen stehen im Kopf des Skripts. `iphone/41` (gescrollt) und `42` (Maghrib angetippt) brauchen Wischen und Tippen; liegen ihre Aufnahmen `guide-41.png` und `guide-42.png` dort, vergleicht das Skript sie mit. Aufgenommen werden sie mit dem UI-Hilfsprojekt: `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-41-42-guide.txt` mit `OUT=screenshots-out/phase-5`.

```bash
make compare-guide
```

`make compare-walk` (seit Phase 13) startet die App je Zustand mit `-debugWalk` und `-debugWalkStep` wie die Referenzbilder `iphone/43`–`49` (Start, Takbīr, Stehen leise und laut, Niederwerfung, erstes Sitzen, Ende; `43`, `47`, `49` auch dunkel) und legt Kreis, Kopf, Fortschritt, Seite und Knöpfe neben die Referenz, Ergebnis in `screenshots-out/phase-13/`. Den Ablauf mit Tippen – Knopf in der Anleitung, Beginnen, Weiter, Zurück, Schließen, dann mit Maghrib – spielt `scripts/ui-harness/scripts/iphone-43-49-walk-flow.txt` durch.

```bash
make compare-walk
```

`make compare-verses` stellt `iphone/50` (Verse, hell) und `51` (dunkel) nach und schreibt die Aufnahmen (`verses-50.png`, `verses-51.png`) und Ausschnitte von Leiste, Titel, Karte, Fußnote und Liste nach `screenshots-out/phase-6/`, dazu die Seite aus dem Katalog (`-debugCatalog verses`) in der Breite der Referenzbilder.

```bash
make compare-verses
```

`make compare-qada` stellt `iphone/60` nach (Nachholen mit den Zahlen des Prototyps) und schreibt die Aufnahme (`qada-60.png`) und Ausschnitte von Leiste, Kopf, Zusammenfassung, Plan und „Nach Gebet“ nach `screenshots-out/phase-6/`, dazu die Seite aus dem Katalog (`-debugCatalog qada`). `iphone/61` ist die Seite ganz nach unten gescrollt; liegt ihre Aufnahme `qada-61.png` dort – aufgenommen mit dem UI-Hilfsprojekt –, vergleicht das Skript sie mit.

```bash
make compare-qada
```

`make compare-settings` stellt die Einstellungen (`iphone/70`, `73` bis `81`, `83`), das Adhan-Sheet (`86`) und das Onboarding (`01` bis `03`, `05`) mit den Debug-Argumenten nach – `-debugTab settings|method|…|privacy|support|adhan` und `-debugOnboarding 1|2|3|4` – und schreibt Aufnahmen und Ausschnitte nach `screenshots-out/phase-7/`. Gruppen und Karten werden in zwei Hälften verglichen; die Lage in der Höhe folgt den Leisten des Systems (Kopf des Skripts). `iphone/71` und `72` sind die Einstellungen gescrollt, `82` „Hohe Breitengrade“ mit „Manuelle Winkel“; liegen ihre Aufnahmen `settings-71.png`, `settings-72.png` und `settings-82.png` dort – aufgenommen mit dem UI-Hilfsprojekt –, vergleicht das Skript sie mit. `iphone/04` zeigt nur den Dialog des Systems.

```bash
make compare-settings
```

```bash
make compare-settings STATES='70 86'
```

Einzelne Ausschnitte vergleicht `scripts/compare-shot`; die Optionen stehen im Kopf von `scripts/compare-shot.swift`. Was vom Referenzbild abweicht und warum, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 2“ bis „Annahmen in Phase 8“.

## Mitteilungen

Die App merkt lokale Mitteilungen bei iOS vor, ohne Server. Je Ereignis gibt es eine zu seiner Zeit, wenn seine Glocke nicht auf „Aus“ steht: „Dhuhr · 11:52“ – „Zeit für Dhuhr in Berlin.“. Ist eine Vorab-Erinnerung gewählt, kommt dazu eine früher: „Dhuhr in 10 Minuten“ – „Dhuhr beginnt um 11:52 Uhr.“. Die Texte stehen in der Sprache der App, auch bei der eigenen Wahl; Uhrzeit und Tag gelten am Ort, Minutenkorrekturen eingerechnet. Kerahat hat keine Mitteilung.

| Glocke | Mitteilung zur Gebetszeit | Erinnerung |
|---|---|---|
| Ton | Klang „Kurzer Adhan“: die Aufnahme der gewählten Stimme (`App/Sounds`), zu Fadschr die Fadschr-Variante, sobald es sie gibt; Stimme 3 ohne Aufnahme und der Sonnenaufgang: Systemton. Klang „Systemton“: Systemton. Klang „Lautlos“: ohne Ton | Systemton, beim Klang „Lautlos“ ohne Ton |
| Lautlos | ohne Ton | ohne Ton |
| Aus | keine | keine |

iOS hält je App höchstens 64 ausstehende Mitteilungen. Die App plant deshalb ein rollierendes Fenster: die nächsten 64 in zeitlicher Folge, eine Erinnerung nur mit ihrer Mitteilung. Mit den Startwerten – fünf Glocken an, Erinnerung 10 Minuten vorher – sind das zehn am Tag, gut sechs Tage; alle sechs mit Erinnerung gut fünf Tage, ohne Erinnerung 10 bis 13 Tage. Neu geplant wird beim Start, wenn die App nach vorn kommt, nach jeder Änderung an Ort, Methode, Asr, Regel für hohe Breiten, Minutenkorrektur, Glocken, Erinnerung, Klang, Stimme und Sprache, nach der Antwort im Onboarding und bei der Hintergrundaktualisierung: Etwa einmal am Tag weckt iOS die App kurz (`BGAppRefreshTask`, Kennung `<Bundle-ID>.refresh` in der Info.plist). Den Zeitpunkt bestimmt iOS; im Simulator gibt es sie nicht.

Ohne Erlaubnis plant die App nichts; die Glocken bleiben einstellbar, unter Einstellungen › Mitteilungen steht der Hinweis. Gefragt wird im Onboarding; wer dort „Später“ wählt, wird bei der ersten Änderung an einer Glocke oder unter Einstellungen › Mitteilungen gefragt. Mitteilungen sind nicht zeitkritisch. Bei offener App erscheinen sie als Banner mit Ton.

### Abgleich von `system/92`

`system/92` zeigt den Sperrbildschirm mit der Mitteilung zu Dhuhr und der Erinnerung zehn Minuten davor. Nachgestellt wird er mit dem UI-Hilfsprojekt (`scripts/ui-harness/scripts/system-92.txt`):

1. Systemsprache des Simulators auf Deutsch, damit iOS „jetzt“ und „vor 10 Min.“ schreibt; die Uhr auf dem Sperrbildschirm folgt der Statusleiste.
2. Die App mit `-debugFixtureTimes -debugNotifications -debugTime 11:41` starten.
3. Das Gerät sperren und gut elf Minuten warten.
4. Den Stapel der beiden Mitteilungen aufklappen und aufnehmen.

Die Argumente stehen in `docs/PROMPTS.md`, was abweicht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 8“).

```bash
make statusbar TIME=11:52
```

Das Protokoll der App nennt in DEBUG jedes Mal, was iOS vormerkt:

```bash
xcrun simctl spawn booted log show --last 15m --predicate "subsystem == \"$(scripts/bundle-id)\" AND category == \"notifications\""
```

Töne sind im Simulator auf diesem Mac nicht zu hören (kein Ausgabegerät); sie bleiben am Gerät zu prüfen.

## Widgets und Live-Aktivität

Die Widget-Extension (`Widgets/`) bietet ein Widget in fünf Größen, seit Phase 14 das mittlere Widget „Live“ im Stil der Live-Aktivität (Spec § 9.11) und die Live-Aktivität. Beide rechnen mit PrayerCore aus dem, was die App in die App Group schreibt (`WidgetState`): Ort, Name des Ortes, Berechnung samt Minutenkorrektur, Kerahat-Schalter und die Sprache der App, auch bei der eigenen Wahl. Die App schreibt den Stand beim Start, wenn sie nach vorn kommt, nach jeder Änderung und bei der Hintergrundaktualisierung; hat er sich geändert, laden die Widgets neu. Den Ort entscheidet die App; die Extension fragt nie nach dem Standort.

| Größe | zeigt |
|---|---|
| klein (systemSmall) | Stadt, Symbol des nächsten Ereignisses, Name, Uhrzeit, „in 2:01:29“ |
| mittel (systemMedium) | dazu „NÄCHSTES“ und die sechs Zeiten des Tages, das nächste Ereignis hervorgehoben, Vergangenes abgeblendet |
| „Live“, mittel (eigenes Widget `PrayerLive`) | Akzentverlauf, Kopf mit App-Symbol, „Vaqt“ und Stadt, Tagesbogen mit Zeiten und Kerahat, „Maghrib · 16:27“ und Countdown |
| rund (accessoryCircular) | Ring vom vorigen bis zum nächsten Ereignis, innen Symbol und Uhrzeit |
| Rechteck (accessoryRectangular) | Tagesbogen im Stil der Live-Aktivität, einfarbig: Gebete mit Symbol, Jetzt-Punkt mit Ring, Kerahat gestreift, im Bogen „Maghrib · 16:27“ und der Countdown |
| Zeile (accessoryInline) | Symbol und „Maghrib 16:27“ |

Wie die Zeiten-Seite nennen die Widgets das nächste Ereignis, auch den Sonnenaufgang. Die Zeitleiste hat einen Eintrag für jetzt und einen zu jedem Ereignis der nächsten 24 Stunden, für den Bogen dazu zwischen Fadschr und Ischa und an den Grenzen der Kerahat-Fenster Zwischeneinträge – im Widget „Live“ alle 5, im Rechteck alle 10 Minuten (seit Phase 14; iOS lehnt Archive über 10 MB ab); Countdown und Ring laufen dazwischen von selbst (`Text(timerInterval:)`, `ProgressView(timerInterval:)`). Ohne Ort zeigen die Widgets „Stadt wählen“, ohne Zeiten den Hinweis der Zeiten-Seite (`noTimes`).

Die Live-Aktivität läuft je Pflichtgebet, ohne Sonnenaufgang, standardmäßig ab 30 Minuten vorher (Einstellungen › Live-Aktivität: Aus, 10, 15, 20, 30, 45, 60, 90 oder 120 Minuten). iOS startet sie selbst (`Activity.request(…, start:)`), auch wenn die App nicht läuft. Ab Gebetsbeginn ist sie `stale` und zeigt „Jetzt“ statt des Countdowns, der Bogen das Gebet als laufend. 15 Minuten nach Beginn endet sie. Ein geplantes Ende kennt ActivityKit nicht; die App beendet die Aktivität, sobald sie läuft – zum Gebetsbeginn, wenn sie vorn ist, sonst beim Start, wenn sie nach vorn kommt, oder bei der Hintergrundaktualisierung – und lässt sie bis 15 Minuten nach Beginn auf dem Sperrbildschirm stehen. Läuft die App nicht, bleibt „Jetzt“ stehen; iOS beendet eine Aktivität nach spätestens 8 Stunden. iOS nimmt höchstens fünf Aktivitäten je App an, geplante mitgezählt; die App plant die nächsten fünf.

Seit Phase 16 (Spec § 10.3):
- **Verbotszeit:** Fällt die Verbotszeit vor Dhuhr oder Maghrib in die Strecke, gibt es zwei Aktivitäten: eine grüne bis zu ihrem Beginn und eine orange (Kennung mit dem Zusatz „verbot“) bis zum Gebet.
- **Kein „Jetzt“:** Zu ihrem `staleDate` schrumpft eine Aktivität auf eine schmale Zeile, „Asr · 14:00 · hat begonnen“ bzw. „Verbotszeit ab 11:42“. Sobald die App läuft, beendet sie die Aktivität sofort.
- **Reihenfolge:** `relevanceScore` wächst mit dem Start, die neueste steht deshalb oben und in der Dynamic Island.
- **Deckkraft:** Der Hintergrund hat 30 % Deckkraft. Das Widget „Live“ bleibt deckend, weil iOS unter Widgets eine eigene Fläche legt (siehe `docs/OPEN-QUESTIONS.md`, „Annahmen in Phase 16“).
- **Aufräumen:** Die Widget-Erweiterung sieht die Aktivitäten der App nicht und kann sie deshalb nicht beenden.

### Abgleich von `system/90`, `91` und `93`–`96`

`make compare-system` nimmt den Katalog (`-debugCatalog widgets`, `live`) in den Maßen des Prototyps auf und legt jeden Baustein neben die Referenz. Im System selbst – Widgets auf Home- und Sperrbildschirm, Live-Aktivität auf dem Sperrbildschirm und in der Dynamic Island – stellt das UI-Hilfsprojekt die Referenzbilder nach; die Schritte und Argumente stehen in `docs/PROMPTS.md`, was abweicht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 9“ und „Annahmen in Phase 14“). Die Widgets von „Vaqt“ liegen im Simulator auf der Seite links neben der des Hilfsprojekts; eingerichtet werden sie mit `system-setup-home-widgets.txt` und `system-setup-lock-widgets.txt`.

Das Protokoll der App nennt in DEBUG, welche Aktivitäten es gibt und was die App anmeldet, auffrischt und beendet:

```bash
xcrun simctl spawn booted log show --last 15m --predicate "subsystem == \"$(scripts/bundle-id)\" AND (category == \"liveActivity\" OR category == \"widgets\")"
```

## iPhone Duo

Das Duo (seit 23.10.2026) hat außen ein Display mit 466 × 678 pt und innen eines mit 951 × 669 pt quer. Die App zeigt dieselben Seiten wie auf dem iPhone (Design Spec § 8); was sich ändert, steuern das System und die Größenklasse:

- **Leisten:** Tableiste, Zurück-Knopf und Status legt iOS in eine senkrechte Leiste am rechten Rand, auch in RTL; im Split View liegt sie am Rand der App. Einstellungskreis und Seiten-Chips werden dort Einträge der Leiste des Systems (`VerticalTopBar`); auf dem iPhone bleibt die eigene Leiste oben.
- **Außen (compact):** die Seiten wie auf dem iPhone, 382 pt breit neben der Leiste.
- **Innen quer (regular):** Zeiten, Qibla, Anleitung, Verse und Nachholen in zwei Spalten, die sich am Falz treffen; den Falz meldet das System (`ReservedRegion` `.division`). Einstellungen und Unterseiten als mittige 600-pt-Spalte, Stadt- und Adhan-Sheet als mittige 600-pt-Karte.
- **Innen hoch:** Die Leisten stehen waagerecht wie auf dem iPhone, die Seiten untereinander. **Tischhaltung** (halb aufgeklappt, Falz waagerecht): der erste Teil über dem Falz, der zweite darunter, jeder für sich scrollbar; die Qibla-Seite bleibt untereinander.
- **Split View:** compact, die Seiten wie auf dem iPhone.

Mindestversion bleibt iOS 26; alles, was das Duo betrifft, steht hinter `#available(iOS 27.1, *)`. Auf dem iPhone ändert sich nichts.

### Abgleich mit `duo/*`

Den Simulator „iPhone Duo“ gibt es erst mit dem Runtime „iOS 27.2“ Build 24B91016s (eigene Kennung `com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4`); der Runtime 24B8117 der übrigen Simulatoren schließt das Duo aus. Auf- und zugeklappt, halb geöffnet und gedreht wird in Device Hub (Schieberegler des Scharniers) – `simctl` und XCUITest können das Scharnier nicht stellen. `make compare-duo` nimmt deshalb je Lauf eine Haltung auf:

```bash
make compare-duo MODE=open
```

```bash
make compare-duo MODE=closed STATES='10 85'
```

Aufnahmen und Vergleiche liegen in `screenshots-out/phase-10/`. Startet der Duo nach einem Neustart, ist er zugeklappt. Was abweicht und warum, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 10“). Das Protokoll der App nennt in DEBUG Platz, Falz und Größenklasse:

```bash
xcrun simctl spawn 'iPhone Duo' log stream --level debug --predicate "subsystem == \"$(scripts/bundle-id)\" AND category == \"duo\""
```

## Texte

Alle Texte stehen im Prototyp im Objekt `T`, seit Phase 15 in 16 Sprachen (DE, TR, EN, ES, FR, NL, BS, SQ, AR, UR, ID, MS, BN, FA, RU, IT; Spec § 9.10). Die zwölf Sprachen ab FR sind KI-Entwürfe und stehen im Katalog mit dem Status „Needs Review“; vor dem App Store prüfen sie Muttersprachler. `scripts/import-strings` erzeugt daraus `Localizable.xcstrings` und `L10n.swift` im Paket `DesignSystem` und `App/InfoPlist.xcstrings`. Die Dateien werden nicht von Hand geändert: Text im Prototyp ändern, dann `make strings`. Im Code heißt `t('navPrayers')` aus dem Prototyp `L10n.navPrayers`.

**Mehrzahl** (Phase 15): Texte mit Zahl und Zählwort haben ihre Formen in `PLURAL` im Prototyp, je Sprache nach den Kategorien von CLDR (`zero`, `one`, `two`, `few`, `many`, `other`) – etwa „1 Tag“/„2 Tage“, russisch „1 день“/„2 дня“/„5 дней“, arabisch mit Dual. Im Katalog werden sie zu Plural-Varianten, in `L10n` ist die Zahl ein `Int` (`L10n.qcResultDetail(d:k:)`). `L10n.text` schreibt mit der Locale der Textsprache – nur dann wählt iOS die richtige Form.

**Ziffern und Kalender** (Phase 15, entschieden mit dem Plan): Die App schreibt Zahlen wie das System – Persisch ۰–۹, Arabisch ٠–٩ dort, wo die Region es tut (z. B. `ar_SA`), sonst 0–9; das gilt für Uhrzeiten (`L10n.time`), Countdown, Zahlen und die Ziffern in den Texten (`LocalizedDigits`). Das Datum steht im Kalender der Region (Persisch: persisch); ist er selbst islamisch, bleibt die erste Zeile gregorianisch (`L10n.displayCalendar`). Zeitspannen beginnen von rechts nach links rechts (`L10n.timeRange`).

Die Verse kommen aus `VERSES` und `SURAH` im Prototyp: Übersetzungen und Namen der Suren als `verse_<Sure>_<Vers>` und `surah_<Sure>` in den String Catalog (`L10n.verseTranslation(surah:ayah:)`, `L10n.surahName(_:)`), Stelle und arabischer Text nach `Packages/PrayerCore/Sources/PrayerCore/Verses/VerseList.swift`. Die Übersetzungen sind Platzhalter und tragen im Katalog den Kommentar `TODO(placeholder)` (Spec § 6.12). Es gibt sie nur in DE/TR/EN/ES; die übrigen Sprachen zeigen den englischen Platzhalter und den englischen Namen der Sure, Arabisch keine Übersetzung – der Vers selbst steht darüber (Spec § 9.10).

`App/InfoPlist.xcstrings` enthält die Begründung der Standortabfrage im System-Dialog (`NSLocationWhenInUseUsageDescription`) – der Text `alLocBody` aus `T`. Die Info.plist braucht ihn zusätzlich als Grundwert; der steht in `project.yml`, und `make check-strings` prüft, dass er dem deutschen Text entspricht.

Die Vorab-Erinnerung braucht im Türkischen eine Endung, die von der Uhrzeit abhängt: „Öğle vakti 12:53’te başlıyor.“, aber „15:36’da“. `TurkishClockSuffix` (PrayerCore) bestimmt sie nach dem letzten gesprochenen Zahlwort, `L10n.notifReminderBody(p:at:)` hängt sie an (Phase 11); im türkischen Text von `T` steht deshalb keine feste Endung.

`L10n.locale` nennt die Sprache, in der die Texte gerade erscheinen; mit ihr schreibt die App Datum und Ländernamen. `L10n.chosenLanguage` ist die in der App gewählte Sprache (`nil`: wie das Gerät).

Neben `noTimes` (Phase 3) und `noCompass` (Phase 4) hat der Prototyp in Phase 7 den Text `hlMoonsighting` bekommen: der Hinweis unter „Hohe Breitengrade“, dass die Regel bei Moonsighting nicht wirkt. Der Katalog hatte damit 273 Einträge, seit Phase 13 sind es 337.

Die Adresse hinter „Quellcode“ steht in `project.yml` (`SOURCE_CODE_URL`, seit 16.11.2026 das öffentliche Repo `https://github.com/Memo668/vaqt`) und kommt über die Info.plist (`SourceCodeURL`) in die App.

## Große Schrift und Barrierefreiheit

Die App folgt Dynamic Type bis AX5 (Phase 11). Ab den AX-Größen stellen sich enge Zeilen um, statt mitten im Wort oder in der Zahl umzubrechen: Die Gebetskarte setzt die Uhrzeit unter den Namen, die Fakten-Kacheln der Anleitung stehen untereinander, die Zeilen mit Stepper (Nachholen, Minutenkorrektur) werden zweizeilig. Countdown (×1,05), Zeiten am Bogen (×1,2), die Zeile über dem Countdown (bis „xxxLarge“), die Chips (bis AX1, dann Large Content Viewer) und die Widgets (×1,2) wachsen begrenzt. Lange Wörter trennt das System; die weichen Trennstriche von `Hyphenation` sichern das für iOS 26 ab.

`make capture` nimmt jeden Bildschirm in Varianten auf und schreibt dazu die Prüfung der Bedienungshilfen von Xcode (`performAccessibilityAudit`) und den Baum der Bedienungshilfen; die Aufnahmen liegen auf der externen Platte, wenn sie angesteckt ist (`screenshots-out/phase-11/matrix` zeigt dorthin). Was die Prüfung meldet und was davon bleibt, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 11“).

## App Store

`make archive` baut das Release-Archiv für das iPhone (`generic/platform=iOS`) ohne Signatur nach `Archives/Gebetszeiten.xcarchive` neben den Build-Daten, auf der externen Platte, wenn sie angesteckt ist. Danach prüft `scripts/check-archive` es auf das, was der Upload braucht: Widget-Extension und Symbole eingebettet, beide Datenschutz-Manifeste, das helle App-Icon ohne Alphakanal, alle Texte in DE, TR, EN und ES, nur iPhone (`UIDeviceFamily` 1), Exportkontrolle, Kennungen und Versionen von App, Extension und Hintergrundaufgabe, keine Debug-Startargumente in den Binärdateien und, bei einem signierten Archiv, die App Group in den Entitlements. „FEHLER“ heißt: so nicht hochladen; „Hinweis“ nennt die Platzhalter, die bis zum Entwicklerkonto bleiben. Ein anderes Archiv prüft `scripts/check-archive <Pfad.xcarchive>`.

Die Gerätefamilie steht in `project.yml` an beiden Targets, nicht beim Projekt: XcodeGen setzt für iOS-Targets sonst „1,2“, und als iPad-App mit nur Hochformat lehnte Apple den Upload ab. Die Exportkontrolle beantwortet `ITSAppUsesNonExemptEncryption = NO` in der Info.plist: Die App verschlüsselt nicht selbst und geht nur über MapKit ins Netz.

Datenschutz-Manifeste: `App/PrivacyInfo.xcprivacy` und `Widgets/PrivacyInfo.xcprivacy` (kein Tracking, keine erfassten Daten, UserDefaults mit Grund). Die Angaben für App Store Connect – „Keine Daten erfasst“ mit Begründung je Datenart – stehen in `docs/APP-STORE.md`. Das App-Symbol ist ein Platzhalter: der Tagesbogen mit den fünf Gebeten, hell, dunkel und getönt, erzeugt von `swift scripts/app-icon.swift` (TODO(placeholder), Spec § 6.9).

## Bundle-ID und App Group

Die App heißt bei Apple `de.mehmetyilmaz.gebetszeiten`, die Extension `de.mehmetyilmaz.gebetszeiten.widgets`, die App Group `group.de.mehmetyilmaz.gebetszeiten`; Team ist das Entwicklerkonto `V7652FBKMY` (Einzelperson, alles entschieden am 15.11.2026; bis dahin Platzhalter `com.example.gebetszeiten`). Die Bundle-ID lässt sich nach dem ersten Upload nicht mehr ändern. Bundle-ID und App Group stehen nur oben in `project.yml` (`APP_BUNDLE_ID`, `APP_GROUP_ID`): Info.plists und Entitlements von App und Extension, die Kennung der Hintergrundaktualisierung (`<Bundle-ID>.refresh`) und das Subsystem des Protokolls nehmen sie von dort; `Makefile`, Abgleich-Skripte, UI-Hilfsprojekt und `scripts/check-archive` lesen die Bundle-ID über `scripts/bundle-id`. Das UI-Hilfsprojekt hat für sich selbst eine eigene Kennung (`com.example.gebetszeiten.uiharness`); es läuft nur im Simulator und gehört nicht zur App.

Testinstallationen auf eigenen iPhones laufen seit dem 15.11.2026 mit diesem Team und diesen Kennungen; die vorläufigen Kennungen aus der Zeit des persönlichen Teams (`com.v7652fbkmy.…`) nicht mehr verwenden. Wer das Projekt mit einem anderen Konto baut, ändert `DEVELOPMENT_TEAM` und die beiden Kennungen nur lokal und checkt sie nicht ein.

## Lizenz

Der Code steht unter der MIT-Lizenz (`LICENSE`, entschieden am 16.11.2026). Ausgenommen sind die fremden Teile aus `docs/THIRD-PARTY.md`: Adhan Swift (MIT), die Schriften Amiri und Amiri Quran (SIL OFL 1.1) und die Adhan-Aufnahmen (CC0 bzw. gemeinfrei) behalten ihre eigene Lizenz.
