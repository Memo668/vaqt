# Prayer Times (iOS) – Design Spec v0.7

Handoff for building the native SwiftUI app. The visual reference is `prayer-times-prototype.html` (single file, open it in a browser). Design tokens are in its `:root` CSS, every string is in the JS object `T` (DE/TR/EN/ES), mock data is in `CITIES` / `BERLIN_SUMMER` / `METHODS`, and the app state model is `S`.

Product guardrails: non-profit, no ads, no tracking, no accounts, no social features. All calculation happens on device. Since v0.3 there is a small "Verses" area (verse of the day, last 7 days); it is deliberately not a Quran reader.

---

## 1. Screens & navigation map

```
Onboarding (paged, first launch only, "Skip" on steps 1–2)
 ├─ 1 Welcome ─────────────── [Continue]
 ├─ 2 Location priming ────── [Allow Location] → iOS alert
 │                             ├─ allow → step 3
 │                             └─ deny  → City sheet (manual fallback) → step 3
 │                            [Choose City Manually] → City sheet → step 3
 └─ 3 Notification priming ── [Allow Notifications] → iOS alert → Main
                              [Not Now] → Main

Main = TabView with a floating Liquid Glass tab bar at the bottom: Gebete · Verse · Nachholen
 Every tab has the ⚙︎ Settings circle top left (glass); Settings is pushed onto that tab's stack.

Tab "Gebete" – top bar as in Projekt-Health "Heute" (decided 07.11.2026)
 ├─ Top bar: [⚙︎]  (Zeiten)  (Qibla)  (Anleitung)   ← four separate glass elements, no shared capsule
 ├─ Pages (swipe left/right or tap a chip; the bar stays fixed, content scrolls under it)
 │   ├─ Zeiten (Home)
 │   │   ├─ tap city / banner "Change" → City sheet (.large)
 │   │   ├─ bell per row → cycles Sound → Silent → Off (+ HUD toast)
 │   │   └─ high-latitude note "Change rule" → Settings › High Latitude
 │   ├─ Qibla
 │   └─ Anleitung (prayer guide) – opens on the prayer whose time it is now; segmented control for the other four
 │       └─ "Open Qibla" → Qibla page
 └─ ⚙︎ → Settings (nav bar with back button; no top bar there)

Tab "Verse"      – verse of the day (Arabic + translation + reference, Share, Copy); list of the last days, tap to show
Tab "Nachholen"  – Qada tracker: share made up in % + progress, per-prayer counters, daily plan, calculator for a missed period

Settings
     ├─ Location: Use Current Location (Toggle) · City → City sheet · [Open iOS Settings] when denied
     ├─ Calculation: Method → searchable list · Asr → picker · High Latitude → picker · Minute Adjustments → steppers
     ├─ Notifications: Per Prayer → segmented pickers · Reminder Before → picker · Live Activity → picker (Off · 30 · 60 min before) · Sound → picker · Preview Adhan → Adhan sheet
     ├─ Appearance: Appearance → picker · Language → picker · Show Kerahat Times (Toggle, default on)
     └─ About: Source Code ↗ · Privacy → page · Version   (footer: calculation disclaimer)

Sheets: City search (.large, searchable) · Adhan player (.large)
Outside the app: Widgets (small, medium, accessoryCircular, accessoryRectangular, accessoryInline) · Live Activity (Lock Screen, Dynamic Island compact / minimal / expanded) · Local notifications (prayer + reminder)
```

iPhone Duo (foldable, since 23.10.2026) uses the same map; only the bars move (see § 8).

---

## 2. Design tokens

**Colour** (map to semantic SwiftUI colours; only the accent is custom)

