import SwiftUI

/// A searchable grid of SF Symbols: the curated set when the search field is
/// empty, matches from every bundled symbol name otherwise.
struct SymbolPicker: View {
    @Binding var selection: String?
    let defaultSymbol: String
    let tint: Color
    /// Search text to start with (snapshots).
    var initialQuery = ""
    @State private var model = SymbolPickerModel()
    @Environment(\.dismiss) private var dismiss

    private static let cell = 32.0
    private let columns = [GridItem(.adaptive(minimum: cell, maximum: cell), spacing: Design.Spacing.small)]

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.regular) {
            TextField("Search symbols", text: $model.query, prompt: Text("Search symbols"))
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
            ScrollView {
                if model.results.isEmpty {
                    Text("No symbols match “\(model.query)”.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    LazyVGrid(columns: columns, spacing: Design.Spacing.small) {
                        ForEach(model.results, id: \.self) { name in
                            symbolButton(name)
                        }
                    }
                    .padding(Design.Spacing.hairline)
                }
            }
            .frame(height: 240)
            HStack {
                Button("Use Default") { choose(nil) }
                    .disabled(selection == nil)
                Spacer()
                Text(selection ?? defaultSymbol)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(Design.Spacing.medium)
        .frame(width: 380)
        .onAppear {
            if !initialQuery.isEmpty { model.query = initialQuery }
        }
    }

    private func symbolButton(_ name: String) -> some View {
        let isSelected = (selection ?? defaultSymbol) == name
        return Button { choose(name) } label: {
            Image(systemName: name)
                .font(.title3)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
                .frame(width: Self.cell, height: Self.cell)
                .background(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(.quaternary.opacity(0.5)),
                            in: .rect(cornerRadius: Design.Radius.small * 2))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help(name)
        .accessibilityLabel(Text(verbatim: name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func choose(_ name: String?) {
        selection = name == defaultSymbol ? nil : name
        dismiss()
    }
}
