import SwiftUI

/// "Loading torrents..." while the core starts, or the start-up error.
struct StartupOverlay: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.phase {
        case .starting:
            ProgressView("Loading torrents…")
                .padding(Design.Spacing.xLarge)
                .background(.regularMaterial, in: .rect(cornerRadius: Design.Radius.large))
        case .failed(let message):
            ContentUnavailableView {
                Label("qBittorrent Neo Could Not Start", systemImage: Symbol.exclamationmarkTriangle)
            } description: {
                Text(message)
            } actions: {
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut(.defaultAction)
            }
            .background(.background)
        case .running:
            EmptyView()
        }
    }
}