| Token | Light | Dark | SwiftUI |
|---|---|---|---|
| accent (Pine Teal) | `#1F7A6D` | `#4CC2AE` | Asset `AccentColor` |
| on-accent | `#FFFFFF` | `#04221D` | Text on accent fills |
| accent-tint | accent 13 % | accent 13 % | `.accent.opacity(0.13)` |
| label / label-3 | system | system | `.primary` / `.tertiary` |
| label-2 (textSecondary) | `#6C6C70` | `secondaryLabel` | Same token as Projekt-Health: 4.7 : 1 on page, 5.2 : 1 on card (system secondary only ≈ 3.4 : 1 in light) |
| bg-grouped / bg-cell | `#F2F2F7` / `#FFF` | `#000` / `#1C1C1E` | `systemGroupedBackground` / `secondarySystemGroupedBackground` |
| separator | system | system | `Color(.separator)` |
| fill-3 | system | system | `tertiarySystemFill` |
| arc-track | accent 20 % on background | accent 30 % on background | Upcoming part of the day arc |
| kerahat / kerahat-text | `#C7862A` / `#9A6212` | `#D9A04E` / `#E3B36B` | Kerahat marks (arc at 50 % opacity, 95 % while active) / caption text while active |

Contrast: accent on white 5.2 : 1, dark accent on `#1C1C1E` 7.8 : 1, on-accent text ≥ 5 : 1 in both modes.
Alternative accents (prototype panel): Deep Green `#2E7D4F`/`#5FCB8A`, Night Indigo `#4252B5`/`#8E9BFF`, Desert Sand `#8F6420`/`#E2B566`.

**Spacing** 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · list inset 16 · min. touch target 44 · prayer row 52 (compact 44)
**Radii** 6 · 10 · 26 (list groups and cards, `.continuous`, as Projekt-Health) · 20 (player card) · 22 (widgets) · 24 (sheets) · capsule buttons and chips · 56 (screen)
**Top bar** gap 8 between the glass elements; if the labels don't fit (German, large text), unselected chips collapse to 52 pt glass circles (icon only) · height 52 (label chips) / 56 (label + value), grows with Dynamic Type up to AX1 · page margin 16
**Prayer cards** radius 18 (`--r-row`), gap 8 (compact 6), height 52 (compact 44)
**Tab bar** floating, 62 high, 22 from the sides and the bottom edge
**Type** (system text styles, Dynamic Type on): largeTitle 34 bold · title2 22 semibold (city) · title3 20 · headline/body 17 · subheadline 15 · footnote 13 · caption 12/11.
Countdown: 64 pt thin, `monospacedDigit()`, `@ScaledMetric` capped at ×1.05 (×0.86 when ≥ 10 h); inside the day arc 56 pt (50 pt when ≥ 10 h).
**Motion**: native push, sheets and toggles; small "pop" on the bell (`.bouncy`); respect Reduce Motion.
**Icons**: SF Symbols, e.g. `sun.horizon`, `sunrise`, `sun.max`, `sun.min`, `sunset`, `moon.stars`, `bell.and.waves.left.and.right`, `bell`, `bell.slash`, `location.fill`, `location.slash`, `wifi.slash`, `safari`, `gearshape`.

---

## 3. Components

