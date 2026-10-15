import Foundation
import Observation

/// A file or folder of a torrent's content tree. Folder values are
/// aggregated from their children (ignored children excluded from progress,
/// remaining and availability, like qBittorrent).
@Observable @MainActor
final class FileNode: Identifiable {
    /// Stable identity: `f<index>` for files, `d<path>` for folders.
    let id: String
    var name: String
    /// Path relative to the torrent root, `/`-separated.
    var path: String
    let isFolder: Bool
    /// Torrent file index; -1 for folders.
    let fileIndex: Int
    let depth: Int
    var size: Int64
    var progress: Double
    var priority: FilePriorityChoice
    var remaining: Int64
    var availability: Double
    var isExpanded = false

    @ObservationIgnored weak var parent: FileNode?
    @ObservationIgnored var children: [FileNode] = []

    init(id: String, name: String, path: String, isFolder: Bool, fileIndex: Int, depth: Int, size: Int64 = 0,
         progress: Double = 0, priority: FilePriorityChoice = .normal, availability: Double = -1) {
        self.id = id
        self.name = name
        self.path = path
        self.isFolder = isFolder
        self.fileIndex = fileIndex
        self.depth = depth
        self.size = size
        self.progress = progress
        self.priority = priority
        self.remaining = priority == .ignored ? 0 : Int64(Double(size) * (1 - progress))
        self.availability = availability
    }

    /// Checkbox state: unchecked = ignored, mixed folders are partial when any
    /// descendant is ignored.
    var checkState: CheckState {
        switch priority {
        case .ignored: .unchecked
        case .mixed: hasIgnoredDescendant ? .partial : .checked
        default: .checked
        }
    }

    enum CheckState {
        case checked, unchecked, partial
    }

    private var hasIgnoredDescendant: Bool {
        children.contains { $0.priority == .ignored || ($0.priority == .mixed && $0.hasIgnoredDescendant) }
    }

    /// Recomputes this folder's values from its children (recursively).
    func aggregate() {
        guard isFolder else { return }
        var total: Int64 = 0
        var wanted: Int64 = 0
        var done = 0.0
        var left: Int64 = 0
        var availabilitySum = 0.0
        var availabilitySize: Int64 = 0
        var priorities = Set<Int>()
        for child in children {
            child.aggregate()
            total += child.size
            priorities.insert(child.priority.rawValue)
            guard child.priority != .ignored else { continue }
            wanted += child.size
            done += child.progress * Double(child.size)
            left += child.remaining
            if child.availability >= 0 {
                availabilitySum += child.availability * Double(child.size)
                availabilitySize += child.size
            }
        }
        size = total
        progress = wanted > 0 ? done / Double(wanted) : 1
        remaining = left
        availability = availabilitySize > 0 ? availabilitySum / Double(availabilitySize) : -1
        priority = priorities.count == 1 ? FilePriorityChoice(rawValue: priorities.first ?? 1) ?? .mixed : .mixed
    }
}
