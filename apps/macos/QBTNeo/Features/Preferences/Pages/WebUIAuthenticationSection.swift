import SwiftUI

/// WebUI › Authentication: credentials, API key, bypass rules and banning.
struct WebUIAuthenticationSection: View {
    @Bindable var model: PreferencesModel
    @State private var isEditingSubnets = false

    var body: some View {
        Section("Authentication") {
            CommitTextField(title: "Username:", text: $model.draft.webui.webUiUsername, trims: true)
            if let error = model.usernameError {
                InlineMessage(text: error)
            }
            WebUIPasswordRow(model: model)
            WebUIAPIKeyRow(model: model)
            Toggle("Bypass authentication for clients on localhost", isOn: $model.draft.webui.bypassLocalAuth)
            LabeledContent {
                Button("IP subnet whitelist…") { isEditingSubnets = true }
                    .disabled(!model.draft.webui.bypassAuthSubnetWhitelistEnabled)
            } label: {
                Toggle("Bypass authentication for clients in whitelisted IP subnets",
                       isOn: $model.draft.webui.bypassAuthSubnetWhitelistEnabled)
            }
            SpinField(title: "Ban client after consecutive failures:", value: $model.draft.webui.webUiMaxAuthFailCount,
                      range: 0...Int64(Int32.max), special: .text(String(localized: "Never")))
            SpinField(title: "ban for:", value: $model.draft.webui.webUiBanDuration, range: 1...Int64(Int32.max),
                      unit: String(localized: "sec"), width: FeatureDesign.Width.wideSpinField)
            SpinField(title: "Session timeout:", value: $model.draft.webui.webUiSessionTimeout, range: 0...Int64(Int32.max),
                      unit: String(localized: "sec"), special: .text(String(localized: "Disabled")), width: FeatureDesign.Width.wideSpinField)
        }
        .sheet(isPresented: $isEditingSubnets) {
            TrustedSubnetsSheet(subnets: model.draft.webui.bypassAuthSubnetWhitelist) { list in
                Task { await model.applyImmediately { $0.webui.bypassAuthSubnetWhitelist = list } }
            }
        }
    }
}
