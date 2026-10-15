import AppKit
import SwiftUI

/// Adds a native search field at the trailing end of the Settings window's
/// pane toolbar (classic System Preferences). SwiftUI can't do it: on a
/// `Settings` scene's `TabView`, `.searchable` blanks the pane while the field
/// is idle and `.toolbar` items turn the pane buttons into a plain group, so
/// this thin wrapper around the toolbar's delegate supplies one extra
/// `NSSearchToolbarItem` and forwards everything else to SwiftUI.
/// Return opens the first result, Escape clears, ⌘F focuses (`focusRequest`).
struct SettingsToolbarSearch: NSViewRepresentable {
    @Binding var text: String
    var focusRequest: Int
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ view: InstallerView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if coordinator.item.searchField.stringValue != text { coordinator.item.searchField.stringValue = text }
        if coordinator.focusRequest != focusRequest {
            coordinator.focusRequest = focusRequest
            view.window?.makeFirstResponder(coordinator.item.searchField)
        }
        if let window = view.window { coordinator.install(in: window) }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class InstallerView: NSView {
        weak var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            MainActor.assumeIsolated { coordinator?.install(in: window) }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSToolbarDelegate, NSSearchFieldDelegate {
        static let identifier = NSToolbarItem.Identifier("SettingsSearch")
        var parent: SettingsToolbarSearch
        var focusRequest: Int
        let item = NSSearchToolbarItem(itemIdentifier: identifier)
        /// SwiftUI's toolbar delegate (the toolbar holds its delegate weakly; SwiftUI keeps it alive).
        /// Read by the Objective-C forwarding overrides, which AppKit calls on the main thread.
        nonisolated(unsafe) private weak var original: (any NSToolbarDelegate)?
        private var isInstalling = false

        init(parent: SettingsToolbarSearch) {
            self.parent = parent
            self.focusRequest = parent.focusRequest
            super.init()
            item.preferredWidthForSearchField = SettingsLayout.searchFieldWidth
            item.searchField.placeholderString = String(localized: "Search")
            item.searchField.delegate = self
            item.searchField.sendsSearchStringImmediately = true
            item.searchField.setAccessibilityLabel(String(localized: "Search settings"))
        }

        /// Wraps the toolbar's delegate once the scene has created the toolbar (retrying briefly).
        func install(in window: NSWindow) {
            guard window.toolbar?.delegate !== self, !isInstalling else { return }
            guard let toolbar = window.toolbar else {
                isInstalling = true
                Task { [weak self, weak window] in
                    for _ in 0..<30 where window?.toolbar == nil {
                        try? await Task.sleep(for: .milliseconds(50))
                    }
                    self?.isInstalling = false
                    if let window, window.toolbar != nil { self?.install(in: window) }
                }
                return
            }
            original = toolbar.delegate
            toolbar.delegate = self
            insertSearchItem(into: toolbar)
        }

        /// Appends the flexible space and the search field unless they're there.
        private func insertSearchItem(into toolbar: NSToolbar) {
            guard !toolbar.items.contains(where: { $0.itemIdentifier == Self.identifier }) else { return }
            toolbar.insertItem(withItemIdentifier: .flexibleSpace, at: toolbar.items.count)
            toolbar.insertItem(withItemIdentifier: Self.identifier, at: toolbar.items.count)
        }

        // MARK: NSToolbarDelegate (everything but the search item goes to SwiftUI)

        func toolbar(
            _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool
        ) -> NSToolbarItem? {
            if itemIdentifier == Self.identifier { return item }
            return original?.toolbar?(toolbar, itemForItemIdentifier: itemIdentifier, willBeInsertedIntoToolbar: flag)
        }

        func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            (original?.toolbarDefaultItemIdentifiers?(toolbar) ?? []) + [.flexibleSpace, Self.identifier]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            (original?.toolbarAllowedItemIdentifiers?(toolbar) ?? []) + [.flexibleSpace, Self.identifier]
        }

        func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            original?.toolbarSelectableItemIdentifiers?(toolbar) ?? []
        }

        func toolbarWillAddItem(_ notification: Notification) {
            original?.toolbarWillAddItem?(notification)
        }

        /// SwiftUI rebuilds the pane items when the scene updates and drops
        /// ours with them: put the search field back once it's done.
        func toolbarDidRemoveItem(_ notification: Notification) {
            original?.toolbarDidRemoveItem?(notification)
            let removed = notification.userInfo?["item"] as? NSToolbarItem
            guard removed === item, let toolbar = notification.object as? NSToolbar else { return }
            Task { [weak self, weak toolbar] in
                guard let self, let toolbar, toolbar.delegate === self else { return }
                if let index = toolbar.items.firstIndex(where: { $0.itemIdentifier == .flexibleSpace }), index == toolbar.items.count - 1 {
                    toolbar.removeItem(at: index)
                }
                insertSearchItem(into: toolbar)
            }
        }

        override func responds(to selector: Selector!) -> Bool {
            super.responds(to: selector) || (original?.responds(to: selector) ?? false)
        }

        override func forwardingTarget(for selector: Selector!) -> Any? {
            original?.responds(to: selector) == true ? original : super.forwardingTarget(for: selector)
        }

        // MARK: NSSearchFieldDelegate

        func controlTextDidChange(_ notification: Notification) {
            let value = item.searchField.stringValue
            if parent.text != value { parent.text = value }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                parent.text = ""
                return false
            default:
                return false
            }
        }
    }
}
