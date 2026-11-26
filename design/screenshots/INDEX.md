# Referenz-Screenshots

Aus dem Prototyp `prayer-times-prototype.html` erzeugt, nur der Bildschirm ohne Gerätrahmen, 2x.
iPhone: 390 × 844 pt · iPhone Duo zu: 466 × 678 pt · iPhone Duo auf: 951 × 669 pt.
Uhrzeiten/Zahlen stammen aus den Mock-Daten des Prototyps (Berlin, 10.11.2026). Mit `-debugFixtureTimes` zeigt die App dieselben Werte.
Wenn nichts anderes steht: Deutsch, hell, Berlin, 14:25 (Asr aktiv).

**Stand v0.8 (Phase 12, 15.11.2026):** Die Bilder unter `iphone/` hat `scripts/capture-prototype` aus dem Prototyp v0.8 neu aufgenommen (Spec § 9) – alle Zustände stehen in `scripts/capture-prototype.mjs`. Neu sind die dunklen Fassungen der geänderten Bildschirme (`-dark`) und `05`, `23`, `33`, `34`, `82`, `83`. Noch von v0.7 sind `73`, `74`, `76`–`81`, `85`, `86` und alle `duo/*`.

**Spec v0.9 (18.11.2026, § 10):** Neu aufgenommen sind die Bilder, deren Texte oder Aussehen sich geändert haben. Das sind „Verbotszeit“ mit Infopunkt, die längeren Abschnitte im Bogen, Onboarding und Datenschutztexte, der Rechner mit „Für wen?“ und „Alles zurücksetzen“, die Live-Aktivität mit 30 % und das Widget „Live“: `iphone/01`–`04`, `10`–`23`, `30`–`34`, `40`–`50`, `60`, `61`, `70`–`75`, `system/90`–`96`. Im Prototyp scheint das Widget „Live“ mit 30 % durch; in der App bleibt es deckend (`docs/OPEN-QUESTIONS.md`, „Annahmen in Phase 16“).

**Spec v0.10 (24.11.2026, § 11):** Neu aufgenommen sind `iphone/50` und `51` (Verse mit den Ausschnitten veröffentlichter Übersetzungen, darunter der Name der Übersetzung) und `iphone/86` (Adhan-Fenster mit einer Aufnahme statt dreier Stimmen, neu auch dunkel). `duo/closed-50` und `duo/open-50` sind weiter von v0.7 und zeigen noch die früheren Platzhaltertexte; sie gelten nur für die Anordnung.

**Spec v0.11 (Nachtrag zu Phase 18, 24./25.11.2026, § 11.3–11.7):** Neu aufgenommen sind das Onboarding (fünf Schritte: die Rechtsschule ist Schritt 3, `03-*`; Mitteilungen und „Kostenlos“ rücken zu `05` und `06`; in `01`, `02` und `04` nur die fünf Punkte), die Einstellungen `70`–`72` (Gruppe „Darstellung“ über „Berechnung“, Zeilen „Stil“ und „Rechtsschule“) und neu `25`–`27` (Grundfarbe, Rechtsschule, Blatt zu den Verbotszeiten), `80-settings-sound-system`, `87` (Stil), `88` (Rechtsschule) sowie `system/97`–`99` (Stile der Live-Aktivität und des Widgets „Live“). Alle übrigen Bilder sind gleich geblieben (Pixelvergleich mit der Aufnahme aus dem neuen Prototyp).

**Spec v0.12 (Phase 19, 25.11.2026, § 12):** Neu ist der Ordner `carplay/` mit CarPlay, StandBy und den Tafeln der kleinen Widgets und der Live-Aktivität „klein“ (Abschnitt unten). Alle übrigen Bilder sind gleich geblieben (Pixelvergleich von `iphone/10`, `87`, `system/91`, `93` mit der Aufnahme aus dem neuen Prototyp).

