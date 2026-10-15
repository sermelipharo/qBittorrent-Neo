import Foundation

/// Text of the menu bar item: compact rates ("↓1.2M ↑340K") and torrent counts ("3/12").
enum MenuBarTitle {
    /// Rates for `direction`, or nil when `hidesZero` removes every shown rate.
    static func speed(download: Int64, upload: Int64, direction: MenuBarSpeedDirection, hidesZero: Bool) -> String? {
        var parts: [String] = []
        if direction != .upload, !(hidesZero && download <= 0) { parts.append("↓" + rate(download)) }
        if direction != .download, !(hidesZero && upload <= 0) { parts.append("↑" + rate(upload)) }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    static func count(active: Int, total: Int, style: MenuBarCountStyle) -> String {
        switch style {
        case .activeOfTotal: "\(active)/\(total)"
        case .active: "\(active)"
        case .total: "\(total)"
        }
    }

    /// One rate without a space or a "/s": "0", "340K", "1.2M", "12M".
    static func rate(_ bytesPerSecond: Int64) -> String {
        guard bytesPerSecond > 0 else { return "0" }
        var value = Double(bytesPerSecond)
        var unit = 0
        while value >= 1000, unit < UnitFormatter.Unit.allCases.count - 1 {
            value /= 1024
            unit += 1
        }
        let digits = unit > 0 && value < 10 ? 1 : 0
        let number = value.formatted(.number.precision(.fractionLength(digits)).rounded(rule: .down))
        return number + UnitFormatter.Unit.allCases[unit].name.prefix(1)
    }
}
