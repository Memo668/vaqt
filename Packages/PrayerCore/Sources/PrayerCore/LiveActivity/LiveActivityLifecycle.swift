import Foundation

/// Was mit den Live-Aktivitäten geschieht, die iOS schon kennt, wenn die App neu plant – beim Start, wenn
/// sie nach vorn kommt, nach jeder Änderung und bei der Hintergrundaktualisierung (Spec § 4: „old
/// activities are ended on the next launch / background refresh“).
///
/// ActivityKit kann eine Aktivität zu einem Zeitpunkt starten, aber nicht zu einem Zeitpunkt beenden. Zu
/// ihrem `staleDate` schrumpft sie deshalb von selbst auf eine schmale Zeile (Spec § 10.3); beenden kann sie
/// erst die App, sobald sie danach läuft – dann sofort. Läuft die App nicht, bleibt die Zeile stehen,
/// längstens beendet iOS die Aktivität nach 8 Stunden. Die Widget-Erweiterung sieht die Aktivitäten der App
/// nicht und kann deshalb nicht aufräumen (getestet am 18.11.2026).
public enum LiveActivityLifecycle {

    /// Eine Aktivität, die iOS schon kennt und die noch nicht beendet ist.
    public struct Existing: Hashable, Sendable {
        /// Kennung der Aktivität bei iOS.
        public let activityID: String
        /// Kennung im Plan (`LiveActivityPlan.id`).
        public let planID: String
        /// Ab wann sie laufen soll (App-Uhr), wie beim Anmelden geplant.
        public let start: Date
        /// Ob iOS sie erst zum geplanten Zeitpunkt startet (`ActivityState.pending`).
        public let isPending: Bool
        /// Der Inhalt, den sie gerade zeigt.
        public let content: LiveActivityContent

        public init(activityID: String, planID: String, start: Date, isPending: Bool, content: LiveActivityContent) {
            self.activityID = activityID
            self.planID = planID
            self.start = start
            self.isPending = isPending
            self.content = content
        }
    }

    /// Was zu tun ist.
    public enum Action: Hashable, Sendable {
        /// Anmelden: sofort, wenn der Start erreicht ist, sonst zum geplanten Zeitpunkt.
        case request(LiveActivityPlan)
        /// Den Inhalt einer laufenden Aktivität auffrischen, etwa den Bogen auf „jetzt“.
        case update(activityID: String, content: LiveActivityContent)
        /// Beenden. Mit Zeitpunkt (App-Uhr) bleibt sie bis dahin auf dem Sperrbildschirm stehen, ohne sofort.
        case end(activityID: String, content: LiveActivityContent?, dismissAt: Date?)
    }

    /// Die Schritte, mit denen aus den bestehenden Aktivitäten der Plan wird.
    ///
    /// - Was nicht mehr im Plan steht – Live-Aktivität aus, anderer Ort, andere Zeiten –, endet sofort; eine
    ///   geplante, die sich geändert hat, wird ersetzt.
    /// - Hat eine laufende Aktivität gewechselt (Gebetsbeginn oder Beginn der Verbotszeit), endet sie sofort.
    /// - Eine laufende Aktivität vor ihrem Wechsel bekommt den neuen Inhalt, wenn er sich geändert hat.
    /// - Was im Plan steht und iOS nicht kennt, wird angemeldet – aber nur vor dem Wechsel: Eine Aktivität,
    ///   die nur noch die schmale Zeile zeigen würde, startet nicht mehr.
    public static func actions(existing: [Existing], plan: [LiveActivityPlan], now: Date) -> [Action] {
        let planned = Dictionary(plan.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var actions: [Action] = []
        var kept: Set<String> = []

        for activity in existing {
            guard let target = planned[activity.planID], !kept.contains(activity.planID) else {
                actions.append(.end(activityID: activity.activityID, content: nil, dismissAt: nil))
                continue
            }
            if activity.isPending {
                if activity.start == target.start, activity.content == target.content {
                    kept.insert(target.id)
                } else {
                    actions.append(.end(activityID: activity.activityID, content: nil, dismissAt: nil))
                }
                continue
            }
            kept.insert(target.id)
            if now >= target.end {
                actions.append(.end(activityID: activity.activityID, content: nil, dismissAt: nil))
            } else if activity.content != target.content {
                actions.append(.update(activityID: activity.activityID, content: target.content))
            }
        }

        for target in plan where !kept.contains(target.id) && now < target.end {
            actions.append(.request(target))
        }
        return actions
    }

    /// Wann die App, solange sie läuft, wieder nachsehen soll: zum nächsten Wechsel einer Aktivität im Plan
    /// (Gebetsbeginn oder Beginn der Verbotszeit). Dann beendet sie sie. `nil` ohne Plan.
    public static func nextCheck(plan: [LiveActivityPlan], now: Date) -> Date? {
        plan.map(\.end).filter { $0 > now }.min()
    }
}
