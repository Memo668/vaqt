# Bauplan – Gebetszeiten (SwiftUI)

Elf Phasen, jede für sich abnehmbar. Pro Phase stehen hier Ziel, Inhalt, die passenden Referenz-Screenshots und die Abnahme. Regeln und Prüfablauf: `CLAUDE.md`.

## Vor dem Start: Entscheidungen (Standardwerte, falls nichts anderes gesagt wird)

| Thema | Standard | Spec |
|---|---|---|
| Arbeitstitel / Bundle-ID | „Gebetszeiten“ / `de.mehmetyilmaz.gebetszeiten` (bis 15.11.2026 Platzhalter `com.example.gebetszeiten`; steht nur in `project.yml`); im App Store „Gebetszeiten – Namaz Vakti“ | § 6.9 |
| Mindestversion | iOS 26 | § 6.10 |
| Rechenbibliothek | Adhan Swift (MIT) | § 6.3 |
| Automatische Methode | DE, AT und TR → Diyanet, ES → MWL, SA → Umm al-Qura, ID → Kemenag, US und CA → ISNA, EG → Egyptian, PK, IN, BD und AF → Karachi, MY → JAKIM, SG → Singapore, IR → Tehran, alle übrigen Länder MWL (entschieden am 10.11.2026) | § 5, § 6.1 |
| Kerahat-Dauern | 45 / 10 / 45 Min. als Konstanten in `PrayerCore` | § 6.15 |
| Vers-Übersetzungen, Adhan-Aufnahme | Bis Phase 17 Platzhalter. Seit Phase 18 Ausschnitte veröffentlichter Übersetzungen (vorläufige Auswahl) und eine Aufnahme unter CC BY; Quellen in `docs/THIRD-PARTY.md` | § 6.5, § 6.12, § 11 |
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

Gebaut am 11.11.2026. Abgleich mit `make compare-qibla`; was übereinstimmt, was abweicht und was angenommen ist, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 4“). Der Kompass selbst ist im Simulator nur mit festem Kurs geprüft; Kurs, geografisch Nord, Kalibrierungskarte und Haptik brauchen ein echtes Gerät.

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

Gebaut am 12.11.2026. Abgleich mit `make compare-guide`, `iphone/41` und `42` mit dem UI-Hilfsprojekt; was übereinstimmt, was abweicht und was angenommen ist, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 5“). Die Haltungsfiguren sind die Strichpiktogramme des Prototyps; ob es echte Illustrationen werden und wer die Texte fachlich prüft, ist offen (Spec § 6.14).

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

Gebaut am 12.11.2026. Abgleich mit `make compare-verses` und `make compare-qada`, `iphone/61` mit dem UI-Hilfsprojekt; was übereinstimmt, was abweicht und was angenommen ist, steht in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 6“). Das Nachholen liegt in den UserDefaults der App und startet leer; ohne Einträge fehlen Zusammenfassung und Plan (entschieden am 12.11.2026). Die Übersetzungen der Verse sind Platzhalter (Spec § 6.12).

## Phase 7 – Einstellungen, Onboarding, Adhan

- Einstellungen als `NavigationStack` mit allen Unterseiten aus `PAGES`:
  - Methode (durchsuchbar, Automatik je Land), Asr, hohe Breiten, Minutenkorrektur
  - Mitteilungen pro Gebet, Vorab-Erinnerung, Live-Aktivität (Aus/30/60), Klang
  - Darstellung, Sprache, Kerahat-Schalter
  - Datenschutz, Quellcode, Version
- Onboarding in drei Schritten, Standort und Mitteilungen erst nach dem jeweiligen Vorab-Bildschirm abfragen. Die Standortabfrage, die die Zeiten-Seite seit Phase 3 beim ersten Start selbst stellt, wandert dann hinter den Vorab-Bildschirm.
- Adhan-Sheet: Wellenform, Scrubber, Play/Pause, Stimmen (Platzhalter), Fadschr-Variante; Clips höchstens 30 s.

