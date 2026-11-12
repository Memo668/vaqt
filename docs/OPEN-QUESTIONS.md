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

### 3. Banner „Standortzugriff aus – Stadt manuell gewählt“, solange noch keine Stadt gewählt ist

Verweigert jemand den Standort, bevor eine Stadt gewählt ist, steht das Banner schon da – sein Text sagt aber „Stadt manuell gewählt“. Der Prototyp kennt den Zustand nicht: Dort ist immer eine Stadt gewählt. `T` hat keinen anderen Text.

- **Standard:** Das Banner bleibt, wie es ist. Die Stadtzeile zeigt „Stadt wählen“, und das Stadt-Sheet öffnet sich von selbst. Sobald eine Stadt gewählt ist, stimmt der Text.

### 4. Bundesländer in der Ortssuche

Die Ortssuche fragt bei Apple nach Städten und Verwaltungsgebieten. Mit „nur Städte“ fehlen Stadtstaaten: Für „Berl“, „Hambu“ und „Wien“ liefert der Dienst dann weder Berlin noch Hamburg noch Wien, weil er sie als Verwaltungsgebiet führt. Mit den Verwaltungsgebieten stehen sie an erster Stelle – es erscheinen aber auch Flächenländer wie „Bayern“ als Vorschlag. Wer eines wählt, bekommt die Zeiten für dessen Mitte.

- **Standard:** Städte und Verwaltungsgebiete, weil fehlende Großstädte schwerer wiegen als ein Bundesland in der Liste.

### 5. Antippen beim Abgleich

`xcrun simctl` kann starten und aufnehmen, aber nicht tippen. Zustände, die einen Tipp brauchen – `iphone/85` (Stadt-Sheet), später Qibla, Anleitung, Nachholen und die Einstellungen –, lassen sich damit nicht automatisch nachstellen. In Phase 3 hat ein kleines Hilfsprojekt außerhalb des Repos getippt: ein UI-Test, der die installierte App startet, antippt, wischt, tippt und aufnimmt (`/Volumes/Extern/Builds/NamazVakti/ui-harness`).

- **Standard:** Das Hilfsprojekt bleibt außerhalb des Repos. Vorschlag: als `scripts/ui-harness` ins Repo übernehmen, damit `make` auch Zustände mit Tipp nachstellen kann.

## Vor der Veröffentlichung zu prüfen

- **Kompass am echten Gerät** (Phase 4): Der Simulator hat keinen Kompass; geprüft ist dort alles nur mit festem Kurs. Am Gerät zu prüfen: dass die Skala ruhig und in die richtige Richtung dreht, dass mit Standortfreigabe geografisch Nord gilt und ohne sie magnetisch Nord, ab welcher Abweichung die Karte „Kompass kalibrieren“ erscheint (angenommen sind 25°), die Haptik beim Ausrichten und der Verbrauch, solange die Seite offen ist.
- **JAKIM und Kemenag** rechnen mit reinen Winkeln 20°/18°, ohne Sicherheitsminuten (entschieden am 10.11.2026, siehe unten). Beide sind gegen offizielle Tabellen zu prüfen, bevor die App erscheint. Bisher gibt es nur den Vergleich mit dem Mock für Jakarta: Kemenag liegt bis zu 3 Minuten daneben (Dhuhr 11:36 statt 11:39). Die Voreinstellung `singapore` von Adhan Swift – dieselben Winkel, Dhuhr +1, aufgerundet – läge näher (11:38).

## Entschieden am 10.11.2026

Die Entscheidung steht jeweils wörtlich in Anführungszeichen.

### Automatische Methode je Land

- **Deutschland:** „Diyanet“ – statt MWL wie im Prototyp und im Vorschlag der Spec (§ 5, § 6.1).
- **Österreich:** „Ja, auch Österreich“ – ebenfalls Diyanet. Begründung: Die Zeiten von Diyanet sind in Deutschland und Österreich sehr verbreitet (DITIB).
- **Weitere Länder:** „Eigene Methode je Land“.

| Land | Methode |
|---|---|
| DE, AT, TR | Diyanet |
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
- **Folge für die Zeiten:** Ohne eigene Wahl rechnet die App in Deutschland und Österreich mit Diyanet – siehe „Mock-Zeiten für Berlin“.

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

## Entschieden mit dem Plan für Phase 2 am 10.11.2026

Der Plan für Phase 2 wurde am 10.11.2026 mit vier Vorschlägen freigegeben („Freigeben“). Damit gilt:

| Punkt | Entscheidung | Was das heißt |
|---|---|---|
| Aufnahmeweg für den Abgleich | neues Debug-Argument `-debugCatalog arc\|rows\|glass\|cards\|all`, nur in DEBUG | Die App zeigt den Katalog der Bausteine statt der Tabs. Bogen und Gebetskarten stehen im Zustand der übrigen Debug-Argumente. Dunkel und RTL kommen ohne eigenes Argument aus (`xcrun simctl ui … appearance dark`, `-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES`). |
| Ring bei eng liegenden Markern | 1,5 pt sichtbar, wie im Referenzbild `iphone/22` | Die Spec nennt 3 pt. Der Prototyp zeichnet eine 3 pt breite Kontur, deren innere Hälfte unter der Füllung liegt (`paint-order: stroke`). |
| Stepper | eigener Baustein `StepperPill` wie in `iphone/60` | 94 × 32 pt, Radius 8, zwei Tasten mit eigenen VoiceOver-Texten (`qadaMinus`, `qadaPlus`, `stepLess`, `stepMore`). Der `Stepper` des Systems sieht in iOS 26 anders aus und kennt nur einen gemeinsamen Text. |
| `BellState` | liegt in `PrayerCore` | Ton, Lautlos, Aus mit der Reihenfolge der Glocke und der Voreinstellung des Prototyps. Phase 8 braucht den Stand ohne UI. |

