import SwiftUI

/// "Icon:" and "Color:" rows of the category and tag editors. The icon button
/// previews the choice and opens the symbol picker.
struct LabelAppearanceFields: View {
    let kind: LabelAppearance.Kind
    @Binding var appearance: LabelAppearance
    @State private var isPickingSymbol = false

    var body: some View {
        LabeledContent("Icon:") {
            Button {
                isPickingSymbol = true
            } label: {
                Image(systemName: appearance.resolvedSymbol(kind))
                    .font(.title3)
                    .foregroundStyle(appearance.resolvedColor(kind))
                    .frame(width: 28, height: 22)
            }
            .help("Choose an icon")
            .accessibilityLabel(Text("Icon"))
            .accessibilityValue(Text(verbatim: appearance.resolvedSymbol(kind)))
            .accessibilityIdentifier("label-icon-button")
            .popover(isPresented: $isPickingSymbol, arrowEdge: .trailing) {
                SymbolPicker(selection: $appearance.symbol, defaultSymbol: kind.defaultSymbol, tint: appearance.resolvedColor(kind))
            }
        }
        LabeledContent("Color:") {
            LabelColorPicker(selection: $appearance.color, defaultColor: kind.defaultColor)
        }
    }
}
