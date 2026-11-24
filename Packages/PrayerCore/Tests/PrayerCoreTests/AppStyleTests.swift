#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Der Stil der App (Nachtrag zu Phase 18, Spec § 11.7): Grundfarbe und Aussehen der Live-Aktivität, im Inhalt der
/// Aktivität mitgetragen.
@Suite("Stil der App")
struct AppStyleTests {

    @Test("Standard: Petrol, farbig, nicht invertiert")
    func standard() {
        #expect(AppStyle.standard == AppStyle(accent: .teal, liveActivity: .full, isInverted: false))
        #expect(AppStyle().isStandard)
        #expect(!AppStyle(accent: .ocean).isStandard)
        #expect(!AppStyle(liveActivity: .mono).isStandard)
        #expect(!AppStyle(isInverted: true).isStandard)
    }

    @Test("die Kennungen sind die des Prototyps (ACCENTS, LA_STYLES)")
    func identifiers() {
        #expect(AccentColorID.allCases.map(\.rawValue) == [
            "teal", "green", "blue", "violet", "berry", "graphite",
            "cyan", "grass", "indigo", "orchid", "orange", "gold",
            "ocean", "forest", "navy", "plum", "wine", "mono",
            "mint", "sage", "ice", "lavender", "mauve", "sand",
        ])
        #expect(LiveActivityStyle.allCases.map(\.rawValue) == ["full", "arc", "mono"])
        #expect(AccentColorID.standardRow.allSatisfy { $0.isInStandardRow })
        #expect(!AccentColorID.orange.isInStandardRow)
    }

    @Test("unbekannte oder fehlende Werte gelten als Standard, statt alles zu verwerfen")
    func decoding() throws {
        let decode = { (json: String) in try JSONDecoder().decode(AppStyle.self, from: Data(json.utf8)) }
        #expect(try decode(#"{"accent":"ocean","liveActivity":"arc","isInverted":true}"#)
            == AppStyle(accent: .ocean, liveActivity: .arc, isInverted: true))
        #expect(try decode(#"{"accent":"neon","liveActivity":"glow"}"#) == .standard)
        #expect(try decode("{}") == .standard)
        let style = AppStyle(accent: .sand, liveActivity: .mono, isInverted: true)
        #expect(try JSONDecoder().decode(AppStyle.self, from: JSONEncoder().encode(style)) == style)
    }

    @Test("die Live-Aktivität trägt den Stil; ältere Inhalte ohne Stil lesen sich ohne")
    func content() throws {
        let style = AppStyle(accent: .gold, liveActivity: .arc)
        let plans = LiveActivityPlanner(source: FixtureTimesSource()).plan(
            at: FixtureTimes.referenceDay.at("14:25", in: .berlin), place: fixturePlace("berlin"),
            settings: CalculationSettings(),
            options: LiveActivityPlanner.Options(
                leadMinutes: 30, cityName: "Berlin", isCurrentLocation: true, showKerahat: true, style: style
            )
        )
        let content = try #require(plans.first?.content)
        #expect(content.style == style)
        #expect(content.markedBegun.style == style)
        let decoded = try JSONDecoder().decode(LiveActivityContent.self, from: JSONEncoder().encode(content))
        #expect(decoded == content)

        var object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(content)) as? [String: Any])
        object.removeValue(forKey: "style")
        let old = try JSONDecoder().decode(LiveActivityContent.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(old.style == nil)
    }

    @Test("ein anderer Stil ändert den Inhalt – geplante Aktivitäten werden ersetzt, laufende aufgefrischt")
    func lifecycle() throws {
        let now = FixtureTimes.referenceDay.at("14:25", in: .berlin)
        func plan(_ style: AppStyle) -> [LiveActivityPlan] {
            LiveActivityPlanner(source: FixtureTimesSource()).plan(
                at: now, place: fixturePlace("berlin"), settings: CalculationSettings(),
                options: LiveActivityPlanner.Options(
                    leadMinutes: 30, cityName: "Berlin", isCurrentLocation: true, showKerahat: true, style: style
                )
            )
        }
        let before = plan(.standard), after = plan(AppStyle(accent: .ocean))
        let existing = before.map {
            LiveActivityLifecycle.Existing(activityID: "a-" + $0.id, planID: $0.id, start: $0.start, isPending: true, content: $0.content)
        }
        let actions = LiveActivityLifecycle.actions(existing: existing, plan: after, now: now)
        #expect(actions.filter { if case .end = $0 { true } else { false } }.count == before.count)
        #expect(actions.filter { if case .request = $0 { true } else { false } }.count == after.count)
        let running = try #require(before.first)
        let update = LiveActivityLifecycle.actions(
            existing: [LiveActivityLifecycle.Existing(activityID: "r", planID: running.id, start: running.start, isPending: false, content: running.content)],
            plan: after, now: now
        )
        #expect(update.contains { if case .update(activityID: "r", _) = $0 { true } else { false } })
    }
}

#endif
