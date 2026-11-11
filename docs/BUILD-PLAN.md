# Bauplan – Gebetszeiten (SwiftUI)

Elf Phasen, jede für sich abnehmbar. Pro Phase stehen hier Ziel, Inhalt, die passenden Referenz-Screenshots und die Abnahme. Regeln und Prüfablauf: `CLAUDE.md`.

## Vor dem Start: Entscheidungen (Standardwerte, falls nichts anderes gesagt wird)

| Thema | Standard | Spec |
|---|---|---|
| Arbeitstitel / Bundle-ID | „Gebetszeiten“ / `com.example.gebetszeiten` (vor dem ersten Archiv ersetzen) | § 6.9 |
| Mindestversion | iOS 26 | § 6.10 |
| Rechenbibliothek | Adhan Swift (MIT) | § 6.3 |
| Automatische Methode | DE, AT und TR → Diyanet, ES → MWL, SA → Umm al-Qura, ID → Kemenag, US und CA → ISNA, EG → Egyptian, PK, IN, BD und AF → Karachi, MY → JAKIM, SG → Singapore, IR → Tehran, alle übrigen Länder MWL (entschieden am 10.11.2026) | § 5, § 6.1 |
| Kerahat-Dauern | 45 / 10 / 45 Min. als Konstanten in `PrayerCore` | § 6.15 |
| Vers-Übersetzungen, Adhan-Aufnahmen | Platzhalter, markiert mit `TODO(placeholder)` | § 6.5, § 6.12 |
| Varianten | jeweils die erste Option aus § 7 | § 7 |

---

## Phase 0 – Projektgerüst

- Xcode-Projekt, App-Target, Widget-Extension (WidgetKit und ActivityKit), App Group.
- Lokale Pakete `PrayerCore`, `DesignSystem`, `Features` mit Test-Targets.
- Adhan Swift per Swift Package Manager einbinden.
- Skript `scripts/import-strings` liest das Objekt `T` aus `design/prayer-times-prototype.html` und erzeugt `Localizable.xcstrings` (DE, TR, EN, ES, Platzhalter `{x}` → `%@`).
- `Clock`/`LocationSource`-Protokolle, Debug-Startargumente laut `CLAUDE.md`, Fixture mit den Mock-Zeiten.
- `README.md` mit den Build-, Test- und Simulator-Befehlen.

**Abnahme:** App startet im Simulator mit einer leeren `TabView` (Gebete, Verse, Nachholen). `xcodebuild test` ist grün. Der String Catalog enthält alle Schlüssel aus `T`.

## Phase 1 – PrayerCore (Logik, ohne UI)

- **Gebetszeiten:**
  - Methoden aus `METHODS`; Adhan-Voreinstellungen, wo es sie gibt, sonst eigene Winkel.
  - Asr: Standard oder Hanafi.
  - Hohe Breiten: Winkelbasiert, Siebtel der Nacht, Nachtmitte.
  - Minutenkorrekturen ±30.
- **Tagesphase** wie `phase()`:
  - Zeitstrahl über drei Tage.
  - Sonnenaufgang beendet Fadschr.
  - Ischa darf nach Mitternacht liegen.
  - Ergebnis: aktuelles Gebet, nächstes Ereignis, Restzeit, Fortschritt im Bogen.
- **Kerahat-Fenster** wie `kerahatWins()` und `activeKerahat()`.
- **Qibla:** Richtung und Entfernung zur Kaaba.
- **Hijri-Datum:** Umm al-Qura.
- **Anleitung:** `guideState()` (aktuelles bzw. nächstes Gebet, manuelle Wahl) und die Daten aus `RAKAH`, `GUIDE_STEPS`, `FORMULA`.
- **Nachholen:**
  - offene und erledigte Gebete, Anteil in Prozent
  - Zeitraum → Tage (Jahr 365, Monat 30)
  - Witr optional
  - voraussichtliches Ende
- **Tests:**
  - alle Fälle aus Spec § 4: vor Fadschr, nach Sonnenaufgang, nach Ischa, Ischa nach Mitternacht, Jakarta Maghrib → Ischa
  - Kerahat am Rand der Fenster
  - Nachholen-Formeln
  - Anleitung bei Zeitwechsel
  - Berechnung gegen Referenzwerte aus den Adhan-Testdaten; die Mock-Zeiten nur als Plausibilität (±5 Min.)

