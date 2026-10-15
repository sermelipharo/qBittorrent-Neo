import SwiftUI

/// The bottom status bar (features.md §1.4): free space, external IP, DHT,
/// connection status, alternative speed toggle and the speed buttons.
/// Items size to their content; optional info items drop out when the window
/// is too narrow (DHT first, then external IP, then free space).
struct StatusBarView: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach([3, 2, 1, 0], id: \.self) { level in
                row(level: level)
            }
        }
        .font(.callout)
        .lineLimit(1)
        .frame(height: Design.Size.statusBarHeight)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .contextMenu { StatusBarMenu() }
    }

    private func row(level: Int) -> some View {
        HStack(spacing: Design.Spacing.medium) {
            StatusBarInfoItems(level: level)
            Spacer(minLength: 0)
            ConnectionStatusIndicator()
            AltSpeedToggle()
            SpeedStatusButton(direction: .download)
            SpeedStatusButton(direction: .upload)
        }
        .padding(.horizontal, Design.Spacing.medium)
    }
}
