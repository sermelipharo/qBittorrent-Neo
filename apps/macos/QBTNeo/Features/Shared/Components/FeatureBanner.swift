import SwiftUI

/// A warning strip at the top of a window (e.g. "Fetching of RSS feeds is
/// disabled now!") with an optional action.
struct FeatureBanner: View {
    let text: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            Image(systemName: Symbol.exclamationmarkTriangleFill)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.vertical, Design.Spacing.small)
        .background(.orange.opacity(0.12))
        .overlay(alignment: .bottom) { Divider() }
    }
}
