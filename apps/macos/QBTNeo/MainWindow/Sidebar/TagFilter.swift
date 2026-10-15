import Foundation

/// Tag filter: All, Untagged, or one tag.
enum TagFilter: Hashable, Sendable {
    case all
    case untagged
    case tag(String)

    func matches(_ tags: [String]) -> Bool {
        switch self {
        case .all: true
        case .untagged: tags.isEmpty
        case .tag(let tag): tags.contains(tag)
        }
    }
}