**Referenzen:** `iphone/01`–`04`, `70`–`81`, `86`.

Gebaut am 12.11.2026 in drei Teilschritten: Einstellungen (Liste des Systems, eigene Sprachwahl, Hinweis bei Moonsighting), Onboarding, Adhan-Sheet mit zwei freien Aufnahmen von Wikimedia Commons als Platzhalter (Stimme 3 und Fadschr-Variante stumm). Abgleich mit `make compare-settings` über die Debug-Argumente `-debugTab settings|method|…|adhan` und `-debugOnboarding 1|2|3`, `iphone/71` und `72` mit dem UI-Hilfsprojekt; was übereinstimmt, was abweicht und was angenommen ist, steht in `docs/OPEN-QUESTIONS.md` („Entschieden mit dem Plan für Phase 7“, „Annahmen in Phase 7“).

## Phase 8 – Mitteilungen

- `UNUserNotificationCenter`, rollierendes Fenster wegen des Limits von 64 ausstehenden Mitteilungen.
- Neu planen beim Start, bei Hintergrundaktualisierung und nach jeder Änderung der Einstellungen.
- Status pro Gebet (Ton/Lautlos/Aus), Vorab-Erinnerung, Texte laut Spec.

**Referenz:** `system/92`.

Gebaut am 12.11.2026 in drei Schritten.
- **PrayerCore:** `NotificationPlanner` plant die nächsten 64 Mitteilungen samt Erinnerungen, mit Texten und Tönen; dazu Tests mit Mock-Zeiten, Zeitzonen, Sommerzeit, hohen Breiten und Mitternacht.
- **Features und App:** Die App merkt die Mitteilungen über `UNUserNotificationCenter` vor. Neu geplant wird beim Start, wenn die App nach vorn kommt, nach jeder Änderung und bei der Hintergrundaktualisierung (`BGAppRefreshTask`).
- **Abgleich:** `system/92` mit dem neuen Debug-Argument `-debugNotifications` und dem UI-Hilfsprojekt.

Entscheidungen, Annahmen und was abweicht stehen in `docs/OPEN-QUESTIONS.md` („Entschieden mit dem Plan für Phase 8“, „Annahmen in Phase 8“).

## Phase 9 – Widgets und Live-Aktivität

- **Widgets:** systemSmall, systemMedium, accessoryCircular, accessoryRectangular, accessoryInline; Zeitleiste aus `PrayerCore` über die App Group.
- **Live-Aktivität** (ActivityKit):
  - Sperrbildschirm mit dem kleinen Bogen auf Akzent-Hintergrund
  - Dynamic Island kompakt, minimal und erweitert (Balken mit Kerahat-Linie)
  - Start pro Gebet mit `Activity.request(…, start:)`
  - `staleDate` liegt auf dem Gebetsbeginn, `isStale` zeigt dann „Jetzt: …“
  - endet 15 Min. nach Beginn; Vorlauf laut Einstellung

**Referenzen:** `system/90`, `91`, `93`–`96`.

Gebaut am 12.11.2026 in vier Schritten.
- **PrayerCore:** `WidgetTimeline` liefert die Einträge der Zeitleiste. `LiveActivityPlanner` und `LiveActivityLifecycle` planen je Gebet eine Aktivität mit Vorlauf, `staleDate` zum Gebetsbeginn und Ende 15 Minuten danach, höchstens fünf, und entscheiden, was mit bestehenden geschieht. Dazu Tests mit Mock-Zeiten, Zeitzonen, hohen Breiten, Mitternacht und Sommerzeit.
- **DesignSystem:** der Stand in der App Group (`WidgetState`), `PrayerActivityAttributes`, die fünf Widgets und die Live-Aktivität; im Katalog `-debugCatalog widgets` und `live`.
- **Features, App, Extension:** Die App schreibt den Stand, lädt die Widgets neu und plant die Live-Aktivitäten beim Start, im Vordergrund, nach jeder Änderung und bei der Hintergrundaktualisierung; dabei enden alte. Neu sind das Debug-Argument `-debugLiveActivity` und der Vorlauf Aus bis 120 Minuten.
- **Abgleich:** `make compare-system` im Katalog, im System mit dem UI-Hilfsprojekt.

