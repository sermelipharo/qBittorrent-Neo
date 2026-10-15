import SwiftUI

/// Privacy › IP Filtering: the filter file with reload and rule count, and the banned IP list.
struct IPFilterGroup: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @State private var isReloading = false
    @State private var notice: PreferencesNotice?
    @State private var isEditingBans = false

    var body: some View {
        let connection = model.draft.connection
        SettingsGroup(.ipFilter) {
            LabeledContent {
                HStack(alignment: .top, spacing: Design.Spacing.small) {
                    Toggle(SettingsCatalog.title("ip_filter_enabled"), isOn: $model.draft.connection.ipFilterEnabled)
                        .labelsHidden()
                    PathControl(title: SettingsCatalog.key("ip_filter_enabled"), path: $model.draft.connection.ipFilterPath,
                                kind: .files("dat", "p2p", "p2b"), panelMessage: String(localized: "Choose an IP filter file"))
                        .disabled(!connection.ipFilterEnabled)
                    Button("Reload the filter", systemImage: Symbol.arrowClockwise, action: reload)
                        .labelStyle(.iconOnly)
                        .help("Reload the filter")
                        .disabled(isReloading || connection.ipFilterPath.isEmpty)
                }
            } label: {
                Text(SettingsCatalog.title("ip_filter_enabled"))
            }
            .setting("ip_filter_enabled")
            if isReloading {
                ProgressView("Reloading the filter…")
                    .controlSize(.small)
            } else if let notice {
                InlineMessage(text: notice.text, style: notice.isError ? .error : .success)
            }
            Toggle(SettingsCatalog.title("ip_filter_trackers"), isOn: $model.draft.connection.ipFilterTrackers)
                .disabled(!connection.ipFilterEnabled)
                .setting("ip_filter_trackers")
            HStack(spacing: Design.Spacing.regular) {
                Button(SettingsCatalog.title("banned_IPs")) { isEditingBans = true }
                Text("^[\(connection.bannedIps.count) banned address](inflect: true)")
                    .foregroundStyle(.secondary)
            }
            .setting("banned_IPs")
        }
        .sheet(isPresented: $isEditingBans) {
            BannedIPsSheet(addresses: model.draft.connection.bannedIps) { list in
                Task { await model.applyImmediately { $0.connection.bannedIps = list } }
            }
        }
    }

    /// Forces a reload like qBittorrent: clear the path, set it again (which
    /// also enables filtering), then wait for the core's parse result in the log.
    private func reload() {
        let path = model.draft.connection.ipFilterPath
        let lastID = app.log.lastID
        isReloading = true
        notice = nil
        Task {
            await model.applyImmediately {
                $0.connection.ipFilterPath = ""
                $0.connection.ipFilterEnabled = true
            }
            await model.applyImmediately { $0.connection.ipFilterPath = path }
            notice = await IPFilterReloadResult.wait(in: app.log, after: lastID)
            isReloading = false
        }
    }
}
