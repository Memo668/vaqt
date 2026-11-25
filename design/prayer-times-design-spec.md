# Prayer Times (iOS) – Design Spec v0.12

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
Outside the app: Widgets (small, medium, accessoryCircular, accessoryRectangular, accessoryInline; since v0.12 the small "Tagesbogen") · Live Activity (Lock Screen, Dynamic Island compact / minimal / expanded; since v0.12 "small" for CarPlay and the Apple Watch Smart Stack) · Local notifications (prayer + reminder) · StandBy and CarPlay show the small widgets without background (§ 12)
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
| DayArc | Thick circular arc (≈128°, stroke 12 pt, round caps) for the prayer day from Fajr (left end) to Isha (right end). The five prayers and sunrise sit on the arc as round icon markers (30 pt; current 34 pt with a soft glow), placed by time (sunrise since 16.11.2026, § 9.14). Upcoming = tinted track colour (accent 20 % on background, 30 % in dark) with an accent icon; begun = filled accent with a white icon. The solid accent part of the track runs from Fajr to "now"; a white knob (14 pt, light shadow) marks "now" and hides under the current marker. Each marker carries its time outside the curve (below the two end markers); the current time label is accent and bold. When two prayers sit close together (e.g. Maghrib → Isha in Jakarta), the later marker gets a 3 pt background ring. Kerahat windows are thin 3 pt segments just inside the track (radius − 19 pt, 50 % opacity, 95 % while active), so they stay visible next to the markers. The countdown sits inside the arc at 56 pt (50 pt from 10 h, text style 32 pt). Sunrise has the same marker as the prayers but is never the current one; VoiceOver still counts only the five prayers: "3 of 5 prayer times have begun today". In RTL Fajr starts on the right; numbers and icons are not mirrored. Optional (variant). SwiftUI: `Canvas` or `Shape` + `trim(from:to:)` for the progress, markers as overlaid views. |
| Countdown | `Text(timerInterval:)` or `TimelineView(.periodic(by: 1))`. Label "Asr in" / "Fajr tomorrow in". |
| Inset grouped rows | NavigationLink with value · Toggle (accent tint) · Stepper with value + resulting time subtitle · checkmark pickers · destructive "Reset" row. |
| Segmented icon picker | Per-prayer notification state (same three symbols as the bell). |
| Searchable list | `.searchable` for methods and cities, "No Results" row. |
| Sheets | `.presentationDetents([.large])`, drag indicator, Cancel/Close. |
| HUD toast | Glass capsule above the home indicator (the top is now taken by the bar), about 1.7 s. |
| Banner / note / hint pill | Location denied (banner + "Change"), high latitude (note card + link), offline (small pill). |
| Compass | Dial with 5° ticks, upright cardinal labels, N in red, accent Qibla needle + Kaaba marker, fixed lubber line. Aligned within ±3° → accent + `.success` haptic. |
| Adhan player | Title (name of the muezzin), waveform (played part in accent), scrubber, 72 pt play/pause; under the card a footnote with the source and licence of the recording. Until v0.9 also a voice list (placeholders) and a Fajr variant toggle; both removed in § 11.2. |
| Widgets | systemSmall (next prayer + timer; without background in StandBy and CarPlay its own arrangement, § 12.1) · systemSmall "Tagesbogen" (§ 12.2) · systemMedium (next + all six times, next highlighted) · accessoryCircular (Gauge from previous → next) · accessoryRectangular (next, timer, following) · accessoryInline (icon + "Asr 14:00"). |
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
5. Adhan recordings: source, licence, number of voices; full Adhan in-app or only the 30 s clip? → Decided 24.11.2026: one recording, the clip of at most 30 s (§ 11.2). A Fajr version is still open.
6. Time-sensitive notifications (break through Focus)? Needs the entitlement and a justification for review.
7. Hijri date: Umm al-Qura calendar vs. local moon sighting; ±1 day correction setting?
8. Passed rows now use textSecondary `#6C6C70` (4.7 : 1). Is that enough dimming, or should passed rows get an extra marker?
9. Brand: app name per language and app icon (the crescent in the prototype is a placeholder).
10. Minimum iOS version: the top bar uses `glassEffect`, `GlassEffectContainer` and `.buttonStyle(.glass)` (iOS 26). Deployment target iOS 26, like Projekt-Health?
11. Share a small design package with Projekt-Health (tokens, top bar, card radius 26), or keep the two apps independent?
12. Verses: which translations, with which licence (e.g. DE Bubenheim/Elyas, TR Diyanet meali, EN Sahih International, ES Isa García)? The prototype uses placeholder translations. Arabic text source (e.g. Tanzil, Uthmani script) with attribution. Who picks the verses (fixed curated list vs. rotation)? → Provisional decision 24.11.2026: verbatim excerpts of published translations, Arabic text in the spelling of Tanzil (§ 11.1). Which verses and how many is still open.
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