## Entschieden mit der Abnahme von Phase 2 am 11.11.2026

- **`-debugCatalog` in `CLAUDE.md`:** „ja“ – Das Argument steht jetzt in der Liste der Debug-Argumente in `CLAUDE.md`, wie schon in `README.md`.

## Entschieden mit dem Plan für Phase 3 am 11.11.2026

Der Plan für Phase 3 wurde am 11.11.2026 mit vier Vorschlägen freigegeben („Freigeben“). Damit gilt:

| Punkt | Entscheidung | Was das heißt |
|---|---|---|
| Symbol für den Chip „Anleitung“ | die Zeichnung des Prototyps: ein Gebetsteppich mit Mihrab-Bogen (`pray`) | Die Design Spec nennt für diesen Chip kein SF Symbol, und in den SF Symbols gibt es keines für Gebet oder Moschee; es gilt deshalb das Referenzbild. `GlassSymbol.prayerRug` zeichnet die Linien des Prototyps in einem Feld von 22 pt. „Zeiten“ zeigt `clock`, „Qibla“ `safari`. |
| Orte ohne Sonnenauf- oder -untergang | neuer Text `noTimes` in `T` (DE, TR, EN, ES), gezeigt an der Stelle von Bogen und Karten | „Für diesen Ort lassen sich heute keine Gebetszeiten berechnen, weil die Sonne nicht auf- oder untergeht.“ Der Prototyp hat dafür einen neuen Schlüssel bekommen, sein Aussehen ist unverändert. Der String Catalog hat damit 261 Einträge. |
| Gespeicherte Städte | Die Liste startet leer. Jede über die Suche gewählte Stadt wird gemerkt und ist dann auch ohne Netz wählbar. Löschen mit der Wischgeste der Liste. | Die fünf Städte aus `iphone/85` stehen nur mit `-debugFixtureTimes` da. Das Löschen geht über die Spec hinaus. Die Stadt, die gerade gilt, lässt sich nicht löschen. |
| Teilung der Phase | zwei Abschnitte in einem Durchgang | 3a: Leiste, Pager, Zeiten-Seite, Glocke, Toast, Abgleich `iphone/10` bis `22`. 3b: Stadt-Sheet, Standort, Ortssuche, `iphone/85`. |

Mit dem Plan freigegeben sind auch seine Annahmen; sie stehen unten unter „Annahmen in Phase 3“.

## Abnahme von Phase 3 am 11.11.2026

Phase 3 wurde am 11.11.2026 abgenommen („Abnehmen“), so wie sie auf dem Zweig `phase-3` stand (Stand `87bbb08`). Zu den Punkten 3 bis 5 unter „Braucht eine Entscheidung“ – Banner ohne gewählte Stadt, Bundesländer in der Ortssuche, Antippen beim Abgleich – gab es dabei keine Antwort; dort gilt weiter der jeweilige Standard.

## Entschieden mit dem Plan für Phase 4 am 11.11.2026

Der Plan für Phase 4 wurde am 11.11.2026 freigegeben („Freigeben“). Damit gelten die drei empfohlenen Antworten und die Annahmen des Plans:

| Punkt | Entscheidung | Was das heißt |
|---|---|---|
| Standort verweigert und keine Stadt gewählt | Skala ohne Nadel, an der Stelle der Info-Zeile ein Textknopf „Stadt wählen“ | Der Knopf öffnet das Stadt-Sheet. Der Text ist `citySheetTitle`; ein neuer Text war nicht nötig. Die Titelzeile heißt dann nur „Qibla“. |
| Gerät ohne Kompass (Simulator, iPhone-App auf dem Mac) | Skala fest mit Norden oben, die Nadel zeigt die Richtung auf der Skala; Kursanzeige und Peilmarke entfallen, die Info-Zeile bleibt | Neuer Text `noCompass` in `T`, in der Statuszeile: „Kein Kompass verfügbar“ · „Pusula kullanılamıyor“ · „No compass available“ · „Brújula no disponible“. Das Aussehen des Prototyps ist unverändert. Der String Catalog hat damit 262 Einträge. |
| Standort verweigert, Stadt gewählt | magnetisch Nord | iOS liefert geografisch Nord nur zusammen mit dem Standort des Geräts. Ohne Freigabe weicht der Kurs um die örtliche Missweisung ab – in Mitteleuropa wenige Grad, anderswo mehr. |
| Ort | eigenes Modell `PlaceModel` statt `TodayModel` durchzureichen | Zeiten- und Qibla-Seite teilen sich das Modell. `TodayModel` behält seine Schnittstelle. |
| Kalibrierungskarte | bei ungültigem Kurs oder mehr als 25° Abweichung (`Heading.poorAccuracy`) | Apple nennt keine Schwelle; der Wert ist eine Annahme und am Gerät zu prüfen (siehe oben). |
| Debug-Argument `-debugQiblaAccuracy` | neu | Die Referenzbilder zeigen die Karte immer, die App nur bei ungenauem Kompass. Mit `-debugQiblaAccuracy 40` lässt sie sich nachstellen. |
| `-debugFixtureTimes` ohne `-debugQiblaHeading` | Kurs 99°, der Startwert von `S.qibla.heading` | wie die übrigen Startwerte von `S`. Für den Abgleich gelten die Werte der Bilder: 98° (`iphone/30`), 137° (`31`), 138° (`32`). |
| Entfernung unter 10 km | auf ganze Kilometer | Mit der Rundung auf 10 km stünde 1 bis 5 km vor der Kaaba „0 km“. Ab 10 km gilt die entschiedene Rundung auf 10 km. |
| Standort noch nicht bestimmt | „Qibla · Aktueller Standort“, Skala ohne Nadel | bis der Ort da ist |

