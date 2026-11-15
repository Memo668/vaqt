# Schlussabgleich der Referenzbilder

## Phase 12 (15.11.2026, Prototyp v0.8)

Seit Phase 12 stammen die Bilder unter `iphone/` aus dem Prototyp v0.8 (`scripts/capture-prototype`). Abgeglichen ist, was sich mit Spec § 9 geändert hat; die Zahlen sind die mittlere Abweichung der Ausschnitte (Anteil der Pixel über 24 von 255). Was abweicht und bleibt, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 12“.

| Bild | Befehl | Ergebnis |
|---|---|---|
| `iphone/01`, `01-…-dark` | `make compare-settings STATES=01`; dunkel einzeln | stimmt – App-Symbol statt Mondsichel, dunkel die dunkle Fassung |
| `iphone/02`, `03` | `make compare-settings STATES='02 03'` | stimmt – vier Punkte, „Überspringen“ auch auf Schritt 3 |
| `iphone/05`, `05-…-dark` | `make compare-settings STATES=05` | stimmt – Seite 4 mit Herz und Chips (Seite 6,4 %) |
| `iphone/10`–`22` | `make compare-today` | stimmt – Leiste mittig (Chips 6,6 %, Kreis 5 %), Pfeile am Datum, Kerahat auf der Spur; Kopf 4–5 %, Bogen 5–7 % wie bisher |
| `iphone/14-…-dark` | `make compare-today STATES=14d` | stimmt |
| `iphone/19` | `make compare-today STATES=19` | stimmt bis auf die Leiste: Chips mittig mit Abstand zum Kreis statt darunter (Annahmen in Phase 12) |
| `iphone/23`, `23-…-dark` | `make compare-today STATES='23 23d'` | stimmt – anderer Tag, „Zurück zu heute“, Tag statt Countdown (Bogen 5,5 %); Kerahat-Abschnitte ohne „vorbei“, kurzes Datum im Format von iOS |
| `iphone/30`–`34`, `33-…-dark` | `make compare-qibla` | stimmt – Keil ±40°, „Im Toleranzbereich“ mit Drehhinweis, Legende; Kompass 1,0–1,5 % |
| `iphone/40`–`42` **T** | `make compare-guide` (41, 42 mit dem UI-Hilfsprojekt) | Leiste stimmt; Kopfkarte und Ablauf erst mit Phase 13 (Knopf „Gebet Schritt für Schritt“) |
| `iphone/50`, `51` | `make compare-verses` | Kreis rechts stimmt; Vers erst mit Phase 13 (Amiri Quran) |
| `iphone/60` | `make compare-qada` | stimmt – Kreis rechts |
| `iphone/61`, `61-…-dark` **T** | `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-61-qada.txt`, dann `make compare-qada` | stimmt – Rechner als Karte ganz unten (rechts 4,7 %); die Einleitung ist in der breiteren App eine Zeile kürzer |
| `iphone/70`–`81`, `86` | `make compare-settings` | wie bisher; `71` mit dem neuen Text unter „Kerahat-Zeiten zeigen“ |
| `iphone/72`, `72-…-dark` **T** | UI-Hilfsprojekt `iphone-71-72-settings.txt`, dann `make compare-settings STATES=72` | stimmt – Zeile „Gebetszeiten unterstützen“, App-Symbol über der Tagline |
| `iphone/75` | `make compare-settings STATES=75` | stimmt – vier Regeln |
| `iphone/82`, `82-…-dark` **T** | UI-Hilfsprojekt `iphone-82-settings-hl-manual.txt`, dann `make compare-settings STATES=82` | stimmt – „Dämmerungswinkel“ mit zwei Steppern |
| `iphone/83`, `83-…-dark` | `make compare-settings STATES=83` | stimmt – 17 pt tiefer wie alle Unterseiten |

Nicht neu abgeglichen: `system/*` (Phase 14) und `duo/*` (Duo-Simulator aus).

## Phase 11 (13.11.2026, Prototyp v0.7)

Phase 11, 13.11.2026: die Bilder aus `design/screenshots/` nachgestellt, mit dem Befehl dafür und dem Ergebnis – 56 von 64. Offen sind die acht Bilder des aufgeklappten iPhone Duo (`duo/open-*`): Aufklappen geht nur in Device Hub, und der Nutzer hat „Ohne innen abschließen“ gewählt. „Stimmt“ heißt: Inhalt, Zustand, Texte, Farben und Abstände wie im Referenzbild – im Rahmen der Abweichungen, die für alle Bilder gelten (unten). Jede weitere Abweichung ist benannt, mit dem Abschnitt in `docs/OPEN-QUESTIONS.md`, der sie erklärt.

