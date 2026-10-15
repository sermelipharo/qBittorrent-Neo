import Foundation

/// Flat input for building a content tree (from `TorrentFile` or metadata).
struct FileEntry: Sendable, Equatable {
    var index: Int
    var path: String
    var size: Int64
    var progress: Double = 0
    var priority: FilePriority = .normal
    var availability: Double = -1

    init(index: Int, path: String, size: Int64, progress: Double = 0, priority: FilePriority = .normal, availability: Double = -1) {
        self.index = index
        self.path = path
        self.size = size
        self.progress = progress
        self.priority = priority
        self.availability = availability
    }

    init(_ file: TorrentFile) {
        self.init(index: Int(file.index), path: file.name, size: file.size, progress: file.progress,
                  priority: file.priority, availability: file.availability)
    }
}
