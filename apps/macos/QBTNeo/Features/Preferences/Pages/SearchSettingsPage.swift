import SwiftUI

/// Settings › Search (preferences.md §6, GUI-only settings).
struct SearchSettingsPage: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openWindow) private var openWindow
    @AppStorage(FeatureDefaults.storeSearchTabs) private var storeTabs = false
    @AppStorage(FeatureDefaults.storeSearchResults) private var storeResults = false
    @AppStorage(FeatureDefaults.searchHistoryLength) private var historyLength = 50
    @State private var status: SearchEngineStatus?

    var body: some View {
        Form {
            Section("Search UI") {
                Toggle("Store opened tabs", isOn: $storeTabs).settingAnchor("search.2")
                Toggle("Also store search results", isOn: $storeResults).settingAnchor("search.3")
                    .disabled(!storeTabs)
                    .padding(.leading, Design.Spacing.xLarge)
                LabeledContent("History length") {
                    HStack(spacing: Design.Spacing.tight) {
                        TextField("History length", value: $historyLength, format: .number)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: FeatureDesign.Width.narrowField)
                        Stepper("History length", value: $historyLength, in: 0...99)
                            .labelsHidden()
                    }
                }.settingAnchor("search.4")
                .onChange(of: historyLength) { historyLength = min(max(historyLength, 0), 99) }
            }.settingAnchor("search.1")
            Section("Search engine") {
                LabeledContent("Python:") {
                    if let status {
                        Text(status.pythonFound ? "\(status.pythonVersion) (\(status.pythonPath))" : status.message)
                            .foregroundStyle(status.pythonFound ? .primary : Color.red)
                            .textSelection(.enabled)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }.settingAnchor("search.6")
                LabeledContent {
                    Button("Search plugins…") { openWindow(id: FeatureWindowID.searchPlugins.rawValue) }
                } label: {
                    Text("The Python executable can be set on the Advanced page.")
                        .settingsFootnote()
                }
            }.settingAnchor("search.5")
        }
        .task(id: app.phase) {
            guard let client = app.client as? any SearchClient else { return }
            status = await CoreCall.run { client.searchEngineStatus() }
        }
    }
}