### 9.14 Sunrise on the arc
Decided by the product owner on 16.11.2026 ("Gleicher Punkt wie Gebete", "Überall mit Bogen"): sunrise gets a marker on the arc **like the prayers** – same size (Home 30 pt, Live Activity/Live widget/Lock Screen widget their marker size), sunrise symbol, its time next to it where the arc shows times, upcoming tinted and filled once the sun has risen. It is never the current marker (sunrise ends Fajr, no glow, no "now" chip) and does not count in the VoiceOver text of the arc. It sits at the start of the first kerahat segment. Everywhere the day arc appears: Home (today and other days), Live Activity, the medium "Live" widget and the Lock Screen rectangular widget.


## 10. Changes after the first beta (v0.9, approved 18.11.2026)

Feedback from the product owner and a tester after build 0.1.0 (2), shown in the prototype on 17./18.11.2026 and approved ("Sonst kann man alles so weit übernehmen", 18.11.2026). The prototype panel lists each change under "Änderungen vom 17./18.11.2026". Where this section and older sections disagree, this section wins. Religious texts (§ 10.2, § 10.7) are drafts and must be reviewed before the App Store.

### 10.1 "Verbotszeit" and longer windows on the arc
- **German name:** In German the kerahat windows are called **"Verbotszeit"**, plural "Verbotszeiten": "Verbotszeit 07:14–07:59" on the rows, "Verbotszeit bis 16:27", "Verbotszeiten zeigen", "Verbotszeiten: …" for VoiceOver. Other languages keep their term (TR "Kerahat", EN "Makruh" …).
- **Minimum length on the arc:** Each window drawn on the track reaches at least `r_current + 0.8 × r_marker` along the arc from the marker it touches, so it always shows beside that marker. Before, the 10 minutes before Dhuhr lay completely under the Dhuhr marker.
  - Home: 17 + 12 = 29 pt. Live Activity and Live widget: 12 + 8.4 = 20.4 pt. Lock Screen widget: 7.5 + 5.2 = 12.7 pt.
  - Sunrise grows forward, the windows before Dhuhr and Maghrib grow backward.
  - The drawn length is then no longer to scale. Times on the rows and for VoiceOver stay exact.

### 10.2 What are prohibited times? (info sheet)
- **Info dot on the rows:** The kerahat subline on the rows (Sunrise, Dhuhr, Asr) becomes a button with a trailing info glyph (13 pt, opacity 0.6).
- **Sheet:** Tapping it opens a sheet "Was sind Verbotszeiten?" (`kerahatInfoTitle`), with a close button (xmark) in the trailing corner. It contains, in this order:
  - the intro (`kerahatInfoP1`);
  - a group "Heute" with three rows: a kerahat dot, the description (`kerahatInfoL1`–`L3`) and today's time range, kept on one line;
  - the section "Asr noch nicht gebetet?" (`kerahatAsrTitle`, `kerahatAsrBody`): only the farḍ of Asr is still prayed, the sunnah is left out, and the prayer counts as on time (Hanafi);
  - the reason (`kerahatInfoP2`);
  - a footnote with the school and the approximations: 45 min after sunrise, 10 min before Dhuhr, 45 min before sunset.
- **Guide:** The Asr guide gets a note under "Ab der 3. Rakʿa …" with a kerahat dot (`gAsrKerahat`).
- There is no extra hint on the Asr row; the info dot is enough (decided 18.11.2026).

### 10.3 Live Activity: translucent, orange in prohibited times, ended ones compact
- **Opacity:** The background gradient is drawn at **30 %**, so the system blur and wallpaper show through.
- **Orange:** While a prohibited time runs, the activity is orange.
  - Gradient from `#EC8530`: 80 % with white, the colour itself, 76 % with black.
  - The header shows "Verbotszeit bis {b}" (`kerahatNow`) instead of the city.
  - The kerahat segments on the track are `#FFE2BF`, markers and knob are tinted orange.
  - In the Dynamic Island, symbol, time, countdown and bar are `#F0A257`.
- **Model:** A Live Activity can change its look only once without the app (`staleDate`).
  - Dhuhr and Maghrib, whose prohibited window lies inside the activity's span, get **two activities**: a green one from the start until the prohibited time begins (`staleDate` = its start), and an orange one scheduled at that moment until the prayer (`staleDate` = prayer).
  - If the whole span lies inside the window (Maghrib with a lead of ≤ 45 min), only the orange one is used.
  - The system limit of five activities counts both.
