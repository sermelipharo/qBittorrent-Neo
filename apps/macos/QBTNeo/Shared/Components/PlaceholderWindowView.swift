import SwiftUI

/// Temporary content of windows whose feature is not built yet.
struct PlaceholderWindowView: View {
    let window: AppWindowID

    var body: some View {
        ContentUnavailableView {
            Label(window.title, systemImage: window.systemImage)
        } description: {
            Text("This window is not available yet.")
        }
        .frame(minWidth: 380, minHeight: 260)
        .navigationTitle(window.title)
    }
}
