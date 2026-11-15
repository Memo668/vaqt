// scripts/import-strings.swift
//
// Liest das Objekt `T` (alle App-Texte, DE/TR/EN/ES) und die Verse (`VERSES`, `SURAH`) aus
// design/prayer-times-prototype.html und erzeugt daraus
//
//   • Packages/DesignSystem/Sources/DesignSystem/Resources/Localizable.xcstrings
//   • Packages/DesignSystem/Sources/DesignSystem/Generated/L10n.swift
//   • App/InfoPlist.xcstrings – die Texte der Info.plist, die aus `T` kommen (siehe `infoPlistTexts`)
//   • Packages/PrayerCore/Sources/PrayerCore/Verses/VerseList.swift – Stelle und arabischer Text der Verse
//
// Übersetzungen der Verse und Namen der Suren hängen von der Sprache ab und kommen deshalb in den
// String Catalog (`verse_<Sure>_<Vers>`, `surah_<Sure>`); die Übersetzungen sind Platzhalter und tragen
// dort den Kommentar `TODO(placeholder)` (entschieden am 12.11.2026, docs/OPEN-QUESTIONS.md).
//
// Aufruf über den Wrapper:
//   scripts/import-strings            Dateien neu schreiben
//   scripts/import-strings --check    nur prüfen, ob die Dateien zum Prototyp passen (Exit 1 bei Abweichung)
//
// `T` wird mit JavaScriptCore ausgewertet, nicht per Regex gelesen – so stimmen
// Schlüssel und Werte auch bei Anführungszeichen, Doppelpunkten und Escapes im Text.
//
// Regeln:
//   • Schlüssel bleiben wie im Prototyp (`t('navPrayers')` ↔ `L10n.navPrayers`).
//   • Platzhalter `{name}` werden zu `%@`; hat ein Text mehrere, zu `%1$@`, `%2$@` …
//     Die Reihenfolge der Argumente ist die des ersten Auftretens (DE, dann TR, EN, ES).
//   • Listen (z. B. `dirs`) werden zu `dirs.0`, `dirs.1` …
//   • Quellsprache des Katalogs ist Deutsch.
//   • Die Info.plist braucht jeden ihrer Texte zusätzlich als Grundwert. Der steht in project.yml und
//     muss dem deutschen Text entsprechen; das Skript prüft das, schreibt project.yml aber nicht um.

import Foundation
import JavaScriptCore

// MARK: - Hilfen

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("import-strings: \(message)\n".utf8))
    exit(1)
}

let languages = ["de", "tr", "en", "es"]

/// Ein Text als Zeichenkette in doppelten Anführungszeichen, wie Swift und YAML sie schreiben.
func literalString(_ text: String) -> String {
    "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

// MARK: - Argumente

var root = FileManager.default.currentDirectoryPath
var checkOnly = false
var arguments = Array(CommandLine.arguments.dropFirst())
while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--root":
        guard !arguments.isEmpty else { fail("--root braucht einen Pfad") }
        root = arguments.removeFirst()
    case "--check":
        checkOnly = true
    default:
        fail("Unbekanntes Argument: \(argument)")
    }
}

let rootURL = URL(fileURLWithPath: root)
let prototypeURL = rootURL.appendingPathComponent("design/prayer-times-prototype.html")
let catalogURL = rootURL.appendingPathComponent("Packages/DesignSystem/Sources/DesignSystem/Resources/Localizable.xcstrings")
let swiftURL = rootURL.appendingPathComponent("Packages/DesignSystem/Sources/DesignSystem/Generated/L10n.swift")
let infoPlistURL = rootURL.appendingPathComponent("App/InfoPlist.xcstrings")
let verseListURL = rootURL.appendingPathComponent("Packages/PrayerCore/Sources/PrayerCore/Verses/VerseList.swift")
let projectURL = rootURL.appendingPathComponent("project.yml")

/// Texte der Info.plist, die aus `T` kommen: Schlüssel der Info.plist → Schlüssel in `T`.
/// `NSLocationWhenInUseUsageDescription` ist die Begründung im System-Dialog der Standortabfrage –
/// im Prototyp der Text des nachgebauten Dialogs (`alLocBody`, design/screenshots/iphone/04).
let infoPlistTexts: [(plistKey: String, textKey: String)] = [
    ("NSLocationWhenInUseUsageDescription", "alLocBody"),
]