- **Ended activities:**
  - When stale, an activity shrinks to **one line**: app icon, "{p} · {time}", and on the trailing side either "Verbotszeit ab {a}" (`kerahatFrom`, green one at the start of the prohibited time) or "hat begonnen" (`laBegan`, at prayer start). Padding 11/14 pt, radius 20, 13 pt semibold.
  - There is no "Jetzt" any more.
  - The app ends old activities whenever it runs, as before.
- **Order:** The newest activity gets the highest `relevanceScore` (it grows with the start time), so it is on top on the Lock Screen and in the Dynamic Island.
- Overlap cannot be avoided completely without a server: iOS does not end an activity at a time, and the widget extension does not see the app's activities (tested 18.11.2026).

### 10.4 Live widget translucent
The Home Screen widget "Live" draws its gradient at **30 %** as well. Whether iOS shows the wallpaper through a translucent `containerBackground` has to be checked on the device; if not, keep the closest look iOS allows and note it.

### 10.5 Onboarding
- **Step 1:** The title is **"Jedes Gebet zur rechten Zeit."** (`ob1Title`, all 16 languages).
- **Step 2 (location):** "Berechnet auf deinem iPhone" with a body that names Apple Maps for the place name (`ob2Title`, `ob2Body`, § 10.6).
- **Step 3 (notifications):** Under the body a note box: info glyph in accent, `fill-3` background, radius 14, footnote. It says that a countdown appears on the Lock Screen before each prayer (Live Activity) and that it can be turned off in Settings › Live-Aktivität (`ob3Live`).

### 10.6 Privacy texts
The location prompt (`alLocBody`, also `NSLocationWhenInUseUsageDescription`), the location footer (`locFooter`), the privacy page (`privacyBody2`) and onboarding step 2 say what really happens:
- Prayer times are calculated on the device.
- For the place name and the city search the app asks Apple Maps.
- We receive nothing.

The coordinates are rounded to 0.01° before they are stored or sent (in the app since `71e8cd9`). `docs/DATENSCHUTZ.md` and `PRIVACY.md` say the same, including the location as a region hint for the city search.

### 10.7 Qada: man or woman, reset
- **Step 1 "Für wen?":** a segmented control Mann / Frau.
  - For "Frau": two steppers, "Regel pro Monat (Tage)" 3–10 (default 7) and "Wochenbett insgesamt (Tage)" 0–400 (step 5), with the note that prayers on those days are waived and not made up.
  - Owed days = span − round(span ÷ 30 × days per month) − postnatal days, at least 0.
  - The detail line names the deduction (`qcResultDetailF`).
- The steps are renumbered 1–4.
- **Reset:** A red text button "Alles zurücksetzen" sits under the calculator. It opens an alert "Alle Werte zurücksetzen?" with Cancel and a destructive "Zurücksetzen". It sets open counts, totals, the plan (5 per day) and the calculator back, then shows the toast "Alles zurückgesetzt".

### 10.8 Fajr alarm (Phase 17, build 4)
- **Settings:** In the Notifications group a row "Wecker zu Fadschr" (value: ring time or "Aus") opens a page.
  - A switch "Wecker".
  - When on, the choice "Vor Sonnenaufgang" (default; minutes 10–120, step 5, default 45) or "Feste Uhrzeit" (step 5 min, 03:00 to sunrise − 5).
  - A fixed time rings at most 5 min before sunrise.
  - The footers explain the daily ring, silent mode and Focus, and how the two modes differ.
  - **Sound** (added 18.11.2026 with the Phase 17 plan): a group "Klang" with "Systemton" (default, the iOS alarm sound) or "Kurzer Adhan" (since v0.10 the one adhan recording, § 11.2; before that the voice chosen in the adhan sheet). Footer `alarmSoundFooter`.
  - **Permission denied:** the switch stays off and cannot be turned on; below it "iOS-Einstellungen öffnen", footer `alarmDeniedFooter`. The settings row and the chip then show "Aus" or nothing.
- **Alarm alert:** title "Wecker zu Fadschr" (`alarmRow`), one button "Stopp" (`alarmStop`), no snooze (decided 18.11.2026). Reason in the system dialog: `alAlarmBody`.
- **Today screen:** The Fajr row shows a small chip with a clock glyph and today's ring time.
- **Implementation:** AlarmKit (iOS 26). The permission is asked when the alarm is first turned on, and the daily time is recalculated with the prayer times.

### 10.9 Share link
"App weiterempfehlen" shares the public TestFlight invitation during the beta and the App Store page afterwards (`APP_STORE_URL`, in the app since `71e8cd9`).

---

## 11. Changes before the Golden Beta (v0.10 and v0.11, decided 24.11.2026)

