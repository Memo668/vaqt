# Offene Fragen

Hier steht alles, was Spec, Screenshots und Prototyp nicht eindeutig beantworten. Was noch offen ist, nennt den Standardwert, mit dem bis zu einer Entscheidung gebaut wird. Was entschieden ist, steht weiter unten mit seiner Folge. Die offenen Designfragen der Spec selbst stehen in `design/prayer-times-design-spec.md` § 6.

## Braucht eine Entscheidung

### 1. Umm al-Qura im Ramadan

Die Methode legt Ischa 90 Minuten nach Maghrib (`iMin:90`). In Saudi-Arabien gilt im Ramadan ein Abstand von 120 Minuten; Adhan Swift empfiehlt dafür eine eigene Korrektur von +30 Minuten.

- **Stand:** Die Antwort vom 10.11.2026 – „So wie es in Europa normal gehandhabt wird“ – ist noch nicht eindeutig und wird geklärt.
- **Standard bis dahin:** immer 90 Minuten, wie im Prototyp, auch im Ramadan.

### 2. Moonsighting und die Regel für hohe Breiten (vertagt bis Phase 7)

Moonsighting rechnet in Adhan Swift mit eigenen jahreszeitlichen Grenzen und übergeht die Regel für hohe Breiten. Die Einstellung „Hohe Breitengrade“ wirkt bei dieser Methode also nicht.

- **Standard:** so lassen. Ob die Einstellungen das sagen sollen, entscheidet Phase 7.

### 3. Orte ohne Sonnenauf- oder -untergang (vertagt bis Phase 3)

Nördlich des Polarkreises geht die Sonne an manchen Tagen nicht auf oder nicht unter. Adhan Swift liefert dann keine Zeiten: `PrayerTimesSource.times` gibt `nil` zurück, und es gibt keinen Zeitstrahl. Spec und Prototyp kennen den Fall nicht.

- **Standard:** offen bis Phase 3. Vorschlag: ein Hinweis an der Stelle der Zeiten.

## Vor der Veröffentlichung zu prüfen

- **JAKIM und Kemenag** rechnen mit reinen Winkeln 20°/18°, ohne Sicherheitsminuten (entschieden am 10.11.2026, siehe unten). Beide sind gegen offizielle Tabellen zu prüfen, bevor die App erscheint. Bisher gibt es nur den Vergleich mit dem Mock für Jakarta: Kemenag liegt bis zu 3 Minuten daneben (Dhuhr 11:36 statt 11:39). Die Voreinstellung `singapore` von Adhan Swift – dieselben Winkel, Dhuhr +1, aufgerundet – läge näher (11:38).

## Entschieden am 10.11.2026

Die Entscheidung steht jeweils wörtlich in Anführungszeichen.

### Automatische Methode je Land

- **Deutschland:** „Diyanet“ – statt MWL wie im Prototyp und im Vorschlag der Spec (§ 5, § 6.1).
- **Weitere Länder:** „Eigene Methode je Land“.

| Land | Methode |
|---|---|
| DE, TR | Diyanet |
| ES | MWL |
| SA | Umm al-Qura |
| ID | Kemenag |
| US, CA | ISNA |
| EG | Egyptian |
| PK, IN, BD, AF | Karachi |
| MY | JAKIM |
| SG | Singapore |
| IR | Tehran |
| alle übrigen Länder und ohne Land | MWL |

Moonsighting gilt in keinem Land von selbst; die Methode lässt sich nur wählen. Die Zuordnung steht in `CalculationMethod.automatic(forCountryCode:)`.

- **Folge für die Referenzbilder:** `iphone/70` und `iphone/73` zeigen für Berlin „Automatisch · MWL“ (im Prototyp `CITIES.berlin.auto`). Die Fixture-Daten bleiben wie der Prototyp. Annahme für Phase 7: Mit `-debugFixtureTimes` gilt die Automatik der Fixture-Stadt (`FixtureTimes.City.automaticMethodID`), damit sich die Bilder nachstellen lassen; ohne das Argument gilt Diyanet.
- **Folge für die Zeiten:** Ohne eigene Wahl rechnet die App in Deutschland mit Diyanet – siehe „Mock-Zeiten für Berlin“.

### „In Mekka“

„Unter 1 km“ – statt der vorgeschlagenen 5 km (`Qibla.meccaRadiusKm`). Näher an der Kaaba zeigt die Qibla-Seite die Meldung statt der Nadel.

- **Folge für die Referenzbilder:** keine. Die Fixture-Stadt Mekka liegt an der Kaaba; `iphone/32` lässt sich weiter nachstellen.

### Anleitung: Ende des Zeitfensters von Ischa

„Fadschr von morgen“ – statt Fadschr von heute wie im Prototyp (`ph.t[NEXT_OF[p]]`). Das Fenster liefert `Guide.window(of:in:at:)`.

