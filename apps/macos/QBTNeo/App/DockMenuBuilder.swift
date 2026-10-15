import AppKit

/// The Dock menu (qBittorrent's desktop-integration menu without Show/Exit).
@MainActor
struct DockMenuBuilder {
    let model: AppModel

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        // While the UI is locked the Dock menu is disabled (features.md §1.3.6).
        guard !model.lock.isLocked else {
            menu.autoenablesItems = false
            let locked = NSMenuItem(title: String(localized: "qBittorrent Neo is locked"), action: nil, keyEquivalent: "")
            locked.isEnabled = false
            menu.addItem(locked)
            return menu
        }
        menu.addItem(item(String(localized: "Add Torrent File…")) { model.fileImport = .torrentFiles })
        menu.addItem(item(String(localized: "Add Torrent Link…")) { model.sheet = .addLinks(initialText: AppModel.clipboardLinks()) })
        menu.addItem(.separator())
        let alt = item(String(localized: "Alternative Speed Limits")) { model.toggleAltSpeedLimits() }
        alt.state = model.status.altSpeedEnabled ? .on : .off
        menu.addItem(alt)
        menu.addItem(item(String(localized: "Set Global Speed Limits…")) { model.sheet = .speedLimits })
        menu.addItem(.separator())
        menu.addItem(item(String(localized: "Start All Torrents")) { model.startAll() })
        menu.addItem(item(String(localized: "Stop All Torrents")) { model.stopAll() })
        return menu
    }

    private func item(_ title: String, action: @escaping @MainActor () -> Void) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(ClosureMenuTarget.invoke), keyEquivalent: "")
        let target = ClosureMenuTarget(action: action)
        item.target = target
        item.representedObject = target
        return item
    }
}