**Kennzeichen:** **T** braucht einen Tipp oder eine Geste (UI-Hilfsprojekt, `make harness`), **N** braucht den Nutzer (iPhone Duo in Device Hub auf- oder zuklappen), **G** lässt sich vollständig nur am Gerät prüfen.

**Was für alle Bilder gilt** (seit Phase 2, in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 2“ bis „10“):

- Der Simulator (iPhone 18 Pro, 402 × 874 pt) ist 12 pt breiter und 30 pt höher als die Referenzbilder (390 × 844 pt); der sichere Bereich beginnt bei 62 statt 58 pt. Verglichen werden deshalb Ausschnitte, nicht ganze Bilder.
- Die Referenzbilder sind nicht mit SF Pro gesetzt: Ziffern und Texte sind in der App schmaler, Grundlinien liegen bis 1 pt anders.
- SF Symbols statt der Zeichnungen des Prototyps; Liquid Glass, Tableiste, Listen, Sheets, Schalter und Leisten zeichnet das System.
- Der Countdown läuft: Eine Aufnahme zeigt ein bis zwei Sekunden weniger.
- Laufweite des Systems statt der geerbten −0,41 px (entschieden mit dem Plan für Phase 11).

Alle Befehle setzen voraus, dass die App gebaut und installiert ist; die `make`-Ziele tun das selbst.

