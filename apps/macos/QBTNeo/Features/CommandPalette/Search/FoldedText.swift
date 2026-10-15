import Foundation

/// Text prepared once for fuzzy matching: case, diacritics and width folded
/// ("Ё" matches "е", "Ｓ" matches "s"), stored as Unicode scalars, with the
/// positions where words start.
struct FoldedText: Sendable {
    let scalars: [Unicode.Scalar]
    /// `isWordStart[i]`: scalar `i` begins a word (after a space or punctuation, or a lower→upper case change).
    let isWordStart: [Bool]

    init(_ text: String) {
        let folded = Self.fold(text)
        scalars = Array(folded.unicodeScalars)
        // Case changes are read from the original text when folding kept its length (camelCase hosts, file names).
        let original = Array(text.unicodeScalars)
        let sameLength = original.count == scalars.count
        var starts = [Bool](repeating: false, count: scalars.count)
        for index in scalars.indices {
            if index == 0 {
                starts[index] = true
            } else if !Self.isWordCharacter(scalars[index - 1]) {
                starts[index] = Self.isWordCharacter(scalars[index])
            } else if sameLength, original[index].properties.isUppercase, original[index - 1].properties.isLowercase {
                starts[index] = true
            } else if scalars[index].properties.numericType != nil, scalars[index - 1].properties.numericType == nil {
                starts[index] = true
            }
        }
        isWordStart = starts
    }

    var isEmpty: Bool { scalars.isEmpty }

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

    private static func isWordCharacter(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.isAlphabetic || scalar.properties.numericType != nil
    }
}
