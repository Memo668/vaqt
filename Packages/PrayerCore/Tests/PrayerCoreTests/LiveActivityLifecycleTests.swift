#if DEBUG

import Foundation
import Testing
@testable import PrayerCore

/// Was mit den Live-Aktivitäten geschieht, die iOS schon kennt, wenn die App neu plant (Spec § 4: „old
/// activities are ended on the next launch / background refresh“). Mock-Zeiten für Berlin am 10.11.2026,
/// 30 Minuten Vorlauf.
@Suite("Live-Aktivität: Lebenslauf")
struct LiveActivityLifecycleTests {

    private let day = FixtureTimes.referenceDay
    private let planner = LiveActivityPlanner(source: FixtureTimesSource())

    private func at(_ time: String) -> Date {
        day.at(time, in: .berlin)
    }

    private func plan(at time: String, lead: Int = 30) -> [LiveActivityPlan] {
        planner.plan(
            at: at(time), place: fixturePlace("berlin"), settings: CalculationSettings(),
            options: LiveActivityPlanner.Options(leadMinutes: lead, cityName: "Berlin", isCurrentLocation: true, showKerahat: true)
        )
    }

    private func existing(_ plan: LiveActivityPlan, id: String, pending: Bool) -> LiveActivityLifecycle.Existing {
        LiveActivityLifecycle.Existing(
            activityID: id, planID: plan.id, start: plan.start, isPending: pending, content: plan.content
        )
    }

    private func requests(_ actions: [LiveActivityLifecycle.Action]) -> [String] {
        actions.compactMap { if case .request(let plan) = $0 { plan.id } else { nil } }
    }

    private func ends(_ actions: [LiveActivityLifecycle.Action]) -> [String] {
        actions.compactMap { if case .end(let id, _, _) = $0 { id } else { nil } }
    }

    @Test("nichts angemeldet: alles im Plan wird angemeldet")
    func requestsAll() {
        let plan = plan(at: "14:25")
        #expect(LiveActivityLifecycle.actions(existing: [], plan: plan, now: at("14:25")) == plan.map { .request($0) })
    }

    @Test("schon angemeldet und unverändert: nichts zu tun")
    func keepsPending() {
        let existing = plan(at: "14:25").enumerated().map { self.existing($1, id: "A\($0)", pending: true) }
        #expect(LiveActivityLifecycle.actions(existing: existing, plan: plan(at: "14:40"), now: at("14:40")).isEmpty)
    }

    @Test("von 30 auf 60 Minuten: die geplanten werden ersetzt")
    func leadChange() {
        let existing = plan(at: "14:25").enumerated().map { self.existing($1, id: "A\($0)", pending: true) }
        let actions = LiveActivityLifecycle.actions(existing: existing, plan: plan(at: "14:25", lead: 60), now: at("14:25"))
        #expect(ends(actions) == ["A0", "A1", "A2", "A3", "A4"])
        #expect(requests(actions) == plan(at: "14:25", lead: 60).map(\.id))
    }

    @Test("Aus: alles endet sofort, auch was schon läuft")
    func off() {
        let plan = plan(at: "16:00")
        let existing = [existing(plan[0], id: "M", pending: false)]
            + plan.dropFirst().enumerated().map { self.existing($1, id: "P\($0)", pending: true) }
        let actions = LiveActivityLifecycle.actions(existing: existing, plan: [], now: at("16:00"))
        #expect(actions == existing.map { .end(activityID: $0.activityID, content: nil, dismissAt: nil) })
    }

    @Test("Gebetsbeginn: die Aktivität endet und bleibt mit „Jetzt“ bis 15 Minuten danach stehen")
    func endsAtPrayer() throws {
        let running = try #require(plan(at: "16:00").first)
        let now = plan(at: "16:27")
        let target = try #require(now.first)
        let actions = LiveActivityLifecycle.actions(existing: [existing(running, id: "M", pending: false)], plan: now, now: at("16:27"))
        #expect(actions.first == .end(activityID: "M", content: target.content.markedBegun, dismissAt: at("16:42")))
        #expect(requests(actions).first == "live.2026-11-10.isha")
    }

    @Test("mehr als 15 Minuten nach Beginn endet sie sofort")
    func overdue() throws {
        let running = try #require(plan(at: "16:00").first)
        let actions = LiveActivityLifecycle.actions(existing: [existing(running, id: "M", pending: false)], plan: plan(at: "16:50"), now: at("16:50"))
        #expect(actions.first == .end(activityID: "M", content: nil, dismissAt: nil))
    }

    @Test("vor Beginn bekommt eine laufende Aktivität den Stand von jetzt – der Bogen rückt nach")
    func updatesRunning() throws {
        let started = try #require(plan(at: "15:57").first)
        let fresh = try #require(plan(at: "16:10").first)
        let actions = LiveActivityLifecycle.actions(existing: [existing(started, id: "M", pending: false)], plan: plan(at: "16:10"), now: at("16:10"))
        #expect(actions.first == .update(activityID: "M", content: fresh.content))
    }

    @Test("was schon begonnen hat und iOS nicht kennt, startet nicht mehr")
    func noLateStart() {
        let actions = LiveActivityLifecycle.actions(existing: [], plan: plan(at: "16:30"), now: at("16:30"))
        #expect(requests(actions).first == "live.2026-11-10.isha")
        #expect(!requests(actions).contains("live.2026-11-10.maghrib"))
    }

    @Test("zweimal dieselbe Aktivität: die zweite endet")
    func duplicates() throws {
        let maghrib = try #require(plan(at: "14:25").first)
        let existing = [existing(maghrib, id: "A", pending: true), existing(maghrib, id: "B", pending: true)]
        let actions = LiveActivityLifecycle.actions(existing: existing, plan: [maghrib], now: at("14:25"))
        #expect(actions == [.end(activityID: "B", content: nil, dismissAt: nil)])
    }

    @Test("solange die App läuft, sieht sie zum nächsten Gebetsbeginn wieder nach")
    func nextCheck() {
        #expect(LiveActivityLifecycle.nextCheck(plan: plan(at: "14:25"), now: at("14:25")) == at("16:27"))
        #expect(LiveActivityLifecycle.nextCheck(plan: plan(at: "16:30"), now: at("16:30")) == at("18:17"))
        #expect(LiveActivityLifecycle.nextCheck(plan: [], now: at("14:25")) == nil)
    }
}

#endif
