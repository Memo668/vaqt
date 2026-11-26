# Gebetszeiten – iOS-App (SwiftUI)

Gemeinnützige Gebetszeiten-App: werbefrei, ohne Tracking, ohne Konto. Name unter dem Symbol und in der App: **„Vaqt“** (Arbeitsname seit 15.11.2026, Spec § 9.13); Bundle-ID, Targets und Typen heißen weiter „Gebetszeiten“. Wir bauen den Designprototyp aus `design/` **eins zu eins** als native SwiftUI-App nach – gleiche Bildschirme, gleiche Abstände, Farben, Texte und gleiches Verhalten.

## Quellen der Wahrheit

1. `design/prayer-times-design-spec.md` – Design Spec v0.14: Tokens, Komponenten, Verhalten, Zustände, iPhone Duo (§ 8), offene Fragen (§ 6), Varianten (§ 7), Änderungen vor der Beta (§ 9), nach der ersten Beta (§ 10), vor der Golden Beta (§ 11, mit dem Nachtrag § 11.3–11.7: Klang, Stil, Rechtsschule, Onboarding) CarPlay und StandBy (§ 12, Phase 19) und das App-Icon (§ 13, Phase 20; seit v0.14 mit eigenen Symbolen statt SF Symbols).
2. `design/screenshots/` – Referenzbilder je Bildschirm und Zustand. Übersicht: `design/screenshots/INDEX.md`. Seit Spec v0.8 nimmt `scripts/capture-prototype` sie aus dem Prototyp auf.
3. `design/prayer-times-prototype.html` – Quelltext des Prototyps (~2 400 Zeilen, nicht komplett einlesen, gezielt suchen):
   - Tokens: `:root`-CSS am Anfang (Farben hell/dunkel, Abstände, Radien, Schriftgrößen)
   - alle Texte, 16 Sprachen (Spec § 9.10): JS-Objekt `T`
   - Logik: `todayTimes()`, `phase()`, `phaseKey()`, `kerahatWins()`, `activeKerahat()`, `guideState()`, `dayProgress()`, `ARCS` + `arcHTML()`, `qadaPage()`
   - Daten: `METHODS`, `RAKAH`, `GUIDE_STEPS`, `FORMULA`, `VERSES`, `KERAHAT_MIN`, `KERAHAT_MIN_BY` und `MADHABS` (Verbotszeiten je Rechtsschule), `ACCENTS` (24 Grundfarben), `LA_STYLES` (Stile der Live-Aktivität)
   - Seiten: `homePage()`, `prayerRow()`, `topBarHTML()`, `qiblaPage()`, `guidePage()`, `versesPage()`, `qadaPage()`, `PAGES` (Einstellungen, darin `style()` und `madhab()`), `laBanner()`/`diExpanded()` (Live-Aktivität, Stil über `laAttr()` und die Variablen `--la-*` im Block „Stil“), `cwCarPlayHTML()` (Ansicht „CarPlay“ seit Phase 19: `laSmall()`, `cpwNext()`, `cpwArc()`, `ARCS.cpw`/`lasm`, `LAS`)

Werte und Formeln von dort übernehmen, nicht schätzen. Bei Widerspruch gilt: Spec > Screenshot > HTML. Ist etwas unklar, frag nach oder trag es in `docs/OPEN-QUESTIONS.md` ein – nicht raten.

## Nicht übernehmen

- Das Prototyp-Panel links (Simulation, Varianten-Schalter) ist nur Werkzeug. Von den Varianten gilt immer die Standardwahl aus Spec § 7.
- Die Mock-Zeiten (`CITIES`, `BERLIN_SUMMER`) – die App rechnet echt. Die Mock-Zeiten dienen nur als Test-Fixture (siehe Debug).
- CSS-Nachbauten von Systemelementen (Statusleiste, Dynamic Island, Liquid Glass, Alerts, Sheets) – dafür echte iOS-APIs.
- Die Übersetzungen der Verse sind seit Phase 18 wörtliche Ausschnitte veröffentlichter Übersetzungen (Spec § 11.1): nicht umformulieren, nicht kürzen, keine eigenen Übersetzungen ergänzen. Neue Verse brauchen denselben Abgleich mit der Quelle (`docs/THIRD-PARTY.md`).

