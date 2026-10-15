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
                    }
                    .labelsHidden()
                    .fixedSize()
                    Button("Register", action: register)
                }
            }
            CommitTextField(title: "Domain name:", text: $model.draft.webui.dyndnsDomain, trims: true)
            CommitTextField(title: "Username:", text: $model.draft.webui.dyndnsUsername, trims: true)
            CommitTextField(title: "Password:", text: $model.draft.webui.dyndnsPassword, isSecure: true)
        }
    }

    private func register() {
        openURL(model.draft.webui.dyndnsService == .noIp ? PreferenceLinks.noIPRegister : PreferenceLinks.dynDNSRegister)
    }
}
