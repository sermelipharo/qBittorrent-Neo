import SwiftUI

/// One line of secondary explanation under a Settings control (in the controls column).
struct SettingFootnote: View {
    let text: String
    var style = Style.secondary

    enum Style {
        case secondary
        case warning
    }

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(style == .warning ? AnyShapeStyle(Color.red) : AnyShapeStyle(.secondary))
            .fixedSize(horizontal: false, vertical: true)
            // No ideal width: the explanation wraps within the controls column
            // and never widens it, so the column is as wide as its controls.
            .frame(idealWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}
