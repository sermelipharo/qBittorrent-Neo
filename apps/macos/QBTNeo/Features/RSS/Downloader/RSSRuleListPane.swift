import SwiftUI

/// "Download Rules": rule names with an enabled checkbox; add, rename and
/// remove; context menu as in qBittorrent.
struct RSSRuleListPane: View {
    @Bindable var model: RSSDownloaderModel
    @State private var prompt: RulePrompt?
    @State private var pendingRemoval: Set<String>?
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Download Rules")
                    .font(.headline)
                Spacer()
                ControlGroup {
                    Button("Add new rule…", systemImage: "plus") { prompt = .add }
                    Button("Delete rule", systemImage: "minus") { pendingRemoval = model.selection }
                        .disabled(model.selection.isEmpty)
                    Button("Rename rule…", systemImage: "pencil", action: renameSelected)
                        .disabled(model.selection.count != 1)
                        .help("Rename selected rule. You can also use the F2 hotkey to rename.")
                }
                .labelStyle(.iconOnly)
                .fixedSize()
            }
            .padding(Design.Spacing.medium)
            List(model.rules, id: \.name, selection: $model.selection) { rule in
                Toggle(rule.name, isOn: $model[enabled: rule.name])
                    .toggleStyle(.checkbox)
            }
            .contextMenu(forSelectionType: String.self) { names in
                Button("Add new rule…") { prompt = .add }
                if names.count == 1, let name = names.first {
                    Button("Delete rule") { pendingRemoval = [name] }
                    Divider()
                    Button("Rename rule…") { prompt = .rename(name) }
                } else if names.count > 1 {
                    Button("Delete selected rules") { pendingRemoval = names }
                }
                if !names.isEmpty {
                    Divider()
                    Button("Clear downloaded episodes…") { confirmClear = true }
                }
            } primaryAction: { names in
                if names.count == 1, let name = names.first { prompt = .rename(name) }
            }
            .onDeleteCommand { if !model.selection.isEmpty { pendingRemoval = model.selection } }
        }
        .sheet(item: $prompt) { prompt in
            RulePromptSheet(prompt: prompt, model: model)
        }
        .confirmationDialog("Rule deletion confirmation", item: $pendingRemoval) { names in
            Button("Remove", role: .destructive) { Task { await model.removeRules(names) } }
            Button("Cancel", role: .cancel) {}
        } message: { names in
            if names.count == 1, let name = names.first {
                Text("Are you sure you want to remove the download rule named '\(name)'?")
            } else {
                Text("Are you sure you want to remove the selected download rules?")
            }
        }
        .confirmationDialog("Clear downloaded episodes", isPresented: $confirmClear) {
            Button("Clear", role: .destructive) { Task { await model.clearHistory() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear the list of downloaded episodes for the selected rule?")
        }
    }

    private func renameSelected() {
        if let name = model.selection.first { prompt = .rename(name) }
    }
}
