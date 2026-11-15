# Prayer Times (iOS) – Design Spec v0.8

Handoff for building the native SwiftUI app. The visual reference is `prayer-times-prototype.html` (single file, open it in a browser). Design tokens are in its `:root` CSS, every string is in the JS object `T` (16 languages since v0.8, § 9.10), mock data is in `CITIES` / `BERLIN_SUMMER` / `METHODS`, and the app state model is `S`.

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

## 9. Changes before the first beta (v0.8, approved 15.11.2026)

Requested by the product owner after Phase 11 and approved in the prototype ("Passt, umsetzen", 15.11.2026). The prototype panel lists each change under "Änderungen vom 15.11.2026" and jumps to it. Where this section and older sections disagree, this section wins.

### 9.1 App icon everywhere
The real app icon (light and dark variant of `AppIcon`) replaces the crescent glyph wherever the brand mark appears: Onboarding step 1 (120 pt, corner radius 22.4 %, soft shadow), the tagline at the end of Settings (34 pt), Live Activity header (16 pt, radius 4), the new Live-style widget header (16 pt). Notifications and the Home Screen show the system icon anyway. SwiftUI cannot load `AppIcon` as an image: add an image set with the same artwork.

### 9.2 Top bar centred
On iPhone and the Duo when not in rail mode the chips sit centred; the Settings circle moves to the **trailing** edge; a leading spacer of the circle's width keeps the chips centred. The collapse rule is unchanged (unselected chips shrink to circles when the labels don't fit). Duo rail: the circle stays at the top of the column. RTL mirrors (circle leading).

### 9.3 Kerahat drawn on the arc
The three kerahat windows are drawn **on the track itself**: full track width (12 pt Home, 7 pt Live Activity and Live widget, 5 pt striped on the Lock Screen widget), butt caps, colour `kerahat` (light `#C7862A`, dark `#D9A04E`; on the accent background of Live Activity/widget `#F3C979`); opacity 0.92, windows already over 0.42, the active one 1.0. No times in the arc – the times stay on the Sunrise/Dhuhr/Asr rows exactly as in v0.6 ("Kerahat 07:14–07:59", "Kerahat bis 07:59"). Settings footer: "Im Bogen eingezeichnet, die Uhrzeiten stehen bei den Zeiten …".

### 9.4 Previous and next day
- Under the city: the date block (Gregorian + Hijri) with a chevron button on each side – 16 pt glyph, `label-3`, no background, 44 pt hit area. Range ±365 days. RTL mirrors.
- On another day a small text link "Zurück zu heute" (caption 1, accent) appears under the date.
- Another day: the arc shows that day's times and kerahat windows without progress and without the "now" knob; instead of the countdown the hero shows the relative day (system `RelativeDateTimeFormatter`, numeric auto, first letter capitalised: "Morgen", "Übermorgen", "In 3 Tagen") and the short date ("Di., 17. Nov.", 40 pt light). The rows show that day's times and kerahat; no "now" or passed state.
- Notifications, widgets, Live Activity and the countdown always stay on today.

### 9.5 Qibla tolerance
A wedge of **±40° (80° in total)** centred on the Qibla bearing, from radius 22 to 144 (dial `viewBox` −150…150): fill accent 11 % (22 % while the heading is inside), dashed edges accent 50 %. Status: |difference| ≤ 3° → "Du blickst Richtung Qibla" (unchanged); ≤ 40° → "Im Toleranzbereich" with check mark, below it small "Nach rechts drehen 25°"; otherwise the turn hint. Under the bearing line a legend: swatch + "Der markierte Bereich reicht 40° zu jeder Seite der Qibla."

### 9.6 Prayer step by step
- Entry: primary button "Gebet Schritt für Schritt" (play symbol) in the guide's header card, under it "Haltung für Haltung durch alle {n} Rakʿas von {p}." Opens a full-screen cover for the selected prayer.
- Sequence (whole prayer): intro (prayer icon, "{p} · {n} Rakʿas", wudu/Qibla/niyya text, rakʿa dots) → takbīr (1st rakʿa only) → per rakʿa: qiyām (badge "Rezitation: laut/leise"; rakʿa 1–2 "Fātiḥa, danach eine weitere Sure", from rakʿa 3 "nur al-Fātiḥa"), rukūʿ, iʿtidāl, sujūd ("Sprich dreimal"), short sitting (jalsa), second sujūd → after rakʿa 2 of a 3- or 4-rakʿa prayer the first sitting (tashahhud) → at the end the last sitting, salām and "Gebet beendet – Möge Allah dein Gebet annehmen." Dhuhr: 28 steps plus intro and end.
- Layout: close button, title = prayer, subtitle "Rakʿa 2 von 4 · Schritt 9 von 28", progress bar 4 pt; pose tile 172 pt (radius 44, accent tint) with the pictogram at 126 pt; title 1 bold; body text max ≈ 30 characters per line; formula card (Arabic 27 pt Amiri, transliteration italic); buttons "Zurück" (tinted) and "Weiter" (primary) at 1 : 1.6, last step "Fertig". Steps slide 22 pt in reading direction; Reduce Motion: cross-fade only. VoiceOver announces the step line.
- New texts for jalsa, second sujūd, first/last sitting are drafts and need the same expert review as the rest of the guide (§ 6.14).

