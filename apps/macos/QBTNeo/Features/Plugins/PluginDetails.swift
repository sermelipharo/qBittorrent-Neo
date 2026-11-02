import SwiftUI

/// What the selected plugin is: its metadata and file. qBittorrent's engine
/// reports no handler list or activity counters, so those rows only appear
/// when a core provides them.
struct PluginDetails: View {
    let plugin: PluginInfo

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.tight) {
            row("Name:", plugin.name)
            if !plugin.author.isEmpty { row("Author:", plugin.author) }
            if !plugin.description.isEmpty { row("Description:", plugin.description) }
            row("File:", plugin.filePath)
            row("Size:", plugin.fileSize.formatted(.byteCount(style: .file)))
            if !plugin.sha256.isEmpty { row("SHA-256:", plugin.sha256) }
            if !plugin.handlers.isEmpty { row("Events:", plugin.handlers.formatted(.list(type: .and))) }
            if plugin.programsRun + plugin.mailsSent + plugin.failures > 0 {
                row("Activity:", String(localized: "Programs run: \(plugin.programsRun), e-mails sent: \(plugin.mailsSent), failures: \(plugin.failures)"))
            }
            if !plugin.lastError.isEmpty {
                GridRow {
                    Text("Last error:").foregroundStyle(.secondary)
                    Text(plugin.lastError).foregroundStyle(FeatureDesign.Palette.pluginDisabled).textSelection(.enabled)
                }
            }
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: LocalizedStringKey, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).textSelection(.enabled).lineLimit(2).truncationMode(.middle)
        }
    }
}
