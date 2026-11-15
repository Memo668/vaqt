import Foundation
import PrayerCore
import Synchronization
import SwiftUI

/// Ziffern wie das System (Spec § 9.10, entschieden mit dem Plan für Phase 15): Persisch schreibt immer ۰–۹,
/// Arabisch ٠–٩ dort, wo die Region es tut (Saudi-Arabien, Ägypten …), alle übrigen Sprachen 0–9. Uhrzeiten,
/// Countdown, Zahlen, Datum und die Ziffern in den Texten folgen derselben Regel; was das System selbst schreibt
/// (`Text(timerInterval:)`, `formatted`, `DateFormatter`), tut es mit `L10n.locale` ohnehin.
enum LocalizedDigits {

    /// Ersetzt 0–9 in `text` durch die Ziffern der Region von `locale`; bei 0–9 bleibt der Text, wie er ist.
    static func apply(to text: String, locale: Locale) -> String {
        guard let digits = digits(for: locale),
              text.unicodeScalars.contains(where: { ("0"..."9").contains($0) })
        else { return text }
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if ("0"..."9").contains(scalar) {
                scalars.append(digits[Int(scalar.value) - 48])
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    /// Die zehn Ziffern der Region von `locale`, `nil` für 0–9.
    static func digits(for locale: Locale) -> [Unicode.Scalar]? {
        let system = locale.numberingSystem.identifier
        guard system != "latn" else { return nil }
        return cache.withLock { cache in
            if let known = cache[system] { return known }
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.usesGroupingSeparator = false
            let digits = (0...9).map { formatter.string(from: $0 as NSNumber)?.unicodeScalars.first }
            let result = digits.allSatisfy({ $0 != nil }) ? digits.compactMap { $0 } : nil
            let usable = result.flatMap { $0.first == "0" ? nil : $0 }
            cache[system] = usable
            return usable
        }
    }

    private static let cache = Mutex<[String: [Unicode.Scalar]?]>([:])
}

extension L10n {

    /// Eine Uhrzeit, wie sie in der App steht: „14:25“, auf Persisch „۱۴:۲۵“ (immer 24 Stunden wie `fmt()`).
    public static func time(_ time: ClockTime) -> String {
        digits(time.description)
    }

    /// Eine Spanne „15:42–16:27“; Wortverbinder um den Strich halten sie in einer Zeile. Von rechts nach links
    /// beginnt sie mit einer Markierung der Richtung (U+200F): Ohne sie stünde die Spanne – etwa im Isolat eines
    /// eingesetzten Arguments – von links nach rechts, mit dem Beginn links. So steht der Beginn rechts wie im
    /// Prototyp, wo der Browser Ziffern und Strich im Absatz von rechts nach links ordnet.
    public static func timeRange(_ start: ClockTime, _ end: ClockTime) -> String {
        (layoutDirection == .rightToLeft ? "\u{200F}" : "") + time(start) + "\u{2060}–\u{2060}" + time(end)
    }

    /// Eine ganze Zahl ohne Tausendertrennung in den Ziffern der Sprache, z. B. die Nummer einer Rakʿa.
    public static func number(_ value: Int) -> String {
        digits(String(value))
    }

    /// Ersetzt 0–9 durch die Ziffern der Sprache der Texte – für Zahlen, die die App selbst zusammensetzt.
    public static func digits(_ text: String) -> String {
        LocalizedDigits.apply(to: text, locale: locale)
    }

    /// Die Leserichtung der Sprache der Texte – auch dann, wenn sie nicht die des Geräts ist, etwa Arabisch in
    /// der App auf einem deutschen Gerät (`RTL_LANGS`).
    public static var layoutDirection: LayoutDirection {
        currentLanguage.isRightToLeft ? .rightToLeft : .leftToRight
    }

    /// Der Kalender für Datumsangaben neben den Texten: der der Region, also persisch auf Persisch (Spec § 9.10).
    /// Ist er selbst islamisch (z. B. ar_SA), bleibt es beim gregorianischen, damit das Hijri-Datum nicht doppelt
    /// dasteht (entschieden mit dem Plan für Phase 15).
    public static func displayCalendar(for locale: Locale) -> Calendar {
        var calendar = locale.calendar
        if isIslamic(calendar.identifier) {
            calendar = Calendar(identifier: .gregorian)
        }
        calendar.locale = locale
        return calendar
    }

    static func isIslamic(_ identifier: Calendar.Identifier) -> Bool {
        switch identifier {
        case .islamic, .islamicCivil, .islamicTabular, .islamicUmmAlQura: true
        default: false
        }
    }
}