// MARK: - `T` aus dem Prototyp schneiden

/// Liefert das Literal hinter `const <name> = `, von `{` bzw. `[` bis zur passenden Klammer.
/// Zeichenketten und Kommentare werden übersprungen, damit Klammern im Text nicht zählen.
func objectLiteral(named name: String, in source: String, opening: Character = "{") -> String {
    guard let declaration = source.range(of: "const \(name) = \(opening)") else {
        fail("`const \(name) = \(opening)` nicht im Prototyp gefunden")
    }
    let scalars = Array(source[source.index(before: declaration.upperBound)...].unicodeScalars)
    var depth = 0
    var quote: Unicode.Scalar?
    var escaped = false
    var index = 0
    while index < scalars.count {
        let scalar = scalars[index]
        if let open = quote {
            if escaped {
                escaped = false
            } else if scalar == "\\" {
                escaped = true
            } else if scalar == open {
                quote = nil
            }
        } else {
            switch scalar {
            case "'", "\"", "`":
                quote = scalar
            case "{", "[":
                depth += 1
            case "}", "]":
                depth -= 1
                if depth == 0 {
                    var view = String.UnicodeScalarView()
                    view.append(contentsOf: scalars[0...index])
                    return String(view)
                }
            case "/" where index + 1 < scalars.count && scalars[index + 1] == "/":
                while index < scalars.count, scalars[index] != "\n" { index += 1 }
            case "/" where index + 1 < scalars.count && scalars[index + 1] == "*":
                index += 2
                while index + 1 < scalars.count, !(scalars[index] == "*" && scalars[index + 1] == "/") { index += 1 }
                index += 1
            default:
                break
            }
        }
        index += 1
    }
    fail("Ende von `\(name)` nicht gefunden")
}

guard let html = try? String(contentsOf: prototypeURL, encoding: .utf8) else {
    fail("Prototyp nicht lesbar: \(prototypeURL.path)")
}
let literal = objectLiteral(named: "T", in: html)

/// Die Nachträge zu `T` vom 15.11.2026 (Spec § 9): neue und geänderte Texte, die der Prototyp hinter
/// `T` mit `Object.assign(T…)` und `[…].forEach(…)` einträgt – vom Kommentar `patchMarker` bis vor
/// `const SURAH`. Damit kein Nachtrag unbemerkt fehlt, muss jedes `Object.assign(T` des Prototyps in
/// diesem Abschnitt stehen.
let patchMarker = "/* ===== Änderungen vom 15.11.2026: neue und geänderte Texte"
func textPatches(in source: String) -> String {
    guard let start = source.range(of: patchMarker),
          let end = source.range(of: "const SURAH = ", range: start.upperBound..<source.endIndex)
    else {
        fail("Nachträge zu `T` nicht gefunden (`\(patchMarker)` … `const SURAH`)")
    }
    let block = String(source[start.lowerBound..<end.lowerBound])
    let inBlock = block.components(separatedBy: "Object.assign(T").count
    let inFile = source.components(separatedBy: "Object.assign(T").count
    guard inBlock == inFile else {
        fail("`Object.assign(T` steht auch außerhalb der Nachträge vom 15.11.2026 – Abschnitt prüfen")
    }
    return block
}
let patches = textPatches(in: html)

/// Sprachen, die der Prototyp schon hat, die App aber erst mit Phase 15 bekommt (Spec § 9.10). Ihre
/// Texte übergeht der Import bis dahin.
let laterLanguages = ["fr", "nl", "bs", "sq", "ar", "ur", "id", "ms", "bn", "fa", "ru", "it"]

// MARK: - Auswerten (Reihenfolge der Schlüssel bleibt erhalten)

let context = JSContext()!
var scriptError: String?
context.exceptionHandler = { _, exception in scriptError = exception?.toString() }
let script = """
(function () {
  var T = \(literal);
  \(patches)
  return JSON.stringify(Object.keys(T).map(function (lang) {
    return [lang, Object.keys(T[lang]).map(function (key) { return [key, T[lang][key]]; })];
  }));
})()
"""
guard let json = context.evaluateScript(script)?.toString(), scriptError == nil,
      let evaluated = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[Any]]