- **Folge für die Referenzbilder:** keine. Mit den Mock-Zeiten bleibt es bei „18:17–05:16“, weil dort jeder Tag dieselben Uhrzeiten hat.

### Simulator für Tests und Abgleich

„Iphone 18 pro“ – der Simulator „iPhone 18 Pro“ (iOS 27.2). `make` nimmt ihn als Standard; ein anderer lässt sich mit `SIM='…'` wählen.

- **Folge für die Referenzbilder:** Das iPhone 18 Pro hat wie das iPhone 17 402 × 874 pt (1206 × 2622 px bei 3x). Die Referenzbilder sind 390 × 844 pt groß – der Bildschirm ist 12 pt breiter und 30 pt höher. Ein Vergleich Pixel auf Pixel geht damit weiterhin nicht: Verglichen werden Abstände, Größen, Farben und Texte der Bausteine, nicht die Lage im ganzen Bild.

### Mock-Zeiten für Berlin

„Ja, so lassen“ – die Mock-Zeiten bleiben unverändert. Sie sind die Zahlen der Referenz-Screenshots.

Der Prototyp zeigt für Berlin 05:16 · 07:14 · 11:52 · 14:00 · 16:27 · 18:17 und nennt MWL als Methode. Für den 10.11.2026 rechnet die App:

| Methode | Fadschr | Sonnenaufgang | Dhuhr | Asr | Maghrib | Ischa | größte Abweichung vom Mock |
|---|---|---|---|---|---|---|---|
| MWL, die Methode des Prototyps | 05:21 | 07:19 | 11:51 | 13:55 | 16:21 | 18:13 | 6 Minuten (Maghrib) |
| Diyanet, die Automatik der App | 05:21 | 07:12 | 11:55 | 13:59 | 16:28 | 18:13 | 5 Minuten (Fadschr) |

Die Berliner Mock-Zeiten passen eher zum 6./7. November. Die übrigen vier Städte liegen höchstens 4 Minuten neben der Rechnung. Der Test `FixturePlausibilityTests` erlaubt ±5 Minuten: mit der Methode des Prototyps und Berlin-Maghrib als benannter Ausnahme, mit der Automatik der App ohne Ausnahme.

- **Folge für die Referenzbilder:** Ohne `-debugFixtureTimes` zeigt die App für Berlin am 10.11.2026 andere Zahlen als die Screenshots, z. B. Sonnenaufgang 07:12 statt 07:14 und Maghrib 16:28 statt 16:27.

### Bestätigt, wie es war

| Punkt | Entscheidung | Was das heißt |
|---|---|---|
| Regel für hohe Breiten | „Winkelbasiert“ | wie im Prototyp (`hlRule:'angle'`) und im Vorschlag der Spec § 6.2. Adhan Swift würde oberhalb von 48° das Siebtel der Nacht empfehlen. |
| Hijri-Datum | „Um Mitternacht“ | Das Datum wechselt zusammen mit dem gregorianischen, nicht bei Maghrib. Zur Korrektur um ±1 Tag siehe Spec § 6.7. |
| Name der App | „Überall ‚Gebetszeiten‘“ | Unter dem App-Symbol steht in jeder Sprache „Gebetszeiten“, auch wenn `T` vier Namen enthält (Spec § 6.9). |
| Tableiste | „Systemverhalten“ | Die System-`TabView` bleibt. Sie weicht von den Referenzbildern ab: 274 pt breit und mittig statt 346 pt, gefüllte Symbole statt Umrissen, 21 pt statt 22 pt Abstand zum unteren Rand (gemessen auf dem iPhone 17, iOS 27.2). Die Höhe stimmt mit 62 pt. |
| Entfernung zur Kaaba | „Ja, so lassen“ | Die Anzeige rundet auf 10 km, wie die Werte des Prototyps (4130, 2410, 4600, 7920 km). `PrayerCore` liefert die Entfernung ungerundet, für Berlin 4130,2 km. |
| Ausrichtung | „Ja, so lassen“ | nur Hochformat. Ob das innere Display des iPhone Duo Querformat braucht, klärt Phase 10 (Spec § 6.17). |
| Nachholen | „Ja, so lassen“ | Die App startet leer: kein Zeitraum, nichts offen, 5 Gebete pro Tag, ohne Witr. `iphone/60` und `61` zeigen die Beispielzahlen des Prototyps; die gibt es nur in DEBUG (`QadaLedger.prototypeSample`). Annahme für Phase 6: Mit `-debugFixtureTimes` zeigt die Seite sie. |
| JAKIM und Kemenag | „Ja, so lassen“ | reine Winkel 20°/18°. Vor der Veröffentlichung gegen offizielle Tabellen zu prüfen, siehe oben. |

## Annahmen in Phase 1

