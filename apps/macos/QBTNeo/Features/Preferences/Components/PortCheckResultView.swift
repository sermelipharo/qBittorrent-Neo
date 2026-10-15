import SwiftUI

/// The result next to "Test Port".
struct PortCheckResultView: View {
    let state: PortCheckModel.State

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .open(let port):
            InlineMessage(text: String(localized: "Port \(String(port)) is open"), style: .success)
        case .closed(let port):
            InlineMessage(text: String(localized: "Port \(String(port)) is closed"), style: .warning)
        case .failed(let message):
            InlineMessage(text: message)
        }
    }
}
