import XCTest

/// Führt ein kleines Skript gegen die installierte App aus: starten, tippen, wischen, aufnehmen. Je Zeile ein
/// Befehl, `#` leitet einen Kommentar ein. Pfade sind Pfade auf dem Mac; `run` setzt `{ROOT}` und `{OUT}` ein.
///
///   launch <Startargumente …>
///   tap <x> <y>                 Punkt in pt
///   taplabel <Text>             erstes Element mit diesem VoiceOver-Text
///   taplabelif <Text>           wie taplabel, aber ohne Fehler, wenn es das Element nicht gibt
///   drag <x1> <y1> <x2> <y2>
///   scroll <x1> <y1> <x2> <y2>  wie drag, aber langsam und ohne Schwung
///   type <Text>
///   wait <Sekunden>
///   shot <Pfad.png>
///   pages <Pfad ohne Endung>    die ganze Seite: aufnehmen und weiterscrollen, bis sie am Ende steht
///                               (<Pfad>-1.png, -2.png …)
///   dump <Pfad.txt>             Baum der Bedienungshilfen
///   audit <Pfad.txt>            Prüfung der Bedienungshilfen (performAccessibilityAudit) als Liste
///   sbtap <n> / sbtapif <n>     Knopf n im Dialog des Systems (sbtapif: nur wenn einer kommt)
///   sbdump <Pfad.txt>           Baum des Dialogs des Systems
///   sbtree <Pfad.txt>           Baum von SpringBoard (Sperrbildschirm, Mitteilungen, Widgets)
///   sbdrag <x1> <y1> <x2> <y2>  ziehen auf SpringBoard
///   sbpoint <x> <y>             Punkt auf SpringBoard antippen
///   lock / home                 Seitentaste, Home
///   sbpress <x> <y> [s]         lange auf SpringBoard drücken (Insel aufklappen, Bearbeiten-Modus)
///   sbtaplabel <Text>           erstes Element auf SpringBoard mit diesem Text oder dieser Kennung antippen
///   sbtaplabelif <Text>         wie sbtaplabel, aber ohne Fehler, wenn es das Element nicht gibt
///   sbtype <Text>               auf SpringBoard tippen (Suchfeld der Widget-Galerie)
///   sbmove <x1> <y1> <x2> <y2>  im Bearbeiten-Modus ein Symbol oder Widget verschieben (lang halten, langsam ziehen)
///   sbdeletewidget <Kennung>    im Bearbeiten-Modus das erste sichtbare Widget dieser App entfernen (nur dieses)
///   sbremoveif <Text>           steht <Text> im Dialog „Remove …?“, „Remove“ antippen, sonst „Cancel“
///   sbtapcell <Text>            die letzte Zelle auf SpringBoard mit diesem Text antippen (Liste der Widget-Galerie)
///   open <Bundle-ID>            andere App nach vorn (z. B. com.apple.Preferences)
///   opentap <Bundle-ID> <Text>  dort das erste Element mit diesem Text antippen
///   openswitch <Bundle-ID> <Text>  dort den Schalter mit diesem Text umlegen
///   opendump <Bundle-ID> <Pfad>    Baum dieser App
final class HarnessTests: XCTestCase {