else {
    fail("`T` ließ sich nicht auswerten: \(scriptError ?? "unbekannter Fehler")")
}

let foundLanguages = evaluated.compactMap { $0.first as? String }
guard foundLanguages.filter({ !laterLanguages.contains($0) }) == languages else {
    fail("Erwartete Sprachen \(languages) (dazu später \(laterLanguages)), gefunden \(foundLanguages)")
}
let skippedLanguages = foundLanguages.filter { laterLanguages.contains($0) }
let parsed = evaluated.filter { block in (block.first as? String).map(languages.contains) ?? false }

/// Ein Eintrag aus `T`: entweder ein Text oder eine Liste von Texten.
enum Value {
    case text(String)
    case list([String])
}

var order: [String] = []                       // Schlüssel in der Reihenfolge des Prototyps
var table: [String: [String: Value]] = [:]     // Schlüssel → Sprache → Wert

for languageBlock in parsed {
    guard let language = languageBlock[0] as? String, let pairs = languageBlock[1] as? [[Any]] else {
        fail("Unerwartete Struktur in `T`")
    }
    for pair in pairs {
        guard let key = pair[0] as? String else { fail("Schlüssel ohne Namen in \(language)") }
        let value: Value
        if let text = pair[1] as? String {
            value = .text(text)
        } else if let list = pair[1] as? [String] {
            value = .list(list)
        } else {
            fail("\(language).\(key): nur Texte und Listen von Texten werden unterstützt")
        }
        if table[key] == nil { order.append(key) }
        table[key, default: [:]][language] = value
    }
}

// MARK: - Platzhalter

let placeholderPattern = try! NSRegularExpression(pattern: "\\{([A-Za-z0-9_]+)\\}")

/// Namen der Platzhalter in der Reihenfolge ihres Auftretens, mit Wiederholungen.
func placeholders(in text: String) -> [String] {
    let range = NSRange(text.startIndex..., in: text)
    return placeholderPattern.matches(in: text, range: range).map {
        String(text[Range($0.range(at: 1), in: text)!])
    }
}

/// `{name}` → `%@` bzw. `%1$@`; ein wörtliches `%` wird zu `%%`.
func formatString(_ text: String, names: [String], positional: Bool) -> String {
    var result = text.replacingOccurrences(of: "%", with: "%%")
    for (index, name) in names.enumerated() {
        result = result.replacingOccurrences(of: "{\(name)}", with: positional ? "%\(index + 1)$@" : "%@")
    }
    return result
}

// MARK: - Einträge für Katalog und Swift-Datei

struct CatalogEntry {
    let key: String
    let names: [String]                 // Argumente in fester Reihenfolge
    let texts: [String: String]         // Sprache → fertiger Text
    let source: [String: String]        // Sprache → Text wie im Prototyp
    let note: String?                   // Kommentar im Katalog, z. B. TODO(placeholder) bei den Versen
}

enum Accessor {
    case text(key: String, names: [String], german: String)
    case list(key: String, count: Int, german: [String])
}

var entries: [CatalogEntry] = []
var accessors: [Accessor] = []
var missing: [String] = []
var notable: [String] = []

/// Texte der Anleitung, die niemand fachlich geprüft hat (Spec § 6.14): Sie bekommen im Katalog den
/// Kommentar `TODO(review)`, damit Übersetzer und Prüfer sie finden. Die Schritte des Durchlaufs „Gebet
/// Schritt für Schritt“ kamen mit v0.8 dazu (Spec § 9.6) – entschieden mit dem Plan für Phase 13.
let walkReviewKeys: Set<String> = [
    "wkIntroBody", "wkQiyam12", "wkSujudD", "wkJalsa", "wkJalsaD", "wkSujud2", "wkSujud2D",
    "wkTashFirst", "wkTashFirstD", "wkTashLast", "wkTashLastD", "wkDoneBody",
]
let guideReviewKeys: Set<String> = [
    "b_clean", "b_cleanD", "b_niyya", "b_niyyaD", "b_qibla", "b_qiblaD", "b_wudu", "b_wuduD",
    "s_takbir", "s_takbirD", "s_qiyam", "s_qiyamD", "s_ruku", "s_rukuD", "s_itidal", "s_itidalD",
    "s_sujud", "s_sujudD", "s_tash", "s_tashD", "s_salam", "s_salamD",
    "sunna_fajr", "sunna_dhuhr", "sunna_asr", "sunna_maghrib", "sunna_isha",
    "onlyFatiha", "repeatNote", "tashSit", "tashEnd",
]