## Abnahme von Phase 4 am 12.11.2026

Phase 4 wurde am 12.11.2026 abgenommen („Abnehmen“), so wie sie auf dem Zweig `phase-4` stand (Stand `56f6bb2`). Zu den Punkten 1 bis 5 unter „Braucht eine Entscheidung“ gab es dabei keine Antwort; dort gilt weiter der jeweilige Standard. Offen bleibt die Prüfung des Kompasses am echten Gerät (oben unter „Vor der Veröffentlichung zu prüfen“).

## Annahmen in Phase 4

Gemessen ist auf dem iPhone 18 Pro mit iOS 27.2, Zustände wie in `scripts/compare-qibla`. Der Simulator hat keinen Kompass: Alles hier ist mit festem Kurs geprüft (`-debugQiblaHeading`).

### Was mit den Referenzbildern übereinstimmt

- **Kompass (`iphone/30` bis `32`):** Skala, Striche, Zahlen, Himmelsrichtungen, Nadel, Kaaba-Marke, Peilmarke und Mittelpunkt liegen auf den Pixeln der Referenz; der Unterschied der Ausschnitte ist im Mittel 1,1 bis 1,6 von 255. Die Geometrie rechnet dieselben Zahlen wie `dialSVG()` (Tests in `CompassLayoutTests`). Wie auf der Zeiten-Seite sitzt alles 4 pt tiefer und 6 pt weiter rechts, weil der sichere Bereich bei 62 statt 58 pt beginnt und der Bildschirm 12 pt breiter ist.
- **Zustände:** „Nach rechts drehen 39°“ bei Kurs 98° (`30`), Haken und „Du blickst Richtung Qibla“ in Akzent, Peilmarke in Akzent (`31`), in Mekka keine Nadel, keine Kaaba-Marke, leere Statuszeile und die Meldung (`32`).
- **Farben:** Akzent, Striche (`label-3` und `label-2`), Zahlen, Status in Akzent und Kartenfläche bis auf 1 von 255 je Kanal.
- **Kalibrierungskarte:** 86,3 pt hoch (Prototyp 86,6), Symbol 24 × 11 pt wie die Zeichnung; im Katalog in Referenzbreite mit demselben Zeilenumbruch.

**Lage der Zeilen:** Die Grundlinien liegen höchstens 1,7 pt neben denen des Referenzbilds. Das kommt von der Schrift der Referenzbilder: Mit den Maßen von SF Pro gerechnet setzt das CSS des Prototyps jede Zeile auf 0,5 pt dorthin, wo die App sie zeigt.

| Zeile (Grundlinie) | Referenz (y in pt) | App, 4 pt nach oben gerechnet | CSS des Prototyps mit den Maßen von SF Pro |
|---|---|---|---|
| „QIBLA · BERLIN“ | 140,0 | 139,0 | 139,1 |
| Kursanzeige „137°“ | 202,0 | 201,7 | 201,4 |
| Statuszeile | 568,0 | 569,0 | 568,5 |
| Info-Zeile | 597,0 | 597,0 | 596,6 |
| Karte, Titel | 655,0 | 655,0 | 654,7 |
| Karte, Text, erste Zeile | 674,0 | 675,7 | 675,3 |
| Karte, Text, zweite Zeile | 692,0 | 693,3 | 693,2 |

### Was abweicht und bleibt

- **Schrift:** wie in Phase 2. Die Ziffern der Kursanzeige sind in SF Pro schmaler und niedriger: „137°“ ist 93 statt 101 pt breit, die Ziffern 41 statt 42 pt hoch. Kursanzeige und Statuszeile stehen trotzdem mittig an derselben Stelle.
- **Haken vor „Du blickst Richtung Qibla“:** SF Symbol `checkmark`, 11 × 10,7 pt statt der flacheren Zeichnung des Prototyps (12 × 8,5 pt) – so groß wie das Häkchen im Stadt-Sheet.
- **„N“:** das Rot des Systems, in iOS 27.2 `#FF383C` statt `#FF3B30` im Prototyp.
- **Kalibrierungskarte:** 370 statt 358 pt breit, wie alle Karten; ihr Text bricht deshalb nach „die“ statt nach „bis“ um. Sie erscheint nur bei ungenauem Kompass – die Referenzbilder zeigen sie immer.
- **Statusleiste:** `iphone/32` zeigt 15:42; `make statusbar TIME=15:42`.
- **Obere Leiste:** wie in Phase 3 beschrieben (Glass, Schrift).

