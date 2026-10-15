import Foundation

/// A warning shown by the RSS reader.
struct RSSAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