**Spec v0.13 (Phase 20, 26.11.2026, § 13):** Das neue App-Icon (Tagesbogen auf Weiß, dunkel auf Schwarz, Glas-Linse auf dem oberen Punkt, in der Grundfarbe) und der Schalter „App-Icon in der Grundfarbe“ unter Stil. Neu aufgenommen sind alle Bilder mit dem Icon: `iphone/01-onboarding-1-welcome` und `72-settings-bottom` (je hell und dunkel), `87-settings-style*` (mit dem neuen Schalter), `system/91`–`99` und aus Phase 19 `carplay/cp-21`, `cp-30` und `cp-40`–`cp-43`. Die übrigen Bilder sind gleich geblieben: alle 138 Zustände aus dem neuen Prototyp aufgenommen und Pixel für Pixel verglichen; `iphone/16-home-after-isha-dark` und `18-home-high-latitude` weichen in wenigen Pixeln ab (Rauschen beim Zeichnen) und bleiben.

**Nachtrag 16.11.2026 (Spec § 9.14):** Der Sonnenaufgang steht als Punkt im Bogen, gleich groß wie die Gebete. Neu aufgenommen sind deshalb `iphone/10`–`23` sowie `system/90`, `91`, `93`, `94` und `96`. Die Bilder unter `duo/*` sind weiter von v0.7 und zeigen den Bogen noch ohne Sonnenaufgang.

**Phase 14 (15.11.2026):** `system/90`–`96` aus dem Prototyp v0.8 neu (Ansichten `widgets`, `live` und die der Mitteilungen; `screen` in `capture-prototype.mjs` wählt den Bildschirm): Rechteck mit Mini-Bogen, Widget „Live“ über dem mittleren, Kerahat auf der Spur der Live-Aktivität, App-Symbol im Kopf und in den Mitteilungen. Wegen des Namens „Vaqt“ (Spec § 9.13) neu: `04` (Dialog des Systems, jetzt auch aus dem Prototyp), `05`, `71`, `72`, `83` (Texte mit `{app}`). Nach dem Änderungswunsch zum Rechteck (Stil der Live-Aktivität, Spec § 9.11) noch einmal neu: `90`, `93`, `96`.

**Phase 13 (15.11.2026):** neu `43`–`49` (Durchlauf „Gebet Schritt für Schritt“, Zustände von `S.walk`, drei davon dunkel); `42` neu aufgenommen – es stand seit Phase 12 noch so weit gescrollt wie `41`, weil `capture-prototype` den Bildlauf nicht zurücksetzte. Knopf und Amiri-Schrift in `40`–`42`, `50`, `51` hat die App seit Phase 13.

Was der Prototyp v0.8 schon zeigt, die App aber erst später bekommt:
- **Phase 15:** weitere Sprachen.

Abweichungen des Prototyps, denen die App nicht folgt (Spec > Screenshot > HTML):
- **`23` (anderer Tag):** Der Prototyp blendet die Kerahat-Abschnitte nach der heutigen Uhrzeit ab; laut Spec § 9.4 hat ein anderer Tag keinen Zustand „vorbei“ – in der App sind alle drei gleich kräftig.
- **`19` (große Schrift):** Die Chips überdecken im Prototyp das Zahnrad; die App lässt bei Platzmangel den Platzhalter links weg (Spec § 9.2, Zusammenklappen wie bisher).

## Onboarding & Berechtigungen – Phase 7

