import SwiftUI

/// The palette's content: search field (with the nested list's title and a
/// back button), grouped results that keep the selection in view, and a
/// footer with the keys. Drawn on the panel's material; in snapshots, on its own.
struct CommandPaletteView: View {
    let model: CommandPaletteModel
    @Environment(\.isSnapshotRendering) private var isSnapshotRendering

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            results
            Divider()
            footer
        }
        .background {
            if isSnapshotRendering {
                RoundedRectangle(cornerRadius: CommandPalettePanelController.cornerRadius)
                    .fill(.regularMaterial)
                    .shadow(radius: 24, y: 8)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(String(localized: "palette.title", defaultValue: "Command Palette",
                                        comment: "Command Palette window and menu item")))
    }

    private var header: some View {
        HStack(spacing: Design.Spacing.regular) {
            if let title = model.modeTitle {
                Button(String(localized: "Back"), systemImage: Symbol.chevronLeft) { model.back() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(String(localized: "Back"))
                Text(title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 220, alignment: .leading)
                    .padding(.horizontal, Design.Spacing.regular)
                    .padding(.vertical, Design.Spacing.hairline)
                    .background(.quaternary, in: .capsule)
            } else {
                Image(systemName: Symbol.magnifyingglass)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            PaletteSearchField(model: model)
                .frame(height: 28)
        }
        .padding(.horizontal, Design.Spacing.large)
        .padding(.vertical, Design.Spacing.medium)
    }

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(model.sections) { section in
                        Section {
                            ForEach(section.items) { item in
                                CommandPaletteRow(item: item, isSelected: item.id == model.selectedID) { model.run(item) }
                                    .id(item.id)
                            }
                        } header: {
                            Text(section.section.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Design.Spacing.regular)
                                .padding(.top, Design.Spacing.medium)
                                .padding(.bottom, Design.Spacing.tight)
                                .accessibilityAddTraits(.isHeader)
                        }
                    }
                }
                .padding(.horizontal, Design.Spacing.regular)
                .padding(.bottom, Design.Spacing.regular)
            }
            .scrollIndicators(.automatic)
            .overlay {
                if model.rows.isEmpty {
                    Text(String(localized: "No Results"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: model.selectedID) { _, id in
                guard let id else { return }
                if id == model.rows.first?.id, let first = model.sections.first {
                    proxy.scrollTo(first.id, anchor: .top)
                } else {
                    proxy.scrollTo(id)
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: Design.Spacing.large) {
            hint("↑↓", String(localized: "palette.hint.move", defaultValue: "Move", comment: "Command Palette footer: arrow keys"))
            hint("↩", String(localized: "palette.hint.run", defaultValue: "Run", comment: "Command Palette footer: Return key"))
            hint("⇥", String(localized: "palette.hint.more", defaultValue: "More Actions", comment: "Command Palette footer: Tab key"))
            hint("⌘1–9", String(localized: "palette.hint.quick", defaultValue: "Quick Run", comment: "Command Palette footer: Command-digit keys"))
            Spacer(minLength: 0)
            hint("esc", model.isNested ? String(localized: "Back") : String(localized: "Close"))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, Design.Spacing.large)
        .padding(.vertical, Design.Spacing.small)
        .accessibilityHidden(true)
    }

    private func hint(_ keys: String, _ text: String) -> some View {
        HStack(spacing: Design.Spacing.tight) {
            Text(verbatim: keys)
                .monospaced()
                .padding(.horizontal, Design.Spacing.tight)
                .background(.quaternary, in: .rect(cornerRadius: Design.Radius.small))
            Text(text)
        }
    }
}
