import SwiftUI

/// Settings › Remote: controlling the app from a browser (Web UI). Every
/// row below the switch depends on it and appears only while it is on.
struct RemotePane: View {
    @Bindable var model: PreferencesModel
    @State private var status: WebUiStatus?

    var body: some View {
        let webui = model.draft.webui
        SettingsPaneView(.remote, model: model) {
            SettingsGroup(.webUI) {
                Toggle(SettingsCatalog.title("Preferences/WebUI/Enabled"), isOn: $model.draft.webui.webUiEnabled)
                    .setting("Preferences/WebUI/Enabled")
            } content: {
                WebUIStatusRow(status: status, isEnabled: webui.webUiEnabled)
                if let error = model.passwordRequiredError {
                    InlineMessage(text: error)
                }
            }

            if webui.webUiEnabled {
                SettingsGroup(.webUIAddress) {
                    CommitTextField(title: SettingsCatalog.key("web_ui_address"), text: $model.draft.webui.webUiAddress, prompt: "*", trims: true)
                        .help("""
                            IP address that the Web UI will bind to.
                            Specify an IPv4 or IPv6 address. You can specify "0.0.0.0" for any IPv4 address,
                            "::" for any IPv6 address, or "*" for both IPv4 and IPv6.
                            """)
                        .setting("web_ui_address")
                    SpinField(title: SettingsCatalog.key("web_ui_port"), value: $model.draft.webui.webUiPort, range: 1...65_535)
                        .setting("web_ui_port")
                    Toggle(SettingsCatalog.title("web_ui_upnp"), isOn: $model.draft.webui.webUiUpnp)
                        .setting("web_ui_upnp")
                }

                SettingsGroup(.signIn) {
                    CommitTextField(title: SettingsCatalog.key("web_ui_username"), text: $model.draft.webui.webUiUsername, trims: true)
                        .setting("web_ui_username")
                    if let error = model.usernameError {
                        InlineMessage(text: error)
                    }
                    WebUIPasswordRow(model: model)
                        .setting("web_ui_password")
                    WebUIAPIKeyRow(model: model)
                        .setting("web_ui_api_key")
                }

                SettingsGroup(.https) {
                    Toggle(SettingsCatalog.title("use_https"), isOn: $model.draft.webui.useHttps)
                        .setting("use_https")
                } content: {
                    if webui.useHttps {
                        PathField(title: SettingsCatalog.key("web_ui_https_cert_path"), path: $model.draft.webui.webUiHttpsCertPath,
                                  kind: .files("cer", "crt", "pem"), panelMessage: String(localized: "Select certificate"))
                            .setting("web_ui_https_cert_path")
                        PathField(title: SettingsCatalog.key("web_ui_https_key_path"), path: $model.draft.webui.webUiHttpsKeyPath,
                                  kind: .files("key", "pem"), panelMessage: String(localized: "Select private key"))
                            .setting("web_ui_https_key_path")
                        Link("Information about certificates", destination: PreferenceLinks.certificates)
                    }
                }

                RemoteAccessRulesGroup(model: model)

                SettingsGroup(.alternativeWebUI) {
                    Toggle(SettingsCatalog.title("alternative_webui_enabled"), isOn: $model.draft.webui.alternativeWebuiEnabled)
                        .setting("alternative_webui_enabled")
                } content: {
                    PathField(title: SettingsCatalog.key("alternative_webui_path"), path: $model.draft.webui.alternativeWebuiPath,
                              panelMessage: String(localized: "Choose Alternative UI files location"))
                        .disabled(!webui.alternativeWebuiEnabled)
                        .setting("alternative_webui_path")
                    if let error = model.alternativeWebUIError {
                        InlineMessage(text: error)
                    }
                    Link("List of alternative WebUI", destination: PreferenceLinks.alternativeWebUIs)
                }

                RemoteSecurityGroup(model: model)
                RemoteDynDNSGroup(model: model)
            }
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
