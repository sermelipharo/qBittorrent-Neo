import SwiftUI

/// Menu bar commands mirroring qBittorrent's File / Edit / View / Tools / Help.
struct AppCommands: Commands {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openURL) private var openURL

    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()

        CommandGroup(replacing: .appInfo) {
            Button("About qBittorrent Neo") { openWindow(id: AppWindowID.about.rawValue) }
        }

        CommandGroup(replacing: .newItem) {
            Group {
                Button("Add Torrent File…", systemImage: Symbol.docBadgePlus) { model.fileImport = .torrentFiles }
                    .keyboardShortcut("o")
                Button("Add Torrent Link…", systemImage: Symbol.linkBadgePlus) {
                    model.sheet = .addLinks(initialText: AppModel.clipboardLinks())
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            .disabled(model.lock.isLocked)
        }

        CommandGroup(after: .pasteboard) {
            TransferEditCommands(model: model)
                .disabled(model.lock.isLocked)
        }

        CommandGroup(after: .toolbar) {
            ViewCommands(model: model, gui: model.gui)
                .disabled(model.lock.isLocked)
        }

        CommandMenu("Tools") {
            Group {
                Button("Torrent Creator", systemImage: Symbol.wandAndStars) { openWindow(id: AppWindowID.creator.rawValue) }
                    .keyboardShortcut("n")
                Divider()
                Button("Manage Cookies…") { openWindow(id: AppWindowID.cookies.rawValue) }
                Button("Options…", systemImage: Symbol.gearshape) { openSettings() }
                    .keyboardShortcut("o", modifiers: .option)
                Divider()
                Picker("On Downloads Done", selection: Bindable(model.gui).completionAction) {
                    ForEach(CompletionAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
            }
            .disabled(model.lock.isLocked)
        }

        CommandGroup(replacing: .help) {
            Button("Documentation") { openURL(URL(string: "https://doc.qbittorrent.org")!) }
                .keyboardShortcut("?")
            Divider()
            Button("Donate!") { openURL(URL(string: "https://www.qbittorrent.org/donate")!) }
        }
    }
}
