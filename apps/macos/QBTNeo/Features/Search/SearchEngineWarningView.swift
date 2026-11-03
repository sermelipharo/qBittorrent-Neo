import SwiftUI

/// Above a tab's results: the search finished, but engines reported errors
/// (e.g. a site answering "Forbidden"). A few lines are shown; the tooltip
/// has them all.
struct SearchEngineWarningView: View {
    let warnings: [String]

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Text("Some search engines reported errors:")
                Text(warnings.joined(separator: "\n"))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }
        } icon: {
            Image(systemName: Symbol.exclamationmarkTriangleFill)
                .foregroundStyle(.orange)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.bottom, Design.Spacing.small)
        .help(warnings.joined(separator: "\n"))
        .accessibilityElement(children: .combine)
    }
}
