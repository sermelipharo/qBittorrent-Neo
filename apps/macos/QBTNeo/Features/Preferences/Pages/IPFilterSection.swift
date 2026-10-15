import SwiftUI

/// Connection › IP Filtering, the reload button and the banned IP list.
struct IPFilterSection: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @State private var isReloading = false
    @State private var notice: PreferencesNotice?
    @State private var isEditingBans = false

    var body: some View {
        Section("IP Filtering") {
            LabeledContent {
                HStack(alignment: .top, spacing: Design.Spacing.small) {
                    PathControl(
                        title: "Filter path (.dat, .p2p, .p2b):", path: $model.draft.connection.ipFilterPath,
                        kind: .files("dat", "p2p", "p2b"), panelMessage: String(localized: "Choose an IP filter file")
                    )
                    .disabled(!model.draft.connection.ipFilterEnabled)
                    Button("Reload the filter", systemImage: "arrow.clockwise", action: reload)
                        .labelStyle(.iconOnly)
                        .help("Reload the filter")
                        .disabled(isReloading || model.draft.connection.ipFilterPath.isEmpty)
                }
            } label: {
                Toggle("Filter path (.dat, .p2p, .p2b):", isOn: $model.draft.connection.ipFilterEnabled)
            }
            if isReloading {
                ProgressView("Reloading the filter…")
                    .controlSize(.small)
            } else if let notice {
                InlineMessage(text: notice.text, style: notice.isError ? .error : .success)
            }
            Toggle("Apply to trackers", isOn: $model.draft.connection.ipFilterTrackers)
                .disabled(!model.draft.connection.ipFilterEnabled)
            LabeledContent {
                Button("Manually banned IP addresses…") { isEditingBans = true }
            } label: {
                Text("^[\(model.draft.connection.bannedIps.count) banned address](inflect: true)")
                    .foregroundStyle(.secondary)
            }
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
