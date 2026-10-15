import Foundation

/// `Utils::Misc::userFriendlyDuration` with qBittorrent's thresholds.
enum DurationFormatter {
    /// qBittorrent's ETA cap (100 days); values at or above it show "∞".
    static let maxETA: Int64 = 8_640_000

    enum Resolution {
        case minutes
        case seconds
    }

    /// - Parameters:
    ///   - seconds: the duration; negative means infinite.
    ///   - maxCap: values at or above the cap are infinite (`nil` = no cap).
    static func string(_ seconds: Int64, maxCap: Int64? = nil, resolution: Resolution = .minutes) -> String {
        if seconds < 0 { return UnitFormatter.infinity }
        if let maxCap, seconds >= maxCap { return UnitFormatter.infinity }
        if seconds == 0 { return "0" }
        if seconds < 60 {
            return resolution == .minutes ? String(localized: "< 1m") : String(localized: "\(seconds)s", comment: "Duration in seconds")
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return String(localized: "\(minutes)m", comment: "Duration in minutes")
        }
        let hours = minutes / 60
        if hours < 24 {
            return String(localized: "\(hours)h \(minutes % 60)m", comment: "Duration: hours and minutes")
        }
        let days = hours / 24
        if days < 365 {
            return String(localized: "\(days)d \(hours % 24)h", comment: "Duration: days and hours")
        }
        return String(localized: "\(days / 365)y \(days % 365)d", comment: "Duration: years and days")
    }

    /// ETA column / General tab value.
    static func eta(_ seconds: Int64) -> String {
        string(seconds, maxCap: maxETA)
    }

    /// "Last Activity" column: "%1 ago", "< 1m ago" for zero, "∞" if never.
    static func ago(_ seconds: Int64) -> String {
        if seconds < 0 { return UnitFormatter.infinity }
        if seconds == 0 { return String(localized: "< 1m ago") }
        return String(localized: "\(string(seconds)) ago", comment: "Time since last activity")
    }

    /// "Time Active" with seeding time: "%1 (seeded for %2)".
    static func timeActive(_ active: Int64, seeding: Int64) -> String {
        if seeding <= 0 { return string(active) }
        return String(localized: "\(string(active)) (seeded for \(string(seeding)))")
    }
}
