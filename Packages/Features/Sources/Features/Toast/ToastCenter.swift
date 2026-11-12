import DesignSystem
import Observation
import SwiftUI

/// Zeigt den HUD-Toast der App: eine kurze Rückmeldung über der Tableiste, die nach etwa 1,7 Sekunden
/// von selbst verschwindet – `toast()` im Prototyp.
///
/// Es gibt immer nur einen Toast; ein neuer ersetzt den alten und beginnt die Frist von vorn.
@MainActor
@Observable
public final class ToastCenter {

    /// Ein Toast auf dem Bildschirm.
    public struct Message: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let text: String
        public let systemImage: String?
    }

    /// Der Toast, der gerade steht.
    public private(set) var message: Message?

    @ObservationIgnored private let duration: Duration
    @ObservationIgnored private var dismissal: Task<Void, Never>?

    /// - Parameter duration: wie lange ein Toast steht; ohne Angabe die Frist des Prototyps.
    public init(duration: Duration = .seconds(Layout.toastDuration)) {
        self.duration = duration
    }

    /// Zeigt einen Toast und sagt ihn VoiceOver an (`role="status"` im Prototyp).
    public func show(_ text: String, systemImage: String? = nil) {
        message = Message(id: UUID(), text: text, systemImage: systemImage)
        AccessibilityNotification.Announcement(text).post()
        dismissal?.cancel()
        dismissal = Task { [duration] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            message = nil
        }
    }

    /// Nimmt den Toast sofort weg.
    public func dismiss() {
        dismissal?.cancel()
        dismissal = nil
        message = nil
    }
}

/// Stellt den Toast der App über den Inhalt: unten mittig, 100 pt über der Unterkante des Bildschirms
/// und damit 16 pt über der Tableiste. Stehen die Leisten senkrecht am Rand (iPhone Duo), gibt es unten
/// keine Tableiste: Dann steht er 28 pt über der Unterkante, mittig über dem Inhalt
/// (`.screen[data-dev^="duo"] .toast`).
struct ToastHost: ViewModifier {
    let center: ToastCenter

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalBarEdge) private var verticalBarEdge

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ZStack {
                    if let message = center.message {
                        Toast(message.text, systemImage: message.systemImage)
                            .id(message.id)
                            .transition(transition)
                    }
                }
                .padding(.bottom, verticalBarEdge == nil ? Layout.toastBottom : Layout.toastBottomWithVerticalBar)
                // Gemessen wird von der Unterkante des Bildschirms, nicht vom sicheren Bereich; links und
                // rechts bleibt der sichere Bereich, damit der Toast neben einer senkrechten Leiste mittig
                // über dem Inhalt steht.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .vertical)
                .allowsHitTesting(false)
                // `transition: opacity .25s, transform .4s var(--ease-spring)`
                .animation(.spring(duration: 0.4), value: center.message)
            }
    }

    /// Der Toast blendet ein und schiebt sich dabei 10 pt nach oben; bei „Bewegung reduzieren“ nur
    /// einblenden.
    private var transition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 10))
    }
}

extension View {

    /// Zeigt die Toasts von `center` über dieser Ansicht.
    func toasts(from center: ToastCenter) -> some View {
        modifier(ToastHost(center: center))
    }
}
