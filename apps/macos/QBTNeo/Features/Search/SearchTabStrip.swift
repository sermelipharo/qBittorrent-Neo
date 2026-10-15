import SwiftUI

/// One closable chip per search tab, with the status icon and a context menu.
struct SearchTabStrip: View {
    let model: SearchModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Design.Spacing.small) {
                ForEach(model.tabs) { tab in
                    SearchTabChip(tab: tab, isCurrent: tab.id == model.currentTabID) {
                        model.currentTabID = tab.id
                        model.pattern = tab.pattern
                    } close: {
                        model.close(tab)
                    }
                    .contextMenu {
                        if tab.status == .ongoing {
                            Button("Stop search", action: tab.stop)
                        } else {
                            Button("Refresh tab") { model.refresh(tab) }
                        }
                        Divider()
                        Button("Close tab") { model.close(tab) }
                        Button("Close all tabs", action: model.closeAll)
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
        }
        .scrollIndicators(.hidden)
    }
}