## Technik

- Aktuelles Xcode, Swift 6 (strict concurrency), SwiftUI. Mindestversion **iOS 26** (Liquid Glass, geplante Live-Aktivitäten).
- Struktur: App-Target + Widget-Extension (Widgets und Live Activity) + lokale Swift-Pakete:
  - `PrayerCore` – reine Logik ohne UI: Berechnung, Tagesphase, Kerahat, Qibla, Hijri, Nachholen, Daten der Anleitung. Unit-Tests sind Pflicht.
  - `DesignSystem` – Tokens (Palette, Layout, Typography), Glass-Bausteine, `DayArc`, Karten.
  - `Features` – Bildschirme: Today, Qibla, Guide, Verses, Qada, Settings, Onboarding.
- Einzige Fremdabhängigkeit: **Adhan Swift** (MIT) für die Gebetszeiten. Dazu eingebettet die Schriften **Amiri** und **Amiri Quran** (SIL OFL 1.1, seit Phase 13); Seit Phase 18 kommen fremde Inhalte dazu (Spec § 11): die Adhan-Aufnahme von DARSA TV (CC BY), der arabische Verstext nach Tanzil (CC BY 3.0) und die Ausschnitte der Vers-Übersetzungen (vorläufige Auswahl, bei Tanzil nur für nicht kommerzielle Zwecke). Herkunft, Versionen, Bedingungen und Prüfsummen in `docs/THIRD-PARTY.md`, Lizenzen und Hinweise in der App unter Einstellungen › Über › Lizenzen. Keine Analytics, keine Crash-Reporter von Dritten, kein eigener Server. Netzwerk nur über Apple-Dienste (Ortssuche, Geocoding).
- Daten bleiben auf dem Gerät (`@AppStorage`/UserDefaults, auch für das Nachholen – entschieden am 12.11.2026 statt SwiftData). App Group für Widgets und Live Activity.
- Texte: String Catalog `Localizable.xcstrings` mit 16 Sprachen (DE, TR, EN, ES, FR, NL, BS, SQ, AR, UR, ID, MS, BN, FA, RU, IT; Spec § 9.10), erzeugt aus `T` – dazu die Übersetzungen der Verse aus `VERSES`, die Namen der Suren aus `SURAH` und die Mehrzahlformen aus `PLURAL` (seit Phase 15). Die zwölf Sprachen ab FR sind KI-Entwürfe („Needs Review“ im Katalog). AR, UR und FA laufen von rechts nach links; Ziffern und Kalender wie das System der Region (Spec § 9.10). Keine fest verdrahteten Texte.
- Systemkomponenten bevorzugen: `TabView`, `NavigationStack`, `.glassEffect`, `GlassEffectContainer`, `.buttonStyle(.glass)`, `.searchable`, `.sheet`, `Text(timerInterval:)`, `Calendar(identifier: .islamicUmmAlQura)`. Eigene Leisten nur dort, wo die Spec sie verlangt (Chips oben im Gebete-Tab).
- Barrierefreiheit wie in der Spec: Dynamic Type bis AX, VoiceOver-Labels, 44-pt-Tippziele, Reduce Motion, Farbe nie als einziges Signal.

## Debug-Simulation (für den 1:1-Abgleich)

Nur in DEBUG: Startargumente, mit denen sich jeder Referenz-Screenshot nachstellen lässt.