/// Kommentar für einen ungeprüften Text der Anleitung; `nil` für alle übrigen.
func reviewNote(for key: String) -> String? {
    if walkReviewKeys.contains(key) {
        return "TODO(review): Entwurf für „Gebet Schritt für Schritt“ (Spec § 9.6) – fachlich ungeprüft wie die "
            + "übrige Anleitung; vor dem App Store von einem Imam oder Gelehrten prüfen lassen (Spec § 6.14)."
    }
    if guideReviewKeys.contains(key) {
        return "TODO(review): Text der Anleitung – fachlich ungeprüft; vor dem App Store von einem Imam oder "
            + "Gelehrten prüfen lassen (Spec § 6.14)."
    }
    return nil
}

func makeEntry(key: String, perLanguage: [String: String], note: String? = nil) -> CatalogEntry {
    var names: [String] = []
    var repeated = false
    for language in languages {
        guard let text = perLanguage[language] else {
            missing.append("\(language).\(key)")
            continue
        }
        let found = placeholders(in: text)
        if Set(found).count != found.count { repeated = true }
        for name in found where !names.contains(name) { names.append(name) }
        if text.contains("<") || text.contains("&") || text.contains("\n") || text.contains("%") {
            notable.append("\(language).\(key): \(text)")
        }
    }
    let positional = names.count > 1 || repeated
    var texts: [String: String] = [:]
    for (language, text) in perLanguage {
        texts[language] = names.isEmpty ? text : formatString(text, names: names, positional: positional)
    }
    return CatalogEntry(key: key, names: names, texts: texts, source: perLanguage, note: note)
}

for key in walkReviewKeys.union(guideReviewKeys).sorted() where table[key] == nil {
    fail("Text der Anleitung `\(key)` (TODO(review)) fehlt in `T`")
}

for key in order {
    let values = table[key]!
    var textValues: [String: String] = [:]
    var listValues: [String: [String]] = [:]
    for (language, value) in values {
        switch value {
        case .text(let text): textValues[language] = text
        case .list(let list): listValues[language] = list
        }
    }
    if listValues.isEmpty {
        let entry = makeEntry(key: key, perLanguage: textValues, note: reviewNote(for: key))
        entries.append(entry)
        accessors.append(.text(key: key, names: entry.names, german: textValues["de"] ?? ""))
    } else {
        guard textValues.isEmpty else { fail("\(key): in einer Sprache Text, in einer anderen Liste") }
        let counts = Set(listValues.values.map(\.count))
        guard counts.count == 1, let count = counts.first else { fail("\(key): Listen sind verschieden lang") }
        for index in 0..<count {
            let entry = makeEntry(key: "\(key).\(index)", perLanguage: listValues.mapValues { $0[index] })
            guard entry.names.isEmpty else { fail("\(key).\(index): Platzhalter in Listen werden nicht unterstützt") }
            entries.append(entry)
        }
        for language in languages where listValues[language] == nil { missing.append("\(language).\(key)") }
        accessors.append(.list(key: key, count: count, german: listValues["de"] ?? []))
    }
}

// MARK: - Verse (`SURAH`, `VERSES`)

/// Ein Vers aus `VERSES`: Stelle, arabischer Text und die Platzhalter-Übersetzungen je Sprache.
struct PrototypeVerse {
    let surah: Int
    let ayah: Int
    let arabic: String
    let translations: [String: String]
}

let verseScript = """
(function () {
  var SURAH = \(objectLiteral(named: "SURAH", in: html));
  var VERSES = \(objectLiteral(named: "VERSES", in: html, opening: "["));
  return JSON.stringify({
    surahs: Object.keys(SURAH).map(function (n) { return [n, SURAH[n]]; }),
    verses: VERSES
  });
})()
"""
guard let verseJSON = context.evaluateScript(verseScript)?.toString(), scriptError == nil,
      let verseData = try? JSONSerialization.jsonObject(with: Data(verseJSON.utf8)) as? [String: Any],
      let surahPairs = verseData["surahs"] as? [[Any]],
      let verseObjects = verseData["verses"] as? [[String: Any]]
