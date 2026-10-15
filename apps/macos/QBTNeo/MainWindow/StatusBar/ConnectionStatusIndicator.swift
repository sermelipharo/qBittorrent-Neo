import SwiftUI

/// Connection status icon; clicking opens the preferences.
struct ConnectionStatusIndicator: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        let status = model.status.connectionStatus
        Button(action: { openSettings() }, label: {
            Image(systemName: symbol(status))
                .foregroundStyle(color(status))
        })
        .buttonStyle(.borderless)
        .help(tooltip(status))
        .accessibilityLabel(Text("Connection status: \(tooltip(status))"))
        .pointerStyle(.link)
    }

    private func symbol(_ status: ConnectionStatus) -> String {
        switch status {
        case .connected: Symbol.network
        case .firewalled: Symbol.networkBadgeShieldHalfFilled
        case .disconnected: Symbol.networkSlash
        }
    }

    private func color(_ status: ConnectionStatus) -> Color {
        switch status {
        case .connected: TorrentState.downloading.color
        case .firewalled: .orange
        case .disconnected: TorrentState.error.color
        }
    }

    private func tooltip(_ status: ConnectionStatus) -> String {
        switch status {
        case .connected:
            String(localized: "Connection Status: Online")
        case .firewalled:
            String(localized: "Connection Status: No direct connections. This may indicate network configuration problems.")
        case .disconnected:
            String(localized: """
                Connection Status: Offline. This usually means that qBittorrent Neo failed to listen \
                on the selected port for incoming connections.
                """)
        }
    }
}
