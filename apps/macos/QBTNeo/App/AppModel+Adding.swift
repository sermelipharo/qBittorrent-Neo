import AppKit
import SwiftUI

/// Adding torrents: .torrent files, links, drag and drop, URL scheme, paste.
extension AppModel {
    /// Adds a torrent through the "Add new torrent" dialog when it is enabled
    /// (`AddNewTorrentDialog/Enabled`), otherwise directly with the defaults.
    func add(_ source: TorrentSource) {
        guard let client else { return }
        guard gui.addTorrentDialogEnabled else {
            performAsync { _ = try await $0.addTorrent(source: source, params: .sessionDefaults) }
            return
        }
        let dialog = AddTorrentModel(source: source, client: client, app: self)
        let id = register(dialog)
        dialog.beginFetch { [weak self] metadata in
            self?.closeAddDialog(id)
            self?.handleDuplicate(metadata)
        }
        openAddDialogWindow(id)
    }

    func openAddDialogWindow(_ id: UUID) {
        if let openWindow {
            openWindow(id: AppWindowID.addTorrent.rawValue, value: id)
        } else {
            pendingAddDialogs.append(id)
        }
    }

    /// Opens dialogs requested before a window could open them (cold start from Finder).
    func flushPendingWindows() {
        guard let openWindow else { return }
        let pending = pendingAddDialogs
        pendingAddDialogs.removeAll()
        for id in pending { openWindow(id: AppWindowID.addTorrent.rawValue, value: id) }
    }

    /// Confirms and adds the torrent of an "Add new torrent" dialog.
    func accept(_ dialogID: UUID) {
        guard let dialog = addDialog(dialogID) else { return }
        dialog.storeChoices(in: gui)
        let params = dialog.makeParams()
        let source = dialog.source
        closeAddDialog(dialogID)
        performAsync { _ = try await $0.addTorrent(source: source, params: params) }
    }

    private func handleDuplicate(_ metadata: TorrentMetadataInfo) {
        guard gui.confirmMergeTrackers else {
            alert = AppAlert(title: String(localized: "Torrent is already present"),
                             message: String(localized: "Torrent '\(metadata.name)' is already in the transfer list."))
            return
        }
        if metadata.private || (transfers.item(metadata.hash)?.isPrivate ?? false) {
            alert = AppAlert(title: String(localized: "Torrent is already present"),
                             message: String(localized: "Trackers cannot be merged because it is a private torrent."))
        } else {
            confirmation = .mergeTrackers(hash: metadata.hash, name: metadata.name, trackers: metadata.trackers,
                                          urlSeeds: metadata.urlSeeds)
        }
    }

    // MARK: Sources

    func addTorrentFiles(_ urls: [URL]) {
        if let first = urls.first {
            gui.lastOpenDirectory = first.deletingLastPathComponent().path(percentEncoded: false)
        }
        for url in urls { add(.file(path: url.path(percentEncoded: false))) }
    }

    /// "Add torrent links": trimmed, de-duplicated lines.
    func addLinks(_ text: String) {
        var seen = Set<String>()
        for line in text.split(whereSeparator: \.isNewline) {
            let link = line.trimmingCharacters(in: .whitespaces)
            guard !link.isEmpty, seen.insert(link).inserted else { continue }
            add(.url(url: link))
        }
    }

    /// Files and URLs opened from Finder, the magnet scheme, or dropped.
    func open(_ urls: [URL]) {
        for url in urls {
            if url.isFileURL {
                add(.file(path: url.path(percentEncoded: false)))
            } else {
                add(.url(url: url.absoluteString))
            }
        }
    }

    /// Dropped or pasted text: every line that looks like a torrent link is added.
    @discardableResult
    func addTorrentLinks(fromText text: String) -> Bool {
        let links = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter(Self.isTorrentLink)
        for link in links {
            if link.lowercased().hasPrefix("file:"), let url = URL(string: link) {
                add(.file(path: url.path(percentEncoded: false)))
            } else if link.hasPrefix("/") {
                add(.file(path: link))
            } else {
                add(.url(url: link))
            }
        }
        return !links.isEmpty
    }

    /// ⌘V in the transfer list: links in the text, or copied .torrent files.
    func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            addTorrentFiles(urls.filter { $0.pathExtension.lowercased() == "torrent" })
        } else if let text = pasteboard.string(forType: .string) {
            addTorrentLinks(fromText: text)
        }
    }

    /// Files and links dropped on the transfer list.
    func handleDrop(_ items: [DroppedItem]) -> Bool {
        var handled = false
        for item in items {
            switch item {
            case .url(let url) where url.isFileURL:
                guard url.pathExtension.lowercased() == "torrent" else { continue }
                add(.file(path: url.path(percentEncoded: false)))
                handled = true
            case .url(let url):
                handled = addTorrentLinks(fromText: url.absoluteString) || handled
            case .text(let text):
                guard TorrentDragPayload.decode([text]).isEmpty else { continue }
                handled = addTorrentLinks(fromText: text) || handled
            }
        }
        return handled
    }

    /// Torrents dragged from the list: the whole selection when the dragged
    /// row is selected, otherwise just that row.
    func dragIDs(startingAt id: String) -> [String] {
        list.selection.contains(id) ? list.selectedIDs : [id]
    }

    /// `isTorrentLink`: magnet links, `.torrent` paths and http(s) URLs.
    static func isTorrentLink(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.hasPrefix("magnet:") || lower.hasSuffix(".torrent")
            || lower.hasPrefix("http:") || lower.hasPrefix("https:")
    }

    /// Lines the links dialog prefills from the clipboard: URLs, magnets and
    /// bare v1 (hex/base32) or v2 info hashes.
    static func isDownloadable(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.hasPrefix("magnet:") || lower.hasPrefix("http:") || lower.hasPrefix("https:")
            || lower.hasPrefix("ftp:") || lower.hasPrefix("file:") || lower.hasPrefix("data:") {
            return true
        }
        let hex = line.allSatisfy(\.isHexDigit)
        if hex, line.count == 40 || line.count == 64 { return true }
        let base32 = line.allSatisfy { ("a"..."z").contains($0.lowercased()) || ("2"..."7").contains($0) }
        return base32 && line.count == 32
    }

    /// Clipboard lines suitable for the links dialog.
    static func clipboardLinks() -> String {
        let text = NSPasteboard.general.string(forType: .string) ?? ""
        let lines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter(isDownloadable)
        return lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
    }
}
