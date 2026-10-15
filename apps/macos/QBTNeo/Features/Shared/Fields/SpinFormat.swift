import Foundation

/// Integer format of a spin field, like Qt's `QSpinBox`: the minimum (or
/// another sentinel) shows a special text such as "∞" or "Disabled", typed
/// values are clamped to the range, and an optional unit suffix is accepted
/// while parsing.
struct SpinFormat: ParseableFormatStyle {
    var lowerBound: Int64
    var upperBound: Int64
    var specialValue: Int64?
    var specialText: String?
    var suffix: String?

    init(range: ClosedRange<Int64>, special: SpinSpecial? = nil, suffix: String? = nil) {
        lowerBound = range.lowerBound
        upperBound = range.upperBound
        specialValue = special?.value
        specialText = special?.text
        self.suffix = suffix
    }

    var parseStrategy: Strategy {
        Strategy(format: self)
    }

    func format(_ value: Int64) -> String {
        if let specialValue, let specialText, value == specialValue { return specialText }
        return value.formatted(.number.grouping(.never))
    }

    struct Strategy: ParseStrategy {
        let format: SpinFormat

        func parse(_ value: String) throws -> Int64 {
            var text = value.trimmingCharacters(in: .whitespaces)
            if let special = format.specialText, let specialValue = format.specialValue,
               text.localizedCaseInsensitiveCompare(special) == .orderedSame || text.isEmpty {
                return specialValue
            }
            if let suffix = format.suffix, text.hasSuffix(suffix) {
                text = String(text.dropLast(suffix.count)).trimmingCharacters(in: .whitespaces)
            }
            text = text.filter { !$0.isWhitespace && $0 != "," && $0 != "\u{00A0}" && $0 != "'" }
            guard let number = Int64(text) else { throw CocoaError(.formatting) }
            return min(max(number, format.lowerBound), format.upperBound)
        }
    }
}
