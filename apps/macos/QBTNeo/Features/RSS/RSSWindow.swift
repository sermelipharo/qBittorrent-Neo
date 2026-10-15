import SwiftUI

/// The RSS Reader window: feed tree | articles | article preview.
struct RSSWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openWindow) private var openWindow
    @State private var model = RSSModel()
    /// Snapshots: open with the first article of this item selected.
    var initialSelection: String?

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            RSSFeedList(model: model)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 360)
        } content: {
            RSSArticleList(model: model)
                .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            RSSArticleView(item: model.currentArticle, showsFeed: model.showsFeedColumn) {
                if let item = model.currentArticle { model.download([item], app: app) }
            }
        }
        .searchable(text: $model.filter, placement: .toolbar, prompt: "Filter feed items…")
        .toolbar { RSSToolbar(model: model) }
        .sheet(item: $model.sheet) { sheet in
            RSSSheetView(sheet: sheet, model: model)
        }
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .confirmationDialog("Deletion confirmation", item: $model.pendingDeletion) { nodes in
            Button("Delete", role: .destructive) { Task { await model.delete(nodes) } }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Are you sure you want to delete the selected RSS feeds?")
        }
        .frame(minWidth: FeatureDesign.Window.rssMin.width, minHeight: FeatureDesign.Window.rssMin.height)
        .navigationTitle(model.totalUnread > 0 ? String(localized: "RSS (\(model.totalUnread))") : AppWindowID.rss.title)
        .task(id: app.phase) {
            await model.attach(app.client)
            if let initialSelection {
                model.selection = [initialSelection]
                model.articleSelection = Set(model.articles.prefix(1).map(\.id))
            }
        }
        .task { await model.observe(app.events()) }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                await model.reload()
            }
        }
        .onAppear { if app.openWindow == nil { app.openWindow = openWindow } }
    }
}