Entscheidungen, Annahmen und was abweicht stehen in `docs/OPEN-QUESTIONS.md` („Entschieden mit dem Plan für Phase 9“, „Annahmen in Phase 9“).

## Phase 10 – iPhone Duo

- Größenklassen: außen compact, innen regular.
- `TabView`/`NavigationStack` legen die Leisten auf dem Duo selbst senkrecht an den rechten Rand – prüfen, nicht nachbauen.
- Innen ab regular width zwei Spalten, die sich am Falz treffen, wie in Spec § 8.
- Sheets innen als mittige Karte.
- Gibt es noch keinen Duo-Simulator: mit einem Simulator in regular width prüfen und das dokumentieren.

**Referenzen:** `duo/*`.

Gebaut am 12. und 13.11.2026 in drei Schritten.
- **DesignSystem:** `PageArrangement` und `Fold` – untereinander, zwei Spalten am Falz (auch in RTL), Tischhaltung über und unter dem Falz; gemessen mit `readsPageArrangement()` am Falz, den das System meldet (`ReservedRegion` `.division`, iOS 27.1). Dazu die senkrechte Leiste (`readsVerticalBarEdge()`), die mittige 600-pt-Spalte, die Sheet-Karte und Tests.
- **Features:** die fünf Seiten in zwei Teilen (`PageScroll`), Einstellungskreis und Chips als Einträge der senkrechten Leiste, Einstellungen und Sheets innen mittig, Toast und Onboarding für das Duo; neues Debug-Argument `-debugTab city`. Spec-Frage 17 ist mit „Alle drei“ entschieden: Hochformat innen, Tischhaltung und Split View laufen.
- **Abgleich:** `make compare-duo MODE=open|closed` auf dem Simulator „iPhone Duo“ (Runtime iOS 27.2, Build 24B91016s); Auf- und Zuklappen in Device Hub. Auf dem iPhone 18 Pro bleibt alles pixelgleich.

Entscheidungen, Annahmen und was abweicht stehen in `docs/OPEN-QUESTIONS.md` („Entschieden mit dem Plan für Phase 10“, „Annahmen in Phase 10“).

## Phase 11 – Feinschliff

- **Sprachen:** TR, EN und ES auf Textlängen prüfen.
- **Darstellung:** Dynamic Type bis AX5, Dark Mode.
- **Barrierefreiheit:** VoiceOver-Durchgang; RTL mit der Pseudosprache „Right-to-Left“.
- **Leistung:** Akku und Laufzeit prüfen.
- **App Store:** Datenschutzangabe „Keine Daten erfasst“, Platzhalter-Icon.
- `docs/OPEN-QUESTIONS.md` aufräumen.

**Abnahme:** Alle Screenshots aus `design/screenshots/` lassen sich nachstellen und stimmen überein.

