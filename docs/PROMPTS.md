# Prompts für Claude Code

## Einrichten (einmalig)

1. Neuen Ordner anlegen, z. B. `~/Developer/Gebetszeiten`, und `git init` ausführen.
2. Den Inhalt dieses Pakets hineinkopieren:
   - `CLAUDE.md` ins Hauptverzeichnis
   - `docs/` mit Bauplan und diesen Prompts
   - `design/` mit Prototyp, Spec und Screenshots
3. Ersten Commit machen („Design-Übergabe v0.7“).
4. Im Terminal in den Ordner wechseln und `claude` starten. Claude Code liest `CLAUDE.md` automatisch.
5. Pro Phase eine eigene Sitzung (`/clear` dazwischen), so bleibt der Kontext sauber. Mit Umschalt+Tab in den Plan-Modus, damit Claude erst plant und auf deine Freigabe wartet.

Optional: Wenn Claude Code den Code von Projekt-Health sehen soll (Leiste oben, Tokens), hänge im ersten Prompt den Pfad an, z. B. „Zum Abgleich der Glass-Leiste: `<Pfad>/Projekt-Health/Packages/UI/Sources/UI/Today/TodayChipBar.swift` und `Tokens/`“.

---

## Prompt 1 – Start (Plan-Modus)

```
Wir bauen die iOS-App „Gebetszeiten“ nativ in SwiftUI – eins zu eins nach dem Prototyp in design/.
Lies zuerst CLAUDE.md, docs/BUILD-PLAN.md, design/prayer-times-design-spec.md und design/screenshots/INDEX.md.
Schau dir dann die Screenshots design/screenshots/iphone/10-home-asr-active.png, 11-home-asr-active-dark.png, 60-qada.png und system/93-live-activity-lockscreen.png an, damit du den Stil kennst.
Im Prototyp design/prayer-times-prototype.html such gezielt nach T, phase(), kerahatWins(), guideState() und ARCS, statt die ganze Datei zu lesen.

Erstelle einen Plan für Phase 0 (Projektgerüst) und Phase 1 (PrayerCore): Ordner- und Dateiliste, Typen und Protokolle, wie Adhan Swift die Methoden aus METHODS abdeckt, die Testfälle, die Debug-Startargumente.
Liste am Ende alles, was du vor dem Bauen von mir wissen musst. Noch keinen Code.
```

## Prompt 2 – Phase umsetzen (für jede Phase wiederverwenden)

```
Setze Phase <N> aus docs/BUILD-PLAN.md um.
Referenz-Screenshots: <aus dem Bauplan, z. B. design/screenshots/iphone/10 bis 22 und 85>.
Lies dazu die passenden Abschnitte der Spec und die genannten Funktionen im Prototyp-HTML.
Erst planen (Dateien, Komponenten, offene Fragen), nach meiner Freigabe bauen.
Zum Schluss prüfen wie in CLAUDE.md beschrieben:
1. Build und Tests müssen grün sein.
2. Im Simulator iPhone 18 Pro jeden Referenzzustand mit den Debug-Argumenten nachstellen und einen Screenshot aufnehmen.
3. Ihn neben die Referenz legen und die Abweichungen als Liste ausgeben (Abstand, Größe, Farbe, Text, Zustand).
4. Die Abweichungen beheben und erneut vergleichen, bis nichts Sichtbares mehr abweicht.
Danach committen und mir eine kurze Zusammenfassung geben: was fertig ist, was offen ist.
```

## Prompt 3 – Gezielter Abgleich (wenn etwas nicht passt)

```
Vergleiche design/screenshots/<Datei> mit dem aktuellen Stand im Simulator (<Debug-Argumente>).
Nenne jede Abweichung mit Ort, Ist- und Sollwert in pt bzw. als Farbwert und gleiche den Code an. Keine anderen Änderungen.
```

## Prompt 4 – Nach einer Designänderung im Prototyp

