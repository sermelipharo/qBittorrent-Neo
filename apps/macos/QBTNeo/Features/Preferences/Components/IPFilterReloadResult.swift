import Foundation

/// Turns the core's IP filter log line into qBittorrent's reload message
/// ("Successfully refreshed" / "Parsing error").
@MainActor
enum IPFilterReloadResult {
    static func wait(in log: LogStore, after lastID: Int64, timeout: Duration = .seconds(10)) async -> PreferencesNotice {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while clock.now < deadline {
            if let notice = notice(in: log.messages, after: lastID) { return notice }
            try? await Task.sleep(for: .milliseconds(250))
        }
        return PreferencesNotice(
            text: String(localized: "The filter is being reloaded; the result will appear in the Execution Log."), isError: false
        )
    }

    static func notice(in messages: [LogMessage], after lastID: Int64) -> PreferencesNotice? {
        for message in messages.reversed() {
            guard message.id > lastID else { break }
            if message.message.hasPrefix("Successfully parsed the IP filter file") {
                let count = message.message.split(separator: ":").last.map { $0.trimmingCharacters(in: .whitespaces) } ?? "0"
                return PreferencesNotice(
                    text: String(localized: "Successfully parsed the provided IP filter: \(count) rules were applied."), isError: false
                )
            }
            if message.message.hasPrefix("Failed to parse the IP filter file") {
                return PreferencesNotice(text: String(localized: "Failed to parse the provided IP filter"), isError: true)
            }
        }
        return nil
    }
}
