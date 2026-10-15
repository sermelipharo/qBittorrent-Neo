import SwiftUI

extension View {
    /// Secondary explanatory text under a settings group or row.
    func settingsFootnote() -> some View {
        font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
