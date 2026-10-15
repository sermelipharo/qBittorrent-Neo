import SwiftUI

/// WebUI › "Update my dynamic domain name".
struct WebUIDynDNSSection: View {
    @Bindable var model: PreferencesModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        CheckableSection(title: "Update my dynamic domain name", isOn: $model.draft.webui.dyndnsEnabled) {
            LabeledContent("Service:") {
                HStack {
                    Picker("Service:", selection: $model.draft.webui.dyndnsService) {
                        ForEach(PreferenceChoices.dynDNSServices, id: \.self) { service in
                            Text(PreferenceChoices.title(service)).tag(service)
                        }
                    }.settingAnchor("webUI.10")
                    .labelsHidden()
                    .fixedSize()
                    Button("Register", action: register)
                }
            }.settingAnchor("webUI.9")
            CommitTextField(title: "Domain name:", text: $model.draft.webui.dyndnsDomain, trims: true).settingAnchor("webUI.11")
            CommitTextField(title: "Username:", text: $model.draft.webui.dyndnsUsername, trims: true).settingAnchor("webUI.12")
            CommitTextField(title: "Password:", text: $model.draft.webui.dyndnsPassword, isSecure: true).settingAnchor("webUI.13")
        }.settingAnchor("webUI.8")
    }

    private func register() {
        openURL(model.draft.webui.dyndnsService == .noIp ? PreferenceLinks.noIPRegister : PreferenceLinks.dynDNSRegister)
    }
}
