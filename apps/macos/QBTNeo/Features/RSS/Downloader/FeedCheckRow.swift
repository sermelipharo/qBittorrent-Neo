import SwiftUI

/// A feed checkbox that can show a mixed state.
struct FeedCheckRow: View {
    let name: String
    let url: String
    let state: FeedCheckState
    let set: (Bool) -> Void

    var body: some View {
        Button(action: toggle) {
            Label {
                VStack(alignment: .leading, spacing: Design.Spacing.hairline) {
                    Text(name)
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(state == .off ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(state == .on ? "Checked" : (state == .mixed ? "Mixed" : "Unchecked"))
    }

    private var symbol: String {
        switch state {
        case .off: Symbol.square
        case .on: Symbol.checkmarkSquareFill
        case .mixed: Symbol.minusSquareFill
        }
    }

    private func toggle() {
        set(state != .on)
    }
}
