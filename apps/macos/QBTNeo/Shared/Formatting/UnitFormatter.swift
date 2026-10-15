import Foundation

/// Size and speed formatting with qBittorrent's exact rules
/// (`Utils::Misc::friendlyUnit`): binary units, floored values, precision
/// B 0 · KiB/MiB 1 · GiB 2 · larger 3, a no-break space before the unit.
enum UnitFormatter {
    static let infinity = "∞"

    /// Size units in qBittorrent's order; names are localized like its `misc` context.
    enum Unit: Int, CaseIterable {
        case byte, kibibyte, mebibyte, gibibyte, tebibyte, pebibyte, exbibyte

        var name: String {
            switch self {
            case .byte: String(localized: "B", comment: "bytes")
            case .kibibyte: String(localized: "KiB", comment: "kibibytes (1024 bytes)")
            case .mebibyte: String(localized: "MiB", comment: "mebibytes (1024 kibibytes)")
            case .gibibyte: String(localized: "GiB", comment: "gibibytes (1024 mebibytes)")
            case .tebibyte: String(localized: "TiB", comment: "tebibytes (1024 gibibytes)")
            case .pebibyte: String(localized: "PiB", comment: "pebibytes (1024 tebibytes)")
            case .exbibyte: String(localized: "EiB", comment: "exbibytes (1024 pebibytes)")
            }
        }
    }

    /// Localized unit name, e.g. "KiB" / "КБ".
    static func unitName(_ unit: Unit) -> String { unit.name }

    /// Localized speed unit name, e.g. "KiB/s" / "КБ/с".
    static func speedUnitName(_ unit: Unit) -> String { unit.name + perSecond }

    static var kib: String { unitName(.kibibyte) }
    static var mib: String { unitName(.mebibyte) }
    static var kibPerSecond: String { speedUnitName(.kibibyte) }

    private static var perSecond: String { String(localized: "/s", comment: "per second") }

    /// `friendlyUnit(bytes)`; negative input gives "Unknown".
    static func size(_ bytes: Int64) -> String {
        format(bytes, isSpeed: false)
    }

    /// `friendlyUnit(bytesPerSecond, isSpeed: true)`, e.g. "1.5 MiB/s".
    static func speed(_ bytesPerSecond: Int64) -> String {
        format(bytesPerSecond, isSpeed: true)
    }

    /// Speed limit: positive values as a speed, anything else as "∞".
    static func limit(_ bytesPerSecond: Int64) -> String {
        bytesPerSecond > 0 ? speed(bytesPerSecond) : infinity
    }

    /// `friendlyUnitCompact` used by the Dock badge: threshold 1000, precision
    /// 2 decimals below 10, 1 below 100, else 0, single-letter unit ("1.25 M").
    static func compact(_ bytes: Int64) -> String {
        guard bytes >= 0 else { return String(localized: "Unknown") }
        var value = Double(bytes)
        var unit = 0
        while value >= 1000, unit < Unit.allCases.count - 1 {
            value /= 1024
            unit += 1
        }
        let precision = value < 10 ? 2 : (value < 100 ? 1 : 0)
        let number = value.formatted(.number.precision(.fractionLength(unit == 0 ? 0 : precision)).rounded(rule: .down))
        return "\(number)\u{00A0}\(Unit.allCases[unit].name.prefix(1))"
    }

    /// Splits a value into a number and its unit, for axis labels and fields.
    static func scaled(_ bytes: Double) -> (value: Double, unit: String) {
        var value = max(bytes, 0)
        var unit = 0
        while value >= 1024, unit < Unit.allCases.count - 1 {
            value /= 1024
            unit += 1
        }
        return (value, Unit.allCases[unit].name)
    }

    private static func format(_ bytes: Int64, isSpeed: Bool) -> String {
        guard bytes >= 0 else { return String(localized: "Unknown") }
        var value = Double(bytes)
        var unit = 0
        while value >= 1024, unit < Unit.allCases.count - 1 {
            value /= 1024
            unit += 1
        }
        let precision = switch unit {
        case 0: 0
        case 1, 2: 1
        case 3: 2
        default: 3
        }
        let number = value.formatted(.number.precision(.fractionLength(precision)).rounded(rule: .down))
        return "\(number)\u{00A0}\(Unit.allCases[unit].name)\(isSpeed ? perSecond : "")"
    }
}