Diese Punkte ergeben sich aus den Unterlagen oder aus der Umsetzung. Die Zahlen dazu stammen aus einer Rechenprobe mit Adhan Swift 1.5.0.

- **Voreinstellungen von Adhan Swift:** Der Prototyp nennt für jede Methode nur die Winkel (`METHODS`). Adhan Swift bringt für einige Methoden zusätzlich Minuten mit, so wie die jeweilige Stelle ihre Zeiten veröffentlicht – etwa Diyanet: Sonnenaufgang −7, Dhuhr +5, Asr +4, Maghrib +7; MWL: Dhuhr +1. Die App übernimmt die Voreinstellungen samt diesen Minuten.
- **Reihenfolge der Ereignisse:** Der Prototyp sortiert seinen Zeitstrahl nach Uhrzeit. `PrayerTimeline` lässt die Ereignisse in ihrer Tagesfolge; laufend ist das letzte der Folge, das begonnen hat. Für aufsteigende Zeiten und bei Gleichstand ist das Ergebnis dasselbe (Ischa von gestern und Fadschr von heute um 01:08 – Fadschr gewinnt). Der Unterschied zeigt sich mit der Regel „Nachtmitte“ nach der Sonnenwende: Dann liegt Ischa von gestern eine Minute hinter Fadschr von heute (Berlin, 11.07.2027: Ischa 01:12, Fadschr 01:11). Nach Uhrzeit sortiert liefe ab 01:12 „Ischa von gestern“, und Fadschr wäre bis zum Sonnenaufgang nicht hervorgehoben.
- **Zeitumstellung:** Countdown, Spanne und Tagesfortschritt rechnen mit echter Zeit. Am 25.10.2026 um 00:30 sind es bis Fadschr um 05:16 deshalb 5 h 46 min. Der Prototyp käme mit seinen Minuten seit Mitternacht auf 4 h 46 min.
- **Ein Zeitstrahl gilt für einen Kalendertag am Ort.** Nach Mitternacht liefert `PrayerTimeline.phase(at:)` nichts mehr; die App baut dann einen neuen (`covers(_:)`).
- **Zeitfenster von Ischa vor Fadschr:** Läuft vor Fadschr noch Ischa von gestern, zeigt die Anleitung dessen Fenster: von gestern Abend bis Fadschr heute. So endet das Fenster dort, wohin auch der Countdown zählt. Das folgt aus der Entscheidung „Fadschr von morgen“: Ein Ischa endet mit dem Fadschr des Tages nach ihm.
- **Mock-Quelle:** `FixtureTimesSource` nimmt die Fixture-Stadt, die an den Koordinaten des Ortes liegt, für jeden anderen Ort Berlin. Methode und Datum ändern die Mock-Zeiten nicht. Asr-Regel, Minutenkorrekturen und – mit `-debugHighLatitude` – die Regel für hohe Breiten wirken wie in `todayTimes()`. In `AppEnvironment` hängt die Quelle erst Phase 3 ein.
- **Referenzwerte:** Fünf Tabellen aus den Testdaten von Adhan Swift liegen als Kopie unter `Packages/PrayerCore/Tests/PrayerCoreTests/Resources/AdhanTimes/` (MIT, Lizenztext liegt bei). So laufen die Tests auch ohne die externe Platte.
- **Qibla:** Die Richtung kommt von Adhan Swift. Die Entfernung folgt dem Großkreis auf einer Kugel mit 6371,0088 km Radius.
- **Hijri-Text:** `DateFormatter` mit der Vorlage `dMMMMy`, ohne Ära. Für die vier Sprachen kommt derselbe Text heraus wie bei `hijriDate()` im Prototyp, z. B. „30. Dschumada I 1448“.
- **Texte in `PrayerCore`:** Die Namen der Methoden (`METHODS`) und die Formeln der Anleitung (`FORMULA`) stehen als Daten im Code, weil sie in allen Sprachen gleich sind. Alles andere bleibt im String Catalog.
- **Anleitung:** Zwischen Sonnenaufgang und Dhuhr ist das automatische Gebet immer Dhuhr. Der Sonnenaufgang lässt sich nicht wählen.
- **Nachholen:** Die Grenzen der Stepper gelten auch für gespeicherte Werte. Bei 99.999 offenen Gebeten bewirkt „+“ nichts mehr.

Wie weit die Rechenmethoden geprüft sind:

| Methode | Prüfung |
|---|---|
| Diyanet, Umm al-Qura, Singapore, Tehran, Moonsighting | veröffentlichte Tabellen aus den Testdaten von Adhan Swift, auf 0 bis 2 Minuten genau |
| MWL, ISNA, Egyptian | einzelne Tage aus den Tests von Adhan Swift, auf die Minute |
| Karachi | nur die Winkel (18°/18°) |
| JAKIM, Kemenag | nur die Winkel (20°/18°); gegen veröffentlichte Zeiten ungeprüft |

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
