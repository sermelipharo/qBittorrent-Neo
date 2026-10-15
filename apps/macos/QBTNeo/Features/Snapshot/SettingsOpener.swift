import SwiftUI

/// Snapshot mode only: opens the Settings scene when it appears.
struct SettingsOpener: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 10, height: 10)
            .onAppear { openSettings() }
    }
}