### Annahmen in der Umsetzung

- **Ort:** `PlaceModel` sagt, welcher Ort gilt; Zeiten- und Qibla-Seite teilen es sich. Der Tab bestimmt den Ort beim Erscheinen und wenn die App nach vorn kommt, und das Stadt-Sheet hängt am Tab. So öffnet die Qibla-Seite es über „Stadt wählen“, und es öffnet sich wie bisher von selbst, wenn der Standort verweigert und keine Stadt gewählt ist.
- **Kurs:** `CoreLocationHeadingSource` mit 1° Auflösung für das aufrecht gehaltene Gerät. Für geografisch Nord läuft mit Standortfreigabe die Ortung mit, grob (3 km) und nur, solange die Qibla-Seite zu sehen ist; liefert Core Location keinen Wert für geografisch Nord, gilt magnetisch Nord. Die Quelle fragt nie selbst nach der Freigabe. Die Kalibrierungsanzeige des Systems bleibt aus, weil die Seite ihre eigene Karte zeigt.
- **Sichtbar:** Der Kompass läuft nur, solange die Seite gewählt ist, die App vorn ist und weder die Einstellungen noch ein anderer Tab davorliegen (`qiblaVisible()` im Prototyp). Danach bleibt der letzte Kurs stehen.
- **Statuszeile:** ausgerichtet bis einschließlich 3°; die Gradzahl ist gerundet, knapp außerhalb steht deshalb wie im Prototyp noch „3°“; genau entgegengesetzt heißt es „Nach links drehen 180°“. Ein ungültiger Kurs (Genauigkeit negativ) dreht die Skala weiter, meldet aber keine Ausrichtung und zeigt die Kalibrierungskarte.
- **Ausrichten:** Haptik `.success`, ein Ring in Akzent läuft in 0,8 Sekunden 26 pt nach außen (bei „Bewegung reduzieren“ nicht), VoiceOver sagt „Du blickst Richtung Qibla“ an – jeweils nur, wenn die Seite zu sehen ist.
- **VoiceOver:** Der Kompass ist ausgeblendet; was er zeigt, sagen Kursanzeige („137° SO“, ein Element), Statuszeile und Info-Zeile. Die Titelzeile ist eine Überschrift. `dialAria` bleibt ungenutzt, weil der Text die Pfeiltasten der Simulation beschreibt.
- **Kursanzeige:** Ziffern in natürlicher Breite – `.q-readout` verlangt gleich breite Ziffern, aber `.q-deg` setzt die Schrift neu und nimmt das zurück. Sie wächst mit Dynamic Type höchstens auf das 1,2-Fache, die Himmelsrichtung daneben ohne Grenze, wie im Prototyp. Der Kompass bleibt 280 pt groß.
- **RTL:** Skala, Zahlen und Nadel werden nicht gespiegelt. Kursanzeige, Statuszeile und Kalibrierungskarte folgen der Leserichtung – im Prototyp tun sie das als Flex-Zeilen auch.
- **Ohne Kompass:** Bis feststeht, ob das Gerät einen hat, steht die Peilmarke da und der Platz der Kursanzeige bleibt frei; ohne Kompass entfallen beide, und der Kompass rückt nach oben.
- **Entfernung:** mit der Zifferngruppierung der Sprache, wie `num()` im Prototyp: „4.130“, englisch „4,130“, spanisch „4130“.

## Annahmen in Phase 3

Gemessen ist auf dem iPhone 18 Pro mit iOS 27.2, Zustände wie in `scripts/compare-today`. Lage und Größe stammen aus dem Baum der Bedienungshilfen der laufenden App.

### Was mit den Referenzbildern übereinstimmt

- **Zeiten-Seite, `iphone/10` bis `16`, `20` bis `22`:** Leiste, Kopf, Bogen und Karten liegen an der Stelle der Referenz. Der sichere Bereich beginnt im Simulator bei 62 statt 58 pt, alles sitzt deshalb 4 pt tiefer; mittige Bausteine sitzen 6 pt weiter rechts, weil der Bildschirm 12 pt breiter ist.

| Baustein | Referenz (y in pt) | App (y in pt) |
|---|---|---|
| obere Leiste | 58 bis 110 | 62 bis 114 |
| Stadt-Button | 128 bis 172 | 132 bis 176 |
| Datum, zwei Zeilen | 172 bis 213,4 | 176 bis 217,4 |
| Bogen | ab 223,4 | ab 227,4 |
| Gebetskarten, je 52 pt mit 8 pt Abstand | ab 411,4 | ab 415,3 |

