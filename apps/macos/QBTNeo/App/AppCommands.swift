import SwiftUI

/// Menu bar commands mirroring qBittorrent's File / Edit / View / Tools / Help.
struct AppCommands: Commands {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()

        CommandGroup(replacing: .appInfo) {
            Button("About qBittorrent Neo") { openWindow(id: AppWindowID.about.rawValue) }
            if model.updater.isAvailable {
                Button("Check for Updates…") { model.updater.checkForUpdates() }
            }
        }

        CommandGroup(replacing: .newItem) {
            let context = CommandContext(model: model, ids: [])
            Group {
                CommandMenuItem(.addTorrentFile, context: context)
                CommandMenuItem(.addTorrentLink, context: context)
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
            let context = CommandContext(model: model, ids: [])
            Group {
                CommandMenuItem(.torrentCreator, context: context)
                Divider()
                CommandMenuItem(.manageCookies, context: context)
                CommandMenuItem(.options, context: context)
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
            CommandMenuItem(.documentation, context: CommandContext(model: model, ids: []))
            Divider()
            Button("Donate!") { openURL(URL(string: "https://www.qbittorrent.org/donate")!) }
        }
    }
}
