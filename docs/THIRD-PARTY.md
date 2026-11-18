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

## Adhan-Aufnahmen

Platzhalter von Wikimedia Commons (CC0 1.0 bzw. gemeinfrei), siehe `docs/OPEN-QUESTIONS.md` unter „Adhan-Aufnahmen“ und `App/Sounds/`. Sie verlangen keinen Lizenzhinweis; ihre Herkunft ist vor dem App Store zu prüfen.

Prüfsummen (SHA-256), festgehalten am 18.11.2026:

| Datei | SHA-256 |
|---|---|
| `App/Sounds/adhan-voice1.caf` | `56fcd8d321a6735c78e17fdb2477d3b915f8e19ceacd6f69c34cb021e2162fa7` |
| `App/Sounds/adhan-voice2.caf` | `ed932deb81b814672fb65972c0a926ca6a4958c4d7a9fdd87dc94394adede8ea` |
| `App/Sounds/live-activity-silence.caf` | `7d04dabd0bb85e7a498394eb4d32e3e51a33c2b313d85e1a4c85ad4269233e04` (eigene Stille, kein fremder Teil) |
