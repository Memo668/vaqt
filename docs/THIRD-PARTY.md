# Fremde Teile

Was die App von anderen übernimmt, woher es stammt und unter welcher Lizenz. Die Lizenztexte liegen im Paket `DesignSystem` (`Resources/Licenses/`) und stehen in der App unter Einstellungen › Über › Lizenzen (`SoftwareLicense`, Spec § 9.7). Kommt etwas dazu, gehört es hierher und auf diese Seite.

## Adhan Swift

| | |
|---|---|
| Zweck | Berechnung der Gebetszeiten (PrayerCore, `AdhanTimesSource`) |
| Quelle | [batoulapps/adhan-swift](https://github.com/batoulapps/adhan-swift), Swift Package ab 1.5.0 (`Packages/PrayerCore/Package.swift`) |
| Lizenz | MIT, Copyright (c) 2016 Batoul Apps |
| Lizenztext | `Packages/DesignSystem/Sources/DesignSystem/Resources/Licenses/AdhanSwift-LICENSE.txt` (dieselbe Datei wie `Packages/PrayerCore/Tests/PrayerCoreTests/Resources/AdhanTimes/LICENSE-adhan-swift.txt`) |
| Dazu | Fünf Referenztabellen aus den Testdaten von Adhan Swift 1.5.0 in `Packages/PrayerCore/Tests/PrayerCoreTests/Resources/AdhanTimes/` (nur Tests) |

## Amiri und Amiri Quran

| | |
|---|---|
| Zweck | Arabische Schrift: Amiri Quran für die Verse (31 pt), Amiri für die Formeln der Anleitung (23 pt) und des Durchlaufs „Schritt für Schritt“ (27 pt) – Spec § 9.7 |
| Quelle | Release **1.003** von [aliftype/amiri](https://github.com/aliftype/amiri/releases/tag/1.003), Archiv `Amiri-1.003.zip`, geladen am 15.11.2026. Google Fonts liefert dieselbe Fassung (`ofl/amiriquran` aus 1.003; `ofl/amiri` aus 1.002) – damit zeichnet der Prototyp. |
| Lizenz | SIL Open Font License 1.1, Copyright 2010-2022 The Amiri Project Authors |
| Dateien | `Packages/DesignSystem/Sources/DesignSystem/Resources/Fonts/Amiri-Regular.ttf` und `AmiriQuran.ttf`, unverändert aus dem Archiv; Lizenztext `Resources/Licenses/Amiri-OFL.txt` (= `OFL.txt` des Archivs) |
| Einbinden | `ArabicFont` registriert beide Schriften beim ersten Gebrauch für den Prozess (`CTFontManagerRegisterFontsForURL`), ohne Eintrag in der Info.plist |

Prüfsummen (SHA-256):

| Datei | SHA-256 |
|---|---|
| `Amiri-1.003.zip` (Release) | `81af0aff7d2086d8af24cea7202f7546130997982534691373485cd96744d05e` – wie `digest` der Release auf GitHub |
| `Amiri-Regular.ttf` | `cd2550c0f4c05eb341bf97958211aaa39382bca96577ba3a67d4a3b4912c43c0` |
| `AmiriQuran.ttf` | `e2a47644762d16bdfb6d33e0d8db8c6ff30beae84150ef5a705316bbd829455c` |
| `Amiri-OFL.txt` | `72de68e5954f4fdd24702292ef5a32f003ca960ec9330dc86e5eefb5dffb9b22` |

Neue Fassung einbinden: Archiv der Release laden, Prüfsumme gegen `digest` der Release auf GitHub vergleichen, die beiden `.ttf` und `OFL.txt` (als `Amiri-OFL.txt`) ersetzen, die Version in `WalkComponentTests.fontVersion` und hier eintragen und die Maße in `ArabicFont` (Ober- und Unterlänge) prüfen – der Test `fontMetrics` vergleicht sie mit den Dateien.

## Verse: arabischer Text

| | |
|---|---|
| Zweck | Der arabische Text der sechs Verse, jeweils ein Teil des Verses (`VERSES` im Prototyp, `VerseList.swift`) |
| Quelle | Uthmani-Text des [Tanzil-Projekts](https://tanzil.net). Am 24.11.2026 Zeichen für Zeichen mit der Fassung „quran-uthmani“ verglichen (über api.alquran.cloud, das den Text von Tanzil übernimmt): gleich bis auf die Reihenfolge von Schadda und Vokalzeichen, die der Prototyp in der Reihenfolge von Unicode (NFC) speichert. Das Schriftbild ist dasselbe. |
| Lizenz | Creative Commons Attribution 3.0. Der Text darf unverändert verwendet werden, mit Quellenangabe und Link auf tanzil.net ([Text License](https://tanzil.net/docs/text_license)). |
| Hinweis in der App | Einstellungen › Über › Lizenzen (`Resources/Licenses/Tanzil-NOTICE.txt`, der vorgeschriebene Hinweis im Wortlaut). Auf Arabisch nennt auch die Zeile unter der Vers-Karte die Quelle (`verseSource`). |

## Verse: Übersetzungen

Seit Phase 18 (Spec § 11.1). Entschieden am 24.11.2026: die Übersetzungen „erstmal“ aus dem Repo quran-api, als „kurze Ausschnitte wie bisher“. Es ist eine vorläufige Auswahl.

| | |
|---|---|
| Zweck | Die Übersetzung unter dem arabischen Vers: je Sprache ein wörtlicher Ausschnitt einer veröffentlichten Übersetzung. Auf Arabisch steht nur der Vers. |
| Auswahl | Sammlung [fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api), Zweig `1`, Commit `93e6f64925ae76273520d636fcaaf061129f2316` (20.10.2026). Das Repo selbst steht unter der Unlicense. Die Übersetzungen darin gehören weiter den Übersetzern und Verlagen. |
| Wortlaut | Das Repo entfernt am Versende die Satzzeichen. Deshalb ist jeder Text mit der Quelle verglichen, die das Repo nennt: Tanzil (über api.alquran.cloud) und für Indonesisch quranenc.com. Alle 90 Texte stimmen überein, bis auf Satzzeichen am Versende, Anführungszeichen und bei Indonesisch die Fußnotenziffern. Das Satzende stammt aus diesen Quellen. |
| Ausschnitt | Der Teil der Übersetzung, der dem gezeigten arabischen Teil entspricht: ein zusammenhängendes Stück, nichts umformuliert. „…“ steht für ausgelassene Teile des Verses und ist mit einem geschützten Leerzeichen an den Text gebunden. Ein Komma, Semikolon, Doppelpunkt, Gedankenstrich oder Anführungszeichen direkt am Schnitt fällt weg. |
| Prüfung | Geschnitten am 24.11.2026. Ein Skript hat geprüft, dass jeder Ausschnitt wörtlich in der Quelle und im Repo steht. Zwei Hilfsagenten haben unabhängig voneinander alle 90 Ausschnitte gegen den arabischen Text gelesen und keinen falschen Schnitt gefunden. Eine Durchsicht durch Menschen mit der jeweiligen Muttersprache steht aus. |
| Bedingungen | Tanzil stellt die Übersetzungen „for non-commercial purposes only“ bereit und verlangt ab mehr als drei Übersetzungen einen Link auf [tanzil.net/trans](https://tanzil.net/trans/) (gelesen am 24.11.2026). Bevor die App Geld annimmt, ist zu klären, ob das noch passt. Sonst braucht es die Erlaubnis der Übersetzer oder Verlage. |
| Hinweis in der App | Unter der Vers-Karte steht die Übersetzung der Sprache (`verseSource`). Die ganze Liste mit Quellen steht unter Einstellungen › Über › Lizenzen (`Resources/Licenses/QuranTranslations-NOTICE.txt`). |

| Sprache | Übersetzung | Ausgabe im Repo | Verglichen mit |
|---|---|---|---|
| Deutsch | A. S. F. Bubenheim und N. Elyas | `deu-asfbubenheimand` | Tanzil `de.bubenheim` |
| Türkisch | Türkiye Diyanet Vakfı | `tur-diyanetvakfi` | Tanzil `tr.vakfi` |
| Englisch | Saheeh International | `eng-ummmuhammad` | Tanzil `en.sahih` |
| Spanisch | Muhammad Isa García | `spa-muhammadisagarc` | Tanzil `es.garcia` |
| Französisch | Muhammad Hamidullah | `fra-muhammadhamidul` | Tanzil `fr.hamidullah` |
| Niederländisch | Fred Leemhuis | `nld-fredleemhuis` | Tanzil `nl.leemhuis` |
| Bosnisch | Besim Korkut | `bos-besimkorkut` | Tanzil `bs.korkut` |
| Albanisch | Sherif Ahmeti | `sqi-sherifahmeti` | Tanzil `sq.ahmeti` |
| Urdu | Fateh Muhammad Jalandhari | `urd-fatehmuhammadja` | Tanzil `ur.jalandhry` |
| Indonesisch | Kementerian Agama RI | `ind-indonesianislam` | QuranEnc `indonesian_affairs` |
| Malaiisch | Abdullah Muhammad Basmeih | `msa-abdullahmuhamma` | Tanzil `ms.basmeih` |
| Bengalisch | Muhiuddin Khan | `ben-muhiuddinkhan` | Tanzil `bn.bengali` |
| Persisch | Mohammad Mahdi Fooladvand | `fas-mohammadmahdifo` | Tanzil `fa.fooladvand` |
| Russisch | Elmir Kuliev | `rus-elmirkuliev` | Tanzil `ru.kuliev` |
| Italienisch | Hamza Roberto Piccardo | `ita-hamzarobertopic` | Tanzil `it.piccardo` |

Was beim Zusammenstellen auffiel:

- **Niederländisch:** Vorgeschlagen war zuerst Sofian S. Siregar. Sein Text hat in der Quelle Tippfehler in drei der sechs Verse („ven“, „moeilijkeid“, „Voorwaarm“). Weil nichts geändert wird, steht dort jetzt Fred Leemhuis.
- **Türkisch:** Die ältere Übersetzung „Diyanet İşleri“ fasst bei 2:45 zwei Verse zusammen und eignet sich deshalb nicht. Bei der Diyanet Vakfı endet 2:286 in den Daten vor dem Versende; der Ausschnitt (der erste Satz) ist davon nicht berührt.
- **Französisch:** Die Ausgabe von QuranEnc (`fra-muhammadhameedu`) hat Satzfehler („laprière“), deshalb die von Tanzil.
- **Indonesisch:** Die Ausgabe im Repo trägt Fußnotenziffern im Text („kepadamu.50)“). Der Wortlaut kommt deshalb von QuranEnc, ohne die Fußnotenmarken.

Verse ändern oder ergänzen: Die Übersetzungen stehen in `VERSES` im Prototyp (`tr`, je Sprache ein Text), `make strings` trägt sie in den String Catalog. Jeder neue Ausschnitt braucht denselben Abgleich mit der Quelle.

## Adhan-Aufnahme

Seit Phase 18 (Spec § 11.2, entschieden am 24.11.2026). Vorher lagen hier zwei Platzhalter von Wikimedia Commons (`adhan-voice1.caf`, `adhan-voice2.caf`).

| | |
|---|---|
| Zweck | Der kurze Adhan: Ton der Mitteilung zur Gebetszeit, Weckton „Kurzer Adhan“ und die Vorschau im Adhan-Fenster |
| Werk | „Best Adhan - Ustadh Mmanga Muharram - from Tanzania“, Muezzin Ustadh Mmanga Muharram, Aufnahme und Video von DARSA TV (Tansania), veröffentlicht am 12.05.2020 |
| Quelle | [youtube.com/watch?v=TuPIDIsDWl0](https://www.youtube.com/watch?v=TuPIDIsDWl0), 3:14 Minuten. Die Tonspur hat der Inhaber am 24.11.2026 als MP3 geliefert (2:53 Minuten, 128 kbit/s); sie liegt nicht im Repo. |
| Lizenz | Auf YouTube mit „Creative Commons Attribution license (reuse allowed)“ markiert (am 24.11.2026 auf der Seite des Videos nachgesehen). YouTube verweist dafür auf [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Die Lizenz hat der Kanal gesetzt; die Beschreibung des Videos nennt Muezzin, Produktion und Video. Eine eigene Zusage des Muezzins liegt nicht vor. |
| Änderungen | Nur der Ton. Die ersten 29,5 Sekunden, am Ende 1 Sekunde ausgeblendet, mono, 22,05 kHz, IMA4 in CAF (ein Format, das iOS für Mitteilungstöne annimmt, unter 30 Sekunden). Der Ausschnitt endet in der dritten Pause der Aufnahme (ab 28,5 s); gemessen am Lautstärkeverlauf (`adhan-clip.swift envelope`). |
| Schnitt | `swift scripts/adhan-clip.swift clip <mp3> <ausschnitt.caf> 0.0 29.5 1.0`, danach `afconvert -f caff -d ima4 -c 1 <ausschnitt.caf> App/Sounds/adhan.caf` |
| Hinweis in der App | Unter dem Player im Adhan-Fenster (`voiceFooter`) und unter Einstellungen › Über › Lizenzen (`Resources/Licenses/AdhanRecording-NOTICE.txt`: Titel, Urheber, Quelle, Lizenz, Änderungen) |
| Nicht geprüft | Angehört hat den Ausschnitt beim Schneiden niemand: Der Schnitt folgt dem gemessenen Lautstärkeverlauf, und der Simulator hat hier kein Ausgabegerät. Die Probe am Gerät steht aus. Auch fachlich hat ihn niemand angesehen (welcher Teil des Adhan in 30 Sekunden passt). |

Prüfsummen (SHA-256), festgehalten am 24.11.2026:

| Datei | SHA-256 |
|---|---|
| `App/Sounds/adhan.caf` | `49092fe213b985881723a559150098a09218423a213c304fe3bf5ad1743887a9` |
| Gelieferte MP3 (nicht im Repo) | `e72c637397221a8661d7580a061e9ca775d8b7524fb86f0783d55e68f76aac85` |
| `App/Sounds/live-activity-silence.caf` | `7d04dabd0bb85e7a498394eb4d32e3e51a33c2b313d85e1a4c85ad4269233e04` (eigene Stille, kein fremder Teil) |
