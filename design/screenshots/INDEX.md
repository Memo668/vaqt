# Referenz-Screenshots

Aus dem Prototyp `prayer-times-prototype.html` erzeugt, nur der Bildschirm ohne Gerätrahmen, 2x.
iPhone: 390 × 844 pt · iPhone Duo zu: 466 × 678 pt · iPhone Duo auf: 951 × 669 pt.
Uhrzeiten/Zahlen stammen aus den Mock-Daten des Prototyps (Berlin, 10.11.2026). Mit `-debugFixtureTimes` zeigt die App dieselben Werte.
Wenn nichts anderes steht: Deutsch, hell, Berlin, 14:25 (Asr aktiv).

**Stand v0.8 (Phase 12, 15.11.2026):** Die Bilder unter `iphone/` hat `scripts/capture-prototype` aus dem Prototyp v0.8 neu aufgenommen (Spec § 9) – alle Zustände stehen in `scripts/capture-prototype.mjs`. Neu sind die dunklen Fassungen der geänderten Bildschirme (`-dark`) und `05`, `23`, `33`, `34`, `82`, `83`. Noch von v0.7 sind `73`, `74`, `76`–`81`, `85`, `86` und alle `duo/*`.

**Spec v0.9 (18.11.2026, § 10):** Neu aufgenommen sind die Bilder, deren Texte oder Aussehen sich geändert haben. Das sind „Verbotszeit“ mit Infopunkt, die längeren Abschnitte im Bogen, Onboarding und Datenschutztexte, der Rechner mit „Für wen?“ und „Alles zurücksetzen“, die Live-Aktivität mit 30 % und das Widget „Live“: `iphone/01`–`04`, `10`–`23`, `30`–`34`, `40`–`50`, `60`, `61`, `70`–`75`, `system/90`–`96`. Im Prototyp scheint das Widget „Live“ mit 30 % durch; in der App bleibt es deckend (`docs/OPEN-QUESTIONS.md`, „Annahmen in Phase 16“).

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
| `iphone/03-onboarding-3-notifications.png` | Onboarding step 3 (notification priming) |
| `iphone/04-alert-location.png` | iOS location alert over step 2 (system UI, for flow context only) |
| `iphone/05-onboarding-4-free.png` | Onboarding step 4 „Kostenlos. Ohne Werbung.“ (§ 9.9) |
| `iphone/05-onboarding-4-free-dark.png` | Same in dark mode |

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
| `iphone/50-verses.png` | Verse tab: verse of the day + last days |
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

## Sheets – Phase 3 (Stadt) und 7 (Adhan)

| Datei | Zeigt |
|---|---|
| `iphone/85-sheet-city.png` | City sheet (.large, searchable) |
| `iphone/86-sheet-adhan.png` | Adhan player sheet |

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
