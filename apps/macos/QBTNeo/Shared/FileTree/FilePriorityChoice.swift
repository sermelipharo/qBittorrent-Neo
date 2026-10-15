import Foundation

/// Download priority as shown in content trees, including the folder-only
/// "Mixed" value (features.md §2.7.2).
enum FilePriorityChoice: Int, CaseIterable, Identifiable, Sendable {
    case ignored = 0
    case normal = 1
    case high = 6
    case maximum = 7
    case mixed = -1

    var id: Int { rawValue }

    static let selectable: [Self] = [.ignored, .normal, .high, .maximum]

    init(_ priority: FilePriority) {
        self = switch priority {
        case .ignored: .ignored
        case .normal: .normal
        case .high: .high
        case .maximum: .maximum
        }
    }

    var filePriority: FilePriority? {
        switch self {
        case .ignored: .ignored
        case .normal: .normal
        case .high: .high
        case .maximum: .maximum
        case .mixed: nil
        }
    }

    var title: String {
        switch self {
        case .ignored: String(localized: "Do not download")
        case .normal: String(localized: "Normal")
        case .high: String(localized: "High")
        case .maximum: String(localized: "Maximum")
        case .mixed: String(localized: "Mixed")
        }
    }

    /// Multi-selection menu titles ("Normal priority" etc.).
    var menuTitle: String {
        switch self {
        case .ignored: String(localized: "Do not download")
        case .normal: String(localized: "Normal priority")
        case .high: String(localized: "High priority")
        case .maximum: String(localized: "Maximum priority")
        case .mixed: String(localized: "Mixed")
        }
    }
}
