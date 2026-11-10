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

### 3. Rechenmethoden (Phase 1, so gebaut)

Der Prototyp nennt für jede Methode nur die Winkel (`METHODS`). Adhan Swift bringt für einige Methoden zusätzlich Minutenkorrekturen mit, so wie die jeweilige Stelle ihre Zeiten veröffentlicht – etwa Diyanet: Sonnenaufgang −7, Dhuhr +5, Asr +4, Maghrib +7; MWL: Dhuhr +1.

- **Standard:** die Voreinstellungen von Adhan Swift samt Korrekturen übernehmen.
- **JAKIM und Kemenag** haben in Adhan Swift keine Voreinstellung. Standard: reine Winkel 20°/18° ohne Sicherheitsminuten. Gibt es Referenztabellen, an denen sich das prüfen lässt? Für Jakarta liegt Kemenag damit bis zu 3 Minuten neben dem Mock (Dhuhr 11:36 statt 11:39). Die Voreinstellung `singapore` von Adhan Swift (dieselben Winkel, Dhuhr +1, aufgerundet) läge näher (11:38).
- **Umm al-Qura:** Standard ist immer 90 Minuten nach Maghrib, wie im Prototyp (`iMin:90`), auch im Ramadan.
- **Automatische Methode** für Länder außerhalb der Liste im Bauplan (DE, TR, ES, SA, ID): Standard MWL. Für Deutschland siehe Spec § 6.1.
- **Moonsighting** rechnet in Adhan Swift mit eigenen jahreszeitlichen Grenzen und übergeht die Regel für hohe Breiten. Standard: so lassen. Die Einstellung „Hohe Breitengrade“ wirkt bei dieser Methode also nicht – soll die Seite das sagen (Phase 7)?

Wie weit das geprüft ist:

| Methode | Prüfung |
|---|---|
| Diyanet, Umm al-Qura, Singapore, Tehran, Moonsighting | veröffentlichte Tabellen aus den Testdaten von Adhan Swift, auf 0 bis 2 Minuten genau |
| MWL, ISNA, Egyptian | einzelne Tage aus den Tests von Adhan Swift, auf die Minute |
| Karachi | nur die Winkel (18°/18°) |
| JAKIM, Kemenag | nur die Winkel (20°/18°); gegen veröffentlichte Zeiten ungeprüft |

### 4. Regel für hohe Breiten (Phase 1, so gebaut)

- **Standard:** winkelbasiert, wie im Prototyp (`hlRule:'angle'`) und als Vorschlag in Spec § 6.2. Adhan Swift würde oberhalb von 48° das Siebtel der Nacht empfehlen.

### 5. „In Mekka“ und die Entfernung (Phase 4)

Ab welcher Entfernung zur Kaaba zeigt die Qibla-Seite die Meldung statt der Nadel? Der Prototyp kennt nur den Fall „Stadt Mekka“ (`km:0`).

- **Standard:** unter 5 km (`Qibla.meccaRadiusKm`).

Wie wird die Entfernung gerundet? `PrayerCore` liefert sie ungerundet (Berlin 4130,2 km). Die vier Werte des Prototyps (4130, 2410, 4600, 7920 km) passen alle zu „auf 10 km gerundet“: Istanbul sind gerechnet 2405,1 km, Madrid 4598,2 km.

- **Standard:** auf 10 km runden, wie die Werte des Prototyps.

### 6. Ausrichtung

- **Standard:** nur Hochformat. Ob das innere Display des iPhone Duo Querformat braucht, klärt Phase 10 (Spec § 6.17).

### 7. Name der App je Sprache

`T` enthält `appName` in vier Sprachen (Gebetszeiten, Namaz Vakitleri, Prayer Times, Horarios de oración). Unter dem App-Symbol steht bisher in jeder Sprache „Gebetszeiten“.

- **Standard:** bleibt so, bis der Name entschieden ist (Spec § 6.9).

### 8. Mock-Zeiten für Berlin und die echte Rechnung (Phase 1)

Für Berlin am 10.11.2026 rechnet die App mit MWL 05:21 · 07:19 · 11:51 · 13:55 · 16:21 · 18:13. Der Prototyp zeigt 05:16 · 07:14 · 11:52 · 14:00 · 16:27 · 18:17. Maghrib liegt damit 6 Minuten neben der Rechnung, die anderen Werte höchstens 5. Die Berliner Mock-Zeiten passen eher zum 6./7. November. Die übrigen vier Städte liegen höchstens 4 Minuten neben der Rechnung.

- **Standard:** Die Mock-Zeiten bleiben, wie sie sind – sie sind die Zahlen der Referenz-Screenshots. Der Test erlaubt ±5 Minuten und führt Berlin-Maghrib als benannte Ausnahme (`FixturePlausibilityTests`).
- **Folge:** Ohne `-debugFixtureTimes` zeigt die App für Berlin am 10.11.2026 andere Zahlen als die Screenshots, z. B. Asr 13:55 statt 14:00.

### 9. Orte ohne Sonnenauf- oder -untergang (Phase 3)

Nördlich des Polarkreises geht die Sonne an manchen Tagen nicht auf oder nicht unter. Adhan Swift liefert dann keine Zeiten: `PrayerTimesSource.times` gibt `nil` zurück, und es gibt keinen Zeitstrahl. Spec und Prototyp kennen den Fall nicht.