| Datei | Zeigt |
|---|---|
| `iphone/01-onboarding-1-welcome.png` | Onboarding step 1 (welcome) |
| `iphone/01-onboarding-1-welcome-dark.png` | Same in dark mode – app icon instead of the crescent (§ 9.1) |
| `iphone/02-onboarding-2-location.png` | Onboarding step 2 (location priming) |
| `iphone/03-onboarding-3-madhab.png` | Onboarding step 3 „Deine Rechtsschule“: menu button with Hanafi (§ 11.5, `-debugOnboarding 3`) |
| `iphone/03-onboarding-3-madhab-dark.png` | Same in dark mode |
| `iphone/03-onboarding-3-madhab-menu.png` | Same with the menu of the four schools open (in the app: tap the button) |
| `iphone/04-alert-location.png` | iOS location alert over step 2 (system UI, for flow context only) |
| `iphone/05-onboarding-4-notifications.png` | Onboarding step 4 (notification priming; until Phase 18 `03-onboarding-3-notifications`) |
| `iphone/06-onboarding-5-free.png` | Onboarding step 5 „Kostenlos. Ohne Werbung.“ (§ 9.9; until Phase 18 `05-onboarding-4-free`) |
| `iphone/06-onboarding-5-free-dark.png` | Same in dark mode |

## Zeiten (Home) – Phase 2 + 3

| Datei | Zeigt |
|---|---|
| `iphone/10-home-asr-active.png` | Zeiten (Home), Berlin 14:25, Asr active – main reference |
| `iphone/11-home-asr-active-dark.png` | Same in dark mode |
| `iphone/12-home-before-fajr.png` | Before Fajr: nothing highlighted, countdown to Fajr |
| `iphone/13-home-after-sunrise.png` | After sunrise: no current prayer, white "now" knob on the arc |
| `iphone/14-home-kerahat-active.png` | 07:30 – Kerahat after sunrise active (caption in gold, arc segment stronger) |
| `iphone/14-home-kerahat-active-dark.png` | Same in dark mode – kerahat drawn on the track (§ 9.3) |
| `iphone/15-home-kerahat-before-maghrib.png` | 16:05 – Kerahat before Maghrib active on the Asr row |
| `iphone/16-home-after-isha-dark.png` | After Isha (dark): Isha highlighted, "Fajr tomorrow in" |
| `iphone/17-home-location-denied-offline.png` | Location denied banner + offline pill |
| `iphone/18-home-high-latitude.png` | High latitude (Berlin, 21 June): info marks + note card |
| `iphone/19-home-large-type.png` | Large Dynamic Type (≈ xxxLarge) |
| `iphone/20-home-rtl.png` | RTL preview (arc runs right → left, numbers not mirrored) |
| `iphone/21-home-turkish-istanbul.png` | Turkish, Istanbul (Diyanet) |
| `iphone/22-home-jakarta-close-markers.png` | Jakarta, Maghrib active: close markers (Maghrib → Isha 72 min) get a ring |
| `iphone/23-home-next-day.png` | Next day (`-debugDayOffset 1`): that day's times, relative day + date instead of the countdown, „Zurück zu heute“ (§ 9.4) |
| `iphone/23-home-next-day-dark.png` | Same in dark mode |
| `iphone/24-home-alarm-chip.png` | Fajr alarm on (`-debugAlarm before`): chip with clock glyph and today's ring time 06:29 in the Fajr row (§ 10.8, Phase 17) |
| `iphone/25-home-accent-ocean.png` | Accent colour Ozean (`-debugAccent ocean`, § 11.7) |
| `iphone/25-home-accent-orange-kerahat.png` | Accent colour Orange at 07:30: prohibited time violet instead of orange (`-debugAccent orange`) |
| `iphone/25-home-accent-orange-kerahat-dark.png` | Same in dark mode |
| `iphone/26-home-maliki.png` | Madhab Maliki (`-debugMadhab maliki`): no window before Dhuhr, 20 min after sunrise and before Maghrib (§ 11.6) |
| `iphone/26-home-shafii-friday.png` | Madhab Schafii on a Friday (13.11., `-debugDayOffset 3`): no window before Dhuhr |
| `iphone/27-sheet-kerahat.png` | Sheet „Was sind Verbotszeiten?“ (Hanafi, `-debugTab kerahat`, § 10.2, § 11.6) |
| `iphone/27-sheet-kerahat-maliki.png` | Same for Maliki: own intro, two windows |

## Qibla – Phase 4