Decided by the product owner on 24.11.2026, built in Phase 18. § 11.3–11.7 are an addendum (v0.11): shown in the prototype "Stil" on 24.11.2026 and approved the same evening ("Ja, die Farbauswahl ist deutlich besser. Behalten wir so, wird mit in Phase 18 übernommen, so wie im Prototypen." and "Ja, übernehmen" for the prohibited times). The prototype panel lists them under "Nachtrag zu Phase 18". The religious texts of § 11.6 follow two texts by Ibrahim Gezer (24.11.2026) and must be reviewed by him before the App Store.

### 11.1 Verses: excerpts of published translations
- **Arabic text:** unchanged. Each of the six verses shows a part of the verse in the Uthmani spelling of the Tanzil project (tanzil.net).
- **Translation:** no longer a placeholder. Every language except Arabic shows a **verbatim excerpt** of one published translation, cut to the part of the verse that the Arabic shows. Arabic shows the verse alone.
  - "…" marks a left-out part of the verse, before or after the excerpt. It is tied to the text with a no-break space so that it never wraps alone.
  - A comma, semicolon, colon, dash or quotation mark directly at the cut is dropped. Nothing else is changed and nothing is reworded.
- **Translations** (chosen from the collection fawazahmed0/quran-api; provisional): DE Bubenheim and Elyas · TR Türkiye Diyanet Vakfı · EN Saheeh International · ES Muhammad Isa García · FR Muhammad Hamidullah · NL Fred Leemhuis · BS Besim Korkut · SQ Sherif Ahmeti · UR Fateh Muhammad Jalandhari · ID Kementerian Agama RI · MS Abdullah Muhammad Basmeih · BN Muhiuddin Khan · FA Mohammad Mahdi Fooladvand · RU Elmir Kuliev · IT Hamza Roberto Piccardo.
- **Footnote under the verse card** (`verseSource`): names the translation of the language, e.g. "Übersetzung: Bubenheim und Elyas". In Arabic it names the source of the verse text.
- **No network:** the texts are bundled with the app; nothing is loaded at run time.
- **Licences page:** the Arabic text and the translations are listed with their sources (Einstellungen › Über › Lizenzen).
- **Still open:** which verses the app shows in the long run and how many (§ 6.12); the rights to the translations once the app takes money. Most of them come via Tanzil, whose terms allow non-commercial use with a link back. Sources, editions and terms: `docs/THIRD-PARTY.md`.
- Reference: `iphone/50-verses`, `iphone/51-verses-dark`.

### 11.2 Adhan: one recording
- **Removed:** the three placeholder voices with their unverified place names (Makkah, Madinah, Istanbul), the voice list and the switch "Fadschr-Variante". Strings `voice`, `voiceN`, `fajrVariant` and `fajrVariantFooter` are gone.
- **The recording:** the adhan of **Ustadh Mmanga Muharram**, recorded by DARSA TV (Tanzania) and published on YouTube under the Creative Commons Attribution licence. The app uses a cut of at most 30 seconds, the limit of iOS for notification sounds. Notifications, the Fajr alarm ("Kurzer Adhan") and the player all play this cut.
- **Adhan sheet:** title "Adhan". The player card shows the name as title and "Kurzer Adhan · für Mitteilungen" as subtitle, then waveform, scrubber and play/pause. Under the card the footnote `voiceFooter`: "Aufnahme: DARSA TV, Tansania (gekürzt). Lizenz: CC BY."
- **Fajr:** plays the same recording as the other prayers. A Fajr version with "aṣ-ṣalātu khayrun mina n-nawm" needs a recording of its own and is not part of this change.
- **Licences page:** the recording is listed with title, source, licence and the changes made.
- Reference: `iphone/86-sheet-adhan`, `iphone/86-sheet-adhan-dark`. Source, licence and the cut: `docs/THIRD-PARTY.md`.

### 11.3 Sound: only the iOS default
- Settings › Klang stays **Systemton / Kurzer Adhan / Lautlos** (decided 24.11.2026: "Nur iOS-Standard"). There is no list of tones: an app cannot offer Apple's tones itself (`UNNotificationSound` knows only the default sound or the app's own files).
- When "Systemton" is selected, the footer adds `soundSystemFooter`: the sound is chosen in the iOS Settings under "Töne & Haptik".
- Reference: `iphone/80-settings-sound-system`.

### 11.4 Settings: "Darstellung" above "Berechnung"
- The whole group **Darstellung** (Erscheinungsbild, Stil, Sprache, Verbotszeiten zeigen, with its footer) moves directly under **Standort** and above **Berechnung** (wish of 24.11.2026).
- New row **Stil** under Erscheinungsbild; its value is the name of the accent colour (§ 11.7).
- New row **Rechtsschule** in Berechnung, under Asr; its value is the school (§ 11.6).
- Reference: `iphone/70`, `71`, `72`.

