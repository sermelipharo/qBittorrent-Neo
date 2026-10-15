import SwiftUI
import UniformTypeIdentifiers

/// The RSS Downloader window: rules | rule definition | matching articles.
struct RSSDownloaderWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openSettings) private var openSettings
    @State private var model = RSSDownloaderModel()
    @State private var isImporting = false
    @State private var export: RulesExport?

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            if !app.corePreferences.rss.rssAutoDownloadingEnabled {
                FeatureBanner(text: "Auto downloading of RSS torrents is currently disabled. You can enable it in application settings.",
                              actionTitle: "Settings…") { openSettings() }
            }
            HSplitView {
                RSSRuleListPane(model: model)
                    .frame(minWidth: 200, idealWidth: 230, maxWidth: 320)
                RSSRuleEditorPane(model: model, context: TorrentParamsContext(app: app))
                    .frame(minWidth: 460, idealWidth: 540)
                RSSMatchesPane(matches: model.matches)
                    .frame(minWidth: 220, idealWidth: 280)
            }
            HStack {
                Button("Import…") { isImporting = true }
                Menu("Export") {
                    Button("Rules (*.json)…") { startExport(legacy: false) }
                    Button("Rules (legacy) (*.rssrules)…") { startExport(legacy: true) }
                }
                .fixedSize()
                Spacer()
            }
            .padding(Design.Spacing.medium)
            .background(.bar)
            .overlay(alignment: .top) { Divider() }
        }
        .frame(minWidth: FeatureDesign.Window.rssDownloaderMin.width, minHeight: FeatureDesign.Window.rssDownloaderMin.height)
        .navigationTitle(FeatureWindowID.rssDownloader.title)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: RulesExport.types) { result in
            if case .success(let url) = result { Task { await model.importRules(from: url) } }
        }
        .fileDialogMessage(Text("Import RSS rules"))
        .fileExporter(isPresented: $export.isPresentedFlag, document: export?.document, contentType: export?.type ?? .json,
                      defaultFilename: "rss_rules") { _ in export = nil }
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .task(id: app.phase) { await model.attach(app.client) }
        .onDisappear { model.flushSave() }
    }

    private func startExport(legacy: Bool) {
        guard !model.rules.isEmpty else {
            model.alert = RSSAlert(title: String(localized: "Invalid action"), message: String(localized: "The list is empty, there is nothing to export."))
            return
        }
        model.flushSave()
        guard let data = model.exportData(legacy: legacy) else { return }
        export = RulesExport(document: RulesDocument(data: data), type: legacy ? RulesExport.legacyType : .json)
    }
}
