import CoreText
import Foundation
import SwiftUI

/// Die arabischen Schriften der App (Design Spec § 9.7): **Amiri Quran** für die Verse, **Amiri** für die
/// Formeln der Anleitung und des Durchlaufs.
///
/// Beide stammen aus der Release 1.003 von [aliftype/amiri](https://github.com/aliftype/amiri/releases/tag/1.003)
/// (`Amiri-1.003.zip`), unverändert; Prüfsummen in `docs/THIRD-PARTY.md`. Lizenz: SIL Open Font License 1.1,
/// Text in `Resources/Licenses/Amiri-OFL.txt` und auf der Seite Einstellungen › Lizenzen.
///
/// Die Schriften liegen im Bündel des Pakets und werden beim ersten Gebrauch für den Prozess
/// registriert – in der App, in den Tests und im Katalog gleich, ohne Eintrag in der Info.plist.
public enum ArabicFont: CaseIterable, Sendable {
    /// Amiri, Schnitt Regular – für die Formeln (`.formula .ar`, `.walk-formula .ar`).
    case amiri
    /// Amiri Quran – für die Verse (`.verse-ar`).
    case amiriQuran

    /// PostScript-Name, mit dem SwiftUI die Schrift findet.
    public var postScriptName: String {
        switch self {
        case .amiri: "Amiri-Regular"
        case .amiriQuran: "AmiriQuran-Regular"
        }
    }

    /// Datei im Bündel, ohne Endung `.ttf` – so heißt sie in der Release.
    var fileName: String {
        switch self {
        case .amiri: "Amiri-Regular"
        case .amiriQuran: "AmiriQuran"
        }
    }

    /// Höhe der Schrift (Ober- plus Unterlänge, `hhea`) als Vielfaches der Schriftgröße, wie der Browser
    /// sie für die Zeilenhöhe nimmt: Amiri 1,758, Amiri Quran 2,449 – die hohen Zeichen über den Buchstaben
    /// brauchen Platz. Aus den Dateien gelesen; ein Test prüft die Werte.
    public var naturalLineHeight: CGFloat {
        switch self {
        case .amiri: (1124 + 634) / 1000
        case .amiriQuran: (1815 + 634) / 1000
        }
    }

    /// Oberlänge (`hhea.ascender`) als Vielfaches der Schriftgröße.
    public var ascent: CGFloat {
        switch self {
        case .amiri: 1124 / 1000
        case .amiriQuran: 1815 / 1000
        }
    }

    /// Die Schrift in fester Größe. Mit Dynamic Type wächst sie, wenn der Aufrufer die Größe mit
    /// `@ScaledMetric` skaliert – wie `calc(27px*var(--ts))` im Prototyp.
    public func font(size: CGFloat) -> Font {
        ArabicFont.registerIfNeeded()
        return Font.custom(postScriptName, fixedSize: size)
    }

    /// Ob beide Schriften registriert sind – auch dann, wenn ein anderer Teil des Prozesses sie schon
    /// registriert hatte.
    public static var isRegistered: Bool {
        registration
    }

    /// Registriert beide Schriften für den Prozess, einmal.
    public static func registerIfNeeded() {
        _ = registration
    }

    private static let registration: Bool = {
        var success = true
        for typeface in ArabicFont.allCases {
            guard let url = Bundle.module.url(forResource: typeface.fileName, withExtension: "ttf") else {
                success = false
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Schon registriert (etwa aus einem zweiten Bündel derselben Datei) ist kein Fehler.
                let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
                if code != CTFontManagerError.alreadyRegistered.rawValue {
                    success = false
                }
            }
        }
        return success
    }()
}

extension View {

    /// Arabischer Text in Amiri oder Amiri Quran wie `font: 400 <size>/<lineHeight> "Amiri"` im Prototyp:
    /// jede Zeile ein Kasten der Höhe `lineHeight × size`, die Schrift darin wie im Browser – halb so viel
    /// Raum über der Oberlänge wie unter der Unterlänge (`half-leading`).
    ///
    /// Gerechnet wird mit der echten Höhe der Schrift (`naturalLineHeight`), nicht mit der von SF Pro:
    /// Amiri ist höher als ihre Schriftgröße, Amiri Quran fast das Zweieinhalbfache. `lineHeight(.exact)`
    /// (iOS 26) trifft zwar die Höhe der Zeile, setzt die Grundlinie aber anders als der Browser – bei Amiri
    /// Quran 31 pt fast 20 pt höher (gemessen in Phase 13). Deshalb wie bei den übrigen Texten Zeilenabstand
    /// und halber Rand oben und unten.
    ///
    /// Ist die Zeile niedriger als die Schrift (die Verse: 2,15 gegen 2,449), wird der Rand negativ: Eine
    /// Zeile steht genau wie im Prototyp; bricht der Vers um, haben seine Zeilen den Abstand der Schrift
    /// statt des engeren aus dem CSS, denn Zeilenabstand kann nicht negativ werden.
    ///
    /// - Parameter size: Schriftgröße in pt, schon mit Dynamic Type skaliert.
    public func arabicFont(_ typeface: ArabicFont, size: CGFloat, lineHeight: CGFloat) -> some View {
        let extra = size * (lineHeight - typeface.naturalLineHeight)
        return font(typeface.font(size: size))
            .lineSpacing(max(0, extra))
            .padding(.vertical, extra / 2)
            .typesettingLanguage(Locale.Language(identifier: "ar"))
    }
}
