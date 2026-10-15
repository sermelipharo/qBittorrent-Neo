import Foundation

/// One displayed line of the Execution Log ("General" or "Blocked IPs").
struct LogLine: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case message(LogLevel)
        case blockedPeer
    }

    let id: Int64
    let time: String
    let text: String
    let kind: Kind

    /// `time - message`, the format used by Copy.
    var copyText: String { "\(time) - \(text)" }

    init(_ message: LogMessage) {
        id = message.id
        time = Self.format(milliseconds: message.timestamp)
        text = message.message
        kind = .message(message.level)
    }

    init(_ entry: PeerLogEntry) {
        id = entry.id
        time = Self.format(milliseconds: entry.timestamp)
        text = entry.blocked
            ? String(localized: "\(entry.ip) was blocked. Reason: \(entry.reason).")
            : String(localized: "\(entry.ip) was banned")
        kind = .blockedPeer
    }

    private static func format(milliseconds: Int64) -> String {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000).formatted(date: .numeric, time: .standard)
    }
}