Gebaut am 13.11.2026 in acht Schritten:
- **Werkzeug:** Das UI-Hilfsprojekt liegt jetzt im Repo (`scripts/ui-harness`, `make harness`). `make capture` nimmt jeden Bildschirm in Varianten auf – Sprache, Schriftgröße, hell und dunkel, RTL –, mit der Prüfung der Bedienungshilfen von Xcode.
- **Sprachen:** In TR, EN und ES wird bei Standardgröße nichts abgeschnitten; die türkische Endung der Vorab-Erinnerung rechnet die App (`TurkishClockSuffix`).
- **Große Schrift und dunkel:** Ab den AX-Größen stellen sich Gebetskarte, Fakten-Kacheln und Stepper-Zeilen um. Die Zeile im Bogen und der gewählte Chip sind begrenzt, die Widgets wachsen bis zum 1,2-Fachen. Silbentrennung mit dem Wörterbuch des Systems.
- **Barrierefreiheit:** VoiceOver-Texte, Tippziele, Bewegung, Kontrast (`ContrastTests`, dunklere Schrift auf der laufenden Karte), RTL. Eine getönte Fläche in der senkrechten Leiste des Duo lässt das System nicht zu (das Symbol wird darauf weiß); es bleibt beim Symbol in Akzent.
- **Leistung:** CPU-Zeit je Zustand im Simulator.
- **App Store:** Datenschutz-Manifeste, Platzhalter-Icon (Tagesbogen), Angaben in `docs/APP-STORE.md`.
- **Offene Fragen aufgeräumt** und **Schlussabgleich** der Referenzbilder (`docs/REFERENCE-CHECK.md`): 56 von 64 abgeglichen; die acht Bilder des aufgeklappten Duo nicht, weil das Aufklappen den Nutzer braucht („Ohne innen abschließen“).

Entscheidungen, Annahmen und was abweicht stehen in `docs/OPEN-QUESTIONS.md` („Entschieden mit dem Plan für Phase 11“, „Annahmen in Phase 11“).

**Danach:** erste Beta über TestFlight (entschieden am 12.11.2026). Ohne Konto vorbereitet am 14.11.2026: Release-Archiv mit Prüfung (`make archive`, `scripts/check-archive`), nur iPhone, Exportkontrolle, Bundle-ID nur in `project.yml`, Datenschutzerklärung (`docs/DATENSCHUTZ.md`, `docs/PRIVACY.md`) und Texte für TestFlight (`docs/APP-STORE.md`). Was dann noch fehlt – Konto, Kennungen festlegen und registrieren, App Store Connect, signiertes Archiv und Upload –, steht in `docs/OPEN-QUESTIONS.md` unter „Für die erste Beta“.

## Änderungen vor der Beta (Phasen 12–15)

Am 15.11.2026 hat der Nutzer zwölf Änderungen gewünscht und im Prototyp abgenommen („Passt, umsetzen“). Beschreibung: Spec § 9. Referenz: `design/prayer-times-prototype.html` (Panel › „Änderungen vom 15.11.2026“ springt zu jeder Änderung). Für die geänderten Bildschirme gibt es noch keine Referenzbilder in `design/screenshots/`: Jede Phase nimmt sie aus dem Prototyp neu auf (gleiche Simulation, iPhone 17 hell und dunkel) und gleicht dagegen ab. Die erste Beta kommt nach Phase 15.

## Phase 12 – Änderungen am Bestand

*Gebaut am 15.11.2026 auf dem Zweig `phase-12` (ab `eeeb46d`), geprüft gegen die Referenzbilder aus dem Prototyp v0.8; Annahmen in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 12“.*

- **App-Symbol** statt Mondsichel: Onboarding, Zeile am Ende der Einstellungen (Spec § 9.1); Bildsatz mit hell/dunkel.
- **Obere Leiste mittig**, Einstellungskreis rechts, Zusammenklappen wie bisher; Duo-Leiste unverändert (§ 9.2).
- **Kerahat auf der Spur** des Bogens, Uhrzeiten weiter in den Zeilen (§ 9.3).
- **Tage vor und zurück** auf der Zeiten-Seite, ±365 Tage, Textlink „Zurück zu heute“; ein anderer Tag ohne Countdown, mit relativem Tag und Datum (§ 9.4). PrayerCore rechnet dafür die Zeiten für ein beliebiges Datum (Tests: Sommerzeitwechsel, hohe Breiten).
- **Qibla-Toleranz** ±40° als Keil, Status „Im Toleranzbereich“ (§ 9.5).
- **Nachholen:** Rechner als eigene Karte ganz unten (§ 9.8).
- **Onboarding Seite 4** „Kostenlos. Ohne Werbung.“ und **Seite „Unterstützen“** in den Einstellungen, ohne Zahlung (§ 9.9).
- **Hohe Breiten:** vierte Regel „Manuelle Winkel“ mit Steppern 10–20° (§ 9.12); PrayerCore mit eigenen Winkeln und `.twilightAngle` als Grenze, Tests.
- Neue Texte zunächst in DE/TR/EN/ES (die übrigen Sprachen bringt Phase 15).
- Debug: `-debugDayOffset N` für einen anderen Tag; `-debugTab` kennt `support`.

