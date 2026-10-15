import SwiftUI

/// Remote › Access Rules (advanced): authentication bypass and banning.
struct RemoteAccessRulesGroup: View {
    @Bindable var model: PreferencesModel
    @State private var isEditingSubnets = false

    var body: some View {
        SettingsGroup(.accessRules) {
            Toggle(SettingsCatalog.title("bypass_local_auth"), isOn: $model.draft.webui.bypassLocalAuth)
                .setting("bypass_local_auth")
        } content: {
            VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                Toggle(SettingsCatalog.title("bypass_auth_subnet_whitelist_enabled"), isOn: $model.draft.webui.bypassAuthSubnetWhitelistEnabled)
                Button("IP subnet whitelist…") { isEditingSubnets = true }
                    .disabled(!model.draft.webui.bypassAuthSubnetWhitelistEnabled)
                    .padding(.leading, SettingsLayout.indent)
                if let help = SettingsCatalog.help("bypass_auth_subnet_whitelist_enabled") {
                    SettingFootnote(text: help, style: model.draft.webui.bypassAuthSubnetWhitelistEnabled ? .warning : .secondary)
                }
            }
            .setting("bypass_auth_subnet_whitelist_enabled", help: false)
            SpinField(title: SettingsCatalog.key("web_ui_max_auth_fail_count"), value: $model.draft.webui.webUiMaxAuthFailCount,
                      range: 0...Int64(Int32.max), special: .text(String(localized: "Never")))
                .setting("web_ui_max_auth_fail_count")
            SpinField(title: SettingsCatalog.key("web_ui_ban_duration"), value: $model.draft.webui.webUiBanDuration, range: 1...Int64(Int32.max),
                      unit: String(localized: "sec"), width: FeatureDesign.Width.wideSpinField)
                .setting("web_ui_ban_duration")
            SpinField(title: SettingsCatalog.key("web_ui_session_timeout"), value: $model.draft.webui.webUiSessionTimeout,
                      range: 0...Int64(Int32.max), unit: String(localized: "sec"), special: .text(String(localized: "Disabled")),
                      width: FeatureDesign.Width.wideSpinField)
                .setting("web_ui_session_timeout")
        }
        .sheet(isPresented: $isEditingSubnets) {
            TrustedSubnetsSheet(subnets: model.draft.webui.bypassAuthSubnetWhitelist) { list in
                Task { await model.applyImmediately { $0.webui.bypassAuthSubnetWhitelist = list } }
            }
        }
    }
}
