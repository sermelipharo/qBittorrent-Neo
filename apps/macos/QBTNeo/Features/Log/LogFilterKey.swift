import Foundation

/// Inputs of the general log view; the visible lines are rebuilt whenever
/// any of them changes.
struct LogFilterKey: Equatable {
    let lastID: Int64
    let count: Int
    let types: Int
    let query: String
}
