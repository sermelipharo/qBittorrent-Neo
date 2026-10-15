import Foundation

/// Ratios, percentages, dates and other small values formatted the way
/// qBittorrent displays them.
enum ValueFormatter {
    /// Ratios at or above this are infinite (`Torrent::MAX_RATIO`).
    static let maxRatio = 9999.0

    /// Ratio floored to 2 decimals; -1 or ≥ MAX_RATIO shows "∞".
    static func ratio(_ value: Double) -> String {
        if value < 0 || value >= maxRatio || !value.isFinite { return UnitFormatter.infinity }
        return value.formatted(.number.precision(.fractionLength(2)).rounded(rule: .down))
    }

    /// Progress text: "100%" when complete, else floored to one decimal.
    static func progress(_ fraction: Double) -> String {
        if fraction >= 1 { return "100%" }
        let percent = max(fraction, 0) * 100
        return "\(percent.formatted(.number.precision(.fractionLength(1)).rounded(rule: .down)))%"
    }

    /// Percent with one decimal, not floored (peer relevance, availability).
    static func percent(_ fraction: Double) -> String {
        "\((fraction * 100).formatted(.number.precision(.fractionLength(1))))%"
    }

    /// Distributed copies floored to 3 decimals; "N/A" when unknown.
    static func availability(_ value: Double) -> String {
        if value < 0 { return String(localized: "N/A") }
        return value.formatted(.number.precision(.fractionLength(3)).rounded(rule: .down))
    }

    /// Locale short date and time of a Unix timestamp; empty when unset.
    static func date(_ unixSeconds: Int64) -> String {
        guard unixSeconds > 0 else { return "" }
        return Date(timeIntervalSince1970: TimeInterval(unixSeconds)).formatted(date: .numeric, time: .shortened)
    }

    /// Integer counts where -1 means unknown.
    static func count(_ value: Int64) -> String {
        value < 0 ? String(localized: "N/A") : value.formatted()
    }

    /// "%1 (%2)" for connected/total seeds and peers.
    static func connectedOfTotal(_ connected: Int64, _ total: Int64) -> String {
        "\(connected.formatted()) (\(max(total, connected).formatted()))"
    }

    /// Yes/No/N-A for the private flag.
    static func yesNo(_ value: Bool?) -> String {
        guard let value else { return String(localized: "N/A") }
        return value ? String(localized: "Yes") : String(localized: "No")
    }

    /// Info hash or "N/A" when empty.
    static func hash(_ value: String) -> String {
        value.isEmpty ? String(localized: "N/A") : value
    }
}
