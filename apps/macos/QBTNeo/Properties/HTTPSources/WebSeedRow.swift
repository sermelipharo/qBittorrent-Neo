import Foundation

/// An HTTP Sources (web seed) row.
struct WebSeedRow: Identifiable, Equatable, Sendable {
    var url: String
    var id: String { url }
}