## Phase 13 – Gebet Schritt für Schritt und arabische Schrift

*Gebaut am 15.11.2026 auf dem Zweig `claude/phase-13-cce599` (ab `0a3f9aa`, Phase 12 abgenommen), geprüft gegen die Referenzbilder aus dem Prototyp v0.8 (`iphone/40`–`51`, neu `43`–`49`); Annahmen in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 13“.*

- Vollbild-Durchlauf durch das ganze Gebet aus der Anleitung (Spec § 9.6): Ablauf aus `RAKAH` und den Schritten berechnen (PrayerCore `GuideWalk`, Tests: Fadschr 2, Maghrib 3, Dhuhr 4 Rakʿas → 15/22/28 Schritte, dazu Start und Ende), Fortschritt, Zurück/Weiter, Reduce Motion, VoiceOver. Knopf „Gebet Schritt für Schritt“ in der Kopfkarte; Vollbild über `fullScreenCover`; Dynamic Type bis AX (Kopf bis AX1, Knöpfe untereinander, wenn sie nicht passen).
- Amiri Quran für Verse, Amiri für Formeln einbetten (Release 1.003 von aliftype/amiri, `docs/THIRD-PARTY.md`), Lizenz (OFL) im Lizenzhinweis (§ 9.7): neue Seite Einstellungen › Über › Lizenzen mit Amiri und Adhan Swift (entschieden mit dem Plan).
- Die neuen Texte der Anleitung als ungeprüft kennzeichnen (wie § 6.14): Kommentar `TODO(review)` im String Catalog für alle Texte der Anleitung, die neuen mit Verweis auf § 9.6.
- Referenzbilder `43`–`49` (Durchlauf, drei davon dunkel) aus dem Prototyp, `make compare-walk`; `42` neu aufgenommen (stand seit Phase 12 gescrollt).
- Debug: `-debugWalk <Gebet>`, `-debugWalkStep N`; `-debugTab` kennt `licenses`.

## Phase 14 – Live-Aktivität und Widgets

*Gebaut am 15.11.2026 auf dem Zweig `claude/phase-14-306a00` (ab `066eb90`, Phase 13 abgenommen), geprüft gegen die Referenzbilder aus dem Prototyp v0.8 (`system/90`, `91`, `93`–`96` neu) im Katalog und im System; Annahmen in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 14“.*

- Live-Aktivität: Kerahat auf der Spur (Spec § 9.11).
- Sperrbildschirm-Widget (rechteckig) mit Bogen, einfarbig (entschieden mit dem Plan: das rechteckige); nach dem Änderungswunsch vom 15.11.2026 im Stil der Live-Aktivität: mittig, Gebete mit Symbol, Jetzt-Punkt mit Ring, Gebet und Countdown im Bogen, Kerahat gestreift.
- Neues mittleres Home-Widget „Live“ im Stil der Live-Aktivität; die bisherigen Widgets bleiben. In der Galerie heißt es wie die anderen „Vaqt“.
- Jetzt-Punkt der Widgets: Einträge zwischen Fadschr und Ischa und an den Grenzen der Kerahat-Fenster – im Widget „Live“ alle 5 Minuten, im Rechteck alle 10 Minuten (Archivgrenze von 10 MB), in den übrigen Größen keine (PrayerCore `WidgetTimeline.arcStep`, `lockScreenArcStep`).
- App-Symbol statt Mondsichel in Live-Aktivität und Widgets (Spec § 9.1).
- Debug-Katalog um die neuen Widgets erweitern (`-debugCatalog widgets|live`).
- Referenzbilder `system/90`–`96` aus dem Prototyp (`scripts/capture-prototype`), `make compare-system`, Aufnahmen im System mit dem UI-Hilfsprojekt.
- Name „Vaqt“ (Arbeitsname, Spec § 9.13): `CFBundleDisplayName` von App und Erweiterung, `T.appName` in allen 16 Sprachen, Name in den Dialogtexten; Store-Name „Vaqt – Prayer Time“. Bundle-ID, App Group, Targets und Typen bleiben.

