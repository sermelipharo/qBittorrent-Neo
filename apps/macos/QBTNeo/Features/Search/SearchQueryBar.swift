import SwiftUI

/// Pattern field (with history), category and plugin pickers, Search/Stop.
struct SearchQueryBar: View {
    @Bindable var model: SearchModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            TextField("Search", text: $model.pattern, prompt: Text("A phrase to search for"))
                .textFieldStyle(.roundedBorder)
                .onSubmit(model.search)
                .help("""
                    A phrase to search for.
                    Spaces in a search term may be protected by double quotes.
                    Example:
                    foo bar: search for foo and bar
                    "foo bar": search for foo bar
                    """)
                .textInputSuggestions {
                    ForEach(model.history.reversed().filter { model.pattern.isEmpty || $0.localizedStandardContains(model.pattern) }.prefix(10),
                            id: \.self) { entry in
                        Text(entry).textInputCompletion(entry)
                    }
                }
            Picker("Category", selection: $model.category) {
                Text("All categories").tag("all")
                Divider()
                ForEach(model.categories, id: \.id) { category in
                    Text(category.name).tag(category.id)
                }
            }
            .labelsHidden()
            .fixedSize()
            Picker("Plugins", selection: $model.pluginSelector) {
                Text("Only enabled").tag("enabled")
                Text("All plugins").tag("all")
                Divider()
                ForEach(model.enabledPlugins, id: \.name) { plugin in
                    Text(plugin.fullName).tag(plugin.name)
                }
            }
            .labelsHidden()
            .fixedSize()
            if model.showsStop {
                Button("Stop", systemImage: "stop.fill", action: model.stopCurrent)
            } else {
                Button("Search", systemImage: "magnifyingglass", action: model.search)
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.plugins.isEmpty)
            }
        }
        .padding(Design.Spacing.medium)
        .disabled(model.engineStatus?.pythonFound == false)
    }
}