| Component | Notes |
|---|---|
| TopBar | Fixed via `safeAreaBar(edge: .top)` in a `GlassEffectContainer(spacing: 8)`: four separate glass elements side by side, no shared capsule. Left the circular Settings button (`gearshape`, `.buttonStyle(.glass)`, `.buttonBorderShape(.circle)`, ≥ 44 pt), then the chips "Zeiten", "Qibla" and "Anleitung", each its own capsule (`.glassEffect(.regular.interactive(), in: Capsule())`). Wrapped in `ViewThatFits`: all labels if they fit, otherwise only the selected chip keeps its label and the others become circles. Selected chip: tinted glass (`.glassEffect(.regular.tint(.accentColor.opacity(0.17)).interactive())`), symbol and label in accent, soft accent shadow; **no outline**. Unselected: plain glass, label colour, grey symbol. Chip = SF Symbol + label (`.headline`). Variant "label + value": small name (`.caption`, textSecondary) over the value (`.headline`, monospaced digits); Zeiten shows the next prayer's symbol and time, Qibla the bearing, Anleitung the prayer it opens on. Text grows up to AX1, then Large Content Viewer. Tablist/tab semantics, `isSelected` trait. |
| Pager | Three pages (Zeiten, Qibla, Anleitung) as `TabView(.page)` or a paging `ScrollView`; switch by swipe or chip tap; the selection is kept. Each page scrolls vertically under the bar (system scroll-edge effect). |
| TabBar | System `TabView` (iOS 26 floating glass) with three tabs: Gebete (`moon.stars`), Verse (`book`), Nachholen (`clock.arrow.circlepath`). Selected tab in accent on a lighter glass pill. |
| PrayerRow | Standalone card (no grouped list): SF icon · name · "Now" chip (not colour-only) · time (monospaced) · BellButton 44×44. States: current (card mixed with 15 % accent + soft accent shadow, semibold accent text), passed (textSecondary), upcoming. High-latitude rows get an `info.circle` mark. Kerahat caption under the name (`.caption`, textSecondary, 5 pt dot in the Kerahat colour): Sunrise "Kerahat 07:14–07:59", Dhuhr "Kerahat 11:42–11:52", Asr "Kerahat 15:42–16:27" (the window falls at the end of Asr time). While a window is active: "Kerahat bis 16:27" in kerahat-text. The time range never breaks across lines. |
| BellButton | 3 states sound/silent/off, cycles on tap, VoiceOver label "Fajr notification: Sound. Tap to change.", HUD toast + `.selection` haptic. |
| DayArc | Thick circular arc (≈128°, stroke 12 pt, round caps) for the prayer day from Fajr (left end) to Isha (right end). The five prayers sit on the arc as round icon markers (30 pt; current 34 pt with a soft glow), placed by time. Upcoming = tinted track colour (accent 20 % on background, 30 % in dark) with an accent icon; begun = filled accent with a white icon. The solid accent part of the track runs from Fajr to "now"; a white knob (14 pt, light shadow) marks "now" and hides under the current marker. Each marker carries its time outside the curve (below the two end markers); the current time label is accent and bold. When two prayers sit close together (e.g. Maghrib → Isha in Jakarta), the later marker gets a 3 pt background ring. Kerahat windows are thin 3 pt segments just inside the track (radius − 19 pt, 50 % opacity, 95 % while active), so they stay visible next to the markers. The countdown sits inside the arc at 56 pt (50 pt from 10 h, text style 32 pt). Sunrise is not a marker (not a prayer). VoiceOver: "3 of 5 prayer times have begun today". In RTL Fajr starts on the right; numbers and icons are not mirrored. Optional (variant). SwiftUI: `Canvas` or `Shape` + `trim(from:to:)` for the progress, markers as overlaid views. |
| Countdown | `Text(timerInterval:)` or `TimelineView(.periodic(by: 1))`. Label "Asr in" / "Fajr tomorrow in". |
| Inset grouped rows | NavigationLink with value · Toggle (accent tint) · Stepper with value + resulting time subtitle · checkmark pickers · destructive "Reset" row. |
| Segmented icon picker | Per-prayer notification state (same three symbols as the bell). |
| Searchable list | `.searchable` for methods and cities, "No Results" row. |
| Sheets | `.presentationDetents([.large])`, drag indicator, Cancel/Close. |
| HUD toast | Glass capsule above the home indicator (the top is now taken by the bar), about 1.7 s. |
| Banner / note / hint pill | Location denied (banner + "Change"), high latitude (note card + link), offline (small pill). |
| Compass | Dial with 5° ticks, upright cardinal labels, N in red, accent Qibla needle + Kaaba marker, fixed lubber line. Aligned within ±3° → accent + `.success` haptic. |
| Adhan player | Title (voice), waveform (played part in accent), scrubber, 72 pt play/pause, voice list (placeholders), Fajr variant toggle. |
| Widgets | systemSmall (next prayer + timer) · systemMedium (next + all six times, next highlighted) · accessoryCircular (Gauge from previous → next) · accessoryRectangular (next, timer, following) · accessoryInline (icon + "Asr 14:00"). |
| Live Activity | ActivityKit + WidgetKit extension. **Lock Screen** (≤ 160 pt): accent background (`activityBackgroundTint`, light accent in both modes), header app glyph + name / city, the day arc in white (7 pt track, 21 pt markers, Kerahat marks in warm yellow), inside the arc "Maghrib · 16:27" and the countdown (30 pt rounded bold, `Text(timerInterval:)`). **Dynamic Island compact**: leading prayer symbol, trailing countdown, both in the dark accent. **Minimal**: prayer symbol in a progress ring. **Expanded**: leading symbol + time, trailing city, caption "Maghrib in", countdown 38 pt, bar from the previous event to the next with the Kerahat window as a 2 pt line under the bar, ends labelled ("Asr 14:00" / "Maghrib 16:27"). No buttons. |
| Notifications | Title "Dhuhr · 13:12", body "It's time for Dhuhr in Berlin." Reminder: "Dhuhr in 10 minutes". |
| Verse card | Card radius 26: caption line (VERSE OF THE DAY · date), Arabic text right-aligned (system Arabic font, ~29 pt, `lang="ar"`), translation (`.body`), reference in accent ("Al-Baqara 2:45"), Share (ShareLink) and Copy as capsule buttons. Footer: translation source. Below: last days as standalone cards (date, two lines of translation, reference); tap shows that verse. |
| Prayer guide | Segmented control with the five prayers (dot = current prayer). Header card: status (NOW / UP NEXT) + time window, prayer name with symbol, three fact tiles (fard rakʿahs · recitation aloud/silent · sunnah), rakʿah sequence (numbered dots, filled = aloud, tinted = silent, "Sit" after the 2nd, "Sit · Salām" at the end), note "From the 3rd rakʿah only al-Fātiḥa", button "Back to current prayer" after a manual pick. "Before you begin": wuḍūʾ, clean place/clothing, face the Qibla (button to the Qibla page), intention with prayer name and rakʿahs. "Steps": 7 standalone cards with posture pictogram (takbīr, qiyām, rukūʿ, iʿtidāl, sujūd, tashahhud, salām), short instruction, Arabic formula + transliteration; a dashed card "repeat steps 2–5 for each further rakʿah". Footer: details differ between schools of law. |
| Qada tracker | Summary card: share made up in percent as the largest figure (56 pt rounded bold, accent; one decimal below 10 %, e.g. "4,9 %"), caption "nachgeholt", progress bar, then small: "133 of 2,725 made up" · "2,592 still open". The open count is deliberately small so a large number doesn't discourage; the finish date sits under "Plan". "By prayer": standalone cards with icon, name, count and stepper (− = one made up, + = one more open). "Plan": per-day stepper. "Missed period": steppers for years/months/days, Witr toggle (Hanafi), result line, "Set as open" action. Footer: scholars differ, ask your imam. |

