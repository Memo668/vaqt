# Schlussabgleich der Referenzbilder

## Phase 15 (15.11.2026, Prototyp v0.8 mit `PLURAL`)

Die Referenz ist der Prototyp in derselben Sprache: `make compare-language LANGUAGE=<sprache>` nimmt 20 Zustände aus dem Prototyp (`scripts/capture-prototype` mit `PROTO_LANG`) und aus der App auf und legt sie in gleicher Höhe nebeneinander (`screenshots-out/phase-15/<sprache>/pair-*.png`, nicht in Git). Verglichen wird von Auge; Schrift (Chromium gegen SF), Breite (390 gegen 402 pt) und Laufweite weichen wie in den Phasen davor ab. Was abweicht und bleibt, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 15“.

| Sprache | Befehl | Ergebnis |
|---|---|---|
| Arabisch (`ar`, Ziffern 0–9) | `make compare-language LANGUAGE=ar` | stimmt in allen 20 Zuständen – gespiegelt: Leiste (Kreis links, Chips rechts), Pfeile am Datum, Bogen (Fadschr rechts), Zeilen (Glocke links), Tabs, Kompass nicht gespiegelt wie im Prototyp, Rakʿa-Folge von rechts, Durchlauf (Kreis rechts, Fortschritt von rechts, Pfeile), Nachholen (Balken von rechts), Einstellungen, Widgets und Live-Aktivität im Katalog. Gefunden und behoben: Zeitspannen standen von links nach rechts (Kerahat-Zeile, Kopf der Anleitung), jetzt mit dem Beginn rechts; im Vers ohne Übersetzung stand die Quelle 10 pt zu tief. Bleibt: das kurze Datum eines anderen Tages mit kurzem Wochentag von iOS („أربعاء“; im Prototyp läuft die lange Form über die Zeiten am Rand) |
| Arabisch, Region Saudi-Arabien | `make compare-language LANGUAGE=ar REGION=ar_SA STATES='10 23 60'` | stimmt mit der Entscheidung – ٠–٩ in Zeiten, Bogen, Countdown, Datum, Hijri und Nachholen; die erste Datumszeile bleibt gregorianisch, obwohl der Kalender der Region Umm al-Qura ist. Der Prototyp schreibt mit `ar` ohne Region 0–9 |
| Arabisch, Wahl in der App | UI-Hilfsprojekt `language-choice-rtl.txt` | stimmt – Gerät Deutsch, in der App „العربية“ gewählt: die ganze App von rechts nach links, auch Navigationsleiste (Zurück rechts) und Tab-Leiste |
| Bengali (`bn_BD`) | `make compare-language LANGUAGE=bn` | stimmt – Schrift Bengali in Leiste, Karten, Einstellungen und Durchlauf ohne Kürzung, Zeilenhöhen passen. Wie entschieden 0–9 in Datum und Hijri („মঙ্গলবার, 10 নভেম্বর“); der Prototyp (Chromium) schreibt dort ০–৯, iOS für `bn_BD` nicht |
| Französisch (`fr_FR`) | `make compare-language LANGUAGE=fr` | stimmt – Leiste „Horaires“, Datum und Hijri („30 joumada al oula 1448“), Zeilen mit „Makrouh“, „MAINTENANT“, Tabs; keine Texte abgeschnitten (Texterkennung) |
| Russisch (`ru_RU`) | `make compare-language LANGUAGE=ru` | stimmt – Mehrzahl aus `PLURAL` wie im Prototyp („Зухр · 4 ракаата“, „все 4 ракаата намаза …“), Datum und Hijri („30 джумад-уль-авваль 1448 г“), Leiste mit „Время“, Tabs |

## Phase 14 (15.11.2026, Prototyp v0.8)

Neu aus dem Prototyp sind `system/90`–`96` (`scripts/capture-prototype`, Ansichten `widgets`/`live` und die der Mitteilungen), dazu wegen des Namens „Vaqt“ `iphone/04`, `05`, `71`, `72`, `83`. Abgeglichen in zwei Schritten: im Katalog (`make compare-system`, Ausschnitte gegen die Referenz) und im System mit dem UI-Hilfsprojekt (Aufnahmen in `screenshots-out/phase-14/system-*.png`, nicht in Git). Die Zahlen sind der Anteil der Pixel, die um mehr als 24 von 255 abweichen. Was abweicht und bleibt, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 14“.

