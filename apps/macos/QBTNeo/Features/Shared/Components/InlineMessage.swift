import SwiftUI

/// A short validation or status message shown under a setting.
struct InlineMessage: View {
    enum Style {
        case error
        case warning
        case info
        case success
    }

    let text: String
    var style = Style.error

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.callout)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(text)
    }

    private var symbol: String {
        switch style {
        case .error: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle"
        case .success: "checkmark.circle.fill"
        }
    }

    private var color: Color {
        switch style {
        case .error: .red
        case .warning: .orange
        case .info: .secondary
        case .success: .green
        }
    }
}
