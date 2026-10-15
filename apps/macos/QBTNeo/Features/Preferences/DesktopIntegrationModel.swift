import AppKit
import Observation
import ServiceManagement
import UniformTypeIdentifiers

/// macOS integration settings that live in the system rather than in our
/// preferences: Open at Login (`SMAppService`) and the default application
/// for .torrent files and magnet links (LaunchServices).
@Observable @MainActor
final class DesktopIntegrationModel {
    /// "Open at Login" (`SMAppService.mainApp`); writing registers or unregisters.
    var opensAtLogin = false {
        didSet {
            guard opensAtLogin != oldValue, !isSyncing else { return }
            setOpensAtLogin(opensAtLogin)
        }
    }
    private(set) var isTorrentHandler = false
    private(set) var isMagnetHandler = false
    private(set) var errorMessage: String?

    @ObservationIgnored private var isSyncing = false

    private static let torrentType = UTType("org.bittorrent.torrent") ?? UTType(filenameExtension: "torrent") ?? .data

    func refresh() {
        isSyncing = true
        opensAtLogin = SMAppService.mainApp.status == .enabled
        isSyncing = false
        let me = Bundle.main.bundleURL.standardizedFileURL
        isTorrentHandler = NSWorkspace.shared.urlForApplication(toOpen: Self.torrentType)?.standardizedFileURL == me
        if let magnet = URL(string: "magnet:?xt=urn:btih:0") {
            isMagnetHandler = NSWorkspace.shared.urlForApplication(toOpen: magnet)?.standardizedFileURL == me
        }
    }

    private func setOpensAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    /// Like qBittorrent, the association can only be set, not removed.
    func becomeTorrentHandler() async {
        do {
            try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: Self.torrentType)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    func becomeMagnetHandler() async {
        do {
            try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpenURLsWithScheme: "magnet")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }
}