- **Standort aus, offline (`iphone/17`):** Die Hinweis-Pille ist 26,3 pt hoch und sitzt 10 pt unter dem Datum, das Banner ist 52 pt hoch und sitzt 14 pt darunter, der Bogen 10 pt unter dem Banner. Kein Standortsymbol, keine Marke „manuell“.
- **Hohe Breiten (`iphone/18`):** Info-Marken an Fadschr und Ischa; die Hinweiskarte beginnt 12 pt unter den Karten und ist mit drei Zeilen Text 101 pt hoch. „Regel ändern“ führt nach Einstellungen › Hohe Breitengrade.
- **Zustände:** nichts hervorgehoben vor Fadschr (`12`), kein laufendes Gebet nach Sonnenaufgang (`13`), „Kerahat bis …“ in Gold (`14`, `15`), „Fadschr (morgen) in“ nach Ischa (`16`), gespiegelte Anordnung (`20`), türkische Texte und Daten (`21`), Ring bei eng liegenden Markern (`22`).
- **Stadt-Sheet (`iphone/85`):** Zeile „Aktueller Standort“ 44,3 pt, Städte mit Land 63,3 pt, 32 pt zwischen den Gruppen, 18 pt zwischen Suchfeld und erster Gruppe; Symbol und Häkchen so groß wie die Zeichnungen des Prototyps.
- **Toast:** 36 pt hoch, Unterkante 100 pt über der Unterkante des Bildschirms.

### Was abweicht und bleibt

- **Schrift, Symbole, Glass, Tableiste:** wie in Phase 2 beschrieben. Auf der Zeiten-Seite heißt das: Der Name der Stadt sitzt rund 1 pt tiefer als im Referenzbild und ist rund 5 pt schmaler; der Chip „Zeiten“ ist 1,3 pt breiter, die Kreise daneben sitzen entsprechend weiter rechts.
- **Breite:** Karten, Banner und Hinweiskarte füllen die Breite des Bildschirms abzüglich 16 pt Rand und sind im Simulator deshalb 370 statt 358 pt breit. Der Bogen bleibt 358 pt breit und steht mittig.
- **Große Schrift (`iphone/19`):** Der Text der Chips wächst bis AX1, wie die Spec es verlangt (bei „xxxLarge“ 23 pt); der Prototyp begrenzt ihn auf das 1,15-Fache (19,5 pt). Der gewählte Chip ist deshalb breiter. Stadt und Datum folgen den Größen des Systems (28 und 21 pt statt 29,7 und 20,25 pt); Bogen und Karten liegen dadurch 2 pt tiefer als im Referenzbild. Die Kerahat-Zeile bricht nur in der Karte des laufenden Gebets um, im Referenzbild in allen dreien – die Karten sind breiter und die Schrift schmaler.
- **Stadt-Sheet:** Das Sheet, seine Leiste, das Suchfeld und die Liste sind die des Systems. „Abbrechen“ ist eine Glass-Kapsel statt reinem Text; das Suchfeld ist eine 44 pt hohe Kapsel statt eines 38 pt hohen Rechtecks, die Gruppen liegen deshalb 6 pt tiefer; die Trennlinien sind auf beiden Seiten eingerückt statt bis zum rechten Rand zu laufen. Beim Suchen ersetzt das System Titel und „Abbrechen“ durch das Suchfeld mit einem Schließen-Knopf. Die gesperrte Zeile „Aktueller Standort“ blasst als Ganzes ab; im Prototyp bleibt ihr Symbol in Akzent.
- **Countdown:** Die Uhr läuft ab dem Start weiter. Eine Aufnahme entsteht ein bis zwei Sekunden danach und zeigt deshalb z. B. 2:01:57 statt 2:01:59.
- **Statusleiste:** `make statusbar` setzt 14:25. Die Referenzbilder zeigen die Uhrzeit ihres Zustands; dafür `make statusbar TIME=23:47`.

### Annahmen in der Umsetzung

