import SwiftUI

/// Presents the sheet requested by the RSS model.
struct RSSSheetView: View {
    let sheet: RSSSheet
    let model: RSSModel

    var body: some View {
        switch sheet {
        case .newSubscription(let url):
            RSSFeedSheet(url: url, refreshInterval: 0) { url, interval in
                await model.addFeed(url: url, refreshInterval: interval)
            }
        case .feedOptions(let node):
            RSSFeedSheet(url: node.url, refreshInterval: node.refreshInterval) { url, interval in
                await model.setFeedOptions(node, url: url, refreshInterval: interval)
            }
        case .newFolder:
            NamePromptSheet(title: "Please choose a folder name", label: "Folder name:", initial: String(localized: "New folder")) { name in
                await model.addFolder(named: name)
                return true
            }
        case .rename(let node):
            NamePromptSheet(title: "Please choose a new name for this RSS feed", label: "New feed name:", initial: node.name) { name in
                await model.rename(node, to: name)
            }
        }
    }
}
