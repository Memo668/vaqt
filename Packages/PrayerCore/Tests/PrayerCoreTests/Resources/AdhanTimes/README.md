# Referenztabellen aus Adhan Swift

Fünf Tabellen mit veröffentlichten Gebetszeiten, unverändert übernommen aus `Tests/Resources/Times/` von [Adhan Swift](https://github.com/batoulapps/adhan-swift), Version 1.5.0. Jede Datei nennt unter `source` die Stelle, von der die Zeiten stammen. Lizenz: MIT, siehe `LICENSE-adhan-swift.txt`.

Die Tabellen liegen hier als Kopie, damit die Tests ohne den SwiftPM-Checkout auf der externen Platte laufen.

| Datei | Methode in der App | Tage | erlaubte Abweichung |
|---|---|---|---|
| `Ankara-Turkey.json` | Diyanet | 24 | 2 Minuten |
| `Makkah-UmmAlQura.json` | Umm al-Qura | 12 | keine |
| `Singapore-Singapore.json` | Singapore | 366 | 2 Minuten |
| `Tehran-Tehran.json` | Tehran | 12 | 1 Minute |
| `London-MoonsightingCommittee.json` | Moonsighting | 12 | keine |

`ReferenceTimesTests` rechnet jede Zeile mit `AdhanTimesSource` nach. Die erlaubte Abweichung steht in der Datei unter `variance`; fehlt die Angabe, muss jede Zeit auf die Minute stimmen.

Die Tabellen für Doha, Dubai und Kuwait fehlen, weil die App diese Methoden nicht anbietet. Für MWL, ISNA, Egyptian und Karachi gibt es in Adhan Swift keine Tabelle; MWL, ISNA und Egyptian prüft `ReferenceTimesTests` gegen einzelne Werte aus `Tests/AdhanTests.swift`.
