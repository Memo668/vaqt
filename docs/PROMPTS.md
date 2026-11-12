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
| `iphone/30` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 98 -debugQiblaAccuracy 40` |
| `iphone/31` | … `-debugTime 14:25 -debugTab qibla -debugQiblaHeading 137 -debugQiblaAccuracy 40` |
| `iphone/32` | … `-debugCity mecca -debugTime 15:42 -debugTab qibla -debugQiblaHeading 138 -debugQiblaAccuracy 40` |
| `iphone/40` | … `-debugTab guide` |
| `iphone/41` | wie `40`, dann nach unten scrollen, bis die erste Karte des Ablaufs 133 pt unter der Oberkante steht (UI-Hilfsprojekt, `s21-guide-steps.txt`) |
| `iphone/42` | wie `40`, dann „Maghrib“ in der Auswahl antippen (UI-Hilfsprojekt, `s20-guide.txt`) |
| `iphone/50` / `60` | … `-debugTab verses` / `-debugTab qada` |

Sprache im Simulator: Scheme › Run › Options › App Language, oder `-AppleLanguages "(tr)"`.
