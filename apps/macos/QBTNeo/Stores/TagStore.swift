import Foundation
import Observation

/// Session tags kept in sync from `MainDataUpdate`.
@Observable @MainActor
final class TagStore {
    /// Tags sorted naturally and case-insensitively.
    private(set) var sortedTags: [String] = []
    @ObservationIgnored private var tags: Set<String> = []

    func apply(added: [String], removed: [String], fullUpdate: Bool) {
        guard fullUpdate || !added.isEmpty || !removed.isEmpty else { return }
        var next = fullUpdate ? Set<String>() : tags
        next.subtract(removed)
        next.formUnion(added)
        guard next != tags else { return }
        tags = next
        sortedTags = next.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func contains(_ tag: String) -> Bool { tags.contains(tag) }

    /// Tag rule: trimmed, non-empty, no comma.
    nonisolated static func isValid(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && !trimmed.contains(",")
    }

    /// Splits "a, b,c" into validated, trimmed tags; returns the first invalid one.
    nonisolated static func parseCommaSeparated(_ text: String) -> (tags: [String], invalid: String?) {
        var result: [String] = []
        for part in text.split(separator: ",") {
            let tag = part.trimmingCharacters(in: .whitespaces)
            if tag.isEmpty { continue }
            guard isValid(tag) else { return (result, tag) }
            if !result.contains(tag) { result.append(tag) }
        }
        return (result, nil)
    }
}
