import Foundation

/// Receives core events on core threads and forwards them into an
/// `AsyncStream` consumed on the main actor by `AppModel`.
final class CoreEventBridge: EventListener {
    private let continuation: AsyncStream<CoreEvent>.Continuation

    init(continuation: AsyncStream<CoreEvent>.Continuation) {
        self.continuation = continuation
    }

    func onEvent(event: CoreEvent) {
        continuation.yield(event)
    }
}
