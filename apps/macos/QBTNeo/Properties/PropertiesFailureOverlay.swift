import SwiftUI

/// Shown over a properties page when its data could not be loaded.
struct PropertiesFailureOverlay: View {
    let tab: PropertiesTab
    let isEmpty: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        if isEmpty, let failure = model.properties.failures[tab] {
            ContentUnavailableView {
                Label("\(tab.title) Unavailable", systemImage: Symbol.exclamationmarkTriangle)
            } description: {
                Text(failure)
            }
        }
    }
}