- **Standard:** offen bis Phase 3. Vorschlag: ein Hinweis an der Stelle der Zeiten.

### 10. Nachholen: Startwerte (Phase 6)

Der Prototyp startet mit Beispielzahlen: 1 Jahr 6 Monate, 545 je Gebet, 133 nachgeholt.

- **Standard:** Die App startet leer – kein Zeitraum, nichts offen, 5 Gebete pro Tag, ohne Witr (Spec § 5: „empty state when nothing is entered“). Wie der leere Zustand aussieht, zeigt kein Screenshot.
- Die Beispielzahlen gibt es nur in DEBUG (`QadaLedger.prototypeSample`). Standard: Mit `-debugFixtureTimes` zeigt die Seite sie, damit sich `iphone/60` und `61` nachstellen lassen.

### 11. Hijri-Datum: Wechsel um Mitternacht (Phase 3)

Der Prototyp wechselt das Hijri-Datum um Mitternacht, zusammen mit dem gregorianischen. Der islamische Tag beginnt aber mit dem Sonnenuntergang; manche Apps wechseln deshalb bei Maghrib.

- **Standard:** wie der Prototyp, um Mitternacht. Siehe auch Spec § 6.7 zur Korrektur um ±1 Tag.

### 12. Anleitung: Ende des Zeitfensters von Ischa (Phase 5)

Die Kopfkarte zeigt das Zeitfenster eines Gebets, bei Ischa „18:17–05:16“. Der Prototyp nimmt dafür Fadschr von heute (`ph.t[NEXT_OF[p]]`). Mit echter Rechnung liegt Fadschr von morgen ein bis zwei Minuten daneben.

- **Standard:** wie der Prototyp, die Zeiten von heute.

## Annahmen in Phase 1

Diese Punkte sind entschieden oder ergeben sich aus den Unterlagen. Die Zahlen dazu stammen aus einer Rechenprobe mit Adhan Swift 1.5.0.

- **Reihenfolge der Ereignisse:** Der Prototyp sortiert seinen Zeitstrahl nach Uhrzeit. `PrayerTimeline` lässt die Ereignisse in ihrer Tagesfolge; laufend ist das letzte der Folge, das begonnen hat. Für aufsteigende Zeiten und bei Gleichstand ist das Ergebnis dasselbe (Ischa von gestern und Fadschr von heute um 01:08 – Fadschr gewinnt). Der Unterschied zeigt sich mit der Regel „Nachtmitte“ nach der Sonnenwende: Dann liegt Ischa von gestern eine Minute hinter Fadschr von heute (Berlin, 11.07.2027: Ischa 01:12, Fadschr 01:11). Nach Uhrzeit sortiert liefe ab 01:12 „Ischa von gestern“, und Fadschr wäre bis zum Sonnenaufgang nicht hervorgehoben.
- **Zeitumstellung:** Countdown, Spanne und Tagesfortschritt rechnen mit echter Zeit. Am 25.10.2026 um 00:30 sind es bis Fadschr um 05:16 deshalb 5 h 46 min. Der Prototyp käme mit seinen Minuten seit Mitternacht auf 4 h 46 min.
- **Ein Zeitstrahl gilt für einen Kalendertag am Ort.** Nach Mitternacht liefert `PrayerTimeline.phase(at:)` nichts mehr; die App baut dann einen neuen (`covers(_:)`).
- **Mock-Quelle:** `FixtureTimesSource` nimmt die Fixture-Stadt, die an den Koordinaten des Ortes liegt, für jeden anderen Ort Berlin. Methode und Datum ändern die Mock-Zeiten nicht. Asr-Regel, Minutenkorrekturen und – mit `-debugHighLatitude` – die Regel für hohe Breiten wirken wie in `todayTimes()`. In `AppEnvironment` hängt die Quelle erst Phase 3 ein.
- **Referenzwerte:** Fünf Tabellen aus den Testdaten von Adhan Swift liegen als Kopie unter `Packages/PrayerCore/Tests/PrayerCoreTests/Resources/AdhanTimes/` (MIT, Lizenztext liegt bei). So laufen die Tests auch ohne die externe Platte.
- **Qibla:** Die Richtung kommt von Adhan Swift. Die Entfernung folgt dem Großkreis auf einer Kugel mit 6371,0088 km Radius.
- **Hijri-Text:** `DateFormatter` mit der Vorlage `dMMMMy`, ohne Ära. Für die vier Sprachen kommt derselbe Text heraus wie bei `hijriDate()` im Prototyp, z. B. „30. Dschumada I 1448“.
- **Texte in `PrayerCore`:** Die Namen der Methoden (`METHODS`) und die Formeln der Anleitung (`FORMULA`) stehen als Daten im Code, weil sie in allen Sprachen gleich sind. Alles andere bleibt im String Catalog.
- **Anleitung:** Zwischen Sonnenaufgang und Dhuhr ist das automatische Gebet immer Dhuhr. Der Sonnenaufgang lässt sich nicht wählen.
- **Nachholen:** Die Grenzen der Stepper gelten auch für gespeicherte Werte. Bei 99.999 offenen Gebeten bewirkt „+“ nichts mehr.

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
