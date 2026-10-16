import SwiftUI

/// Snapshot entries for category/tag icons and colors and for "Color by
/// state:" (`--snapshot-only labels,rowcolor`).
@MainActor
enum LabelSnapshots {
    private static let tableSize = CGSize(width: 1_180, height: 430)

    static var entries: [FeatureSnapshotCatalog.Entry] {
        var entries = [
            FeatureSnapshotCatalog.Entry(name: "labels-sidebar", title: "Sidebar", size: CGSize(width: 260, height: 900)) { model in
                applySamples(model)
                return AnyView(SidebarView().environment(\.isSnapshotRendering, true))
            },
            FeatureSnapshotCatalog.Entry(name: "labels-transfer-list", title: AppWindowID.main.title, size: tableSize) { model in
                applySamples(model)
                model.gui.stateColorScope = .wholeRow
                return AnyView(TransferTable())
            },
            FeatureSnapshotCatalog.Entry(name: "labels-cells", title: "Category and Tags cells", size: CGSize(width: 560, height: 300)) { model in
                applySamples(model)
                return AnyView(LabelCellsSnapshot(model: model))
            },
            FeatureSnapshotCatalog.Entry(name: "labels-category-editor", title: AppWindowID.main.title, size: CGSize(width: 600, height: 640)) { model in
                applySamples(model)
                let movies = model.categories.category(named: "Movies") ?? Category(name: "Movies", savePath: "", downloadPath: .default)
                return AnyView(CategoryEditorSheet(request: CategoryEditorRequest(mode: .edit(movies))))
            },
            FeatureSnapshotCatalog.Entry(name: "labels-tag-editor", title: AppWindowID.main.title, size: CGSize(width: 600, height: 300)) { model in
                applySamples(model)
                return AnyView(TagEditorSheet(request: TagEditorRequest(mode: .edit("favorite"))))
            },
            FeatureSnapshotCatalog.Entry(name: "labels-symbol-picker", title: "Icon", size: CGSize(width: 400, height: 380)) { _ in
                AnyView(SymbolPicker(selection: .constant("film.fill"), defaultSymbol: Symbol.folderFill, tint: .purple))
            },
            FeatureSnapshotCatalog.Entry(name: "labels-symbol-search", title: "Icon", size: CGSize(width: 400, height: 380)) { _ in
                AnyView(SymbolPicker(selection: .constant(nil), defaultSymbol: Symbol.tagFill, tint: .orange, initialQuery: "game"))
            },
        ]
        for scope in StateColorScope.allCases {
            entries.append(FeatureSnapshotCatalog.Entry(name: "rowcolor-\(scope.snapshotName)", title: AppWindowID.main.title,
                                                        size: tableSize) { model in
                model.gui.stateColorScope = scope
                return AnyView(TransferTable())
            })
        }
        return entries
    }

    /// Icons and colors for some of the demo categories and tags.
    static func applySamples(_ model: AppModel) {
        let samples: [(String, String, LabelColor?)] = [
            ("Movies", "film.fill", .system(.purple)),
            ("Music", "music.note", .system(.pink)),
            ("Books", "books.vertical.fill", .system(.brown)),
            ("Linux ISOs", "opticaldisc.fill", .system(.green)),
            ("Software", "shippingbox.fill", LabelColor(storage: "#2F7DD1")),
        ]
        for (name, symbol, color) in samples {
            model.labels.setCategory(name, LabelAppearance(symbol: symbol, color: color))
        }
        model.labels.setTag("favorite", LabelAppearance(symbol: "star.fill", color: .system(.yellow)))
        model.labels.setTag("4K", LabelAppearance(symbol: "sparkles", color: .system(.indigo)))
        model.labels.setTag("archive", LabelAppearance(symbol: "archivebox.fill", color: .system(.gray)))
        model.labels.setTag("work", LabelAppearance(symbol: "briefcase.fill", color: .system(.teal)))
    }
}

private extension StateColorScope {
    var snapshotName: String {
        switch self {
        case .off: "none"
        case .wholeRow: "whole-row"
        case .name: "name"
        case .progressBar: "progress"
        case .status: "status"
        }
    }
}
