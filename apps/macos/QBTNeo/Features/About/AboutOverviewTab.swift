import SwiftUI

/// "About" tab: what the application is, copyright and project links.
struct AboutOverviewTab: View {
    var body: some View {
        Form {
            Section {
                Text("An advanced BitTorrent client: qBittorrent's own core with a native SwiftUI interface.")
                Text("qBittorrent Neo is a fork of qBittorrent 5.2.4 whose Qt Widgets interface is replaced by a native macOS app.")
                    .foregroundStyle(.secondary)
                Text("Copyright © 2006-2026 The qBittorrent project")
                    .foregroundStyle(.secondary)
            }
            Section {
                LabeledContent("Home Page:") {
                    Link("https://www.qbittorrent.org", destination: AboutLinks.homePage)
                }
                LabeledContent("Forum:") {
                    Link("https://forum.qbittorrent.org", destination: AboutLinks.forum)
                }
                LabeledContent("Bug Tracker:") {
                    Link("https://bugs.qbittorrent.org", destination: AboutLinks.bugTracker)
                }
            }
        }
        .formStyle(.grouped)
    }
}