```
-debugSkipOnboarding
-debugFixtureTimes            # Mock-Zeiten aus dem Prototyp statt echter Berechnung → gleiche Zahlen wie auf den Screenshots
-debugDate 2026-11-10
-debugTime 14:25              # Uhr läuft ab hier weiter
-debugCity berlin|istanbul|madrid|mecca|jakarta
-debugHighLatitude            # Berlin, 21. Juni
-debugLocationDenied  -debugOffline
-debugTab today|qibla|guide|verses|qada|settings
          method|asr|madhab|hl|adjust|perPrayer|reminder|live|alarm|sound|appearance|style|language|privacy|licenses|support|adhan|city|kerahat   # Seiten der Einstellungen (PAGES; licenses nur in der App), adhan = Adhan-Sheet, city = Stadt-Sheet, kerahat = Blatt „Was sind Verbotszeiten?“
-debugOnboarding 1|2|3|4|5    # Onboarding ab diesem Schritt, auch wenn es schon durchlaufen ist (3 = Rechtsschule, seit dem Nachtrag zu Phase 18)
-debugMadhab hanafi|maliki|shafii|hanbali   # Rechtsschule für die Verbotszeiten (Spec § 11.6)
-debugAccent teal|green|…|sand   # Grundfarbe, Kennungen wie ACCENTS im Prototyp (Spec § 11.7)
-debugLiveStyle full|arc|mono  -debugLiveInverted   # Stil der Live-Aktivität und des Widgets mit dem Bogen (system/97–99)
-debugSound system|adhan|silent   # Klang der Mitteilungen (iphone/80-settings-sound-system)
-debugDayOffset 1             # Zeiten-Seite zeigt einen anderen Tag, −365 bis 365 (iphone/23)
-debugWalk dhuhr              # „Gebet Schritt für Schritt“ für dieses Gebet offen, über der Anleitung (iphone/43–49)
-debugWalkStep 9              # Seite des Durchlaufs wie S.walk.i: 0 = Start, die letzte = „Gebet beendet“
-debugQiblaHeading 137
-debugQiblaAccuracy 40        # Genauigkeit des Kompasses; über 25° erscheint die Kalibrierungskarte (iphone/30–32)
-debugNotifications           # echte Mitteilungen auch mit Mock-Zeiten, fragt beim Start nach der Erlaubnis (system/92)
-debugLiveActivity            # Live-Aktivität zum nächsten Gebet sofort, auch außerhalb des Vorlaufs und mit Mock-Zeiten (system/93–96)
-debugAlarm before|fixed|denied   # Wecker zu Fadschr an (vor Sonnenaufgang / feste Uhrzeit mit kurzem Adhan) oder Erlaubnis abgelehnt, nur mit -debugFixtureTimes (iphone/24, 84)
-debugAlarmIn 2               # ein echter Wecker (AlarmKit) so viele Minuten nach dem Start – zum Test von Ton, Stummmodus und Fokus am Gerät
-debugCatalog arc|rows|glass|cards|compass|guide|steps|verses|qada|settings|onboarding|adhan|widgets|live|carplay|all   # Katalog der Bausteine statt der App, für den Abgleich (make compare, make compare-system); carplay = kleine Widgets ohne Hintergrund (Phase 19)
```

Uhrzeit, Datum und Ort laufen über eine injizierbare `Clock`/`LocationSource`, nie direkt über `Date()` oder `CLLocationManager` in den Views.

## Arbeitsweise

- In Phasen nach `docs/BUILD-PLAN.md`. Pro Phase: erst Plan (Dateien, Typen, offene Fragen), nach Freigabe bauen, dann prüfen.
- **Prüfen** heißt:
  1. `xcodebuild build` und `xcodebuild test` laufen grün.
  2. Simulator iPhone 18 Pro (iOS 26) mit den Debug-Argumenten des Referenzbilds starten.
  3. Screenshot mit `xcrun simctl io booted screenshot` aufnehmen.
  4. Neben die Referenz aus `design/screenshots/` legen.
  5. Abweichungen bei Abständen, Größen, Farben, Texten und Zuständen auflisten und beheben.
- Befehle: `make build`, `make test`, `make run`, `make screenshot` (Übersicht mit `make help`, Einzelheiten in `README.md`). Andere Sprachen: `make run LANGUAGE=ar`, Abgleich mit dem Prototyp in derselben Sprache `make compare-language LANGUAGE=ar`. Das Xcode-Projekt entsteht mit `make project` aus `project.yml`. Die Build-Daten liegen auf der externen Platte „Extern“ (`/Volumes/Extern/Builds/NamazVakti`), weil die interne Platte knapp ist – `xcodebuild` deshalb nicht ohne `-derivedDataPath` aufrufen.
- Kleine Commits pro abgeschlossenem Schritt, Phase im Commit-Text (`Phase 3: Zeiten-Seite – Gebetskarten`).
- Keine neuen Funktionen über Spec und Screenshots hinaus.
