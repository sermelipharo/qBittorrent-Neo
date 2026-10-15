import SwiftUI

/// Settings › WebUI (preferences.md §8).
struct WebUIPage: View {
    @Bindable var model: PreferencesModel
    @State private var status: WebUiStatus?

    var body: some View {
        let enabled = model.draft.webui.webUiEnabled
        Form {
            CheckableSection(title: "Web User Interface (Remote control)", isOn: $model.draft.webui.webUiEnabled) {
                WebUIStatusRow(status: status, isEnabled: enabled)
                CommitTextField(title: "IP address:", text: $model.draft.webui.webUiAddress, prompt: "*", trims: true).settingAnchor("webUI.15")
                    .help("""
                        IP address that the Web UI will bind to.
                        Specify an IPv4 or IPv6 address. You can specify "0.0.0.0" for any IPv4 address,
                        "::" for any IPv6 address, or "*" for both IPv4 and IPv6.
                        """)
                SpinField(title: "Port:", value: $model.draft.webui.webUiPort, range: 1...65_535).settingAnchor("webUI.16")
                Toggle("Use UPnP / NAT-PMP to forward the port from my router", isOn: $model.draft.webui.webUiUpnp).settingAnchor("webUI.17")
            }.settingAnchor("webUI.14")

            Group {
                CheckableSection(title: "Use HTTPS instead of HTTP", isOn: $model.draft.webui.useHttps) {
                    PathField(title: "Certificate:", path: $model.draft.webui.webUiHttpsCertPath,
                              kind: .files("cer", "crt", "pem"), panelMessage: String(localized: "Select certificate")).settingAnchor("webUI.19")
                    PathField(title: "Key:", path: $model.draft.webui.webUiHttpsKeyPath,
                              kind: .files("key", "pem"), panelMessage: String(localized: "Select private key")).settingAnchor("webUI.20")
                    Link("Information about certificates", destination: PreferenceLinks.certificates)
                }.settingAnchor("webUI.18")
                WebUIAuthenticationSection(model: model)
                CheckableSection(title: "Use alternative WebUI", isOn: $model.draft.webui.alternativeWebuiEnabled) {
                    PathField(title: "Files location:", path: $model.draft.webui.alternativeWebuiPath,
                              panelMessage: String(localized: "Choose Alternative UI files location")).settingAnchor("webUI.22")
                    if let error = model.alternativeWebUIError {
                        InlineMessage(text: error)
                    }
                    Link("List of alternative WebUI", destination: PreferenceLinks.alternativeWebUIs)
                }.settingAnchor("webUI.21")
                WebUISecuritySection(model: model)
                WebUIDynDNSSection(model: model)
            }
            .disabled(!enabled)
        }
        .task(id: StatusKey(enabled: model.applied.webui.webUiEnabled, port: model.applied.webui.webUiPort,
                            https: model.applied.webui.useHttps, hash: model.applied.webui.webUiPasswordPbkdf2)) {
            guard let client = model.appInfo else { return }
            try? await Task.sleep(for: .milliseconds(300))
            status = await CoreCall.run { client.webuiStatus() }
        }
    }

    /// Applied values that change the server state.
    private struct StatusKey: Equatable {
        let enabled: Bool
        let port: Int64
        let https: Bool
        let hash: String
    }
}
