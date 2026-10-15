import Foundation

/// Content tree columns (`TreeItemColumns`).
enum FileColumn: String, CaseIterable, Codable, Sendable {
    case name
    case size
    case progress
    case priority
    case remaining
    case availability

    var title: String {
        switch self {
        case .name: String(localized: "Name")
        case .size: String(localized: "Total Size")
        case .progress: String(localized: "Progress")
        case .priority: String(localized: "Download Priority")
        case .remaining: String(localized: "Remaining")
        case .availability: String(localized: "Availability")
        }
    }
}