## Phase 15 – Sechzehn Sprachen

*Gebaut am 15.11.2026 auf dem Zweig `claude/phase-15-9c9615` (ab `8431573`, Phase 14 abgenommen), abgeglichen gegen den Prototyp in derselben Sprache (`make compare-language`: AR, AR mit Region Saudi-Arabien, RU, FR, BN) und mit `make capture` in allen 16 Sprachen; Annahmen in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 15“.*

- String Catalog um FR, NL, BS, SQ, AR, UR, ID, MS, BN, FA, RU, IT aus `T` erweitert (Spec § 9.10); die zwölf Sprachen mit dem Status „Needs Review“, ebenso `App/InfoPlist.xcstrings`. Verse und Suren fallen auf Englisch zurück, Arabisch ohne Übersetzung.
- Plural-Varianten, wo Zahlen mit Zählwort vorkommen: Formen in `PLURAL` im Prototyp (15 Texte, Kategorien nach CLDR), im Katalog als `substitutions`, in `L10n` die Zahl als `Int`; `L10n.text` schreibt mit der Locale der Textsprache.
- Rechts nach links für AR, UR, FA geprüft und richtiggestellt: Leserichtung aus der Sprache der App (auch bei eigener Wahl in der App) in App, Widgets und Live-Aktivität; Zeitspannen mit dem Beginn rechts. Bogen, Pfeile, Spalten, Kompass, Durchlauf, Widgets und Live-Aktivität stimmen mit dem Prototyp.
- Ziffern wie das System (entschieden mit dem Plan): Persisch ۰–۹, Arabisch ٠–٩ nach Region, sonst 0–9 – in Uhrzeiten, Countdown, Zahlen, Datum und Texten. Datum im Kalender der Region (Persisch: persisch), ein islamischer bleibt gregorianisch.
- Textlängen in allen 16 Sprachen geprüft (`make capture`, Prüfung „textClipped“ von Xcode).
- Werkzeuge: `make compare-language` (Prototyp und App nebeneinander), `capture-prototype` mit `PROTO_LANG`, `capture-matrix` mit 16 Sprachen und den Bildschirmen der Phasen 12–14, `check-archive` mit 16 Sprachen.
- Die Übersetzungen sind KI-Entwürfe: vor dem App Store von Muttersprachlern prüfen lassen (`docs/OPEN-QUESTIONS.md`).

**Danach:** erste Beta über TestFlight, Ablauf in `docs/APP-STORE.md` („Mit dem Konto“); Konto, Team und Kennungen sind seit dem 15.11.2026 eingetragen.

## Phase 16 – Änderungen nach der ersten Beta

*Grundlage: Spec v0.9 § 10.1–10.7 und § 10.9, Prototyp „Änderungen vom 17./18.11.2026“, entschieden am 17./18.11.2026 (`docs/OPEN-QUESTIONS.md`). Danach Build 0.1.0 (3) für TestFlight.*

*Gebaut am 18.11.2026 auf `claude/phase-16` (ab `c17a65e`), 1023 Tests grün, geprüft im Simulator gegen die neuen Referenzbilder; Annahmen und Abweichungen in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 16“). Das Widget „Live“ bleibt deckend (iOS lässt es nicht durchscheinen).*

