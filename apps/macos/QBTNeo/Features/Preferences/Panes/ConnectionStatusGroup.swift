import SwiftUI

/// Network › Status: whether peers can reach the app (from the session
/// status), the listening port and external IP, and the on-demand port test.
struct ConnectionStatusGroup: View {
    let model: PreferencesModel
    @Environment(AppModel.self) private var app
    @State private var portCheck = PortCheckModel()

    var body: some View {
        let status = app.status
        let port = model.applied.connection.listenPort
        SettingsGroup(.connectionStatus) {
            VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                Label {
                    Text(summary(status.connectionStatus))
                } icon: {
                    Image(systemName: Symbol.circleFill)
                        .foregroundStyle(color(status.connectionStatus))
                        .imageScale(.small)
                }
                SettingFootnote(text: details(port: port, status: status))
            }
            .setting("system.connectionStatus")
        } content: {
            VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                HStack(spacing: Design.Spacing.regular) {
                    Button(SettingsCatalog.title("system.testPort")) { portCheck.check(port: port, client: model.appInfo) }
                        .disabled(port <= 0 || portCheck.state == .checking || model.appInfo == nil)
                    PortCheckResultView(state: portCheck.state)
                }
                SettingFootnote(text: String(localized: """
                    Sends your IP address and listening port to portcheck.transmissionbt.com, which tries to connect back. \
                    Nothing is sent until you click.
                    """))
            }
            .setting("system.testPort")
        }
        .onChange(of: port) { portCheck.reset() }
    }

    private func summary(_ status: ConnectionStatus) -> String {
        switch status {
        case .connected: String(localized: "Connected — peers can reach you")
        case .firewalled: String(localized: "Firewalled — only outgoing connections work")
        case .disconnected: String(localized: "Offline")
        }
    }

    private func color(_ status: ConnectionStatus) -> Color {
        switch status {
        case .connected: .green
        case .firewalled: .yellow
        case .disconnected: .red
        }
    }

    private func details(port: Int64, status: SessionStatus) -> String {
        let portText = port <= 0 ? String(localized: "Any") : String(port)
        let address = [status.externalIPv4, status.externalIPv6].filter { !$0.isEmpty }.joined(separator: ", ")
        if address.isEmpty { return String(localized: "Listening port: \(portText)") }
        return String(localized: "Listening port: \(portText) · External IP: \(address)")
    }
}
