import Foundation
import Observation

/// Bounded buffer of execution-log lines fed by `CoreEvent.log`, for the
/// Execution Log window. Older lines are dropped beyond `capacity`.
@Observable @MainActor
final class LogStore {
    let capacity: Int
    private(set) var messages: [LogMessage] = []
    private(set) var lastID: Int64 = -1

    init(capacity: Int = 5_000) {
        self.capacity = capacity
    }

    func append(_ message: LogMessage) {
        guard message.id > lastID else { return }
        lastID = message.id
        messages.append(message)
        trim()
    }

    func append(contentsOf batch: [LogMessage]) {
        let fresh = batch.filter { $0.id > lastID }
        guard let last = fresh.last else { return }
        lastID = last.id
        messages.append(contentsOf: fresh)
        trim()
    }

    func clear() {
        messages.removeAll()
    }

    private func trim() {
        if messages.count > capacity { messages.removeFirst(messages.count - capacity) }
    }
}