**Abnahme:** Testabdeckung von `PrayerCore` über 90 %, alle Tests grün.

## Phase 2 – DesignSystem

- Tokens aus dem `:root`-CSS:
  - Farben hell/dunkel; Pine Teal ist der Akzent; `arc-track` und `kerahat`
  - Abstände, Radien (26/18), Typo-Skala
  - Countdown 64 pt, im Bogen 56 pt
- Glass-Bausteine: runder Glass-Button, Chip (normal / getönt ausgewählt), schwebende Leiste.
- **DayArc** nach Spec und `ARCS.home`/`arcHTML()`:
  - Kreisbogen ≈ 128°, 12 pt dick
  - Marker mit Symbol (30/34 pt), Zeiten außen am Bogen
  - weißer Knopf für „jetzt“
  - Kerahat-Segmente innen am Bogen
  - Ring, wenn zwei Marker eng beieinander liegen
  - RTL-Spiegelung ohne gespiegelte Zahlen
  - eine kleine Variante (`ARCS.la`) für die Live-Aktivität
- Gebetskarte (`PrayerRow`) mit Glocke und Kerahat-Zeile; Karte, Fakten-Kachel, Stepper-Pille.
- Ein Preview-Katalog mit allen Bausteinen in hell/dunkel.

**Referenzen:** `iphone/10`–`22` (Bogen und Karten).

**Abnahme:** Die Previews des Bogens für 14:25, vor Fadschr, 08:04, 07:30, 16:05, nach Ischa, Jakarta und RTL stimmen mit den Screenshots überein.

## Phase 3 – Gebete-Tab: Zeiten

- Obere Leiste:
  - Einstellungskreis plus die Chips Zeiten, Qibla und Anleitung (`GlassEffectContainer`)
  - `ViewThatFits`: Reicht der Platz nicht, werden die nicht gewählten Chips zu Kreisen.
- Pager mit drei Seiten: wischen oder Chip antippen.
- Zeiten-Seite:
  - Stadt, gregorianisches und Hijri-Datum
  - Banner „Standort aus“, Offline-Hinweis
  - Bogen mit Countdown
  - sechs Gebetskarten; die Glocke wechselt Ton → Lautlos → Aus, mit Toast
  - Hinweis bei hohen Breiten
- Stadt-Sheet: aktueller Standort, gespeicherte Städte, Suche mit `MKLocalSearchCompleter`; offline nur gespeicherte Städte.
- Standortabfrage „Beim Verwenden der App“; Geocoding für den Stadtnamen.

**Referenzen:** `iphone/10`–`22`, `iphone/85`.

**Abnahme:** Jeder Referenzzustand lässt sich mit den Debug-Argumenten nachstellen und weicht höchstens um 1–2 pt ab.

Gebaut am 11.11.2026. Abgleich mit `make compare-today`; was übereinstimmt, was abweicht und was angenommen ist, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 3“). Qibla, Anleitung und die Einstellungen sind als leere Seiten angelegt.

## Phase 4 – Qibla

- Kompass mit Kurs aus `CLLocationManager` (geografisch Nord):
  - Skala mit 5°-Strichen, aufrechte Himmelsrichtungen, N in Rot
  - Qibla-Nadel und Kaaba-Marke
- Statuszeile „Nach rechts drehen 38°“; bei ±3 ° Akzentfarbe und Haptik.
- In Mekka eine Meldung statt der Nadel.
- Kalibrierungskarte nur bei schlechter `headingAccuracy`.

**Referenzen:** `iphone/30`–`32`.

## Phase 5 – Anleitung

- Auswahl der fünf Gebete; ein Punkt markiert das aktuelle.
- Kopfkarte:
  - Status und Zeitfenster
  - drei Fakten-Kacheln
  - Rakʿa-Folge
  - Hinweis „ab der 3. Rakʿa nur al-Fātiḥa“
  - Knopf zurück zum aktuellen Gebet
- „Vorher“ (mit Sprung zur Qibla-Seite) und „Ablauf“ mit Haltungsfiguren und arabischen Formeln samt Umschrift.
- Automatik wie `guideState()`: Die manuelle Wahl gilt, bis das aktuelle Gebet wechselt oder man die Seite verlässt.