| Bild | Befehl | Ergebnis |
|---|---|---|
| `iphone/01-onboarding-1-welcome` | `make compare-settings STATES=01` (`make statusbar TIME=09:10`) | stimmt – Seite mittig im höheren Bildschirm, Knöpfe am unteren Rand; der Titel bricht nach „Ruhig und“ um (Phase 7) |
| `iphone/02-onboarding-2-location` | `make compare-settings STATES=02` | stimmt – Text in anderer Teilung (Phase 7) |
| `iphone/03-onboarding-3-notifications` | `make compare-settings STATES=03` | stimmt – die Glocke `bell.and.waves…` hat je zwei Wellen (Phase 7) |
| `iphone/04-alert-location` **T** | Standort zurücksetzen (`xcrun simctl privacy … reset location`), dann `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-04-alert-location.txt` | stimmt bis auf die Sprache: Den Dialog zeichnet iOS in der Sprache des Simulators (Englisch), die Begründung kommt aus `alLocBody` (Phase 3) |
| `iphone/10-home-asr-active` | `make compare-today STATES=10`, Bausteine `make compare STATES=10` | stimmt – gegenüber Phase 10 pixelgleich bis auf die Sekunden und die dunklere Schrift der laufenden Karte (Kontrast, Phase 11) |
| `iphone/11-home-asr-active-dark` | `make compare-today STATES=11` | stimmt – dunkel bleibt die Schrift der laufenden Karte unverändert |
| `iphone/12-home-before-fajr` | `make compare-today STATES=12` | stimmt |
| `iphone/13-home-after-sunrise` | `make compare-today STATES=13` | stimmt |
| `iphone/14-home-kerahat-active` | `make compare-today STATES=14` | stimmt |
| `iphone/15-home-kerahat-before-maghrib` | `make compare-today STATES=15` | stimmt – „Kerahat bis 16:27“ in der dunkleren Kerahat-Farbe der laufenden Karte (Phase 11) |
| `iphone/16-home-after-isha-dark` | `make compare-today STATES=16` (`make statusbar TIME=23:30`) | stimmt |
| `iphone/17-home-location-denied-offline` | `make compare-today STATES=17` | stimmt – gegenüber Phase 10 pixelgleich bis auf Sekunden und laufende Karte |
| `iphone/18-home-high-latitude` | `make compare-today STATES=18` (`make statusbar TIME=23:47`) | stimmt |
| `iphone/19-home-large-type` | `make compare-today STATES=19` | stimmt mit den benannten Abweichungen: Chips wachsen bis AX1, Stadt und Datum in den Größen des Systems, die Kerahat-Zeile bricht nur in der laufenden Karte um (Phase 3) |
| `iphone/20-home-rtl` | `make compare-today STATES=20` | stimmt – gespiegelt, Ziffern und Symbole am Bogen nicht |
| `iphone/21-home-turkish-istanbul` | `make compare-today STATES=21` | stimmt |
| `iphone/22-home-jakarta-close-markers` | `make compare-today STATES=22` | stimmt – Ring bei eng liegenden Markern |
| `iphone/30-qibla` | `make compare-qibla STATES=30` | stimmt – Kompass deckungsgleich (im Mittel 1,5 von 255); die Kalibrierungskarte nur bei ungenauem Kompass (`-debugQiblaAccuracy 40`) |
| `iphone/31-qibla-aligned` | `make compare-qibla STATES=31` | stimmt – Haken und „Du blickst Richtung Qibla“ in Akzent |
| `iphone/32-qibla-mecca` **G** | `make compare-qibla STATES=32` (`make statusbar TIME=15:42`); Kompass am Gerät | stimmt – keine Nadel, die Meldung; Kompass selbst nur am Gerät |
| `iphone/40-guide-asr` | `make compare-guide` | stimmt – kleine Texte etwas breiter (Laufweite des Systems, Phase 5 und 11) |
| `iphone/41-guide-steps` **T** | `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-41-42-guide.txt OUT=…`, dann `make compare-guide OUT=…` | stimmt |
| `iphone/42-guide-manual-pick` **T** | wie `41` | stimmt |
| `iphone/50-verses` | `make compare-verses` | stimmt – Arabisch in SF Arabic, das Referenzbild hat eine Ersatzschrift (Phase 6) |
| `iphone/51-verses-dark` | `make compare-verses` | stimmt |
| `iphone/60-qada` | `make compare-qada` | stimmt – die Prozentzahl in SF Pro Rounded (Phase 6) |
| `iphone/61-qada-calculator` **T** | `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-61-qada.txt OUT=…`, dann `make compare-qada OUT=…` | stimmt – liegt 32 pt tiefer, weil der Bildschirm höher ist (Phase 6) |
| `iphone/70-settings` | `make compare-settings STATES=70` | stimmt – großer Titel und Leiste des Systems liegen tiefer (Phase 7); pixelgleich mit Phase 10 |
| `iphone/71-settings-middle` **T** | `make harness SCRIPTS=scripts/ui-harness/scripts/iphone-71-72-settings.txt OUT=…`, dann `make compare-settings OUT=…` | stimmt |
| `iphone/72-settings-bottom` **T** | wie `71` | stimmt – Tagline mit dem Zeichen des Prototyps (Mondsichel) |
| `iphone/73-settings-method` | `make compare-settings STATES=73` | stimmt – Suchfeld des Systems (44 statt 38 pt, Phase 7) |
| `iphone/74-settings-asr` | `make compare-settings STATES=74` | stimmt |
| `iphone/75-settings-hl` | `make compare-settings STATES=75` | stimmt – die Zusätze stehen in einer statt zwei Zeilen (Phase 7) |
| `iphone/76-settings-adjust` | `make compare-settings STATES=76` | stimmt |
| `iphone/77-settings-perprayer` | `make compare-settings STATES=77` | stimmt |
| `iphone/78-settings-reminder` | `make compare-settings STATES=78` | stimmt |
| `iphone/79-settings-live` | `make compare-settings STATES=79` | benannte Abweichung: neun Zeilen (Aus bis 120 Min.) statt drei – entschieden mit dem Plan für Phase 9 |
| `iphone/80-settings-sound` **G** | `make compare-settings STATES=80`; Ton am Gerät | stimmt; Ton nur am Gerät |
| `iphone/81-settings-privacy` | `make compare-settings STATES=81` | stimmt – die Überschrift in einer statt zwei Zeilen (Phase 7) |
| `iphone/85-sheet-city` | `make run ARGS='-debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25 -debugTab city'`, `make screenshot` | stimmt – Sheet, Suchfeld und Liste des Systems (Phase 3) |
| `iphone/86-sheet-adhan` **G** | `make compare-settings STATES=86`; Ton am Gerät | stimmt – pixelgleich mit Phase 10; Schieberegler und Schließen-Knopf des Systems (Phase 7); Ton nur am Gerät |
| `system/90-lockscreen-widgets` **T** | Katalog `make compare-system STATES=90`; im System `make harness SCRIPTS=scripts/ui-harness/scripts/system-90-91.txt` (Widgets vorher mit `system-setup-lock-widgets.txt`) | stimmt im Inhalt – iOS 27 setzt Ring und Rechteck unten auf den Sperrbildschirm; Uhr, Datum und Hintergrund vom System (Phase 9) |
| `system/91-homescreen-widgets` **T** | Katalog `make compare-system STATES=91`; im System `system-90-91.txt` (Widgets vorher mit `system-setup-home-widgets.txt`) | stimmt – Widgets auf dem iPhone 18 Pro größer (164 statt 154 pt, Phase 9); in der Reihe steht jetzt das Platzhalter-Icon |
| `system/92-notifications` **T G** | Systemsprache Deutsch, `make statusbar TIME=11:52`, `make harness SCRIPTS=scripts/ui-harness/scripts/system-92.txt` (wartet elf Minuten) | stimmt – „Dhuhr · 11:52“ / „Zeit für Dhuhr in Berlin.“ / „jetzt“ über „Dhuhr in 10 Minuten“ / „Dhuhr beginnt um 11:52 Uhr.“ / „Vor 10 Min.“, jetzt mit dem Platzhalter-Icon; Stapel, Kopf und Glas zeichnet iOS (Phase 8) |
| `system/93-live-activity-lockscreen` **T G** | Katalog `make compare-system STATES=93`; im System `make harness SCRIPTS=scripts/ui-harness/scripts/system-93-95.txt` | stimmt |
| `system/94-live-activity-island-compact` **T G** | Katalog `STATES=94`; im System `system-93-95.txt` | stimmt |
| `system/95-live-activity-island-expanded` **T G** | Katalog `STATES=95`; im System `system-93-95.txt` | stimmt – den Balken zeichnet iOS dünner (Phase 9) |
| `system/96-live-activity-lockscreen-dark` **T G** | Katalog `STATES=96`; im System dunkel, `make statusbar TIME=16:35`, `make harness SCRIPTS=scripts/ui-harness/scripts/system-96.txt` | stimmt – Maghrib läuft, die Aktivität zählt auf Ischa; die Zeiten am Bogen voll weiß (Phase 11) |
| `duo/closed-10-home` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=10` | stimmt – Seiten wie auf dem iPhone neben der senkrechten Leiste (Phase 10) |
| `duo/closed-11-home-dark` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=11` | stimmt |
| `duo/closed-30-qibla` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=30` | stimmt |
| `duo/closed-40-guide` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=40` | stimmt – außen 382 pt breit, die Rakʿa-Folge bricht um (Phase 10) |
| `duo/closed-50-verses` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=50` | stimmt |
| `duo/closed-60-qada` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=60` | stimmt |
| `duo/closed-70-settings` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=70` | stimmt – Titel und Ränder des Systems (Phase 10) |
| `duo/closed-85-sheet-city` **N** | Duo zugeklappt: `make compare-duo MODE=closed STATES=85` | stimmt – iOS legt das Sheet außen unter die senkrechte Leiste (Phase 10) |
| `duo/open-10-home` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=10` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-11-home-dark` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=11` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-30-qibla` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=30` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-40-guide` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=40` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-50-verses` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=50` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-60-qada` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=60` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-70-settings` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=70` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |
| `duo/open-85-sheet-city` **N** | Duo aufgeklappt, quer: `make compare-duo MODE=open STATES=85` | **offen** – nicht abgeglichen: braucht das Aufklappen in Device Hub (Nutzer: „Ohne innen abschließen“); zuletzt abgeglichen mit Phase 10 |