- **Texte:**
  - Neue und geänderte Schlüssel in `T`. DE, TR und EN sind entworfen.
  - ES und die zwölf weiteren Sprachen als KI-Entwurf ergänzen („Needs Review“).
  - `make strings`, dazu `App/InfoPlist.xcstrings` und der Standorttext in project.yml.
- **Bogen:** Mindestlänge der Kerahat-Abschnitte in `DayArcLayout` für alle Stile (Home, Live-Aktivität, Widget „Live“, Rechteck), mit Tests.
- **Verbotszeiten:** Die Kerahat-Zeilen werden zu Knöpfen mit Infopunkt. Dazu das Sheet „Was sind Verbotszeiten?“ und der Hinweis in der Anleitung zu Asr.
- **Live-Aktivität:**
  - Deckkraft 30 %, oranger Zustand, auch in der Dynamic Island.
  - Zwei Aktivitäten bei Dhuhr und Maghrib, im Planer und Lebenszyklus in PrayerCore, mit Tests.
  - Abgelaufene als schmale Zeile im `isStale`-Zustand, kein „Jetzt“, `relevanceScore` nach Startzeit.
- **Widget „Live“:** Deckkraft 30 %. Am Gerät prüfen, ob iOS durchscheinen lässt.
- **Onboarding:** neuer Titel, Schritt 2 mit Apple Karten, Schritt 3 mit Hinweis auf die Live-Aktivität.
- **Datenschutz:** Texte in der App, dazu `docs/DATENSCHUTZ.md` und `PRIVACY.md` (Apple Karten, Region bei der Stadtsuche, Rundung).
- **Nachholen:** Mann oder Frau mit Abzug von Regel und Wochenbett (PrayerCore, Tests). „Alles zurücksetzen“ mit Warnung.
- **Prüfen:**
  - Referenzbilder der betroffenen Bildschirme neu aus dem Prototyp (`scripts/capture-prototype`) und abgleichen.
  - System: Live-Aktivität, Dynamic Island und Widgets mit dem UI-Hilfsprojekt.
  - Am iPhone: Transparenz und die zwei Aktivitäten.
- **Danach:** Build 0.1.0 (3) archivieren, prüfen (`scripts/check-archive`) und für „Intern“ und „Extern“ hochladen.

## Phase 17 – Wecker zu Fadschr

*Grundlage: Spec v0.9 § 10.8 und der Prototyp (Einstellungen › Wecker zu Fadschr). Danach Build 4.*

*Gebaut am 18.11.2026 auf `claude/phase-17`, 1058 Tests grün, geprüft im Simulator gegen `iphone/24` und `iphone/84`. Mit dem Plan entschieden: kein Schlummern, Klang wählbar (Systemton oder kurzer Adhan), bei abgelehnter Erlaubnis gesperrter Schalter mit Weg in die iOS-Einstellungen. Annahmen in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 17“). Am 18.11.2026 um 22:02 hat ein Test-Wecker (`-debugAlarmIn 4`) auf dem iPhone Duo geklingelt, nach der Erlaubnis über den Schalter. Abgenommen am 19.11.2026.*

- AlarmKit (iOS 26): Erlaubnis beim ersten Einschalten, täglicher Wecker „Vor Sonnenaufgang“ (Minuten) oder zu einer festen Uhrzeit (höchstens 5 Minuten vor Sonnenaufgang). Neu berechnen, wenn sich Zeiten, Ort oder Einstellungen ändern.
- Einstellungsseite mit Schalter, Auswahl und Stepper. Chip mit Weckzeit in der Fadschr-Zeile.
- Texte in 16 Sprachen, Tests für die Weckzeit (PrayerCore), Prüfung am Gerät (Stummmodus, Fokus).