| Datei | Zeigt |
|---|---|
| `iphone/30-qibla.png` | Qibla page, heading 98° – now inside the ±40° wedge (compass, drag to rotate in prototype) |
| `iphone/31-qibla-aligned.png` | Qibla aligned (±3°): accent + haptic |
| `iphone/32-qibla-mecca.png` | In Mecca: message instead of a needle |
| `iphone/33-qibla-tolerance.png` | Heading 112°: inside the ±40° wedge – „Im Toleranzbereich“, „Nach rechts drehen 25°“ (§ 9.5) |
| `iphone/33-qibla-tolerance-dark.png` | Same in dark mode |
| `iphone/34-qibla-outside.png` | Heading 60°: outside the wedge – only the turn hint |

## Anleitung – Phase 5

| Datei | Zeigt |
|---|---|
| `iphone/40-guide-asr.png` | Anleitung opens on the current prayer (Asr) |
| `iphone/41-guide-steps.png` | Anleitung scrolled: steps with pictograms and formulas |
| `iphone/42-guide-manual-pick.png` | Manual pick (Maghrib): "Back to current prayer" button |

## Gebet Schritt für Schritt – Phase 13 (§ 9.6)

Vollbild über der Anleitung; `-debugWalk dhuhr -debugWalkStep N` mit `N` wie `S.walk.i` im Prototyp.

| Datei | Zeigt |
|---|---|
| `iphone/43-walk-intro.png` | Dhuhr, start page: prayer badge, „Dhuhr · 4 Rakʿas“, wudu/Qibla/niyya text, rakʿa dots, „Beginnen“ (`i = 0`) |
| `iphone/43-walk-intro-dark.png` | Same in dark mode |
| `iphone/44-walk-takbir.png` | Takbīr, „Rakʿa 1 von 4 · Schritt 1 von 28“, formula in Amiri 27 pt (`i = 1`) |
| `iphone/45-walk-qiyam-silent.png` | Standing, tag „Rezitation: leise“ (`i = 2`) |
| `iphone/46-walk-qiyam-loud.png` | Maghrib, standing, tag „Rezitation: laut“ (`-debugWalk maghrib`, `i = 2`) |
| `iphone/47-walk-sujud.png` | Prostration, „Sprich dreimal:“ with formula (`i = 5`) |
| `iphone/47-walk-sujud-dark.png` | Same in dark mode |
| `iphone/48-walk-tash-first.png` | First sitting after rakʿa 2, at-Tahiyyāt (`i = 14`) |
| `iphone/49-walk-done.png` | „Gebet beendet“, check in accent circle, „Fertig“ (`i = 29`) |
| `iphone/49-walk-done-dark.png` | Same in dark mode |

## Verse – Phase 6

| Datei | Zeigt |
|---|---|
| `iphone/50-verses.png` | Verse tab: verse of the day + last days; excerpts of published translations, translation named under the card (§ 11.1) |
| `iphone/51-verses-dark.png` | Verse tab dark |

## Nachholen – Phase 6

| Datei | Zeigt |
|---|---|
| `iphone/60-qada.png` | Nachholen: percent as largest figure |
| `iphone/61-qada-calculator.png` | Nachholen scrolled to the end: counters + calculator card (§ 9.8) |
| `iphone/61-qada-calculator-dark.png` | Same in dark mode – calculator as a card at the very bottom (§ 9.8) |

## Einstellungen – Phase 7