### 11.5 Onboarding: madhab page and swipe
- **Five pages:** Willkommen, Standort, **Rechtsschule** (new), Mitteilungen, Unterstützen. The page dots show five.
- **Rechtsschule:** badge with the book glyph, title `obMadhabTitle` ("Deine Rechtsschule"), body `obMadhabBody`. Under the body a capsule button (fill-3, 44 pt high, semibold body) shows the chosen school and an up/down chevron; tapping it opens a menu with the four schools (checkmark at the chosen one). In the app this is a `Picker` with `.pickerStyle(.menu)`. Hanafi is preselected. "Weiter" (`obContinue`) goes on; "Überspringen" keeps Hanafi. The choice can be changed later in Settings › Rechtsschule.
- **Swipe:** a horizontal swipe goes one page on (to the left) or back (to the right), mirrored in RTL. Swiping never asks for a permission – like "Überspringen". At the first and the last page the swipe rubber-bands back; the last page closes only with its button. Vertical drags are left to the page.
- Debug: `-debugOnboarding 1…5`.
- Reference: `iphone/03-onboarding-3-madhab` (+ `-dark`, `-menu`); notifications and support move to `iphone/05-onboarding-4-notifications` and `iphone/06-onboarding-5-free` (+ `-dark`).

### 11.6 Prohibited times by madhab
- **Setting:** Settings › Berechnung › **Rechtsschule**: Hanafi (default), Maliki, Schafii, Hanbali. Each option has a subline naming its windows (`madhabSub_*`); the footer (`madhabFooter`) says that the Asr time is set separately. The madhab does **not** change the Asr calculation.
- **Windows and lengths** (minutes; decided 24.11.2026, research in `docs/OPEN-QUESTIONS.md`):

