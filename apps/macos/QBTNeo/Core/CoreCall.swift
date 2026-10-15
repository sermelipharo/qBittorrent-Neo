import Foundation

/// Runs synchronous core calls off the main actor. The facade's sync methods
/// never block on I/O, but they can return large arrays (thousands of
/// torrents or files) whose conversion should not stall the UI.
enum CoreCall {
    @concurrent
    static func run<T: Sendable>(_ work: @Sendable () throws -> T) async throws -> T {
        try work()
    }

    @concurrent
    static func run<T: Sendable>(_ work: @Sendable () -> T) async -> T {
        work()
    }
}