---

## 4. Interaction notes

- **Current prayer logic**: the latest event ≤ now on a 3-day timeline. Sunrise ends Fajr (Sunrise → Dhuhr: nothing current). Before Fajr: nothing highlighted, countdown to Fajr. After Isha: Isha highlighted, label "Fajr tomorrow in". Isha may fall after midnight (high latitude, "middle of the night").
- At 0:00 the highlight moves and rows re-dim (one re-render per phase change; the countdown updates every second).
- Choosing a city switches to manual location. "Current Location" switches back (disabled when permission is denied).
- Minute adjustments ±30 min per time, applied immediately everywhere (Home, widgets, notifications).
- Top bar: tap a chip or swipe horizontally to switch pages (rubber band at both ends, no movement with Reduce Motion). ⚙︎ pushes Settings; back returns to the page that was visible.
- Bottom tabs switch areas; the gear on every tab opens Settings in that tab's stack (prototype: switching tabs closes Settings).
- Prayer guide: shows the current prayer (the latest begun one; before Fajr still Isha; between sunrise and Dhuhr the next one, Dhuhr). A manual pick stays until the current prayer changes or the user leaves the page; then it follows the time again.
- Arc: markers change state only at prayer boundaries; the knob and the accent line move every second.
- Kerahat (Hanafi / Diyanet practice): sunrise → +45 min, Dhuhr − 10 min → Dhuhr, Maghrib − 45 min → Maghrib; computed from the adjusted times. Toggle in Settings › Appearance (default on). Active window = re-render (part of the phase key). Display only – no notifications.
- Live Activity: scheduled per prayer with `Activity.request(…, start:)` (iOS 26, works without a server and while the app is in the background; needs an `AlertConfiguration`). Starts 30 min (or 60) before the prayer, counts down with `Text(timerInterval:)`; `staleDate` = prayer time, so the view switches to "Now: Maghrib" via `context.isStale`; dismissal 15 min after the start. The system limit is 8 h active (+ up to 4 h on the Lock Screen); old activities are ended on the next launch / background refresh. The app's own Live Activity is hidden in the Dynamic Island while the app is open.
- Verses: one verse per day (rotating list); tap an entry of the last days to show it on top. Share opens the system share sheet with Arabic, translation and reference.
- Qada: missed period → days = years × 365 + months × 30 + days; open per prayer = days (+ Witr if on); "Set as open" replaces the counts. "−" marks one prayer as made up, "+" adds one open prayer. Finish date = today + ⌈open ÷ per day⌉ days.
- Sheets close via swipe, Cancel/✕ and Esc (prototype).
- Qibla: heading from `CLLocationManager` (true north). Show the calibration card only when `headingAccuracy` is poor (prototype shows it permanently). Mecca: message instead of a needle.
- Adhan preview: clip ≤ 30 s (iOS limit for `UNNotificationSound`), Fajr variant is a separate clip.
- Accessibility: 44 pt targets, visible focus, VoiceOver labels on all icon buttons, "Now" chip in addition to colour, Dynamic Type up to AX sizes (rows wrap, countdown capped).