- **Standortabfrage:** Bis es das Onboarding gibt (Phase 7), fragt die Zeiten-Seite beim ersten Start selbst („Beim Verwenden der App“). Mit Phase 7 wandert die Abfrage hinter den Vorab-Bildschirm. Wird abgelehnt und ist noch keine Stadt gewählt, öffnet sich das Stadt-Sheet – wie im Ablauf des Prototyps nach „Nicht erlauben“.
- **Begründung im System-Dialog:** `NSLocationWhenInUseUsageDescription` ist der Text `alLocBody` aus `T`, in vier Sprachen (`App/InfoPlist.xcstrings`). Der Dialog erscheint in der Sprache des Systems, nicht in der der App.
- **Automatik und Verweigern:** Ob der aktuelle Standort gilt, ist `S.autoLocation && !S.locDenied` wie im Prototyp. Das Verweigern schaltet die Automatik nicht ab: Wird der Standort in den iOS-Einstellungen wieder erlaubt, gilt er wieder. Die zuletzt gewählte Stadt bleibt gemerkt und gilt, solange der Standort verweigert ist.
- **Noch kein Ort:** Die Stadtzeile zeigt „Aktueller Standort“ (`currentLocation`), solange der Name fehlt, und „Stadt wählen“ (`citySheetTitle`), wenn es weder Freigabe noch Stadt gibt. Bogen und Karten erscheinen, sobald ein Ort da ist. Neue Texte braucht das nicht.
- **Geocoding:** über MapKit (`MKReverseGeocodingRequest`), weil `CLGeocoder` seit iOS 26 als veraltet markiert ist. An Apple gehen dafür nur die Koordinaten. Der Stadtname kommt in der Sprache der App. Gerechnet wird für den Standort des Geräts, nicht für die Mitte der gefundenen Stadt; gefragt wird mit einer Genauigkeit von drei Kilometern.
- **Ohne Netz:** Der zuletzt bestimmte Ort gilt weiter, wenn der neue Standort höchstens 25 km entfernt liegt (`Place.sameAreaKm`). Sonst rechnet die App mit dem Standort ohne Namen, in der Zeitzone des Geräts und – weil das Land fehlt – mit MWL, und zeigt „Aktueller Standort“. Kommt das Netz zurück, holt sie den Namen nach. Ob es ein Netz gibt, sagt `NWPathMonitor`; das schickt selbst nichts.
- **Ortssuche:** `MKLocalSearchCompleter` mit Städten und Verwaltungsgebieten (siehe oben, Punkt 4). Treffer in rund 1000 km Umkreis des Ortes, für den die Seite Zeiten zeigt, stehen zuerst. Der Name einer gewählten Stadt ist der aus der Adresse des Treffers, in der Sprache der App; ohne Zeitzone gilt ein Treffer als nicht bestimmbar. Ein Vorschlag, der schon als gespeicherte Stadt dasteht, erscheint nicht doppelt. Der Suchtext filtert die gespeicherten Städte nach Name und Land, ohne auf Schreibweise und Akzente zu achten.
- **Gespeicherte Städte:** in der Reihenfolge, in der sie gewählt wurden; dieselbe Stadt (Name und Land) steht nur einmal da. Löschen mit der Wischgeste des Systems; ihr Text „Löschen“ kommt vom System. Wird die gemerkte Stadt gelöscht, während der aktuelle Standort gilt, ist auch die Erinnerung an sie weg.
- **Hohe Breiten:** Hinweis und Info-Marken erscheinen an den Tagen, an denen die Regel Fadschr oder Ischa tatsächlich bestimmt (`PrayerTimesSource.usesHighLatitudeRule`). Adhan Swift sagt das nicht selbst; die App vergleicht dazu mit der weitesten Regel „Nachtmitte“. Für Berlin im Jahr 2027 (Diyanet): mit „Winkelbasiert“ vom 4. Mai bis 9. August, mit „Ein Siebtel der Nacht“ vom 28. Februar bis 12. Oktober, mit „Nachtmitte“ vom 23. Mai bis 21. Juli. Nur die letzte Spanne sind die Nächte, in denen es wirklich nicht ganz dunkel wird; davor und danach legen die beiden anderen Regeln Fadschr schon später und Ischa früher, als der Winkel es ergäbe. Der Text des Hinweises („wird es nachts nicht ganz dunkel“) trifft an diesen Tagen nicht wörtlich zu. Moonsighting übergeht die Regel, dort erscheint der Hinweis nie. Mit `-debugHighLatitude` und Mock-Zeiten gilt der Schalter des Prototyps.
- **Countdown und Bogen:** Eine `TimelineView` im Sekundentakt holt die Tagesphase aus dem Zeitstrahl; der Takt schlägt, wenn die App-Uhr auf eine neue Sekunde springt (`AppClock.nextWholeSecondOnDevice`), auch mit der verschobenen Debug-Uhr. Die Karten bauen sich nur neu auf, wenn sich der Schlüssel der Phase ändert (Spec § 4). Für VoiceOver ist der Countdown ein Element in Worten („Maghrib in 2 Std. 2 Min.“).
- **Datum:** der Kalendertag am Ort, nicht der des Geräts – 23:30 in Berlin ist in Jakarta schon der nächste Tag. Ohne Ort gilt die Zeitzone des Geräts. Sprache und Region kommen aus `L10n.locale`.
- **Pager:** eine waagerechte `ScrollView` mit Paging. Die obere Leiste hängt mit `safeAreaBar` darüber; der Inhalt jeder Seite scrollt unter ihr durch, mit dem Randeffekt des Systems. Chips wechseln die Seite mit Bewegung, bei „Bewegung reduzieren“ ohne. Die Auswahl bleibt beim Wechsel der Tabs und beim Öffnen der Einstellungen erhalten, nicht über einen Neustart.
- **Einstellungen als Ziel:** Der Einstellungskreis und „Regel ändern“ führen auf leere Seiten mit Titel und Zurück-Knopf (`SettingsRoute`); die Bildschirme folgen in Phase 7. Die Leiste gibt es bisher nur im Tab „Gebete“; Verse und Nachholen bekommen ihren Einstellungskreis in Phase 6.
- **Speicher:** `SettingsStore` schreibt in die UserDefaults der App Group (`AppGroupIdentifier` in der Info.plist, aus `APP_GROUP_ID`), damit Widgets und Live-Aktivität sie ab Phase 9 lesen können. Gespeichert sind Glocke je Ereignis, Automatik, gewählte Stadt, gespeicherte Städte, zuletzt bestimmter Ort, Rechen-Einstellungen und Kerahat-Schalter; die letzten beiden lassen sich erst in Phase 7 ändern.
- **Abgleich:** Mit `-debugFixtureTimes` startet die App mit den Startwerten von `S` – Glocken wie im Prototyp, die Stadt der Fixture, die fünf Städte aus `CITY_IDS` – und speichert nichts. Die Ortssuche bleibt dann stumm, das Netz gilt als vorhanden, außer mit `-debugOffline`.
- **Unterer Rand:** Unter dem letzten Element bleiben 28 pt bis zur Tableiste – die 112 pt von `.tab-spacer` abzüglich der 84 pt, die im Prototyp hinter der Tableiste liegen.
- **Toast:** Er steht über allen Tabs, 100 pt über der Unterkante des Bildschirms, und verdeckt dabei wie im Prototyp die unterste Gebetskarte. VoiceOver sagt ihn an.

