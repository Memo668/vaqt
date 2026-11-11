# Gebetszeiten – iOS-App (SwiftUI)

Gemeinnützige Gebetszeiten-App: werbefrei, ohne Tracking, ohne Konto. Wir bauen den Designprototyp aus `design/` **eins zu eins** als native SwiftUI-App nach – gleiche Bildschirme, gleiche Abstände, Farben, Texte und gleiches Verhalten.

## Quellen der Wahrheit

1. `design/prayer-times-design-spec.md` – Design Spec v0.7: Tokens, Komponenten, Verhalten, Zustände, iPhone Duo (§ 8), offene Fragen (§ 6), Varianten (§ 7).
2. `design/screenshots/` – Referenzbilder je Bildschirm und Zustand. Übersicht: `design/screenshots/INDEX.md`.
3. `design/prayer-times-prototype.html` – Quelltext des Prototyps (~2 400 Zeilen, nicht komplett einlesen, gezielt suchen):
   - Tokens: `:root`-CSS am Anfang (Farben hell/dunkel, Abstände, Radien, Schriftgrößen)
   - alle Texte DE/TR/EN/ES: JS-Objekt `T`
   - Logik: `todayTimes()`, `phase()`, `phaseKey()`, `kerahatWins()`, `activeKerahat()`, `guideState()`, `dayProgress()`, `ARCS` + `arcHTML()`, `qadaPage()`
   - Daten: `METHODS`, `RAKAH`, `GUIDE_STEPS`, `FORMULA`, `VERSES`, `KERAHAT_MIN`
   - Seiten: `homePage()`, `prayerRow()`, `topBarHTML()`, `qiblaPage()`, `guidePage()`, `versesPage()`, `qadaPage()`, `PAGES` (Einstellungen), `laBanner()`/`diExpanded()` (Live-Aktivität)

Werte und Formeln von dort übernehmen, nicht schätzen. Bei Widerspruch gilt: Spec > Screenshot > HTML. Ist etwas unklar, frag nach oder trag es in `docs/OPEN-QUESTIONS.md` ein – nicht raten.

## Nicht übernehmen

- Das Prototyp-Panel links (Simulation, Varianten-Schalter) ist nur Werkzeug. Von den Varianten gilt immer die Standardwahl aus Spec § 7.
- Die Mock-Zeiten (`CITIES`, `BERLIN_SUMMER`) – die App rechnet echt. Die Mock-Zeiten dienen nur als Test-Fixture (siehe Debug).
- CSS-Nachbauten von Systemelementen (Statusleiste, Dynamic Island, Liquid Glass, Alerts, Sheets) – dafür echte iOS-APIs.
- Platzhalter-Übersetzungen der Verse und Adhan-Stimmen bleiben als `TODO(placeholder)` markiert und gehen so nicht in den App Store.

## Technik

- Aktuelles Xcode, Swift 6 (strict concurrency), SwiftUI. Mindestversion **iOS 26** (Liquid Glass, geplante Live-Aktivitäten).
- Struktur: App-Target + Widget-Extension (Widgets und Live Activity) + lokale Swift-Pakete:
  - `PrayerCore` – reine Logik ohne UI: Berechnung, Tagesphase, Kerahat, Qibla, Hijri, Nachholen, Daten der Anleitung. Unit-Tests sind Pflicht.
  - `DesignSystem` – Tokens (Palette, Layout, Typography), Glass-Bausteine, `DayArc`, Karten.
  - `Features` – Bildschirme: Today, Qibla, Guide, Verses, Qada, Settings, Onboarding.
- Einzige Fremdabhängigkeit: **Adhan Swift** (MIT) für die Gebetszeiten. Keine Analytics, keine Crash-Reporter von Dritten, kein eigener Server. Netzwerk nur über Apple-Dienste (Ortssuche, Geocoding).
- Daten bleiben auf dem Gerät (`@AppStorage`/UserDefaults, SwiftData für Nachholen). App Group für Widgets und Live Activity.
- Texte: String Catalog `Localizable.xcstrings` mit DE, TR, EN, ES, erzeugt aus `T`. Keine fest verdrahteten Texte.
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
-debugQiblaHeading 137
-debugQiblaAccuracy 40        # Genauigkeit des Kompasses; über 25° erscheint die Kalibrierungskarte (iphone/30–32)
-debugCatalog arc|rows|glass|cards|compass|all   # Katalog der Bausteine statt der App, für den Abgleich (make compare)
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
- Befehle: `make build`, `make test`, `make run`, `make screenshot` (Übersicht mit `make help`, Einzelheiten in `README.md`). Das Xcode-Projekt entsteht mit `make project` aus `project.yml`. Die Build-Daten liegen auf der externen Platte „Extern“ (`/Volumes/Extern/Builds/NamazVakti`), weil die interne Platte knapp ist – `xcodebuild` deshalb nicht ohne `-derivedDataPath` aufrufen.
- Kleine Commits pro abgeschlossenem Schritt, Phase im Commit-Text (`Phase 3: Zeiten-Seite – Gebetskarten`).
- Keine neuen Funktionen über Spec und Screenshots hinaus.