---

## 5. State handling

| State | UI behaviour |
|---|---|
| Location not determined / allowed | City with `location.fill`; Settings toggle on |
| Location denied | Banner on Home + manual city; toggle disabled; "Open iOS Settings" row; Current Location row disabled in city sheet |
| Notifications denied | Settings footer hint; bells remain editable (preference stored) |
| Offline | Small hint pill only; everything works (calculation is local); city search shows saved cities only |
| High latitude (≈ ≥ 48°, summer) | Info marks on Fajr/Isha, note card with active rule, rule picker (angle-based default · 1/7 night · middle of night) |
| Large Dynamic Type | Text scales; countdown capped; list scrolls; labels hyphenate/wrap |
| RTL (Arabic later) | Mirrored layout, arc runs right → left (Fajr on the right), compass, numbers and arc icons not mirrored |
| Appearance | System / Light / Dark (app override) |
| Qada data | Stored on device only (SwiftData/UserDefaults), included in no export; empty state when nothing is entered |

Model (mirrors `S` in the prototype): `city`, `autoLocation`, `method` (nil = automatic per country), `asr`, `highLatitudeRule`, `adjustments[6]`, `notification[6]`, `reminderMinutes`, `liveActivityLead` (0/30/60), `showKerahat`, `sound`, `appearance`, `language`, `section` (tab), `qada { years, months, days, witr, perDay, total[6], open[6] }`.
Automatic method per country (proposal): DE → MWL, TR → Diyanet, ES → MWL, SA → Umm al-Qura, ID → Kemenag.

---

## 6. Open questions / decisions

