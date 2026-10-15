import SwiftUI

/// The Execution Log window (View › Log, features.md §3.15): "General"
/// messages with a level filter and "Blocked IPs".
struct ExecutionLogWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(GUIPreferences.self) private var gui
    @State private var model = ExecutionLogModel()

    var body: some View {
        @Bindable var model = model
        List(model.visibleLines, selection: $model.selection) { line in
            LogLineRow(line: line)
        }
        .listStyle(.inset)
        .alternatingRowBackgrounds(gui.alternatingRowColors ? .enabled : .disabled)
        .contextMenu(forSelectionType: Int64.self) { ids in
            Button("Copy", systemImage: "doc.on.doc", action: model.copySelection)
                .disabled(ids.isEmpty)
            Button("Clear", systemImage: "trash", action: clear)
        }
        .onCopyCommand(perform: copyItems)
        .overlay {
            if model.visibleLines.isEmpty {
                ContentUnavailableView(
                    model.tab == .general ? "No Messages" : "No Blocked IPs",
                    systemImage: model.tab == .general ? "text.alignleft" : "hand.raised",
                    description: Text(model.query.isEmpty ? "New entries appear here as they are logged." : "No messages match the search.")
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LogFilterBar(model: model, gui: gui, clear: clear)
        }
        .searchable(text: $model.query, placement: .toolbar, prompt: "Filter messages")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Log", selection: $model.tab) {
                    ForEach(ExecutionLogTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .frame(minWidth: FeatureDesign.Window.logMin.width, minHeight: FeatureDesign.Window.logMin.height)
        .navigationTitle(AppWindowID.log.title)
        .task(id: LogFilterKey(lastID: app.log.lastID, count: app.log.messages.count, types: gui.logTypes, query: model.query)) {
            model.rebuild(from: app.log.messages, types: gui.logTypes)
        }
        .task(id: model.tab) {
            guard model.tab == .blockedIPs else { return }
            await model.pollBlockedPeers(client: app.client)
        }
    }

    private func clear() {
        model.clear(store: app.log)
    }

    private func copyItems() -> [NSItemProvider] {
        let text = model.visibleLines.filter { model.selection.contains($0.id) }.map(\.copyText).joined(separator: "\n")
        return text.isEmpty ? [] : [NSItemProvider(object: text as NSString)]
    }
}