## Wie der Abgleich lief

- **iPhone 18 Pro (iOS 27.2):** alle `make compare-*` mit `OUT=screenshots-out/phase-11/final/<bereich>`, die Zustände mit Tipp über `scripts/ui-harness`. Die mittleren Abweichungen der Ausschnitte liegen wie in den Phasen 2 bis 10 bei etwa 2 bis 15 von 255. Höher liegen die benannten Fälle: `19` (große Schrift), `73` und `75` (anderer Umbruch), `79` (neun Zeilen) und `system/90` (der Katalog ahmt Hintergrund und Zeile über der Uhr nur nach).
- **Gegen den Stand von Phase 10** (`main`), gleiche Zustände: Verse hell und dunkel, Einstellungen und Adhan-Sheet pixelgleich; die Zeiten-Seite gleich bis auf die laufenden Sekunden und die dunklere Schrift der laufenden Karte (Kontrast, Phase 11).
- **iPhone Duo (iOS 27.2, 24B91016s):** `make compare-duo MODE=closed`, zugeklappt; dazu AX5 außen. Aufgeklappt nicht.
- **Was nur am Gerät geht** (Kennzeichen **G**): Kompass, Töne, der geplante Start und das Ende der Live-Aktivität ohne laufende App – siehe „Am Gerät prüfen“ in `docs/OPEN-QUESTIONS.md`.

**Stolperstein:** `xcrun simctl io … screenshot` hing, wenn die Aufnahme direkt auf die externe Platte geschrieben werden sollte; Abgleiche deshalb mit `OUT` auf der internen Platte. Aufnahmen über das UI-Hilfsprojekt (`XCUIScreen`) schreiben auch auf die externe Platte.
