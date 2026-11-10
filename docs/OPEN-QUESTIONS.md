# Offene Fragen

Hier steht alles, was Spec, Screenshots und Prototyp nicht eindeutig beantworten. Jeder Punkt nennt den Standardwert, mit dem bis zu einer Entscheidung gebaut wird. Die offenen Designfragen der Spec selbst stehen in `design/prayer-times-design-spec.md` § 6.

## Braucht eine Entscheidung

### 1. Größe der Referenzbilder und Simulator

Die Referenzbilder sind 390 × 844 pt groß. Der Simulator „iPhone 17“, den `CLAUDE.md` vorgibt, hat 402 × 874 pt (gemessen am Screenshot: 1206 × 2622 px bei 3x). Ein Vergleich Pixel auf Pixel geht damit nicht: Der Bildschirm ist 12 pt breiter und 30 pt höher.

- **Standard:** Abgleich auf dem iPhone 17 wie vorgegeben. Verglichen werden Abstände, Größen, Farben und Texte der Bausteine, nicht die Lage im ganzen Bild.
- **Alternative:** ein Simulator mit 390 × 844 pt für den Abgleich. Das iPhone 17e hat vermutlich diese Größe; geprüft ist das nicht.

### 2. Tableiste: Breite und Symbole

Die App benutzt die System-`TabView` (Spec, Komponente „TabBar“; `CLAUDE.md`: Systemelemente nicht nachbauen). Sie weicht in zwei Punkten vom Prototyp ab, der die Leiste in CSS nachzeichnet:

- Die Leiste ist 274 pt breit und mittig (gemessen auf dem iPhone 17, iOS 27.2). Im Prototyp reicht sie bis 22 pt an beide Ränder (346 pt).
- Das System zeigt gefüllte Symbole (`moon.stars.fill`, `book.fill`). Der Prototyp zeigt Umrisse.
- Der Abstand zum unteren Rand ist 21 pt statt 22 pt.

Die Höhe stimmt mit 62 pt.

- **Standard:** Systemverhalten.
- **Alternative:** Die Umriss-Symbole lassen sich erzwingen. Die Breite der Systemleiste lässt sich nicht einstellen.

### 3. Rechenmethoden (Phase 1)

Der Prototyp nennt für jede Methode nur die Winkel (`METHODS`). Adhan Swift bringt für einige Methoden zusätzlich Minutenkorrekturen mit, so wie die jeweilige Stelle ihre Zeiten veröffentlicht – etwa Diyanet: Sonnenaufgang −7, Dhuhr +5, Asr +4, Maghrib +7; MWL: Dhuhr +1.

- **Standard:** die Voreinstellungen von Adhan Swift samt Korrekturen übernehmen.
- **JAKIM und Kemenag** haben in Adhan Swift keine Voreinstellung. Standard: reine Winkel 20°/18° ohne Sicherheitsminuten. Gibt es Referenztabellen, an denen sich das prüfen lässt?
- **Umm al-Qura:** Standard ist immer 90 Minuten nach Maghrib, wie im Prototyp (`iMin:90`), auch im Ramadan.
- **Automatische Methode** für Länder außerhalb der Liste im Bauplan (DE, TR, ES, SA, ID): Standard MWL. Für Deutschland siehe Spec § 6.1.

### 4. Regel für hohe Breiten (Phase 1)

- **Standard:** winkelbasiert, wie im Prototyp (`hlRule:'angle'`) und als Vorschlag in Spec § 6.2. Adhan Swift würde oberhalb von 48° das Siebtel der Nacht empfehlen.

### 5. „In Mekka“ (Phase 4)

Ab welcher Entfernung zur Kaaba zeigt die Qibla-Seite die Meldung statt der Nadel? Der Prototyp kennt nur den Fall „Stadt Mekka“ (`km:0`).

- **Standard:** unter 5 km.

### 6. Ausrichtung

- **Standard:** nur Hochformat. Ob das innere Display des iPhone Duo Querformat braucht, klärt Phase 10 (Spec § 6.17).

### 7. Name der App je Sprache

`T` enthält `appName` in vier Sprachen (Gebetszeiten, Namaz Vakitleri, Prayer Times, Horarios de oración). Unter dem App-Symbol steht bisher in jeder Sprache „Gebetszeiten“.

- **Standard:** bleibt so, bis der Name entschieden ist (Spec § 6.9).

## Annahmen in Phase 0

Diese Punkte sind entschieden oder ergeben sich aus den Unterlagen. Sie stehen hier, damit sie auffindbar sind.

- **Projekt:** XcodeGen mit `project.yml`; das erzeugte Projekt liegt nicht in Git. Der Quelltext liegt in `~/Developer/NamazVakti`, die Build-Daten auf der externen Platte „Extern“.
- **Bundle-ID, App Group, Team:** Platzhalter `com.example.gebetszeiten` und `group.com.example.gebetszeiten`, kein Team. Vor dem ersten Archiv ersetzen.
- **Simulator-Runtime:** iOS 27.2 statt iOS 26. Die Mindestversion der App bleibt iOS 26; das Aussehen der Systemelemente kann sich zwischen beiden Versionen unterscheiden.
- **Koordinaten und Zeitzonen der fünf Fixture-Städte** stehen nicht im Prototyp. Angenommen ist jeweils die Stadtmitte: Berlin 52,5200 / 13,4050 · Istanbul 41,0082 / 28,9784 · Madrid 40,4168 / −3,7038 · Mekka 21,4225 / 39,8262 · Jakarta −6,2088 / 106,8456. Phase 1 prüft damit Qibla und Entfernung gegen die Werte des Prototyps (Berlin 137°, 4130 km).
- **`-debugHighLatitude`** bedeutet Berlin am 21. Juni **2027** – das Jahr aus `BERLIN_SUMMER`, obwohl die übrigen Screenshots im November 2026 liegen. Zusammen mit `-debugCity` oder `-debugDate` gewinnt `-debugHighLatitude`, und die App meldet den Widerspruch.
- **`-debugFixtureTimes` ohne `-debugCity`** bedeutet Berlin, wie im Prototyp (`S.city`) und in `docs/PROMPTS.md`.
- **Debug-Uhr:** `-debugDate` und `-debugTime` gelten in der Zeitzone der Stadt, ohne Stadt in der des Geräts. Fehlt das Datum, gilt heute; fehlt die Uhrzeit, gilt die aktuelle.
- **Sprache der Screenshots:** über die Systemargumente `-AppleLanguages` und `-AppleLocale`, mit den Regionen aus `LOC` im Prototyp (de-DE, tr-TR, en-GB, es-ES).
- **Texte als `String`:** `L10n` liefert fertige Texte aus dem String Catalog. Mehrere Platzhalter stehen im Katalog als `%1$@`, `%2$@`, weil einzelne Sprachen die Reihenfolge umstellen (z. B. `notifPrayerBody` im Türkischen).
- **App-Symbol:** noch keines; das Platzhalter-Symbol kommt in Phase 11.