else {
    fail("`SURAH` und `VERSES` ließen sich nicht auswerten: \(scriptError ?? "unbekannter Fehler")")
}

var surahNames: [(number: Int, names: [String: String])] = []
for pair in surahPairs {
    guard pair.count == 2, let key = pair[0] as? String, let number = Int(key), let names = pair[1] as? [String: String] else {
        fail("Unerwartete Struktur in `SURAH`")
    }
    surahNames.append((number, names))
}
surahNames.sort { $0.number < $1.number }

var verses: [PrototypeVerse] = []
for (index, object) in verseObjects.enumerated() {
    guard let surah = object["s"] as? Int,
          let ayahText = object["a"] as? String, let ayah = Int(ayahText),
          let arabic = object["ar"] as? String,
          let translations = object["tr"] as? [String: String]
    else {
        fail("`VERSES[\(index)]`: erwartet werden s (Zahl), a (Zahl als Text), ar und tr")
    }
    guard surahNames.contains(where: { $0.number == surah }) else {
        fail("`VERSES[\(index)]`: Sure \(surah) fehlt in `SURAH`")
    }
    guard !verses.contains(where: { $0.surah == surah && $0.ayah == ayah }) else {
        fail("`VERSES[\(index)]`: \(surah):\(ayah) steht doppelt in der Liste")
    }
    verses.append(PrototypeVerse(surah: surah, ayah: ayah, arabic: arabic, translations: translations))
}
guard !verses.isEmpty else { fail("`VERSES` ist leer") }

for surah in surahNames {
    entries.append(makeEntry(
        key: "surah_\(surah.number)", perLanguage: surah.names,
        note: "Name der Sure \(surah.number) aus `SURAH` im Prototyp."
    ))
}
for verse in verses {
    entries.append(makeEntry(
        key: "verse_\(verse.surah)_\(verse.ayah)", perLanguage: verse.translations,
        note: "TODO(placeholder): Übersetzung von \(verse.surah):\(verse.ayah) aus `VERSES` im Prototyp – ein Platzhalter, "
            + "die lizenzierte Übersetzung fehlt noch (Spec § 6.12)."
    ))
}

// MARK: - String Catalog