1. Germany default method: MWL or Diyanet? Many mosques in Germany (DITIB) publish Diyanet times.
2. High-latitude default rule: angle-based (proposal) vs. 1/7 of the night.
3. Calculation library: own implementation or an open-source library (e.g. Adhan Swift, MIT)? It must stay offline and tracking-free.
4. iOS allows at most 64 pending local notifications → schedule a rolling window of about 9–10 days, refresh on app launch / background refresh.
5. Adhan recordings: source, licence, number of voices; full Adhan in-app or only the 30 s clip?
6. Time-sensitive notifications (break through Focus)? Needs the entitlement and a justification for review.
7. Hijri date: Umm al-Qura calendar vs. local moon sighting; ±1 day correction setting?
8. Passed rows now use textSecondary `#6C6C70` (4.7 : 1). Is that enough dimming, or should passed rows get an extra marker?
9. Brand: app name per language and app icon (the crescent in the prototype is a placeholder).
10. Minimum iOS version: the top bar uses `glassEffect`, `GlassEffectContainer` and `.buttonStyle(.glass)` (iOS 26). Deployment target iOS 26, like Projekt-Health?
11. Share a small design package with Projekt-Health (tokens, top bar, card radius 26), or keep the two apps independent?
12. Verses: which translations, with which licence (e.g. DE Bubenheim/Elyas, TR Diyanet meali, EN Sahih International, ES Isa García)? The prototype uses placeholder translations. Arabic text source (e.g. Tanzil, Uthmani script) with attribution. Who picks the verses (fixed curated list vs. rotation)?
13. Qada: count a year as 365 (solar) or 354 (lunar) days? Witr default on for Hanafi users? Reminder to make up prayers (e.g. after each prayer)? Should it be possible to hide the area entirely?
14. Prayer guide: who reviews the texts (imam / scholar per language)? One neutral version, or variants per school (Hanafi, Shafiʿi …) and for women? Real illustrations instead of line pictograms? Audio for the formulas?
15. Kerahat durations: the prototype uses 45 / 10 / 45 min (common Turkish practice). Sources differ for the zenith window (about 10 min vs. 45 min before Dhuhr) and other schools use shorter windows after sunrise (≈ 15–20 min). Fixed values, per method/school, or editable minutes? Name per language (DE "Kerahat", TR "Kerahat", EN/ES "Makruh")?
16. Live Activity: lead time 30 min (default) or 60; one activity per prayer or one per day phase? Should it also run for Sunrise (end of Fajr)? Scheduled starts need iOS 26 – for older systems only start while the app is open, or no Live Activity?
17. iPhone Duo: support the inner display in portrait (horizontal bars), the half-folded "table pose" and Split View next to another app (bar moves to the left edge when the app is on the left)? Not built in the prototype. Widgets/Live Activity were only drawn for the regular iPhone.

---

## 7. Design variants to decide

