import SwiftUI

/// "Authors" tab: qBittorrent's maintainers, credited for the design,
/// behaviour and texts this application reproduces.
struct AboutAuthorsTab: View {
    var body: some View {
        Form {
            Section("Current maintainer") {
                LabeledContent("Name:", value: "Sledgehammer999")
                LabeledContent("Nationality:", value: "Greece")
                LabeledContent("E-mail:", value: "sledgehammer999@qbittorrent.org")
            }
            Section("Original author") {
                LabeledContent("Name:", value: "Christophe Dumez")
                LabeledContent("Nationality:", value: "France")
                LabeledContent("E-mail:", value: "chris@qbittorrent.org")
            }
            Section {
                Text("qBittorrent Neo is built on the work of the qBittorrent project and its contributors and translators.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }
}