    @MainActor
    func testScript() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["HARNESS_SCRIPT"] else {
            throw XCTSkip("HARNESS_SCRIPT fehlt")
        }
        let app = XCUIApplication(bundleIdentifier: environment["HARNESS_BUNDLE_ID"] ?? "com.example.gebetszeiten")
        let screen = app.coordinate(withNormalizedOffset: .zero)
        for raw in try String(contentsOfFile: path, encoding: .utf8).split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            let rest = parts.count > 1 ? parts[1] : ""
            let numbers = rest.split(separator: " ").compactMap { Double($0) }
            switch parts[0] {
            case "launch":
                app.launchArguments = rest.split(separator: " ").map(String.init)
                app.launch()
            case "tap":
                screen.withOffset(CGVector(dx: numbers[0], dy: numbers[1])).tap()
            case "taplabel", "taplabelif":
                let element = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", rest)).firstMatch
                if element.waitForExistence(timeout: parts[0] == "taplabel" ? 5 : 2) {
                    element.tap()
                } else if parts[0] == "taplabel" {
                    XCTFail("kein Element mit Text \(rest)")
                }
            case "drag":
                let start = screen.withOffset(CGVector(dx: numbers[0], dy: numbers[1]))
                let end = screen.withOffset(CGVector(dx: numbers[2], dy: numbers[3]))
                start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)
            case "scroll":
                // Ziehen ohne Schwung (Phase 5): langsam, vor dem Loslassen halten. So steht der Inhalt
                // genau um die Strecke verschoben da; jede Geste verliert dabei rund 10 pt Anlauf.
                let start = screen.withOffset(CGVector(dx: numbers[0], dy: numbers[1]))
                let end = screen.withOffset(CGVector(dx: numbers[2], dy: numbers[3]))
                start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity(rawValue: 250), thenHoldForDuration: 0.8)
            case "type":
                app.typeText(rest)
            case "wait":
                Thread.sleep(forTimeInterval: numbers.first ?? 1)
            case "shot":
                try XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: rest))
            case "pages":
                try capturePages(of: app, to: rest)
            case "dump":
                try app.debugDescription.write(toFile: rest, atomically: true, encoding: .utf8)
            case "audit":
                try audit(app, to: rest)
            case "sbdump":
                // Dialoge des Systems (z. B. die Standortabfrage) gehören zu SpringBoard.
                try springboard.alerts.firstMatch.debugDescription.write(toFile: rest, atomically: true, encoding: .utf8)
            case "sbtap":
                let button = springboard.alerts.buttons.element(boundBy: Int(numbers.first ?? 0))
                XCTAssertTrue(button.waitForExistence(timeout: 5), "kein Dialog des Systems")
                button.tap()
            case "sbtapif":
                // Wie sbtap, aber ohne Fehler, wenn kein Dialog kommt (Phase 8: Erlaubnis schon erteilt).
                let button = springboard.alerts.buttons.element(boundBy: Int(numbers.first ?? 0))
                if button.waitForExistence(timeout: 5) { button.tap() }
            case "sbtree":
                // Phase 8: der ganze Baum von SpringBoard – Sperrbildschirm und Mitteilungen als Text.
                try springboard.debugDescription.write(toFile: rest, atomically: true, encoding: .utf8)
            case "sbdrag":
                let origin = springboard.coordinate(withNormalizedOffset: .zero)
                let start = origin.withOffset(CGVector(dx: numbers[0], dy: numbers[1]))
                let end = origin.withOffset(CGVector(dx: numbers[2], dy: numbers[3]))
                start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.2)
            case "sbpoint":
                // Phase 8: Punkt auf SpringBoard antippen, z. B. einen Stapel Mitteilungen aufklappen.
                springboard.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: numbers[0], dy: numbers[1])).tap()
            case "lock":
                // Phase 8: Seitentaste – sperrt das Gerät (privater Selektor, nur in diesem Hilfsprojekt).
                XCUIDevice.shared.perform(NSSelectorFromString("pressLockButton"))
            case "home":
                XCUIDevice.shared.press(.home)
            case "sbpress":
                // Phase 9: lange drücken, z. B. auf die Dynamic Island oder auf den Home-Bildschirm.
                springboard.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: numbers[0], dy: numbers[1]))
                    .press(forDuration: numbers.count > 2 ? numbers[2] : 1.0)
            case "sbtaplabel", "sbtaplabelif":
                // Phase 9: z. B. „Bearbeiten“, „Widget hinzufügen“ in der Widget-Galerie.
                let element = springboard.descendants(matching: .any)
                    .matching(NSPredicate(format: "label == %@ OR identifier == %@", rest, rest)).firstMatch
                if element.waitForExistence(timeout: parts[0] == "sbtaplabel" ? 5 : 2) {
                    element.tap()
                } else if parts[0] == "sbtaplabel" {
                    XCTFail("kein Element \(rest) auf SpringBoard")
                }
            case "sbmove":
                let origin = springboard.coordinate(withNormalizedOffset: .zero)
                let start = origin.withOffset(CGVector(dx: numbers[0], dy: numbers[1]))
                let end = origin.withOffset(CGVector(dx: numbers[2], dy: numbers[3]))
                start.press(forDuration: 1.6, thenDragTo: end, withVelocity: XCUIGestureVelocity(rawValue: 300), thenHoldForDuration: 1.5)
            case "sbdeletewidget":
                // Phase 9: Der Minus-Knopf sitzt 8 pt über und links vor dem Rahmen des Widgets. Bestätigt
                // wird nur, wenn der Dialog die App nennt.
                let widgets = springboard.icons.matching(NSPredicate(format: "identifier == %@ AND value BEGINSWITH 'Widget'", rest))
                let screenWidth = springboard.frame.width
                guard let widget = (0..<widgets.count).map({ widgets.element(boundBy: $0) })
                    .first(where: { $0.frame.minX >= 0 && $0.frame.minX < screenWidth }) else { break }
                springboard.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: widget.frame.minX + 5, dy: widget.frame.minY + 5)).tap()
                let alert = springboard.alerts.firstMatch
                if alert.waitForExistence(timeout: 3) {
                    if alert.label.contains(rest) { alert.buttons["Remove"].tap() } else { alert.buttons["Cancel"].tap() }
                }
            case "sbremoveif":
                // Phase 9: nur eigene Widgets entfernen – steht der Text nicht im Dialog, abbrechen.
                let alert = springboard.alerts.firstMatch
                guard alert.waitForExistence(timeout: 3) else { break }
                if alert.label.contains(rest) {
                    alert.buttons["Remove"].tap()
                } else {
                    alert.buttons["Cancel"].tap()
                }
            case "sbtapcell":
                // Phase 9: In der Widget-Galerie gibt es die Liste zweimal; die vordere ist die letzte.
                let cells = springboard.cells.matching(NSPredicate(format: "label BEGINSWITH %@", rest))
                XCTAssertTrue(cells.firstMatch.waitForExistence(timeout: 5), "keine Zelle \(rest) auf SpringBoard")
                cells.element(boundBy: cells.count - 1).tap()
            case "sbtype":
                springboard.typeText(rest)
            case "open":
                // Phase 8: eine andere App nach vorn, z. B. die Einstellungen (com.apple.Preferences).
                XCUIApplication(bundleIdentifier: rest).activate()
            case "opentap", "openswitch", "opendump":
                // opentap <Bundle-ID> <Text>: erstes Element mit diesem Text in dieser App antippen.
                // openswitch <Bundle-ID> <Text>: den Schalter mit diesem Text umlegen (rechts in der Zeile).
                // opendump <Bundle-ID> <Pfad>: Baum dieser App.
                let command = parts[0]
                let target = rest.split(separator: " ", maxSplits: 1).map(String.init)
                let other = XCUIApplication(bundleIdentifier: target[0])
                switch command {
                case "opendump":
                    try other.debugDescription.write(toFile: target[1], atomically: true, encoding: .utf8)
                case "openswitch":
                    let toggle = other.switches.matching(NSPredicate(format: "label == %@", target[1])).firstMatch
                    XCTAssertTrue(toggle.waitForExistence(timeout: 5), "kein Schalter \(target[1]) in \(target[0])")
                    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
                default:
                    let element = other.descendants(matching: .any).matching(NSPredicate(format: "label == %@", target[1])).firstMatch
                    XCTAssertTrue(element.waitForExistence(timeout: 5), "kein Element mit Text \(target[1]) in \(target[0])")
                    element.tap()
                }
            default:
                XCTFail("unbekannter Befehl: \(line)")
            }
        }
    }

    @MainActor
    private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    /// Phase 11: die ganze Seite in Bildschirmen. Nach jeder Aufnahme zieht die Geste den Inhalt um gut die
    /// Hälfte der Bildschirmhöhe nach oben, ohne Schwung; die Aufnahmen überlappen sich. Die Seite steht am
    /// Ende, wenn die Texte nach der Geste dort liegen, wo sie vorher lagen – höchstens 15 Aufnahmen.
    @MainActor
    private func capturePages(of app: XCUIApplication, to prefix: String) throws {
        let frame = app.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: frame.midX, dy: frame.minY + frame.height * 0.78))
        let end = origin.withOffset(CGVector(dx: frame.midX, dy: frame.minY + frame.height * 0.22))
        var previous = textPositions(in: app)
        for page in 1...15 {
            try XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(prefix)-\(page).png"))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: XCUIGestureVelocity(rawValue: 900), thenHoldForDuration: 0.4)
            Thread.sleep(forTimeInterval: 0.5)
            let positions = textPositions(in: app)
            if positions == previous { break }
            previous = positions
        }
    }

    /// Lage aller Texte ohne Ziffern im Baum der Bedienungshilfen: Rahmen und Text, ohne die Adresse des
    /// Elements, die bei jeder Abfrage eine andere ist; ohne Ziffern im Text, weil der Countdown läuft.
    @MainActor
    private func textPositions(in app: XCUIApplication) -> [Substring] {
        app.debugDescription.split(separator: "\n").compactMap { line in
            guard line.contains("StaticText"), let label = line.range(of: "label: '"),
                  !line[label.upperBound...].contains(where: \.isNumber),
                  let frame = line.range(of: "{{")
            else { return nil }
            return line[frame.lowerBound...]
        }
    }

    /// Phase 11: die Prüfung der Bedienungshilfen von Xcode – Kontrast, abgeschnittener Text, Dynamic Type,
    /// Tippziele, Beschreibung, Eigenschaften. Jeder Befund wird notiert, keiner lässt den Lauf scheitern.
    @MainActor
    private func audit(_ app: XCUIApplication, to path: String) throws {
        var lines: [String] = []
        try app.performAccessibilityAudit(for: .all) { issue in
            let element = issue.element.map { element in
                "\(element.elementType.rawValue) '\(element.label)' \(element.frame)"
            } ?? "–"
            lines.append("\(Self.name(of: issue.auditType)) | \(issue.compactDescription) | \(element) | \(issue.detailedDescription)")
            return true
        }
        let text = lines.isEmpty ? "keine Befunde\n" : lines.joined(separator: "\n") + "\n"
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private static func name(of type: XCUIAccessibilityAuditType) -> String {
        let names: [(XCUIAccessibilityAuditType, String)] = [
            (.contrast, "contrast"), (.elementDetection, "elementDetection"), (.hitRegion, "hitRegion"),
            (.sufficientElementDescription, "sufficientElementDescription"), (.dynamicType, "dynamicType"),
            (.textClipped, "textClipped"), (.trait, "trait"),
        ]
        let matched = names.filter { type.contains($0.0) }.map(\.1)
        return matched.isEmpty ? "type \(type.rawValue)" : matched.joined(separator: "+")
    }
}