| Datei | Zeigt |
|---|---|
| `iphone/70-settings.png` | Settings root (top) |
| `iphone/71-settings-middle.png` | Settings: notifications (incl. Live Activity) + appearance (Kerahat toggle) |
| `iphone/72-settings-bottom.png` | Settings: about + disclaimer + tagline |
| `iphone/72-settings-bottom-dark.png` | Same in dark mode – support row, app icon over the tagline (§ 9.1, 9.9) |
| `iphone/73-settings-method.png` | Settings › Calculation method (searchable, auto per country) |
| `iphone/74-settings-asr.png` | Settings › Asr (standard / Hanafi) |
| `iphone/75-settings-hl.png` | Settings › High latitude rule |
| `iphone/76-settings-adjust.png` | Settings › Minute adjustments (steppers) |
| `iphone/77-settings-perprayer.png` | Settings › Notifications per prayer |
| `iphone/78-settings-reminder.png` | Settings › Reminder before |
| `iphone/79-settings-live.png` | Settings › Live Activity lead time |
| `iphone/80-settings-sound.png` | Settings › Sound |
| `iphone/80-settings-sound-system.png` | Settings › Sound with „Systemton“: footer says where to choose the tone in iOS (`-debugSound system`, § 11.3) |
| `iphone/81-settings-privacy.png` | Settings › Privacy page |
| `iphone/82-settings-hl-manual.png` | Settings › High latitude with „Manuelle Winkel“ selected: twilight angle steppers (§ 9.12) |
| `iphone/82-settings-hl-manual-dark.png` | Same in dark mode |
| `iphone/83-settings-support.png` | Settings › Unterstützen (§ 9.9) |
| `iphone/83-settings-support-dark.png` | Same in dark mode |
| `iphone/84-settings-alarm.png` | Settings › Wecker zu Fadschr (`-debugTab alarm -debugAlarm before`): on, 45 min before sunrise, system sound (§ 10.8, Phase 17) |
| `iphone/84-settings-alarm-dark.png` | Same in dark mode |
| `iphone/84-settings-alarm-fixed.png` | Same with a fixed time 05:30 and the short adhan (`-debugAlarm fixed`) |
| `iphone/84-settings-alarm-off.png` | Same page, alarm off (`-debugTab alarm`) |
| `iphone/84-settings-alarm-denied.png` | Alarm permission denied (`-debugAlarm denied`): switch off and disabled, „iOS-Einstellungen öffnen“ |
| `iphone/87-settings-style.png` | Settings › Stil (`-debugTab style`, § 11.7): Live Activity preview, standard row of accent colours, switch „App-Icon in der Grundfarbe“ (since v0.13, § 13.2), three styles, „Invertiert“ |
| `iphone/87-settings-style-dark.png` | Same in dark mode |
| `iphone/87-settings-style-open.png` | Same with Orange and „Nur Bogen“ inverted: grid 4 × 6 open (`-debugAccent orange -debugLiveStyle arc -debugLiveInverted`) |
| `iphone/87-settings-style-open-end.png` | Same, scrolled to the end: „Standard wiederherstellen“ |
| `iphone/88-settings-madhab.png` | Settings › Rechtsschule (`-debugTab madhab`, § 11.6) |
| `iphone/88-settings-madhab-dark.png` | Same in dark mode, Schafii selected |

## Sheets – Phase 3 (Stadt) und 7 (Adhan)

| Datei | Zeigt |
|---|---|
| `iphone/85-sheet-city.png` | City sheet (.large, searchable) |
| `iphone/86-sheet-adhan.png` | Adhan player sheet: one recording, source and licence under the player (§ 11.2) |
| `iphone/86-sheet-adhan-dark.png` | Same in dark mode |

## Widgets, Mitteilungen, Live-Aktivität – Phase 8 + 9, v0.8 in Phase 14

| Datei | Zeigt |
|---|---|
| `system/90-lockscreen-widgets.png` | Lock Screen: accessoryCircular + accessoryRectangular (arc in the Live Activity style, since v0.8) + inline |
| `system/91-homescreen-widgets.png` | Home Screen: systemMedium „Live“ (since v0.8) + systemMedium + systemSmall |
| `system/92-notifications.png` | Notifications: prayer + reminder |
| `system/93-live-activity-lockscreen.png` | Live Activity on the Lock Screen (day arc on accent) |
| `system/94-live-activity-island-compact.png` | Live Activity – Dynamic Island compact |
| `system/95-live-activity-island-expanded.png` | Live Activity – Dynamic Island expanded (long press) |
| `system/96-live-activity-lockscreen-dark.png` | Live Activity, dark system, Maghrib active |

