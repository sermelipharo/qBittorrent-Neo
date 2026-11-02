import SwiftUI

/// Installed plugins: enabled rows green, disabled red; the checkbox or a
/// double-click toggles a plugin, the context menu enables/disables or
/// uninstalls (qBittorrent's `PluginsDialog` tree).
struct PluginsTable: View {
    @Bindable var model: PluginsModel

    var body: some View {
        Table(model.plugins, selection: $model.selection, sortOrder: $model.sortOrder) {
            TableColumn("ID", value: \.id) { plugin in
                Text(plugin.id).foregroundStyle(plugin.statusColor)
            }
            .width(min: 80, ideal: 150)
            TableColumn("Name", value: \.name) { plugin in
                Text(plugin.name).foregroundStyle(plugin.statusColor)
            }
            .width(min: 100, ideal: 230)
            TableColumn("Version", value: \.version) { plugin in
                Text(plugin.version).foregroundStyle(plugin.statusColor)
            }
            .width(min: 50, ideal: 60, max: 100)
            TableColumn("Invocable") { plugin in
                Text(plugin.invocableText).foregroundStyle(plugin.statusColor).help(PluginsWindow.invocableHelp)
            }
            .width(min: 60, ideal: 70, max: 110)
            TableColumn("Enabled") { plugin in
                Toggle("Enabled", isOn: Binding(
                    get: { plugin.enabled },
                    set: { value in Task { await model.setEnabled([plugin.id], value) } }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)
            }
            .width(min: 50, ideal: 60, max: 100)
        }
        .contextMenu(forSelectionType: String.self) { ids in
            let enabled = model.plugins.first { ids.contains($0.id) }?.enabled ?? false
            Toggle("Enabled", isOn: Binding(get: { enabled }, set: { value in Task { await model.setEnabled(ids, value) } }))
            Divider()
            Button("Uninstall", systemImage: Symbol.minusCircle) { Task { await model.uninstall(ids) } }
        } primaryAction: { ids in
            for id in ids { Task { await model.toggle(id) } }
        }
        .dropDestination(for: URL.self) { urls, _ in
            let paths = urls.filter(\.isFileURL).map { $0.path(percentEncoded: false) }
            Task { await model.install(paths) }
            return !paths.isEmpty
        }
    }
}