## Annahmen in Phase 2

Diese Punkte ergeben sich aus dem Abgleich mit den Referenzbildern `iphone/10` bis `22`, `40` und `60` oder aus der Umsetzung. Gemessen ist auf dem iPhone 18 Pro mit iOS 27.2.

### Was mit den Referenzbildern übereinstimmt

- **Bogen:** Lage und Größe von Spur, Markern, Zeiten, Knopf, Schein, Ring und Kerahat-Segmenten in allen neun Zuständen (`iphone/10` bis `16`, `20`, `22`), auch dunkel und RTL. Die Geometrie rechnet auf drei Nachkommastellen dieselben Zahlen wie der Code des Prototyps.
- **Farben:** Akzent, Bogenspur, Schein, Kerahat-Segmente (ruhend und aktiv), Kartenfläche und Karte des laufenden Gebets stimmen hell und dunkel bis auf 1 von 255 je Kanal.
- **Gebetskarten:** Höhe 52 pt, Abstände, Lage von Symbol, Name, Chip „Jetzt“, Kerahat-Zeile, Uhrzeit und Glocke, auch in RTL.
- **Über die Abnahme hinaus geprüft:** hohe Breiten mit den Info-Marken an Fadschr und Ischa (`iphone/18`), große Schrift (`iphone/19`: Die Kerahat-Zeile bricht vor der Zeitspanne um, Symbole bleiben fest, die Zeiten am Bogen wachsen auf das 1,2-Fache) und Türkisch mit Istanbul (`iphone/21`, Chip „ŞİMDİ“).
- **Fakten-Kacheln und Stepper:** Größe und Lage wie in `iphone/40` und `iphone/60`.
- **Kleiner Bogen der Live-Aktivität:** Lage von Spur, Markern, Zeiten, Knopf und Kerahat-Segmenten wie in `system/93`; der Ring bei eng liegenden Markern ist am Fall Jakarta geprüft. Verglichen wurde ein gerendertes Bild des Bausteins, weil die Live-Aktivität selbst erst in Phase 9 entsteht.

### Was abweicht und bleibt

- **Schrift der Referenzbilder:** Die Bilder sind offenbar auf einem Rechner ohne SF Pro entstanden – die Ziffern sind breiter, die „1“ hat einen Fuß. Die App nimmt die Systemschrift, wie die Spec es verlangt. Folgen:
  - Texte sind in der App etwas schmaler. Am deutlichsten beim Countdown: „2:01:59“ ist rund 177 pt breit, im Referenzbild rund 194 pt.
  - Der Doppelpunkt zwischen Ziffern sitzt in der App mittig, im Referenzbild auf der Grundlinie. Das macht die Systemschrift von selbst.
  - Grundlinien liegen bis zu 1 pt anders, weil die Schriften andere Ober- und Unterlängen haben.
- **Symbole:** Die App zeigt SF Symbols, wie die Spec sie nennt, statt der Zeichnungen des Prototyps. Größe und Strichstärke sind angeglichen (siehe Tabelle unten), die Formen bleiben verschieden. Am deutlichsten bei der Glocke „Ton“: `bell.and.waves.left.and.right` ist mit den Wellen rund 25 pt breit, die Zeichnung des Prototyps rund 17 pt.
- **Glass:** Echtes Liquid Glass ist auf dem hellen Seitenhintergrund durchsichtiger als die Nachbildung im Prototyp: Die Kreise sind nicht weiß gefüllt und haben statt des grauen Schlagschattens einen feinen Rand. Das ist Systemverhalten.
- **Trennstrich im Stepper:** `separator` ist in iOS 27.2 heller als im Prototyp – hell 12 % statt 29 % Deckkraft, dunkel 50 % statt 65 %. Die Spec verlangt die Systemfarbe; der Strich ist deshalb heller als in `iphone/60`. Die übrigen Systemfarben (`tertiaryLabel`, die Füllungen, die Hintergründe) haben die Werte des Prototyps.

