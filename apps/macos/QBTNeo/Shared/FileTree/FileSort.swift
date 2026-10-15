import Foundation

/// Sort comparator for content trees; folders always sort before files in
/// ascending order, names compare naturally.
struct FileSort: SortComparator, Hashable, Codable, Sendable {
    var column: FileColumn
    var order: SortOrder = .forward

    init(_ column: FileColumn, order: SortOrder = .forward) {
        self.column = column
        self.order = order
    }

    func compare(_ lhs: FileNode, _ rhs: FileNode) -> ComparisonResult {
        MainActor.assumeIsolated { Self.compare(column, order: order, lhs, rhs) }
    }

    @MainActor
    static func compare(_ column: FileColumn, order: SortOrder, _ lhs: FileNode, _ rhs: FileNode) -> ComparisonResult {
        if lhs.isFolder != rhs.isFolder {
            let folderFirst: ComparisonResult = lhs.isFolder ? .orderedAscending : .orderedDescending
            return order == .forward ? folderFirst : folderFirst.reversed
        }
        let result: ComparisonResult = switch column {
        case .name: lhs.name.localizedStandardCompare(rhs.name)
        case .size: value(lhs.size, rhs.size)
        case .progress: value(lhs.progress, rhs.progress)
        case .priority: value(lhs.priority.rawValue, rhs.priority.rawValue)
        case .remaining: value(lhs.remaining, rhs.remaining)
        case .availability: value(lhs.availability, rhs.availability)
        }
        let tieBroken = result == .orderedSame ? lhs.name.localizedStandardCompare(rhs.name) : result
        return order == .forward ? tieBroken : tieBroken.reversed
    }

    private static func value<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : (lhs == rhs ? .orderedSame : .orderedDescending)
    }
}
