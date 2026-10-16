import SwiftUI

/// Color swatches for a category or tag: the default, the system palette and
/// a custom color well. The selected swatch gets a ring, like Finder's tags.
struct LabelColorPicker: View {
    @Binding var selection: LabelColor?
    let defaultColor: Color

    private static let swatch = 16.0

    var body: some View {
        HStack(alignment: .center, spacing: Design.Spacing.regular) {
            HStack(spacing: Design.Spacing.hairline) {
                swatch(color: defaultColor, title: String(localized: "Default color"), isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(LabelTint.allCases) { tint in
                    swatch(color: tint.color, title: tint.title, isSelected: selection == .system(tint)) {
                        selection = .system(tint)
                    }
                }
            }
            ColorPicker("Custom Color", selection: customColor, supportsOpacity: false)
                .labelsHidden()
                .help("Custom Color")
        }
    }

    /// The custom color well shows the current color and turns any pick into a custom color.
    private var customColor: Binding<Color> {
        Binding {
            selection?.color ?? defaultColor
        } set: { color in
            let picked = LabelColor(color)
            if picked != selection { selection = picked }
        }
    }

    private func swatch(color: Color, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: Self.swatch, height: Self.swatch)
                .overlay { Circle().strokeBorder(.black.opacity(0.15), lineWidth: 0.5) }
                .padding(2)
                .overlay {
                    if isSelected { Circle().strokeBorder(.primary.opacity(0.75), lineWidth: 1.5) }
                }
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
