#if DEBUG

import Foundation
import PrayerCore
import Testing
@testable import DesignSystem

/// Die Gebetskarten müssen zeigen, was `prayerRow()` und `kerahatSub()` im Prototyp zeigen – geprüft an
/// den Zuständen der Referenzbilder `iphone/10` bis `22`, mit den Mock-Zeiten vom 10.11.2026.
@Suite("Gebetskarte")
struct PrayerRowModelTests {

    private func rows(
        _ city: String = "berlin", _ time: String, showKerahat: Bool = true, highLatitude: Bool = false
    ) -> [PrayerRowModel] {
        PrayerRowModel.rows(
            for: CatalogFixtures.phase(city: city, time: time), showKerahat: showKerahat, isHighLatitude: highLatitude
        )
    }

    /// Die Kerahat-Zeilen als lesbarer Text, ohne die Wortverbinder: `nil`, „07:14–07:59“ oder „bis 07:59“.
    private func captions(_ rows: [PrayerRowModel]) -> [String?] {
        rows.map { row in
            row.kerahat.map { $0.isActive ? "bis \($0.end)" : "\($0.start)–\($0.end)" }
        }
    }

    @Test("sechs Karten in der Reihenfolge des Tages, mit den Uhrzeiten am Ort")
    func order() {
        let rows = rows("berlin", "14:25")
        #expect(rows.map(\.prayer) == [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha])
        #expect(rows.map(\.time.description) == ["05:16", "07:14", "11:52", "14:00", "16:27", "18:17"])
        #expect(rows.map(\.id) == Prayer.allCases)
    }

    @Test("14:25 (iphone/10): Asr läuft, davor ist alles vorbei, Maghrib und Ischa kommen noch")
    func asrActive() {
        let rows = rows("berlin", "14:25")
        #expect(rows.map(\.status) == [.passed, .passed, .passed, .current, .upcoming, .upcoming])
        #expect(captions(rows) == [nil, "07:14–07:59", "11:42–11:52", "15:42–16:27", nil, nil])
    }

    @Test("vor Fadschr (iphone/12): nichts ist hervorgehoben, nichts vorbei")
    func beforeFajr() {
        #expect(rows("berlin", "05:14").allSatisfy { $0.status == .upcoming })
    }

    @Test("08:04 (iphone/13): Fadschr und Sonnenaufgang sind vorbei, keine Karte ist hervorgehoben")
    func afterSunrise() {
        let rows = rows("berlin", "08:04")
        #expect(rows.map(\.status) == [.passed, .passed, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(captions(rows) == [nil, "07:14–07:59", "11:42–11:52", "15:42–16:27", nil, nil])
    }

    @Test("07:30 (iphone/14): Unter Sonnenaufgang steht „Kerahat bis 07:59“")
    func kerahatAfterSunrise() {
        let rows = rows("berlin", "07:30")
        #expect(rows.map(\.status) == [.passed, .passed, .upcoming, .upcoming, .upcoming, .upcoming])
        #expect(captions(rows) == [nil, "bis 07:59", "11:42–11:52", "15:42–16:27", nil, nil])
    }

    @Test("16:05 (iphone/15): Unter Asr steht „Kerahat bis 16:27“, Asr bleibt hervorgehoben")
    func kerahatBeforeMaghrib() {
        let rows = rows("berlin", "16:05")
        #expect(rows.map(\.status) == [.passed, .passed, .passed, .current, .upcoming, .upcoming])
        #expect(captions(rows) == [nil, "07:14–07:59", "11:42–11:52", "bis 16:27", nil, nil])
    }

    @Test("nach Ischa (iphone/16): Ischa ist hervorgehoben, alles andere vorbei")
    func afterIsha() {
        #expect(rows("berlin", "23:30").map(\.status) == [.passed, .passed, .passed, .passed, .passed, .current])
    }

    @Test("Jakarta 17:57 (iphone/22): Maghrib läuft, das Fenster vor Maghrib steht bei Asr")
    func jakarta() {
        let rows = rows("jakarta", "17:57")
        #expect(rows.map(\.status) == [.passed, .passed, .passed, .passed, .current, .upcoming])
        #expect(rows.map(\.time.description) == ["04:06", "05:24", "11:39", "14:57", "17:49", "19:01"])
        #expect(captions(rows) == [nil, "05:24–06:09", "11:29–11:39", "17:04–17:49", nil, nil])
    }

    @Test("an den Rändern eines Fensters: Der Beginn gehört dazu, das Ende nicht", arguments: [
        ("15:41:59", false),
        ("15:42:00", true),
        ("16:26:59", true),
        ("16:27:00", false),
    ])
    func kerahatEdges(time: String, isActive: Bool) {
        #expect(rows("berlin", time)[3].kerahat?.isActive == isActive)
    }

    @Test("ohne den Schalter „Kerahat-Zeiten zeigen“ hat keine Karte eine Kerahat-Zeile")
    func kerahatOff() {
        #expect(rows("berlin", "16:05", showKerahat: false).allSatisfy { $0.kerahat == nil })
    }

    @Test("die Spanne bricht nicht um: Wortverbinder stehen um den Strich")
    func rangeDoesNotBreak() throws {
        let caption = try #require(rows("berlin", "14:25")[3].kerahat)
        #expect(caption.range == "15:42\u{2060}–\u{2060}16:27")
        #expect(caption.range.replacingOccurrences(of: "\u{2060}", with: "") == "15:42–16:27")
    }

    @Test("der Text der Zeile kommt aus dem String Catalog und nennt die Zeiten")
    func captionText() throws {
        let waiting = try #require(rows("berlin", "14:25")[3].kerahat)
        #expect(waiting.text == L10n.kerahatRow(r: waiting.range))
        #expect(waiting.text.contains("15:42"))
        #expect(waiting.text.contains("16:27"))

        let active = try #require(rows("berlin", "16:05")[3].kerahat)
        #expect(active.text == L10n.kerahatNow(b: "16:27"))
        #expect(active.text.contains("16:27"))
        #expect(!active.text.contains("15:42"))
    }

    @Test("hohe Breiten: Nur Fadschr und Ischa tragen die Info-Marke")
    func highLatitudeMarks() {
        #expect(rows("berlin", "14:25", highLatitude: true).map(\.showsHighLatitudeMark)
            == [true, false, false, false, false, true])
        #expect(rows("berlin", "14:25").allSatisfy { !$0.showsHighLatitudeMark })
    }
}

#endif
