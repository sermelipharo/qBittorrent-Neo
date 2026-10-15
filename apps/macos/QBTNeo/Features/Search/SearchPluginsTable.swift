import SwiftUI

/// The installed plugins table: enabled rows green, disabled red;
/// double-click toggles, the context menu enables/disables or uninstalls.
struct SearchPluginsTable: View {
    @Bindable var model: SearchPluginsModel

    var body: some View {
        Table(model.plugins, selection: $model.selection, sortOrder: $model.sortOrder) {
            TableColumn("Name", value: \.fullName) { plugin in
                Text(plugin.fullName).foregroundStyle(plugin.searchStatusColor)
            }
            TableColumn("Version", value: \.version) { plugin in
                Text(plugin.version).foregroundStyle(plugin.searchStatusColor)
            }
            .width(min: 50, ideal: 60)
            TableColumn("Url", value: \.url) { plugin in
                Text(plugin.url).foregroundStyle(plugin.searchStatusColor)
            }
            TableColumn("Enabled") { plugin in
                Text(plugin.enabled ? "Yes" : "No").foregroundStyle(plugin.searchStatusColor)
            }
            .width(min: 50, ideal: 60)
        }
        .contextMenu(forSelectionType: String.self) { names in
            let enabled = model.plugins.first { names.contains($0.name) }?.enabled ?? false
            Button(enabled ? "Disable" : "Enable") { model.setEnabled(names, !enabled) }
            Divider()
            Button("Uninstall", systemImage: Symbol.minusCircle) { Task { await model.uninstall(names) } }
        } primaryAction: { names in
            for name in names { model.toggle(name) }
        }
        .dropDestination(for: URL.self) { urls, _ in
            Task { await model.install(urls.map { $0.isFileURL ? $0.path(percentEncoded: false) : $0.absoluteString }) }
            return true
        }
    }
}
