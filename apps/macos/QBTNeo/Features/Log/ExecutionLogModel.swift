import AppKit
import Observation

/// Execution Log window state (features.md §3.15): filtered general
/// messages (newest first) from `LogStore`, and the blocked-peer log polled
/// from the core while the "Blocked IPs" tab is shown.
@Observable @MainActor
final class ExecutionLogModel {
    var tab: ExecutionLogTab = .general
    var query = ""
    var selection: Set<Int64> = []
    private(set) var lines: [LogLine] = []
    private(set) var blockedLines: [LogLine] = []

    @ObservationIgnored private var peerLastID: Int64 = -1
    /// Capacity of each view (qBittorrent's `MAX_VISIBLE_MESSAGES`).
    private static let capacity = 20_000

    /// Rebuilds the visible general lines from the store with the level
    /// filter (`GUI/Log/Types` flags) and the search text.
    func rebuild(from messages: [LogMessage], types: Int) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        var result: [LogLine] = []
        result.reserveCapacity(min(messages.count, Self.capacity))
        for message in messages.reversed() where types & message.level.filterFlag != 0 {
            if !trimmed.isEmpty, !message.message.localizedStandardContains(trimmed) { continue }
            result.append(LogLine(message))
            if result.count == Self.capacity { break }
        }
        lines = result
        selection.formIntersection(result.map(\.id))
    }

    /// Polls the core's peer log until the calling task is cancelled.
    func pollBlockedPeers(client: (any CoreClient)?) async {
        while !Task.isCancelled {
            if let client {
                let lastID = peerLastID
                let entries = await CoreCall.run { client.peerLog(lastKnownId: lastID) }
                if let last = entries.last {
                    peerLastID = last.id
                    blockedLines.insert(contentsOf: entries.reversed().map(LogLine.init), at: 0)
                    if blockedLines.count > Self.capacity { blockedLines.removeLast(blockedLines.count - Self.capacity) }
                }
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    var visibleLines: [LogLine] { tab == .general ? lines : blockedLines }

    /// Copies the selected rows as `time - message`, one per line.
    func copySelection() {
        let text = visibleLines.filter { selection.contains($0.id) }.map(\.copyText).joined(separator: "\n")
        guard !text.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    /// Clears the current view only; the core keeps its own buffer.
    func clear(store: LogStore) {
        if tab == .general {
            store.clear()
            lines = []
        } else {
            blockedLines = []
        }
        selection = []
    }
}