**Referenzen:** `iphone/40`–`42`.

## Phase 6 – Verse und Nachholen

- **Verse:**
  - Vers des Tages auf Arabisch, mit Übersetzung (Platzhalter) und Quelle
  - Teilen über `ShareLink`, Kopieren
  - Liste der letzten Tage
- **Nachholen:**
  - Prozent als größte Zahl, Balken, „x von y nachgeholt · noch n offen“
  - pro Gebet ein Stepper
  - Plan pro Tag mit voraussichtlichem Ende
  - Rechner für den verpassten Zeitraum, Witr-Schalter, „Als offen übernehmen“

**Referenzen:** `iphone/50`, `51`, `60`, `61`.

## Phase 7 – Einstellungen, Onboarding, Adhan

- Einstellungen als `NavigationStack` mit allen Unterseiten aus `PAGES`:
  - Methode (durchsuchbar, Automatik je Land), Asr, hohe Breiten, Minutenkorrektur
  - Mitteilungen pro Gebet, Vorab-Erinnerung, Live-Aktivität (Aus/30/60), Klang
  - Darstellung, Sprache, Kerahat-Schalter
  - Datenschutz, Quellcode, Version
- Onboarding in drei Schritten, Standort und Mitteilungen erst nach dem jeweiligen Vorab-Bildschirm abfragen. Die Standortabfrage, die die Zeiten-Seite seit Phase 3 beim ersten Start selbst stellt, wandert dann hinter den Vorab-Bildschirm.
- Adhan-Sheet: Wellenform, Scrubber, Play/Pause, Stimmen (Platzhalter), Fadschr-Variante; Clips höchstens 30 s.

**Referenzen:** `iphone/01`–`04`, `70`–`81`, `86`.

## Phase 8 – Mitteilungen

- `UNUserNotificationCenter`, rollierendes Fenster wegen des Limits von 64 ausstehenden Mitteilungen.
- Neu planen beim Start, bei Hintergrundaktualisierung und nach jeder Änderung der Einstellungen.
- Status pro Gebet (Ton/Lautlos/Aus), Vorab-Erinnerung, Texte laut Spec.

**Referenz:** `system/92`.

## Phase 9 – Widgets und Live-Aktivität

- **Widgets:** systemSmall, systemMedium, accessoryCircular, accessoryRectangular, accessoryInline; Zeitleiste aus `PrayerCore` über die App Group.
- **Live-Aktivität** (ActivityKit):
  - Sperrbildschirm mit dem kleinen Bogen auf Akzent-Hintergrund
  - Dynamic Island kompakt, minimal und erweitert (Balken mit Kerahat-Linie)
  - Start pro Gebet mit `Activity.request(…, start:)`
  - `staleDate` liegt auf dem Gebetsbeginn, `isStale` zeigt dann „Jetzt: …“
  - endet 15 Min. nach Beginn; Vorlauf laut Einstellung

**Referenzen:** `system/90`, `91`, `93`–`96`.

## Phase 10 – iPhone Duo

- Größenklassen: außen compact, innen regular.
- `TabView`/`NavigationStack` legen die Leisten auf dem Duo selbst senkrecht an den rechten Rand – prüfen, nicht nachbauen.
- Innen ab regular width zwei Spalten, die sich am Falz treffen, wie in Spec § 8.
- Sheets innen als mittige Karte.
- Gibt es noch keinen Duo-Simulator: mit einem Simulator in regular width prüfen und das dokumentieren.

**Referenzen:** `duo/*`.

## Phase 11 – Feinschliff

- **Sprachen:** TR, EN und ES auf Textlängen prüfen.
- **Darstellung:** Dynamic Type bis AX5, Dark Mode.
- **Barrierefreiheit:** VoiceOver-Durchgang; RTL mit der Pseudosprache „Right-to-Left“.
- **Leistung:** Akku und Laufzeit prüfen.
- **App Store:** Datenschutzangabe „Keine Daten erfasst“, Platzhalter-Icon.
- `docs/OPEN-QUESTIONS.md` aufräumen.

**Abnahme:** Alle Screenshots aus `design/screenshots/` lassen sich nachstellen und stimmen überein.