## Stil der Live-Aktivität – Nachtrag zu Phase 18 (§ 11.7)

Im Katalog mit `-debugCatalog live` bzw. `widgets` und `-debugLiveStyle arc|mono`, `-debugLiveInverted`, `-debugAccent …` (`scripts/compare-system`).

| Datei | Zeigt |
|---|---|
| `system/97-live-activity-arc.png` | „Nur Bogen“: colourless surface, arc in the dark accent |
| `system/97-live-activity-mono.png` | „Schwarz-weiß“: no colour, app icon grey |
| `system/97-live-activity-full-inverted.png` | „Farbig“, inverted: white surface, arc and text in the accent |
| `system/97-live-activity-arc-inverted.png` | „Nur Bogen“, inverted |
| `system/97-live-activity-mono-inverted.png` | „Schwarz-weiß“, inverted |
| `system/97-live-activity-ocean.png` | „Farbig“ in Ozean |
| `system/98-live-activity-kerahat.png` | Prohibited time (16:05): orange, header „Verbotszeit bis 16:27“ |
| `system/98-live-activity-kerahat-arc.png` | Same, „Nur Bogen“: only the arc orange, header in `#F8B877` |
| `system/98-live-activity-kerahat-mono.png` | Same, „Schwarz-weiß“: striped, no orange |
| `system/98-live-activity-kerahat-full-inverted.png` | Same, „Farbig“ inverted |
| `system/98-live-activity-kerahat-arc-inverted.png` | Same, „Nur Bogen“ inverted |
| `system/98-live-activity-kerahat-warm.png` | Same with Orange as accent: violet instead of orange |
| `system/98-live-activity-island-expanded-kerahat-warm.png` | Dynamic Island expanded, prohibited time, Orange: violet text, bar and marks |
| `system/98-live-activity-island-expanded-mono.png` | Dynamic Island expanded, „Schwarz-weiß“: all white |
| `system/99-homescreen-widgets-arc-inverted.png` | Home Screen: widget „Live“ in „Nur Bogen“, inverted |
| `system/99-homescreen-widgets-ocean.png` | Home Screen: widgets in Ozean |

## CarPlay und StandBy – Phase 19 (Spec v0.12 § 12)

Aus der Ansicht „CarPlay“ des Prototyps (`scripts/capture-prototype cp-`), nicht der iPhone-Bildschirm, sondern der Rahmen: der Bildschirm im Auto (breit 960 × 360 pt, Standard 800 × 480 pt), eine Tafel in Originalgröße oder StandBy (844 × 390 pt). Ohne eigene CarPlay-App (entschieden am 25.11.2026). Dashboard, Anordnung der Widgets im Auto, die Fläche hinter einem Widget und StandBy sind angenähert; zum Abgleich mit der App taugen die Tafeln (`cp-40`–`cp-52`). Im Katalog: `-debugCatalog live` (Live-Aktivität „klein“ in vier Größen) und `-debugCatalog carplay` (die kleinen Widgets mit und ohne Hintergrund, die Live-Aktivität „klein“ nach dem Wechsel), `scripts/compare-system cp…`. Um 16:05 läuft die Verbotszeit vor Maghrib.