| Bild | Befehl | Ergebnis |
|---|---|---|
| `system/91` | `make compare-system STATES=91` | stimmt – Widget „Live“ 6,5 % (Kopf mit App-Symbol, Bogen 314 × 116 mit Kerahat golden auf der Spur, „Maghrib · 16:27“, Countdown; die Punkte liegen auf 0,5 pt), mittleres 8,3 %, kleines 7,9 % |
| `system/90` | `make compare-system STATES=90` | stimmt im Inhalt – Rechteck im Stil der Live-Aktivität (Bogen mittig, Gebete mit Symbol, Knopf mit Ring, Kerahat gestreift, Gebet und Countdown im Bogen; nach dem Änderungswunsch neu aufgenommen), Ring und Zeile liegen auf 1–2 pt; die Zahl (93 %) kommt vom Hintergrund: der Katalog zeichnet die Sperrbildschirm-Widgets unter denen des Home-Bildschirms auf dunklerem Verlauf |
| `system/93`, `96` | `make compare-system STATES='93 96'` | stimmt – 6,6 % und 7,3 %; Kerahat auf der Spur (vorbei blasser), App-Symbol im Kopf; dunkel mit der hellen Fassung des Symbols (siehe Annahmen). Neu aufgenommen mit dem neuen Rechteck darunter |
| `system/94`, `95` | `make compare-system STATES='94 95'` | stimmt – 7,0 % und 8,9 %, unverändert seit Phase 9 |
| `system/90`, `91`, `93`–`96` **T** | UI-Hilfsprojekt `system-setup-*.txt`, `system-90-91.txt`, `system-93-95.txt`, `system-96.txt` | stimmt im Inhalt – Widgets von „Vaqt“ auf Home- und Sperrbildschirm, Live-Aktivität, Insel kompakt und erweitert, dunkel; Abweichungen kommen von iOS (Sperrbildschirm von iOS 27 mit den Widgets unten, Hintergrund, Insel). Das Rechteck stand zuerst als Platzhalter da: iOS lehnte seine Zeitleiste mit Einträgen alle 5 Minuten als zu groß ab (10,5 MB); mit 10 Minuten (5,4 MB) zeigt es den Inhalt |
| `system/92` | – | nur die Referenz neu: Der Prototyp zeigt jetzt das App-Symbol in den Mitteilungen. Die App ändert dort nichts; iOS zeigt sein App-Symbol selbst (Spec § 9.1). Nicht neu im System aufgenommen (elf Minuten Wartezeit) |
| `iphone/04`, `05`, `71`, `72`, `83` | – | nur die Referenz neu: „Vaqt“ statt „Gebetszeiten“ in `{app}` und im Dialog; die App nimmt den Namen aus dem String Catalog. Der Dialog in `04` ist der des Systems und zeigt `CFBundleDisplayName` |

Nicht neu abgeglichen: `duo/*` (Duo-Simulator aus).

## Phase 13 (15.11.2026, Prototyp v0.8)

Neu sind die Bilder `iphone/43`–`49` des Durchlaufs „Gebet Schritt für Schritt“ (`scripts/capture-prototype`, Zustände von `S.walk`); `42` ist neu aufgenommen, weil es seit Phase 12 noch so weit gescrollt stand wie `41`. Die Zahlen sind der Anteil der Pixel, die um mehr als 24 von 255 abweichen. Was abweicht und bleibt, steht in `docs/OPEN-QUESTIONS.md` unter „Annahmen in Phase 13“.

| Bild | Befehl | Ergebnis |
|---|---|---|
| `iphone/43`–`49`, `43`/`47`/`49-…-dark` | `make compare-walk` | stimmt – Seite 1,7–3,9 % (`48`: 6,8 %, eine Zeile mehr, siehe unten), Kreis 0,8–1,9 % (dunkel 4,7–5,6 %, echtes Glas), Fortschritt 0–1 %, Knöpfe 1,8–7,1 %, Kopf 5,5–7,2 % (Laufweite der Schrittzeile) |
| `iphone/40` | `make compare-guide` | stimmt – Kopfkarte bis zur Rakʿa-Folge 3,2–3,5 %; Knopf „Gebet Schritt für Schritt“ mit Zeile darunter gleich groß und gleich gesetzt (11 % durch die Laufweite der Titel); in Referenzbreite (Katalog `guide`) 5,5 % |
| `iphone/41` **T** | UI-Hilfsprojekt `iphone-41-42-guide.txt`, dann `make compare-guide` | stimmt – Ablauf mit Formeln in Amiri 4,6–5,7 %, Grundlinie der Formel auf etwa 1 pt; Katalog `steps` 4,4 % |
| `iphone/42` **T** | wie `41` | stimmt – Maghrib gewählt, Knopf und „Zum aktuellen Gebet“ 6,2–6,7 % |
| `iphone/50`, `51` | `make compare-verses` | stimmt – Vers in Amiri Quran, Grundlinie auf 0,1 pt; Karte rechts 3,8 %, links 6,7 % (Laufweite der Übersetzung); Katalog 5,3 % |
| `iphone/72` **T** | UI-Hilfsprojekt `iphone-71-72-settings.txt`, dann `make compare-settings STATES=72` | weicht ab wie gewollt – Zeile „Lizenzen“ unter „Über“ (Spec § 9.7), der Prototyp hat sie nicht |

Dazu ohne Referenzbild: der Ablauf mit Tippen (UI-Hilfsprojekt `iphone-43-49-walk-flow.txt`: Knopf öffnet Asr, nach der Wahl Maghrib „Maghrib · 3 Rakʿas“, Beginnen/Weiter/Zurück/Schließen, Baum der Bedienungshilfen), RTL (gespiegelt: Kreis rechts, Fortschritt von rechts, „Zurück“ rechts), xxL/xxxL/AX5, die Seite „Lizenzen“.

Nicht neu abgeglichen: `system/*` (seit Phase 14 abgeglichen, oben) und `duo/*` (Duo-Simulator aus).

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
| `iphone/40`–`42` **T** | `make compare-guide` (41, 42 mit dem UI-Hilfsprojekt) | Leiste stimmt; Kopfkarte und Ablauf erst mit Phase 13 (Knopf „Gebet Schritt für Schritt“) – abgeglichen unter „Phase 13“ |
| `iphone/50`, `51` | `make compare-verses` | Kreis rechts stimmt; Vers erst mit Phase 13 (Amiri Quran) – abgeglichen unter „Phase 13“ |
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