var strings: [String: Any] = [:]
for entry in entries {
    var localizations: [String: Any] = [:]
    for (language, text) in entry.texts {
        localizations[language] = ["stringUnit": ["state": "translated", "value": text]]
    }
    var item: [String: Any] = ["extractionState": "manual", "localizations": localizations]
    var notes: [String] = []
    if !entry.names.isEmpty {
        let list = entry.names.enumerated().map { "\($0.offset + 1) = \($0.element)" }.joined(separator: ", ")
        notes.append("Argumente: \(list)")
    }
    if let note = entry.note {
        notes.append(note)
    }
    if !notes.isEmpty {
        item["comment"] = notes.joined(separator: " ")
    }
    strings[entry.key] = item
}
let catalog: [String: Any] = ["sourceLanguage": "de", "strings": strings, "version": "1.0"]
guard let catalogData = try? JSONSerialization.data(
    withJSONObject: catalog, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
    var catalogText = String(data: catalogData, encoding: .utf8)
else {
    fail("Katalog ließ sich nicht serialisieren")
}
catalogText += "\n"

// MARK: - InfoPlist.xcstrings

var infoPlistStrings: [String: Any] = [:]
var projectProblems: [String] = []
let projectText = (try? String(contentsOf: projectURL, encoding: .utf8)) ?? ""
for (plistKey, textKey) in infoPlistTexts {
    guard let entry = entries.first(where: { entry in entry.key == textKey }) else {
        fail("`\(textKey)` fehlt in `T`; die Info.plist braucht ihn für \(plistKey)")
    }
    guard entry.names.isEmpty else { fail("\(textKey): Texte der Info.plist dürfen keine Platzhalter haben") }
    var localizations: [String: Any] = [:]
    for language in languages {
        guard let text = entry.source[language] else { fail("\(language).\(textKey) fehlt für die Info.plist") }
        localizations[language] = ["stringUnit": ["state": "translated", "value": text]]
    }
    infoPlistStrings[plistKey] = [
        "comment": "Aus `T.\(textKey)` im Prototyp.",
        "extractionState": "manual",
        "localizations": localizations,
    ]
    // Der Grundwert in project.yml: `<Schlüssel>: "<deutscher Text>"`.
    let german = entry.source["de"] ?? ""
    if !projectText.contains("\(plistKey): \(literalString(german))") {
        projectProblems.append("project.yml: \(plistKey) muss lauten: \(literalString(german))")
    }
}
let infoPlistCatalog: [String: Any] = ["sourceLanguage": "de", "strings": infoPlistStrings, "version": "1.0"]
guard let infoPlistData = try? JSONSerialization.data(
    withJSONObject: infoPlistCatalog, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
    var infoPlistText = String(data: infoPlistData, encoding: .utf8)
else {
    fail("InfoPlist-Katalog ließ sich nicht serialisieren")
}
infoPlistText += "\n"

// MARK: - L10n.swift

let reservedWords: Set<String> = [
    "as", "break", "case", "catch", "class", "continue", "default", "defer", "do", "else", "enum", "extension",
    "fallthrough", "false", "for", "func", "guard", "if", "import", "in", "init", "inout", "internal", "is", "let",
    "nil", "operator", "private", "protocol", "public", "repeat", "rethrows", "return", "self", "Self", "static",
    "struct", "subscript", "super", "switch", "throw", "throws", "true", "try", "typealias", "var", "where", "while",
    "Any", "Type",
]

func identifier(_ name: String) -> String {
    var result = String(name.unicodeScalars.map { scalar -> Character in
        let isLetter = ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar)
        let isDigit = ("0"..."9").contains(scalar)
        return isLetter || isDigit || scalar == "_" ? Character(scalar) : "_"
    })
    if let first = result.unicodeScalars.first, ("0"..."9").contains(first) { result = "_" + result }
    return reservedWords.contains(result) ? "`\(result)`" : result
}

func comment(_ text: String) -> String {
    text.replacingOccurrences(of: "\n", with: " ")
}

var swift = """
// Erzeugt von scripts/import-strings aus design/prayer-times-prototype.html (Objekt `T`).
// Nicht von Hand ändern – Texte im Prototyp ändern und das Skript neu ausführen.
//
// Schlüssel und Argumentnamen sind die des Prototyps: `t('wIn', {t: …})` ↔ `L10n.wIn(t: …)`.

// swiftlint:disable all
import Foundation

public enum L10n {

"""

var seenIdentifiers: Set<String> = []
for accessor in accessors {
    switch accessor {
    case .text(let key, let names, let german):
        let name = identifier(key)
        guard seenIdentifiers.insert(name).inserted else { fail("Doppelter Swift-Name für Schlüssel \(key)") }
        swift += "    /// „\(comment(german))“\n"
        if names.isEmpty {
            swift += "    public static var \(name): String { text(\(literalString(key))) }\n"
        } else {
            let parameters = names.map { "\(identifier($0)): String" }.joined(separator: ", ")
            let values = names.map(identifier).joined(separator: ", ")
            swift += "    public static func \(name)(\(parameters)) -> String { text(\(literalString(key)), \(values)) }\n"
        }
    case .list(let key, let count, let german):
        let name = identifier(key)
        guard seenIdentifiers.insert(name).inserted else { fail("Doppelter Swift-Name für Schlüssel \(key)") }
        swift += "    /// \(comment(german.joined(separator: " · ")))\n"
        swift += "    public static var \(name): [String] { (0..<\(count)).map { text(\"\(key).\\($0)\") } }\n"
    }
}

// Verse: Die Schlüssel folgen aus der Stelle, deshalb je ein Zugriff für alle Suren und alle Verse.
let firstVerse = verses[0]
let firstSurahName = surahNames.first { $0.number == firstVerse.surah }?.names["de"] ?? ""
swift += """

    /// Name einer Sure aus `SURAH` im Prototyp, z. B. „\(comment(firstSurahName))“ für \(firstVerse.surah).
    public static func surahName(_ surah: Int) -> String { text("surah_\\(surah)") }
    /// Übersetzung eines Verses aus `VERSES` im Prototyp, z. B. „\(comment(firstVerse.translations["de"] ?? ""))“ für \(firstVerse.surah):\(firstVerse.ayah).
    /// TODO(placeholder): ein Platzhalter – die lizenzierte Übersetzung fehlt noch (Spec § 6.12).
    public static func verseTranslation(surah: Int, ayah: Int) -> String { text("verse_\\(surah)_\\(ayah)") }

"""

swift += "\n    /// Alle Schlüssel des String Catalogs, in der Reihenfolge des Prototyps.\n"
swift += "    public static let allKeys: [String] = [\n"
for entry in entries {
    swift += "        \(literalString(entry.key)),\n"
}
swift += "    ]\n}\n"

// MARK: - VerseList.swift

var verseList = """
// Erzeugt von scripts/import-strings aus design/prayer-times-prototype.html (`VERSES`).
// Nicht von Hand ändern – Verse im Prototyp ändern und das Skript neu ausführen.

extension Verse {

    /// Die Verse der Seite „Verse“ in der Reihenfolge des Prototyps. Übersetzungen und Namen der Suren
    /// stehen im String Catalog (`verse_<Sure>_<Vers>`, `surah_<Sure>`).
    ///
    /// TODO(placeholder): Welche Verse die App zeigt und woher der arabische Text kommt (z. B. Tanzil,
    /// Uthmani-Schrift, mit Quellenangabe), ist noch offen – Spec § 6.12.
    public static let all: [Verse] = [

"""
for verse in verses {
    verseList += "        Verse(surah: \(verse.surah), ayah: \(verse.ayah), arabic: \(literalString(verse.arabic))),\n"
}
verseList += "    ]\n}\n"

// MARK: - Schreiben oder prüfen

func current(_ url: URL) -> String? {
    try? String(contentsOf: url, encoding: .utf8)
}

if checkOnly {
    var stale: [String] = []
    if current(catalogURL) != catalogText { stale.append(catalogURL.lastPathComponent) }
    if current(swiftURL) != swift { stale.append(swiftURL.lastPathComponent) }
    if current(infoPlistURL) != infoPlistText { stale.append(infoPlistURL.lastPathComponent) }
    if current(verseListURL) != verseList { stale.append(verseListURL.lastPathComponent) }
    guard stale.isEmpty else {
        fail("Nicht aktuell: \(stale.joined(separator: ", ")). Bitte `scripts/import-strings` ausführen.")
    }
} else {
    do {
        for url in [catalogURL, swiftURL, infoPlistURL, verseListURL] {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        try catalogText.write(to: catalogURL, atomically: true, encoding: .utf8)
        try swift.write(to: swiftURL, atomically: true, encoding: .utf8)
        try infoPlistText.write(to: infoPlistURL, atomically: true, encoding: .utf8)
        try verseList.write(to: verseListURL, atomically: true, encoding: .utf8)
    } catch {
        fail("Schreiben fehlgeschlagen: \(error.localizedDescription)")
    }
}
// Der Grundwert in project.yml wird in beiden Fällen geprüft, aber nie umgeschrieben.
guard projectProblems.isEmpty else {
    fail(projectProblems.joined(separator: "\n"))
}

// MARK: - Bericht

let perLanguage = languages.map { language in
    "\(language.uppercased()) \(entries.filter { $0.texts[language] != nil }.count)"
}.joined(separator: ", ")
let withArguments = entries.filter { !$0.names.isEmpty }
let allNames = Set(withArguments.flatMap(\.names)).sorted().joined(separator: ", ")

print(checkOnly ? "String Catalog ist aktuell." : "String Catalog geschrieben.")
print("  Schlüssel im Prototyp: \(order.count)  →  Einträge im Katalog: \(entries.count)  (\(perLanguage))")
print("  Texte mit Argumenten: \(withArguments.count)  (Namen: \(allNames))")
print("  Info.plist: \(infoPlistTexts.map { pair in "\(pair.plistKey) ← \(pair.textKey)" }.joined(separator: ", "))")
print("  Verse: \(verses.count) mit \(surahNames.count) Suren  →  \(verseListURL.lastPathComponent)")
if !skippedLanguages.isEmpty {
    print("  Übergangen bis Phase 15: \(skippedLanguages.joined(separator: ", "))")
}
if !missing.isEmpty {
    print("  FEHLEND (\(missing.count)): \(missing.joined(separator: ", "))")
}
if !notable.isEmpty {
    print("  Auffällig – enthält <, &, % oder Zeilenumbruch (\(notable.count)):")
    for line in notable { print("    \(line)") }
}