| Datei | Zeigt |
|---|---|
| `carplay/cp-10-widgets-wide.png` (+ `-dark`) | CarPlay, wide screen: widgets left of the Dashboard – Vaqt „Nächstes Gebet“ without background, enlarged (the „Tagesbogen“ looks the same there), two widgets of other apps |
| `carplay/cp-11-widgets-standard.png` (+ `-dark`) | Same on the standard screen (two widgets) |
| `carplay/cp-12-widgets-kerahat.png` (+ `-dark`) | Same in the prohibited time (16:05): „Verbotszeit bis 16:27“ |
| `carplay/cp-20-dashboard-wide.png` (+ `-dark`) | Dashboard with map, the Live Activity „small“ (240 × 78) and music |
| `carplay/cp-21-dashboard-standard.png` (+ `-dark`) | Same on the standard screen, Live Activity 240 × 100 with header |
| `carplay/cp-22-dashboard-kerahat.png` | Dashboard in the prohibited time: the Live Activity orange |
| `carplay/cp-30-alert.png` (+ `-dark`) | The Live Activity as a notice over another app (map) |
| `carplay/cp-40-live-small.png` | Live Activity „small“ in all sizes: 240 × 100 (header), 240 × 78, 170 × 78, Smart Stack 194 × 80,5; below the same activity after its change (two lines): the green part ends at the prohibited time, „Verbotszeit ab 15:42“ |
| `carplay/cp-41-live-small-kerahat.png` | Same in the prohibited time: orange, „Verbotszeit bis 16:27“ in the arc (flat sizes) or the header; after the change orange with „hat begonnen“ |
| `carplay/cp-42-live-small-{arc,mono,full-inverted,arc-inverted,mono-inverted,ocean}.png` | The board in the other styles of § 11.7 and in Ozean, full opacity |
| `carplay/cp-43-live-small-kerahat-{arc,mono,full-inverted,arc-inverted,warm}.png` | Same in the prohibited time; `warm` = accent Orange, violet instead of orange |
| `carplay/cp-50-small-widgets.png` (+ `-dark`) | The small widgets at 158 × 158: top with background (Home Screen) – „Nächstes Gebet“ as before, the new „Tagesbogen“ with the arc; bottom without background (StandBy, CarPlay) – both the same, the large arrangement of „Nächstes Gebet“ |
| `carplay/cp-51-small-widgets-kerahat.png` (+ `-dark`) | Same in the prohibited time |
| `carplay/cp-52-small-widgets-ocean.png`, `cp-52-small-widgets-kerahat-warm.png` | Same in Ozean; in the prohibited time with Orange (violet) |
| `carplay/cp-60-standby.png`, `cp-61-standby-kerahat.png` | StandBy (approximated): iPhone landscape, left a widget of another app, right Vaqt „Nächstes Gebet“ without background (the „Tagesbogen“ looks the same), enlarged, dark |

## iPhone Duo – Phase 10

| Datei | Zeigt |
|---|---|
| `duo/closed-10-home.png` | iPhone Duo closed (outer 5.4″): Zeiten |
| `duo/closed-30-qibla.png` | iPhone Duo closed (outer 5.4″): Qibla |
| `duo/closed-40-guide.png` | iPhone Duo closed (outer 5.4″): Anleitung |
| `duo/closed-50-verses.png` | iPhone Duo closed (outer 5.4″): Verse |
| `duo/closed-60-qada.png` | iPhone Duo closed (outer 5.4″): Nachholen |
| `duo/closed-70-settings.png` | iPhone Duo closed (outer 5.4″): Settings (Back at the top of the bar column) |
| `duo/closed-85-sheet-city.png` | iPhone Duo closed (outer 5.4″): city sheet |
| `duo/closed-11-home-dark.png` | iPhone Duo closed (outer 5.4″): Zeiten dark |
| `duo/open-10-home.png` | iPhone Duo open (inner 7.6″): Zeiten |
| `duo/open-30-qibla.png` | iPhone Duo open (inner 7.6″): Qibla |
| `duo/open-40-guide.png` | iPhone Duo open (inner 7.6″): Anleitung |
| `duo/open-50-verses.png` | iPhone Duo open (inner 7.6″): Verse |
| `duo/open-60-qada.png` | iPhone Duo open (inner 7.6″): Nachholen |
| `duo/open-70-settings.png` | iPhone Duo open (inner 7.6″): Settings (Back at the top of the bar column) |
| `duo/open-85-sheet-city.png` | iPhone Duo open (inner 7.6″): city sheet |
| `duo/open-11-home-dark.png` | iPhone Duo open (inner 7.6″): Zeiten dark |