| # | Decision | Options (default first) |
|---|---|---|
| 1 | Accent colour | Pine Teal · Deep Green · Night Indigo · Desert Sand |
| 2 | Countdown style | Digital `1:17:23` · relative text "1 h 17 min" |
| 3 | Day arc | On (behind countdown) · off (more compact Home) |
| 4 | Row density | Regular 52 pt · compact 44 pt |
| 5 | Navigation | **Decided 07.11.2026:** top bar in Liquid Glass (Settings circle + Zeiten/Qibla chips), as in Projekt-Health |
| 5b | Top bar chips | Label only (default) · label + value (next prayer time / Qibla bearing) |
| 5c | Arc markers | Placed by time (default; shows the long gap before Dhuhr) · evenly spaced (calmer, less precise) · thin line with dots (v0.3) vs. thick track with icon markers (v0.5, default) |
| 5d | Bottom tabs | Gebete · Verse · Nachholen (default) · later also a Dhikr counter or Hijri calendar (not in scope yet) |
| 5e | Prayer guide name | Anleitung (DE) · Rehber (TR) · Guide (EN) · Guía (ES) – alternatives: "So betest du", "Gebet lernen" |
| 5f | Top bar when crowded | Unselected chips as icon circles (default, `ViewThatFits`) · horizontally scrolling chips as in Projekt-Health |
| 5g | Kerahat marking | Thin segments inside the arc + row captions (default) · row captions only · off |
| 5h | Live Activity look | Accent background with the day arc (default) · system material with a linear bar (calmer, closer to Apple's timers) |
| 5i | iPhone Duo inner display | Two columns at the fold (default) · tab bar as a sidebar on the left (iPad style) |
| 6 | Highlight | Current prayer (app) · next prayer (as in the widgets) |
| 7 | Notification control | Bell on every Home row · Settings only (calmer Home) |
| 8 | Hijri date | Always shown under the Gregorian date · tap to switch |

Variants 1–4 and 5b can be switched live in the prototype panel ("Design variants").

---

## 8. iPhone Duo (foldable)

Two size classes, one hierarchy: the outer display is compact width, the inner display (open) is regular width. Same screens, same navigation as on iPhone; only the bars and the column layout change. Prototype: panel › Device › "Duo closed" / "Duo open". Point sizes are taken from published screenshots (outer ≈ 466 × 678 pt, inner ≈ 951 × 669 pt landscape, 3x) – verify in Xcode once Device Hub supports the Duo.

| Area | Outer display (closed) | Inner display (open, landscape) |
|---|---|---|
| Bars | Vertical column on the **right** edge (76 pt): top bar (⚙︎ + Zeiten/Qibla/Anleitung as icon-only glass circles, selected = tinted) and the tab bar (Gebete/Verse/Nachholen, icon + small label) at the bottom. Same physical side in RTL. | Same column on the right (bars stay vertical in landscape). In portrait the bars return to horizontal (not built yet). |
| System | Dynamic Island vertical in the upper-right corner around the front camera, circular status element below it. | No visible camera; the island only appears for Live Activities/alerts. Status element in the corner. |
| Pushed pages | Back moves to the top of the bar column; large title stays in the content. | Same; Settings content as a centred 600 pt column. |
| Content | 390 pt wide – the iPhone layouts fit unchanged, without the top and bottom bars (more vertical room). | Two columns that meet at the fold (left 475 pt): Zeiten = city, date, day arc ‖ prayer cards · Qibla = compass ‖ bearing, distance, calibration · Anleitung = prayer picker, header card, Vorher ‖ Ablauf · Verse = verse card ‖ last days · Nachholen = %, plan ‖ by prayer, calculator. In RTL the columns swap but still meet at the fold. |
| Sheets / alerts | Sheet up to the bar column. | Sheet as a centred 600 pt card; alerts centred in the right half (trailing side in book pose). |

SwiftUI: keep `TabView` and `NavigationStack` (the system lays the bars out vertically – custom bars don't get this); branch on `horizontalSizeClass` for the two-column layout; no fixed widths. Live Activities need no changes – the vertical Dynamic Island shows them.

---

## Changelog

- **v0.7 (09.11.2026):** iPhone Duo: outer display with the bars in a vertical column on the right (vertical Dynamic Island, circular status), inner display with two columns that meet at the fold. Panel: Device switch.
- **v0.6 (09.11.2026):** Qada summary shows the share made up in percent as the largest figure (open count small). Kerahat times subtly marked on the arc (thin inner segments) and on the Sunrise/Dhuhr/Asr rows, with a toggle in Settings. New Live Activity: Lock Screen with the day arc, Dynamic Island compact and expanded; setting "Live Activity" (Off/30/60 min before). Prototype panel: view "Live Activity".
- **v0.5 (08.11.2026):** Day arc redrawn after the TaubatApp widget reference: thick track, prayers as icon markers on the arc with their times outside the curve, white "now" knob, countdown inside the arc slightly smaller.
- **v0.4 (07.11.2026):** Third chip "Anleitung" in the top bar of the Gebete tab: step-by-step prayer guide that always opens on the current prayer (rakʿah count, aloud/silent, sunnah, before-you-begin, 7 steps with pictograms and formulas). Unselected chips collapse to glass circles when the labels don't fit.
- **v0.3 (07.11.2026):** Top bar elements now stand alone (Settings circle, Zeiten, Qibla as separate glass bubbles; selection = tinted glass, no outline). Prayer times as standalone cards. Arc now spans Fajr → Isha with five prayer dots (hollow → filled). New bottom tab bar with the areas Gebete, Verse (verse of the day) and Nachholen (Qada tracker and calculator).
- **v0.2 (07.11.2026):** Bottom tab bar replaced by a top bar in Liquid Glass, aligned with Projekt-Health "Heute": Settings as a separate circle on the left, Zeiten and Qibla as chips in a glass capsule; swipe between the two pages; Settings is a pushed page. List groups radius 26, textSecondary `#6C6C70`, toast moved to the bottom.
- **v0.1 (07.11.2026):** First prototype.