### 9.7 Arabic typeface
Verses: **Amiri Quran** 31 pt, line height 2.15. Formulas: **Amiri** 23 pt (guide), 27 pt (step by step). Both SIL Open Font License 1.1: bundle the font files, register them, and list the licence on the licences page.

### 9.8 Qada calculator
Own card at the **very bottom** of the page (after the counters per prayer, before the footnote): accent tile with the qada symbol, title "Nachholgebete berechnen", lead "Wie lange hast du nicht regelmäßig gebetet? Ein ungefährer Zeitraum reicht."; three numbered steps – 1 Zeitraum (tiles Jahre/Monate/Tage, each with a stepper), 2 Witr switch, 3 Ergebnis (number 40 pt rounded accent + "Gebete nachzuholen", detail "545 Tage × 5 Gebete"); primary button "Als offen übernehmen" (disabled at 0 days) and the existing footnote. Card outline: inset 1.5 pt accent 30 %. Page order: title, intro, progress card, daily plan, counters, calculator, footnote.

### 9.9 Free, no ads – and support
- Onboarding gets a 4th page "Kostenlos. Ohne Werbung." (heart badge, text, chips "Keine Werbung / Kein Tracking / Kein Konto", button "Los geht's"). "Überspringen", "Später" and the answer to the notification prompt lead to this page; 4 dots.
- Settings: own group with the row "{App} unterstützen" (red heart, subline "Kostenlos und werbefrei, dank Spenden") → page "Unterstützen": hero, "Wofür Spenden gedacht sind" (Apple developer account 99 € a year, maintenance, content), card "Spenden sind bald möglich" with "App weiterempfehlen" (share sheet), footnote "Spenden sind freiwillig …".
- **No payment in v1** (decided 15.11.2026, "Erst nur der Hinweis"). A later donation needs In-App Purchase (Apple's rule for supporting developers) and the paid-apps agreement.

### 9.10 Sixteen languages
DE, TR, EN, ES plus **FR, NL, BS, SQ, AR, UR, ID, MS, BN, FA, RU, IT** (decided 15.11.2026). Arabic, Urdu and Persian are right-to-left: the layout mirrors (arc from right to left, chevrons, columns). All strings live in `T` (prototype) / the String Catalog; the twelve new languages are AI drafts and need a native-speaker review before the App Store. Counts need plural variants in the catalog (several drafts use a fixed plural): the forms per language and text are in `PLURAL` (CLDR categories, `t()` picks them with `Intl.PluralRules`), the catalog gets them as plural variations. Verse translations exist only for DE/TR/EN/ES (placeholders); other languages fall back to English, Arabic shows no translation under the verse. Dates use the system calendar of the locale (fa-IR shows the Persian calendar); if that calendar is itself Islamic (e.g. ar-SA), the first date line stays Gregorian so the Hijri date does not appear twice (decided 15.11.2026). Digits follow the system of the locale (decided 15.11.2026): Persian always uses ۰–۹, Arabic uses ٠–٩ only where the region does (e.g. Saudi Arabia, Egypt), Urdu and Bengali use 0–9 – prayer times, countdowns, numbers, dates and the digits inside texts alike. The prototype keeps times in 0–9.

### 9.11 Live Activity and widgets with the same arc
- Live Activity: kerahat on the track as in § 9.3.
- Lock Screen rectangular widget, in the Live Activity style (changed after review, 15.11.2026): the arc centred in the widget (ARCS `acc`, 160 × 72 pt incl. the text; track 5 pt with the filled progress, prayer markers 13 pt with symbol, the current one 15 pt with a glow, knob 3.6 pt with a white ring), inside the arc "{p} · {time}" (11 pt semibold) and the countdown (17 pt rounded bold). No times at the arc ends – too small to read. The Lock Screen is monochrome: everything is white, graded by opacity; dark parts (symbols on begun markers, the knob's centre, the gap ring of close markers) show through. Kerahat is striped on the track (dark base, white dashes 1.6/1.4) so it reads on the filled and the open part; windows already over 0.5.
- New **medium Home Screen widget "Live"** in the Live Activity look: accent gradient, header (icon + app name, city), arc 314 × 116 pt with times, "{p} · {time}", countdown 30 pt rounded bold. The existing widgets stay.
- Assumption: "das große Sperrbildschirm-Widget" = the rectangular Lock Screen widget. If the medium list widget was meant, it gets the arc instead.

### 9.12 High latitudes: manual angles
Fourth rule "Manuelle Winkel" (subline "Eigene Dämmerungswinkel für Fadschr und Ischa"). When selected, a group "Dämmerungswinkel" with steppers for Fadschr and Ischa, 10–20°, default 15°. Calculation: the chosen angles; the night portion angle ÷ 60 is the safe bound (Adhan: custom `fajrAngle`/`ishaAngle` with `.twilightAngle`). Footer: "Erreicht die Sonne den eingestellten Winkel nicht, gilt der entsprechende Anteil der Nacht (Winkel ÷ 60)."

### 9.13 Name (working name)
Decided by the product owner on 15.11.2026 ("Vaqt als Arbeitsname"): the app is called **Vaqt** – under the icon (`CFBundleDisplayName` of the app and the widget extension), in the app, the Live Activity, the widget gallery and the system alerts. The name is the same in every language and is not translated (`T.appName` = "Vaqt" in all 16 languages; `alLocTitle`/`alNotTitle` quote it). Only the name changes, not the word: where "Gebetszeiten" / "Namaz vakitleri" / "Prayer times" / "horarios de oración" means prayer times ("Gebetszeiten. Ruhig und genau.", the disclaimer, `noTimes`), it stays.
- App Store name: **"Vaqt – Prayer Time"**, because "Vaqt" alone is taken.
- Unchanged, because nobody sees them: bundle ID `de.mehmetyilmaz.gebetszeiten`, App Group, target, scheme, folder and type names.
- Open before the App Store: there already are "Vaqt" (Lifestyle) and "Vaqt: Prayer Times & Qibla" (a prayer times app; German store "Vaqt: Gebetszeiten & Qibla"). The final name is decided before the App Store release.

---

## Changelog
- **v0.8, addendum 3 (15.11.2026):** plural forms for counted texts in `PLURAL`, digits and calendar per locale (§ 9.10).
- **v0.8, addendum 2 (15.11.2026):** Lock Screen rectangular widget in the Live Activity style – arc centred, markers with symbols, knob with ring, prayer and countdown inside the arc, kerahat striped (§ 9.11).
- **v0.8, addendum (15.11.2026):** working name "Vaqt" under the icon and in the app, App Store name "Vaqt – Prayer Time" (§ 9.13).
- **v0.8 (15.11.2026):** Changes before the first beta (§ 9): app icon everywhere, top bar centred with Settings on the trailing side, kerahat drawn on the arc (times stay on the rows), previous/next day, Qibla tolerance ±40°, prayer step by step, Amiri typefaces, qada calculator card at the bottom, onboarding page "Kostenlos. Ohne Werbung." and support page, 16 languages with RTL, same arc in Live Activity and widgets plus a Live-style medium widget, manual twilight angles for high latitudes.

- **v0.7 (09.11.2026):** iPhone Duo: outer display with the bars in a vertical column on the right (vertical Dynamic Island, circular status), inner display with two columns that meet at the fold. Panel: Device switch.
- **v0.6 (09.11.2026):** Qada summary shows the share made up in percent as the largest figure (open count small). Kerahat times subtly marked on the arc (thin inner segments) and on the Sunrise/Dhuhr/Asr rows, with a toggle in Settings. New Live Activity: Lock Screen with the day arc, Dynamic Island compact and expanded; setting "Live Activity" (Off/30/60 min before). Prototype panel: view "Live Activity".
- **v0.5 (08.11.2026):** Day arc redrawn after the TaubatApp widget reference: thick track, prayers as icon markers on the arc with their times outside the curve, white "now" knob, countdown inside the arc slightly smaller.
- **v0.4 (07.11.2026):** Third chip "Anleitung" in the top bar of the Gebete tab: step-by-step prayer guide that always opens on the current prayer (rakʿah count, aloud/silent, sunnah, before-you-begin, 7 steps with pictograms and formulas). Unselected chips collapse to glass circles when the labels don't fit.
- **v0.3 (07.11.2026):** Top bar elements now stand alone (Settings circle, Zeiten, Qibla as separate glass bubbles; selection = tinted glass, no outline). Prayer times as standalone cards. Arc now spans Fajr → Isha with five prayer dots (hollow → filled). New bottom tab bar with the areas Gebete, Verse (verse of the day) and Nachholen (Qada tracker and calculator).
- **v0.2 (07.11.2026):** Bottom tab bar replaced by a top bar in Liquid Glass, aligned with Projekt-Health "Heute": Settings as a separate circle on the left, Zeiten and Qibla as chips in a glass capsule; swipe between the two pages; Settings is a pushed page. List groups radius 26, textSecondary `#6C6C70`, toast moved to the bottom.
- **v0.1 (07.11.2026):** First prototype.
