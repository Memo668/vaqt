// scripts/import-strings.swift
//
// Liest das Objekt `T` (alle App-Texte, DE/TR/EN/ES) aus
// design/prayer-times-prototype.html und erzeugt daraus
//
//   • Packages/DesignSystem/Sources/DesignSystem/Resources/Localizable.xcstrings
//   • Packages/DesignSystem/Sources/DesignSystem/Generated/L10n.swift
//   • App/InfoPlist.xcstrings – die Texte der Info.plist, die aus `T` kommen (siehe `infoPlistTexts`)
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
let projectURL = rootURL.appendingPathComponent("project.yml")

/// Texte der Info.plist, die aus `T` kommen: Schlüssel der Info.plist → Schlüssel in `T`.
/// `NSLocationWhenInUseUsageDescription` ist die Begründung im System-Dialog der Standortabfrage –
/// im Prototyp der Text des nachgebauten Dialogs (`alLocBody`, design/screenshots/iphone/04).
let infoPlistTexts: [(plistKey: String, textKey: String)] = [
    ("NSLocationWhenInUseUsageDescription", "alLocBody"),
]

// MARK: - `T` aus dem Prototyp schneiden

/// Liefert das Objektliteral hinter `const <name> = `, von `{` bis zur passenden `}`.
/// Zeichenketten und Kommentare werden übersprungen, damit Klammern im Text nicht zählen.
func objectLiteral(named name: String, in source: String) -> String {
    guard let declaration = source.range(of: "const \(name) = {") else {
        fail("`const \(name) = {` nicht im Prototyp gefunden")
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
            case "{":
                depth += 1
            case "}":
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

// MARK: - Auswerten (Reihenfolge der Schlüssel bleibt erhalten)

let context = JSContext()!
var scriptError: String?
context.exceptionHandler = { _, exception in scriptError = exception?.toString() }
let script = """
(function () {
  var T = \(literal);
  return JSON.stringify(Object.keys(T).map(function (lang) {
    return [lang, Object.keys(T[lang]).map(function (key) { return [key, T[lang][key]]; })];
  }));
})()
"""
guard let json = context.evaluateScript(script)?.toString(), scriptError == nil,
      let parsed = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[Any]]
else {
    fail("`T` ließ sich nicht auswerten: \(scriptError ?? "unbekannter Fehler")")
}

let foundLanguages = parsed.compactMap { $0.first as? String }
guard foundLanguages == languages else {
    fail("Erwartete Sprachen \(languages), gefunden \(foundLanguages)")
}

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
}

enum Accessor {
    case text(key: String, names: [String], german: String)
    case list(key: String, count: Int, german: [String])
}

var entries: [CatalogEntry] = []
var accessors: [Accessor] = []
var missing: [String] = []
var notable: [String] = []

func makeEntry(key: String, perLanguage: [String: String]) -> CatalogEntry {
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
    return CatalogEntry(key: key, names: names, texts: texts, source: perLanguage)
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
        let entry = makeEntry(key: key, perLanguage: textValues)
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

// MARK: - String Catalog

var strings: [String: Any] = [:]
for entry in entries {
    var localizations: [String: Any] = [:]
    for (language, text) in entry.texts {
        localizations[language] = ["stringUnit": ["state": "translated", "value": text]]
    }
    var item: [String: Any] = ["extractionState": "manual", "localizations": localizations]
    if !entry.names.isEmpty {
        let list = entry.names.enumerated().map { "\($0.offset + 1) = \($0.element)" }.joined(separator: ", ")
        item["comment"] = "Argumente: \(list)"
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

swift += "\n    /// Alle Schlüssel des String Catalogs, in der Reihenfolge des Prototyps.\n"
swift += "    public static let allKeys: [String] = [\n"
for entry in entries {
    swift += "        \(literalString(entry.key)),\n"
}
swift += "    ]\n}\n"

// MARK: - Schreiben oder prüfen

func current(_ url: URL) -> String? {
    try? String(contentsOf: url, encoding: .utf8)
}

if checkOnly {
    var stale: [String] = []
    if current(catalogURL) != catalogText { stale.append(catalogURL.lastPathComponent) }
    if current(swiftURL) != swift { stale.append(swiftURL.lastPathComponent) }
    if current(infoPlistURL) != infoPlistText { stale.append(infoPlistURL.lastPathComponent) }
    guard stale.isEmpty else {
        fail("Nicht aktuell: \(stale.joined(separator: ", ")). Bitte `scripts/import-strings` ausführen.")
    }
} else {
    do {
        for url in [catalogURL, swiftURL, infoPlistURL] {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        try catalogText.write(to: catalogURL, atomically: true, encoding: .utf8)
        try swift.write(to: swiftURL, atomically: true, encoding: .utf8)
        try infoPlistText.write(to: infoPlistURL, atomically: true, encoding: .utf8)
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
if !missing.isEmpty {
    print("  FEHLEND (\(missing.count)): \(missing.joined(separator: ", "))")
}
if !notable.isEmpty {
    print("  Auffällig – enthält <, &, % oder Zeilenumbruch (\(notable.count)):")
    for line in notable { print("    \(line)") }
}