| School | after sunrise | before Dhuhr | before Maghrib |
|---|---|---|---|
| Hanafi | 45 | 10 | 45 |
| Schafii | 25 | 10, none on Friday | 25 |
| Hanbali | 20 | 10 | 20 |
| Maliki | 20 | – (no window) | 20 |

  - Friday is the weekday of the day the times belong to (in the place's time zone).
  - The windows apply everywhere: arc, rows, VoiceOver, info sheet, Live Activity (two activities only where a window exists), Dynamic Island, widgets.
- **Texts per school:** Hanafi keeps all texts of § 10.1–10.2 verbatim. For the other schools:
  - the Darstellung footer is `kerahatFooter_<school>` (instead of `kerahatFooter`);
  - the info sheet intro is `kerahatP1_<school>` and its footnote `kerahatFoot_<school>`.
- **Info sheet "Was sind Verbotszeiten?"** in this order: intro; group "Heute" with two or three windows; "Asr noch nicht gebetet?" (**Hanafi only**); new "Nach dem Fadschr- und dem Asr-Gebet" (`kerahatAfterTitle`/`Body`, all schools); new "Versäumte Gebete nachholen" (`kerahatQadaTitle`, `kerahatQadaHanafi` or `kerahatQadaOther` with the school adjective `madhabAdj_<school>`); new "Andere Gebete" (`kerahatOtherTitle`/`Body`); the reason (`kerahatInfoP2`); the footnote.
- **Guide:** the Asr note `gAsrKerahat` (§ 10.2) appears only for Hanafi.
- Not in the app (decided 24.11.2026): the times after Fajr and Asr on the arc (they begin with one's own prayer), a hint in the Qada tab, the sources (they are in `docs/OPEN-QUESTIONS.md`).
- Reference: `iphone/88-settings-madhab` (+ `-dark` with Schafii), `iphone/26-home-maliki`, `iphone/26-home-shafii-friday`, `iphone/27-sheet-kerahat`, `iphone/27-sheet-kerahat-maliki`.

### 11.7 Style: accent colour and Live Activity look
- **Page:** Settings › Darstellung › **Stil** (title `style`). From top to bottom:
  - a preview of the Live Activity on a neutral wallpaper (the current state, at 94 %);
  - group **Grundfarbe** (`styleColor`) with footer `styleColorFooter`;
  - group **Live-Aktivität** (`liveAct`): three tiles Farbig / Nur Bogen / Schwarz-weiß (`laFull`, `laArc`, `laMono`) with a small sign of the style and a radio circle, then a switch **Invertiert** (`laInvert`, subline `laInvertSub`); footer `styleLiveFooter`;
  - **Standard wiederherstellen** (`styleReset`), only when something differs from the default (Petrol, Farbig, not inverted).
- **Accent colours:** 24 circles in rows of six (36 pt circle, 48 pt tap target, selected = ring and checkmark, never colour alone). No visible name; VoiceOver reads the name (`col_<id>`).
  - **Collapsed:** only the standard row, under it a small grey chevron (VoiceOver `styleMoreColors`/`styleLessColors`). If another colour is selected, a small dot in that colour stands beside the chevron.
  - **Expanded:** the grid 4 × 6. When the page opens with a colour outside the standard row, it opens expanded; afterwards only the chevron changes it.

| Row | Colours (id: light / dark / text on the dark accent) |
|---|---|
| Standard | teal Petrol `#1F7A6D`/`#4CC2AE`/`#04221D` · green Grün `#2E7D4F`/`#5FCB8A`/`#04220F` · blue Blau `#1E6BB8`/`#6DB5FF`/`#031B33` · violet Violett `#7A4CB5`/`#C4A2FF`/`#1B0B33` · berry Beere `#A93466`/`#FF8FBA`/`#33081B` · graphite Graphit `#48484D`/`#D6D6DC`/`#111113` |
| kräftig | cyan Türkis `#026E89`/`#28D1FE`/`#001F28` · grass Gras `#3C6603`/`#98D75E`/`#111F05` · indigo Indigo `#4646CB`/`#8997FF`/`#151831` · orchid Orchidee `#941C95`/`#E585E2`/`#271126` · orange Orange `#A44C03`/`#FE904D`/`#2C1204` · gold Gold `#876204`/`#F5C25F`/`#251801` |
| tief | ocean Ozean `#024153`/`#43A9CB`/`#011E28` · forest Tanne `#03472A`/`#5FA77F`/`#032112` · navy Nachtblau `#182D6A`/`#728DCD`/`#101932` · plum Aubergine `#50205A`/`#B47EBE`/`#251228` · wine Bordeaux `#6D1733`/`#C37586`/`#2D0F17` · mono Mono `#1C1C1E`/`#F2F2F7`/`#1C1C1E` |
| gedeckt | mint Mint `#015D54`/`#9AE9DD`/`#01201C` · sage Salbei `#556345`/`#BDD4A3`/`#161E0B` · ice Taubenblau `#455A74`/`#9FC1EB`/`#131B27` · lavender Lavendel `#69639D`/`#CBC6FF`/`#1A172C` · mauve Malve `#714967`/`#CBB7C5`/`#1F181D` · sand Sand `#6F4D27`/`#ECCAA7`/`#24180B` |

  - Every colour reaches 4.5 : 1: light on white and on `#F2F2F7`, dark on `#1C1C1E`, the text colour on the dark accent. The colours from row 2 on keep an OKLab distance of at least 0.065 to every other colour, 0.12 to the kerahat colours and to signal red, and 0.07 to the grey secondary text. Unit tests check this.
  - The accent applies to the whole app (everything that was `--accent`, and what is mixed from it), the widgets, the Live Activity and the Dynamic Island. The app icon stays. In dark mode `--on-accent` is the text colour of the row.
- **Warm colours** Orange, Gold, Sand: the prohibited time is **violet instead of orange** everywhere – arc, rows, info dot, Live Activity in every style except black and white, Dynamic Island (including the marks under the bar). Each orange tone is turned to OKLCH hue 300 with the same lightness and chroma:

| Orange | Violet | Use |
|---|---|---|
| `#C7862A` / `#D9A04E` | `#A282D9` / `#B89AED` | `--kerahat` light / dark |
| `#9A6212` / `#E3B36B` | `#7B5FA8` / `#C6ADF6` | `--kerahat-text` light / dark |
| `#F3C979` | `#D8C4FF` | kerahat segments in the Live Activity |
| `#EC8530`, `#D9772B`, `#C4661F`, `#FFE2BF` | `#B38AF6`, `#A37DE1`, `#916CCB`, `#EBE2FF` | Live Activity "Farbig" in the prohibited time |
| `#8A4409`, `#B85C12`, `#F1DCCB`, `#EDA35C`, `#9A4D0E` | `#644990`, `#8762BF`, `#E3DCF3`, `#C2A3F9`, `#7152A0` | inverted styles in the prohibited time |
| `#F0A257`, `#3A1D05`, `#F8B877` | `#C3A2FC`, `#2A1E3D`, `#D0B8FF` | "Nur Bogen" and Dynamic Island in the prohibited time |
| `#E0A84F` | `#C0A1F7` | marks under the bar of the Dynamic Island |

- **Live Activity styles** (also for the Home Screen widget with the arc, "Live"). The opacity of the surface is always 30 %. Variables as in the prototype (`[data-la]`, block "Stil"):
  - **Farbig** (default, § 10.3): gradient of the accent; orange in the prohibited time.
  - **Farbig, invertiert:** white surface, text 80 % accent + 20 % black, track accent at 26 %, line and passed markers in the accent, knob white with accent ring, kerahat `#C7862A`. In the prohibited time text and line `#8A4409`/`#B85C12`.
  - **Nur Bogen:** colourless surface `#2E2E33`, white text, line and passed markers in the dark accent, knob white with accent ring. In the prohibited time the line `#F0A257` and "Verbotszeit bis …" in `#F8B877`.
  - **Nur Bogen, invertiert:** white surface, text `#1C1C1E`, line in the light accent, track black at 16 %. In the prohibited time `#B85C12`, text "Verbotszeit bis …" `#9A4D0E`.
  - **Schwarz-weiß:** `#2E2E33` without colour, app icon grey. Prohibited times are striped (white dashes on black 50 %) and named in the text; no orange.
  - **Schwarz-weiß, invertiert:** white surface, line `#1C1C1E`, stripes as above.
  - **Dynamic Island:** always black. Symbol, time, countdown and bar in the dark accent; in the prohibited time `#F0A257`; with Schwarz-weiß all white (kerahat marks white at 60 %).
- **Changes reach the outside:** widgets reload; running Live Activities are updated and scheduled ones are requested again with the new look.
- Debug: `-debugAccent <id>`, `-debugLiveStyle full|arc|mono`, `-debugLiveInverted`, `-debugTab style`.
- Reference: `iphone/87-settings-style` (+ `-dark`, `-open` with Orange and "Nur Bogen, invertiert", `-open-end`), `iphone/25-home-accent-ocean`, `iphone/25-home-accent-orange-kerahat` (+ `-dark`), `system/97-*` (six styles and Ozean), `system/98-*` (prohibited time, also warm), `system/99-*` (widget "Live").

## 12. CarPlay and StandBy (v0.12, Phase 19, decided 25.11.2026)

Decided by the product owner on 25.11.2026 after the proposal "CarPlay und Apple Watch" (prototype of 24.11.2026): **no own CarPlay app** – prayer times fit no CarPlay app category, the "Audio" entitlement is not requested; Phase 19 builds the CarPlay widgets and the Live Activity "small"; the Apple Watch app follows in Phases 20–22. Apple's rules with sources: `docs/vorschlaege/2026-11-24/carplay-watch.md`. Prototype: view "CarPlay" (panel block "Phase 19"). Where this section and older sections disagree, this section wins.

What Apple allows (iOS 26):
- **Widgets in CarPlay** stand left of the Dashboard (right with right-hand drive). Only the `systemSmall` family, drawn **without the container background**, enlarged and in full colour – like StandBy. Which widgets appear is chosen on the iPhone (Settings › General › CarPlay). Tapping a Vaqt widget in the car does nothing; only CarPlay apps can be opened from there.
- **Live Activities** appear on the CarPlay Dashboard by themselves. With the family `small` they get their own view, the same as in the Smart Stack of Apple Watch. Sizes (HIG): CarPlay 240 × 78, 240 × 100 and 170 × 78 pt, Smart Stack (46 mm) 194 × 80.5 pt; CarPlay scales them per screen. Buttons would do nothing in the car.
- Vaqt's notifications do not appear in the car (only CarPlay apps of some categories may show them).
- The car screen (wide 8 : 3 or standard 5 : 3), the number of widgets side by side, the surface behind a widget and the place of the Live Activity on the Dashboard are approximated in the prototype.

### 12.1 Small widget "Nächstes Gebet" without background
- With its background (Home Screen) it stays as it is (§ 3, `system/91`).
- Without background (`showsWidgetContainerBackground` is false: StandBy and CarPlay) it has its own arrangement, leading and vertically centred, padding 12 / 12 / 12 / 14 (158 pt reference):
  - prayer symbol (22 pt box) and name, 19 pt semibold, accent, tracking −0.3, gap 6;
  - the time large: 46 pt rounded semibold, tracking −1, 3 pt below;
  - "in 2:01:29" (`wIn`), 15 pt medium, secondary, 5 pt below;
  - during a prohibited time: kerahat dot (7 pt) and "Verbotszeit bis 16:27" (`kerahatNow`), 11.5 pt semibold in `--kerahat-text` (violet for warm accents, § 11.7), 6 pt below;
  - no city.
- The background stays removable (`containerBackgroundRemovable(true)`, the default).
- The timeline of the small family also has entries at the start and end of each prohibited window, so that line appears and disappears on time.

### 12.2 New small widget "Tagesbogen"
- `systemSmall` only: Home Screen with background (`--bg-cell`), StandBy and CarPlay without. Gallery name "Vaqt" like the other widgets, description `wArcDesc` ("Der Tagesbogen mit dem nächsten Gebet und den Verbotszeiten.").
- Layout (158 × 158 reference), a centred column with padding 8 / 6:
  - the arc `ARCS.cpw`, 146 × 84: centre 73 / 100, radius 80, ends at 0.66 rad; markers 15 pt with a 9.5 pt symbol, the current one 18 pt with a 10.5 pt symbol and a 12 pt glow; track 6 pt, kerahat 6 pt on the track (minimum length § 10.1); knob 5 pt, white with a 2 pt accent ring, no shadow; no times; sunrise as a marker (§ 9.14);
  - inside the arc "{p} · {time}" (12 pt semibold, secondary) and the countdown (25 pt rounded bold, tracking −0.3), flush with the bottom of the arc;
  - 10 pt below: the location arrow (accent) and the city, 13 pt semibold, secondary – during a prohibited time the kerahat dot and "Verbotszeit bis …" in `--kerahat-text`.
- Colours as the Home arc: accent, `--arc-track`, `--kerahat`, violet for warm accents. The ring around close markers is `--bg-cell`, with and without background.
- Timeline from `WidgetTimeline`: an entry at each event, every 10 minutes between Fajr and Isha for the knob, and at the start and end of each prohibited window (as the Lock Screen rectangle).

### 12.3 Live Activity "small"
- `supplementalActivityFamilies([.small])`. For `activityFamily == .small` the activity has its own view; Lock Screen and Dynamic Island stay unchanged.
- The drawing of the Lock Screen widget (`ARCS.acc`, 160 × 72 incl. "{p} · {time}" and countdown, § 9.11) centred on the surface of the activity, in the colours of the selected style (`--la-*`, § 11.7), but **at full opacity** instead of 30 %: in the car and in the Smart Stack no wallpaper shows through. Orange in a prohibited time (§ 10.3), violet for warm accents; black and white striped.
- A header (app icon 14 pt, "Vaqt", the city or "Verbotszeit bis …"; 12 pt semibold, the city at 0.75) only where there is room: 240 × 100. In the flat sizes "Verbotszeit bis …" replaces "{p} · {time}" inside the arc during a prohibited time.
- No buttons.
- After the change (`staleDate`, § 10.3): two lines, centred – app icon and "{p} · {time}", below "hat begonnen" (`laBegan`) or, for the green part before a prohibited time, "Verbotszeit ab …" (`kerahatFrom`). The single line of the Lock Screen does not fit into 170 pt.

### 12.4 StandBy
StandBy shows the small widgets like CarPlay: without background, enlarged, always dark; both small widgets use the arrangement of § 12.1 and § 12.2. The red night mode is drawn by the system.

- Debug: `-debugCatalog carplay` (the small widgets with and without background, the Live Activity "small" after the change) and `-debugCatalog live` (the Live Activity "small" in the four sizes), with `-debugTime`, `-debugAccent`, `-debugLiveStyle`, `-debugLiveInverted` as before.
- Reference: `carplay/cp-10` … `cp-61` (`INDEX.md`).
- Open (only the CarPlay Simulator or a car can show it): how CarPlay draws the surface behind a widget, whether the `small` family may draw its own surface (the prototype assumes it may), and how the Live Activity appears as a notice when it starts while another app fills the screen.

---

## Changelog
- **v0.12 (25.11.2026, Phase 19):** CarPlay and StandBy (§ 12): the small widget "Nächstes Gebet" without background in its own arrangement, the new small widget "Tagesbogen", the Live Activity "small" for CarPlay and the Smart Stack of Apple Watch at full opacity; no own CarPlay app.
- **v0.11 (24./25.11.2026):** Addendum to the changes before the Golden Beta (§ 11.3–11.7): sound only with the iOS default and a hint where to choose it; group "Darstellung" above "Berechnung"; onboarding with five pages (madhab as a menu) and swipe; prohibited times by madhab (Hanafi, Maliki, Schafii, Hanbali) with their own lengths, texts and info sheet sections; Settings › Stil with 24 accent colours (violet prohibited time for Orange, Gold, Sand) and six Live Activity styles at 30 %.
- **v0.10 (24.11.2026):** Changes before the Golden Beta (§ 11): verse translations as verbatim excerpts of published translations in 15 languages, with the translation named under the card; one adhan recording (Ustadh Mmanga Muharram, DARSA TV, CC BY) instead of three placeholder voices, no Fajr variant switch.
- **v0.9 (18.11.2026):** Changes after the first beta (§ 10): "Verbotszeit" in German and longer kerahat windows on the arc, info sheet on prohibited times, Live Activity at 30 % with orange prohibited time and compact ended activities (newest on top), Live widget at 30 %, new onboarding title, location and Live Activity hints, honest privacy texts, qada for men and women with reset, Fajr alarm (Phase 17), share link to TestFlight.
  - *Addendum 18.11.2026 (Phase 17 plan):* the alarm sound is a choice of system sound or short adhan; denied permission keeps the switch off with a link to iOS Settings; the alert has only "Stopp", no snooze (§ 10.8).
- **v0.8, addendum 4 (16.11.2026):** sunrise as a marker on the day arc, same look as the prayers, everywhere the arc appears (§ 9.14).
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
