import SwiftUI

/// HTTP Sources tab (web seeds, features.md §2.6).
struct HTTPSourcesTab: View {
    let item: TorrentItem
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var properties = model.properties
        Table(properties.webSeeds, selection: $properties.webSeedSelection) {
            TableColumn("URL") { row in
                Text(row.url)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(row.url)
            }
        }
        .contextMenu(forSelectionType: String.self) { ids in
            Button("Add Web Seed…", systemImage: Symbol.plus) { model.requestAddWebSeed(item.id) }
            if !ids.isEmpty {
                Button("Remove Web Seed", systemImage: Symbol.minusCircle) { model.removeWebSeeds(item.id, urls: Array(ids)) }
                Divider()
                Button("Copy Web Seed URL", systemImage: Symbol.docOnDoc) { model.copyToPasteboard(ids.sorted().joined(separator: "\n")) }
                if ids.count == 1, let url = ids.first {
                    Button("Edit Web Seed URL…", systemImage: Symbol.pencil) { model.requestEditWebSeed(item.id, url: url) }
                }
            }
        } primaryAction: { ids in
            if ids.count == 1, let url = ids.first { model.requestEditWebSeed(item.id, url: url) }
        }
        .onDeleteCommand { model.removeWebSeeds(item.id, urls: Array(properties.webSeedSelection)) }
        .overlay {
            if properties.webSeeds.isEmpty {
                if properties.failures[.httpSources] != nil {
                    PropertiesFailureOverlay(tab: .httpSources, isEmpty: true)
                } else {
                    ContentUnavailableView {
                        Label("No HTTP Sources", systemImage: Symbol.globe)
                    } description: {
                        Text("This torrent has no web seeds.")
                    } actions: {
                        Button("Add Web Seed…") { model.requestAddWebSeed(item.id) }
                    }
                }
            }
        }
    }
}