| Ort | SF Symbol als Schriftgröße | Stärke | Maß im Prototyp |
|---|---|---|---|
| Marker im Bogen | 0,72 × Kantenlänge (11,5 pt, laufend 13 pt) | bold | Feld 16 bzw. 18 pt, Strich 1,4 pt |
| Marker im kleinen Bogen | 0,72 × Kantenlänge (8,6 pt, laufend 9,4 pt) | heavy | Feld 12 bzw. 13 pt, Strich 1,15 pt |
| Gebetskarte | 14,5 pt | semibold | Feld 22 pt, Zeichnung knapp 18 pt breit, Strich 1,65 pt |
| Glocke | 13,5 pt | semibold | Feld 20 pt, Glockenkörper gut 12 pt, Strich 1,5 pt |
| Einstellungskreis | 20 pt | medium | Feld 24 pt, Zahnrad knapp 21 pt |
| Chip | 18 pt | medium | Feld 22 pt, Zeichnung 18 pt |
| Stepper | 12,5 pt | regular | Feld 18 pt, Strich gut 10 pt lang |

### Annahmen in der Umsetzung

- **Größe des Bogens:** fest 358 × 180 pt wie `ARCS.home`; er wächst nicht mit der Bildschirmbreite. Auf dem iPhone 18 Pro (402 pt) steht er mittig mit 22 pt Rand. Ob er auf breiteren Geräten wachsen soll, klärt Phase 3 bzw. Phase 10.
- **„Schwebende Leiste“:** `FloatingBar` ist der Träger der oberen Leiste – ein `GlassEffectContainer` mit 8 pt Abstand, ohne eigene Glasfläche (Spec § 3: vier einzelne Glass-Elemente, keine gemeinsame Kapsel). Die Tableiste bleibt die des Systems, der Toast kommt mit Phase 3.
- **Runder Glass-Button:** `.buttonStyle(.glass)` legt 7 pt Innenabstand um den Inhalt. Der Button bekommt deshalb seine Größe (52 pt) von außen, und der Inhalt füllt, was der Stil ihm lässt. Ein Test misst die Größe.
- **Schatten des gewählten Chips:** liegt hinter dem Glas und ist unter dem Chip ausgespart, wie ein `box-shadow`. Als Schatten auf der Glasfläche selbst war er nicht zu sehen.
- **Innenabstand der Chips in RTL:** 14 pt vor dem Symbol, 18 pt hinter dem Titel, in Leserichtung. Der Prototyp setzt die Werte fest links und rechts; in `iphone/20` sitzen sie deshalb vertauscht.
- **Varianten:** jeweils die Standardwahl aus Spec § 7 – Chips nur mit Titel (52 pt hoch), Gebetskarten 52 pt, Marker nach Uhrzeit, Countdown digital.
- **Countdown:** Phase 2 liefert die Schrift (64 pt thin, im Bogen 56 pt, ab zehn Stunden 50 pt, höchstens ×1,05) und den Platz im Bogen. Der laufende Countdown ist ein Baustein der Zeiten-Seite in Phase 3; der Katalog zeigt einen festen Text.
- **Live-Aktivität:** `DayArc(style: .liveActivity)` zeichnet nur den kleinen Bogen (`ARCS.la`, Farben aus `.arc-la`). Kopfzeile, Name und Countdown der Live-Aktivität folgen in Phase 9. Die Zeiten am kleinen Bogen haben Ziffern in natürlicher Breite, nicht gleich breite wie am großen – so zeigt es `system/93`, weil `.arc-la .arc-t` die Schrift neu setzt.
- **Dynamic Type:** Zeiten am Bogen wachsen höchstens auf das 1,2-Fache, der Countdown auf das 1,05-Fache, die Leiste auf das 1,15-Fache; der Text der Chips wächst bis AX1. Die Maße des Bogens bleiben fest.
- **Große Schrift:** Die App folgt den Größen des Systems je Textstil; der Prototyp rechnet einheitlich mit dem 1,35-Fachen. Bei der Stufe „xxxLarge“ ist Fließtext in beiden 23 pt groß, Caption 1 aber 18 statt 16,2 pt und Caption 2 17 statt 14,9 pt. Eine Gebetskarte mit Kerahat-Zeile ist dort deshalb rund 80 statt 75 pt hoch.
- **Zeilenhöhen:** SwiftUI kennt kein `line-height`. `textStyle(_:lineHeight:)` setzt die Zeilenhöhe des Prototyps über engen Zeilenabstand plus Zugabe. Das System rundet jede Zeile auf Gerätepixel; mehrzeilige Texte weichen deshalb bis zu 0,7 pt ab.
- **Schatten:** `box-shadow` mit Weichzeichnung b wird in SwiftUI zu `radius: b / 2`.
- **Uhrzeiten:** immer „HH:mm“ im 24-Stunden-Format, wie `fmt()` im Prototyp, in allen vier Sprachen.
- **Kerahat-Zeile:** Wortverbinder um den Strich halten die Spanne „15:42–16:27“ in einer Zeile.
- **Katalog:** in der Breite der Referenzbilder (390 pt), der Baustein 140 pt unter der Oberkante – so liegt er in jeder Aufnahme am selben Ort. Die Überschriften im Katalog sind Notizen für die Entwicklung und stehen nicht im String Catalog.
- **`-debugCatalog` ohne `-debugFixtureTimes`:** Der Katalog rechnet dann echt, wie später die Zeiten-Seite. Ohne Stadt zeigt er Berlin um 14:25 aus den Mock-Zeiten.

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
