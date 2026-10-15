import SwiftUI

/// Snapshot of the Command Palette on a window background: empty, with a
/// query (Russian when the app runs in Russian), or a torrent's actions.
/// (The full main window cannot be hosted by the feature snapshot renderer.)
/// Uses its own palette model, so recent items are neither read nor written.
struct PaletteSnapshot: View {
    let model: AppModel
    @State private var palette: CommandPaletteModel

    init(model: AppModel, query: String, drillIn: Bool = false) {
        self.model = model
        if let torrent = model.transfers.items.first(where: { $0.name.hasPrefix("Sintel") }) {
            model.list.selection = [torrent.id]
        }
        let palette = CommandPaletteModel(persistent: false)
        palette.app = model
        palette.prepare(query: query)
        if drillIn { palette.drillIn() }
        _palette = State(initialValue: palette)
    }

    /// "st" in English, "ост" in Russian.
    static var sampleQuery: String {
        Locale.current.language.languageCode?.identifier == "ru" ? "ост" : "st"
    }

    var body: some View {
        Rectangle().fill(.background)
            .overlay(alignment: .top) {
                CommandPaletteView(model: palette)
                    .frame(width: CommandPalettePanelController.size.width, height: CommandPalettePanelController.size.height)
                    .padding(.top, 70)
            }
            .environment(\.isSnapshotRendering, true)
            .environment(model)
            .environment(model.gui)
    }
}
