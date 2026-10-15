import SwiftUI

/// Detail column: transfer list above the properties panel, then the status bar.
struct TransferDetailView: View {
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                TransferTable()
                    .frame(minHeight: Design.Size.transferListMinHeight)
                PropertiesPanel(availableHeight: proxy.size.height)
                if gui.statusBarDisplayed {
                    StatusBarView()
                }
            }
        }
    }
}
