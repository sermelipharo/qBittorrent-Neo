import AppKit
import SwiftUI

/// Adds a native search field at the trailing end of the Settings window's
/// pane toolbar (classic System Preferences). SwiftUI can't do it: on a
/// `Settings` scene's `TabView`, `.searchable` blanks the pane while the field
/// is idle and `.toolbar` items turn the pane buttons into a plain group, so
/// this thin wrapper around the toolbar's delegate supplies one extra
/// `NSSearchToolbarItem` and forwards everything else to SwiftUI.
/// Return opens the first result, Escape clears, ⌘F focuses (`focusRequest`).
/// SwiftUI rebuilds the whole toolbar whenever the query swaps the pane for the
/// results, which removes the field from the window and ends the editing. So
/// the text reaches SwiftUI only once typing pauses, and the field takes its
/// focus and caret back when the toolbar has been rebuilt.
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
        if !coordinator.isPushPending, coordinator.item.searchField.stringValue != text { coordinator.item.searchField.stringValue = text }
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
        /// Typing pause before the query is handed to SwiftUI.
        static let typingPause = Duration.milliseconds(400)
        private var pushTask: Task<Void, Never>?
        var isPushPending: Bool { pushTask != nil }
        /// Caret of the field editor that the toolbar rebuild removed, to be put back with the focus.
        private var restoredSelection: NSRange?

        init(parent: SettingsToolbarSearch) {
            self.parent = parent
            self.focusRequest = parent.focusRequest
            super.init()
            item.preferredWidthForSearchField = SettingsLayout.searchFieldWidth
            // No caption under the field: the pane buttons carry labels, the search field doesn't need one.
            item.label = ""
            item.searchField.placeholderString = String(localized: "Search")
            item.searchField.delegate = self
            item.searchField.sendsSearchStringImmediately = false
            item.searchField.target = self
            item.searchField.action = #selector(searchFieldAction(_:))
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
            if (notification.userInfo?["item"] as? NSToolbarItem) === item, restoredSelection != nil { restoreEditing() }
        }

        /// Gives the field the keyboard focus (and caret) it had before the toolbar rebuilt itself.
        private func restoreEditing() {
            Task { [weak self] in
                for _ in 0..<40 {
                    try? await Task.sleep(for: .milliseconds(5))
                    guard let self, let selection = restoredSelection else { return }
                    guard let window = item.searchField.window else { continue }
                    restoredSelection = nil
                    guard window.makeFirstResponder(item.searchField), let editor = item.searchField.currentEditor() else { return }
                    let length = (editor.string as NSString).length
                    let location = min(selection.location, length)
                    editor.selectedRange = NSRange(location: location, length: min(selection.length, length - location))
                    return
                }
                self?.restoredSelection = nil
            }
        }

        /// SwiftUI rebuilds the pane items when the scene updates and drops
        /// ours with them: put the search field back once it's done.
        func toolbarDidRemoveItem(_ notification: Notification) {
            original?.toolbarDidRemoveItem?(notification)
            let removed = notification.userInfo?["item"] as? NSToolbarItem
            if removed === item, let editor = item.searchField.currentEditor() { restoredSelection = editor.selectedRange }
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
            pushTask?.cancel()
            pushTask = Task { [weak self] in
                try? await Task.sleep(for: Self.typingPause)
                guard !Task.isCancelled else { return }
                self?.pushText()
            }
        }

        /// The clear button and the field's delayed action.
        @objc private func searchFieldAction(_ sender: NSSearchField) {
            pushText()
        }

        /// Hands the field's text to SwiftUI now.
        private func pushText() {
            pushTask?.cancel()
            pushTask = nil
            let value = item.searchField.stringValue
            if parent.text != value { parent.text = value }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            switch selector {
            case #selector(NSResponder.insertNewline(_:)):
                pushText()
                parent.onSubmit()
                return true
            case #selector(NSResponder.cancelOperation(_:)):
                pushTask?.cancel()
                pushTask = nil
                parent.text = ""
                return false
            default:
                return false
            }
        }
    }
}
