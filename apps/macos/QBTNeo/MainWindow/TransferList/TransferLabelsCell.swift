import SwiftUI

/// The Category and Tags cells: each name with its icon in the color chosen
/// in the category/tag editor.
struct TransferLabelsCell: View {
    let names: [String]
    let kind: LabelAppearance.Kind
    let labels: LabelAppearanceStore
    let textStyle: AnyShapeStyle
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            ForEach(names, id: \.self) { name in
                let appearance = kind == .category ? labels.category(name) : labels.tag(name)
                HStack(spacing: Design.Spacing.hairline + 1) {
                    Image(systemName: appearance.resolvedSymbol(kind))
                        .imageScale(.small)
                        .foregroundStyle(prominence == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(appearance.resolvedColor(kind)))
                        .accessibilityHidden(true)
                    Text(name)
                        .foregroundStyle(textStyle)
                }
            }
        }
        .lineLimit(1)
        .help(names.joined(separator: ", "))
    }
}