## Phase 18 – Verse und Adhan

*Grundlage: Spec v0.10 § 11, entschieden am 24.11.2026 (`docs/OPEN-QUESTIONS.md`, „Änderungen vor der Golden Beta“). Danach Build 0.1.0 (5) für die Golden Beta am 26.11.2026.*

*Gebaut am 24.11.2026 auf `claude/phase-18`, 1059 Tests grün, geprüft im Simulator gegen `iphone/50`, `51` und `86`. Annahmen in `docs/OPEN-QUESTIONS.md` („Annahmen in Phase 18“). Die Abnahme und die Hörprobe am Gerät stehen aus.*

- Verse: je Sprache ein wörtlicher Ausschnitt einer veröffentlichten Übersetzung statt der Platzhalter. Die Auswahl kommt aus fawazahmed0/quran-api, der Wortlaut ist mit Tanzil und QuranEnc abgeglichen. Unter der Karte steht der Name der Übersetzung. `scripts/import-strings` bricht ab, wenn einem Vers eine Sprache fehlt.
- Adhan: eine Aufnahme (Ustadh Mmanga Muharram, DARSA TV, CC BY) statt dreier Platzhalter-Stimmen, als Ausschnitt von 29,5 Sekunden für Mitteilungen, Wecker und Player. Stimmenliste, Schalter „Fadschr-Variante“ und die Einstellung `voice` entfallen (`AdhanRecording` in PrayerCore).
- Lizenzseite: Aufnahme, arabischer Verstext (Tanzil) und Übersetzungen mit Quelle und Bedingungen. Alles dazu steht in `docs/THIRD-PARTY.md`.
- Referenzbilder `iphone/50`, `51` und `86` neu aus dem Prototyp, `86` jetzt auch dunkel.

**Nachtrag zu Phase 18** (*Spec v0.11 § 11.3–11.7, abgenommen am 24.11.2026 im Prototyp „Stil“, Version 11; Go zum Bau am 24.11.2026. Gebaut auf demselben Zweig, Ergebnis unten unter „Annahmen im Nachtrag zu Phase 18“ in `docs/OPEN-QUESTIONS.md`.*)

- Klang: nur Systemton, kurzer Adhan oder lautlos; bei „Systemton“ der Hinweis `soundSystemFooter`.
- Einstellungen: Gruppe „Darstellung“ unter „Standort“ und über „Berechnung“, neue Zeilen „Stil“ und „Rechtsschule“.
- Onboarding: fünf Seiten mit der Rechtsschule als Seite 3 (`Picker` mit `.pickerStyle(.menu)`, Hanafi vorgewählt), Wischen vor und zurück, im Arabischen gespiegelt, an den Enden federnd, ohne Erlaubnis-Abfrage.
- Verbotszeiten nach Rechtsschule in PrayerCore (`Madhab`, Dauer je Schule, Maliki ohne Fenster vor Dhuhr, Schafii freitags ohne), überall: Bogen, Zeilen, Info-Blatt mit neuen Abschnitten, Anleitung, Widgets, Live-Aktivität und Dynamic Island. Unit-Tests.
- Stil: 24 Grundfarben im DesignSystem umschaltbar (statt des Assets `AccentColor`), violette Verbotszeit bei Orange, Gold und Sand, sechs Varianten der Live-Aktivität (auch für das Widget mit dem Bogen), „Standard wiederherstellen“. Widgets und Live-Aktivität lesen Farbe und Stil aus der App Group bzw. dem Inhalt der Aktivität; geplante Aktivitäten entstehen nach einer Änderung neu. Unit-Tests für Kontrast und Abstände der Farben.
- Texte (69 neue Schlüssel) in 16 Sprachen, die 13 ab ES als KI-Entwurf. Referenzbilder neu aus dem Prototyp (Onboarding, Einstellungen, Stil, Rechtsschule, Klang, Verbotszeiten-Blatt, `system/97`–`99`).