```
Der Prototyp in design/ wurde auf Version <x> aktualisiert (siehe Changelog am Ende der Spec).
Lies die Änderungen, plane die nötigen Anpassungen in der App und setze sie nach meiner Freigabe um. Danach die betroffenen Screenshots abgleichen.
```

---

## Debug-Argumente je Screenshot (Kurzfassung)

| Screenshot | Argumente |
|---|---|
| `iphone/01` | `-debugFixtureTimes -debugDate 2026-11-10 -debugTime 09:10 -debugOnboarding 1` (Statusleiste `make statusbar TIME=09:10`) |
| `iphone/02` | wie `01` mit `-debugOnboarding 2` |
| `iphone/03` | wie `01` mit `-debugOnboarding 3` – seit dem Nachtrag zu Phase 18 die Rechtsschule (`03-onboarding-3-madhab`); das Menü öffnet ein Tipp auf die Kapsel |
| `iphone/05` | wie `01` mit `-debugOnboarding 4` (Mitteilungen, seit dem Nachtrag zu Phase 18; vorher `03`) |
| `iphone/06` | wie `01` mit `-debugOnboarding 5` („Kostenlos“, seit dem Nachtrag zu Phase 18; vorher `05`) |
| `iphone/25` | wie `10` mit `-debugAccent ocean`; `-orange-kerahat` mit `-debugTime 07:30 -debugAccent orange` |
| `iphone/26` | wie `10` mit `-debugMadhab maliki`; `-shafii-friday` mit `-debugMadhab shafii -debugDayOffset 3` |
| `iphone/27` | wie `10` mit `-debugTab kerahat` (`-maliki` mit `-debugMadhab maliki`) |
| `iphone/80-settings-sound-system` | wie `10` mit `-debugTab sound -debugSound system` |
| `iphone/87` | wie `10` mit `-debugTab style`; `-open` mit `-debugAccent orange -debugLiveStyle arc -debugLiveInverted` |
| `iphone/88` | wie `10` mit `-debugTab madhab` (dunkel mit `-debugMadhab shafii`) |
| `carplay/cp-40`–`cp-43` | `-debugCatalog live` mit `-debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25` (41, 43: `16:05`), Stile wie `97`/`98`; nach dem Wechsel in `-debugCatalog carplay` (Phase 19) |
| `carplay/cp-50`–`cp-52` | `-debugCatalog carplay` mit `-debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25` (51: `16:05`), dunkel über `simctl ui … appearance dark`, `52` mit `-debugAccent ocean` bzw. `orange` (Phase 19) |
| `system/97`–`99` | `-debugCatalog live` bzw. `widgets` mit `-debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25` (98: `16:05`) und `-debugLiveStyle arc|mono`, `-debugLiveInverted`, `-debugAccent …` – Einzelheiten in `scripts/compare-system` |
| `iphone/04` | wie `02`, dann „Standort erlauben“ – ohne `-debugFixtureTimes` und mit noch nicht beantworteter Standortabfrage; der Dialog ist der des Systems |
| `iphone/10` | `-debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25` |
| `iphone/12` | … `-debugTime 05:14` |
| `iphone/13` | … `-debugTime 08:04` |
| `iphone/14` | … `-debugTime 07:30` |
| `iphone/15` | … `-debugTime 16:05` |
| `iphone/16` | … `-debugTime 23:30` (Dark Mode) |
| `iphone/17` | … `-debugTime 14:25 -debugLocationDenied -debugOffline` |
| `iphone/18` | … `-debugHighLatitude -debugTime 23:47` |
| `iphone/21` | … `-debugCity istanbul -debugTime 16:01`, Sprache Türkisch |
| `iphone/22` | … `-debugCity jakarta -debugTime 17:57` |
| `iphone/23` | … `-debugTime 14:25 -debugDayOffset 1` (seit Phase 12; `23-…-dark` dunkel) |
| `iphone/30` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 98 -debugQiblaAccuracy 40` |
| `iphone/31` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 137 -debugQiblaAccuracy 40` |
| `iphone/32` | … `-debugCity mecca -debugTime 15:42 -debugTab qibla -debugQiblaHeading 138 -debugQiblaAccuracy 40` |
| `iphone/33` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 112 -debugQiblaAccuracy 40` (seit Phase 12; `33-…-dark` dunkel) |
| `iphone/34` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 60 -debugQiblaAccuracy 40` (seit Phase 12) |
| `iphone/40` | … `-debugTab guide` |
| `iphone/41` | wie `40`, dann nach unten scrollen, bis die erste Karte des Ablaufs 526 pt unter der Oberkante steht (seit v0.8; UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-41-42-guide.txt`) |
| `iphone/42` | wie `40`, dann „Maghrib“ in der Auswahl antippen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-41-42-guide.txt`) |
| `iphone/43` | … `-debugTime 14:25 -debugWalk dhuhr -debugWalkStep 0` (seit Phase 13; `43-…-dark` dunkel) |
| `iphone/44`–`49` | wie `43` mit `-debugWalkStep 1` (Takbīr), `2` (Stehen leise), `5` (Niederwerfung; `47-…-dark` dunkel), `14` (erstes Sitzen), `29` (Ende; `49-…-dark` dunkel); `46` mit `-debugWalk maghrib -debugWalkStep 2` (Stehen laut) |
| `iphone/50` | … `-debugTime 14:25 -debugTab verses` |
| `iphone/51` | wie `50` (Dark Mode) |
| `iphone/60` | … `-debugTime 14:25 -debugTab qada` – mit `-debugFixtureTimes` die Zahlen des Prototyps |
| `iphone/61` | wie `60`, dann ganz nach unten scrollen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-61-qada.txt`) |
| `iphone/70` | … `-debugTime 14:25 -debugTab settings` |
| `iphone/71` | wie `70`, dann scrollen, bis „Pro Gebet“ oben unter der Leiste steht (UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-71-72-settings.txt`) |
| `iphone/72` | wie `70`, dann ganz nach unten scrollen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-71-72-settings.txt`) |
| `iphone/73` | … `-debugTime 14:25 -debugTab method` |
| `iphone/74` | … `-debugTab asr` |
| `iphone/75` | … `-debugTab hl` |
| `iphone/76` | … `-debugTab adjust` |
| `iphone/77` | … `-debugTab perPrayer` |
| `iphone/78` | … `-debugTab reminder` |
| `iphone/79` | … `-debugTab live` |
| `iphone/80` | … `-debugTab sound` |
| `iphone/81` | … `-debugTab privacy` |
| `iphone/82` | wie `75`, dann „Manuelle Winkel“ antippen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/iphone-82-settings-hl-manual.txt`; seit Phase 12) |
| `iphone/83` | … `-debugTab support` (seit Phase 12) |
| `iphone/84` | … `-debugTime 14:25 -debugTab alarm -debugAlarm before` (seit Phase 17); `-fixed` mit `-debugAlarm fixed`, `-denied` mit `-debugAlarm denied`, `-off` ohne `-debugAlarm`, `-dark` wie `84` im dunklen Simulator |
| `iphone/85` | … `-debugTime 14:25 -debugTab city` (seit Phase 10; vorher ein Tipp auf die Stadt) |
| `iphone/86` | … `-debugTime 14:25 -debugTab adhan` |
| `system/92` | `-debugSkipOnboarding -debugFixtureTimes -debugNotifications -debugDate 2026-11-10 -debugTime 11:41`, Systemsprache des Simulators Deutsch, `make statusbar TIME=11:52`; Gerät sperren, gut elf Minuten warten, den Stapel aufklappen, aufnehmen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/system-92.txt`). Die Erinnerung kommt nach einer Minute, Dhuhr nach elf |
| `system/90` | `-debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25` – ohne `-debugLiveActivity` endet eine noch laufende Aktivität; Widgets vorher anlegen: Sperrbildschirm anpassen, Rechteck (seit Phase 14 mit Mini-Bogen) und Ring von „Vaqt“, Zeile über der Uhr (UI-Hilfsprojekt, `scripts/ui-harness/scripts/system-setup-lock-widgets.txt`); App starten, sperren, aufnehmen (`scripts/ui-harness/scripts/system-90-91.txt`). Im Katalog: `make compare-system STATES=90` |
| `system/91` | wie `90`; Widgets vorher anlegen: erst das kleine, dann das mittlere, zuletzt „Live“ (seit Phase 14) – jedes neue landet oben (UI-Hilfsprojekt, `scripts/ui-harness/scripts/system-setup-home-widgets.txt`, sucht „Vaqt“ in der Galerie); App starten, Home, eine Seite nach links, aufnehmen (`scripts/ui-harness/scripts/system-90-91.txt`). Im Katalog: `make compare-system STATES=91` |
| `system/93` | `-debugSkipOnboarding -debugFixtureTimes -debugLiveActivity -debugDate 2026-11-10 -debugTime 14:25`, Widgets wie `90`; sperren, aufnehmen (UI-Hilfsprojekt, `scripts/ui-harness/scripts/system-93-95.txt`) |
| `system/94` | wie `93`, statt sperren Home: die kompakte Insel über den Widgets von `91` (`scripts/ui-harness/scripts/system-93-95.txt`) |
| `system/95` | wie `94`, dann lange auf die Insel drücken (`sbpress 201 30 1.2`, `scripts/ui-harness/scripts/system-93-95.txt`) |
| `system/96` | `… -debugLiveActivity -debugDate 2026-11-10 -debugTime 16:35`, Simulator dunkel (`xcrun simctl ui 'iPhone 18 Pro' appearance dark`), `make statusbar TIME=16:35`; sperren, aufnehmen (`scripts/ui-harness/scripts/system-96.txt`), danach hell und `make statusbar` |
| `duo/closed-*`, `duo/open-*` | Simulator „iPhone Duo“ (Runtime iOS 27.2, Build 24B91016s), in Device Hub zugeklappt bzw. flach aufgeklappt und quer; Argumente wie `iphone/` mit derselben Nummer: `10` (`-debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25`), `11` wie `10` dunkel, `30` … `-debugTab qibla -debugQiblaHeading 136 -debugQiblaAccuracy 40`, `40` … `-debugTab guide`, `50` … `-debugTab verses`, `60` … `-debugTab qada`, `70` … `-debugTab settings`, `85` … `-debugTab city`. Aufnehmen und danebenlegen: `make compare-duo MODE=open` bzw. `MODE=closed`. RTL innen: dazu `-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES` |
| Duo hochkant, Tischhaltung, Split View | ohne Referenzbild: in Device Hub drehen, das Scharnier halb öffnen bzw. eine zweite App daneben öffnen; Argumente wie `duo/open-*` |

Sprache im Simulator: Scheme › Run › Options › App Language, oder `-AppleLanguages "(tr)"` mit `-AppleLocale` wie `LOC` im Prototyp (`make run LANGUAGE=ar`). Seit Phase 15 gibt es 16 Sprachen; jede lässt sich mit `make compare-language LANGUAGE=<sprache>` gegen den Prototyp in derselben Sprache legen (`REGION=ar_SA` für Arabisch mit ٠–٩). Die Wahl in der App bei anderer Sprache des Geräts spielt `scripts/ui-harness/scripts/language-choice-rtl.txt` nach.

Zustände mit Tipp spielt das UI-Hilfsprojekt im Repo nach (`scripts/ui-harness`, seit Phase 11): `make harness SCRIPTS='scripts/ui-harness/scripts/iphone-61-qada.txt'`. Die Aufnahmen landen in `screenshots-out/ui-harness/` oder unter `OUT=…`.
