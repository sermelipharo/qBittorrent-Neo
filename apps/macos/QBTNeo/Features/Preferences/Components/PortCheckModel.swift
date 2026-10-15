import Foundation
import Observation

/// "Test Port": asks the core to check the listening port with
/// portcheck.transmissionbt.com. Runs only when the user clicks the button.
@Observable @MainActor
final class PortCheckModel {
    enum State: Equatable {
        case idle
        case checking
        case open(Int64)
        case closed(Int64)
        case failed(String)
    }

    private(set) var state = State.idle
    @ObservationIgnored private var task: Task<Void, Never>?

    func check(port: Int64, client: (any AppInfoClient)?) {
        guard let client, (1...65_535).contains(port) else { return }
        task?.cancel()
        state = .checking
        task = Task {
            do {
                let isOpen = try await client.checkPort(port: port)
                guard !Task.isCancelled else { return }
                state = isOpen ? .open(port) : .closed(port)
            } catch {
                guard !Task.isCancelled else { return }
                state = .failed(error.userMessage)
            }
        }
    }

    /// Forget a result that no longer applies (the port changed).
    func reset() {
        task?.cancel()
        state = .idle
    }
}
