import SwiftUI

/// Remote › Dynamic DNS (advanced): "Update my dynamic domain name".
struct RemoteDynDNSGroup: View {
    @Bindable var model: PreferencesModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsGroup(.dynamicDNS) {
            Toggle(SettingsCatalog.title("dyndns_enabled"), isOn: $model.draft.webui.dyndnsEnabled)
                .setting("dyndns_enabled")
        } content: {
            Group {
                LabeledContent(SettingsCatalog.key("dyndns_service")) {
                    HStack {
                        Picker(SettingsCatalog.title("dyndns_service"), selection: $model.draft.webui.dyndnsService) {
                            ForEach(PreferenceChoices.dynDNSServices, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        Button("Register", action: register)
                    }
                }
                .setting("dyndns_service")
                CommitTextField(title: SettingsCatalog.key("dyndns_domain"), text: $model.draft.webui.dyndnsDomain, trims: true)
                    .setting("dyndns_domain")
                CommitTextField(title: SettingsCatalog.key("dyndns_username"), text: $model.draft.webui.dyndnsUsername, trims: true)
                    .setting("dyndns_username")
                CommitTextField(title: SettingsCatalog.key("dyndns_password"), text: $model.draft.webui.dyndnsPassword, isSecure: true)
                    .setting("dyndns_password")
            }
            .disabled(!model.draft.webui.dyndnsEnabled)
        }
    }

    private func register() {
        openURL(model.draft.webui.dyndnsService == .noIp ? PreferenceLinks.noIPRegister : PreferenceLinks.dynDNSRegister)
    }
}
