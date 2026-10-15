import Foundation

extension AppModel {
    /// Asks for the favicon of every tracker host not tried yet this session.
    /// Does nothing unless "Download tracker's favicon" is on.
    func requestTrackerFavicons() {
        guard gui.downloadTrackerFavicon, phase == .running else { return }
        for host in trackers.sortedHosts where !favicons.hasRequested(host) {
            guard let url = trackers.urls(onHost: host).map(\.url).min() else { continue }
            favicons.request(host: host, trackerURL: url)
        }
    }
}
