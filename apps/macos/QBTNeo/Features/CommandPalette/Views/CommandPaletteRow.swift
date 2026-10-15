import SwiftUI

/// One palette row: symbol, title with a secondary line, then the on/off
/// state, the keyboard shortcut and a chevron for rows with a nested list.
/// The selected row uses the system's selected-content colors.
struct CommandPaletteRow: View {
    let item: PaletteItem
    let isSelected: Bool
    let run: () -> Void

    var body: some View {
        Button(action: run) {
            HStack(spacing: Design.Spacing.medium) {
                Image(systemName: item.symbol)
                    .imageScale(.medium)
                    .frame(width: Design.Spacing.xLarge)
                    .foregroundStyle(isSelected ? AnyShapeStyle(Self.selectedText) : AnyShapeStyle(.secondary))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(isSelected ? AnyShapeStyle(Self.selectedText.opacity(0.8)) : AnyShapeStyle(.secondary))
                    }
                }
                Spacer(minLength: Design.Spacing.regular)
                trailing
            }
            .padding(.horizontal, Design.Spacing.regular)
            .padding(.vertical, Design.Spacing.small)
            .frame(minHeight: 32)
            .foregroundStyle(isSelected ? AnyShapeStyle(Self.selectedText) : AnyShapeStyle(.primary))
            .background(isSelected ? AnyShapeStyle(Self.selectedBackground) : AnyShapeStyle(.clear),
                        in: .rect(cornerRadius: Design.Radius.large - 2))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text(accessibilityValue))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var trailing: some View {
        HStack(spacing: Design.Spacing.regular) {
            if let isOn = item.isOn {
                Image(systemName: isOn ? Symbol.checkmark : Symbol.minus)
                    .opacity(isOn ? 1 : 0.35)
                    .font(.callout)
            }
            if let shortcut = item.shortcut {
                Text(shortcut.display)
                    .font(.callout.monospaced())
                    .foregroundStyle(isSelected ? AnyShapeStyle(Self.selectedText.opacity(0.85)) : AnyShapeStyle(.secondary))
            }
            if item.hasDetail {
                Image(systemName: Symbol.chevronRight)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(Self.selectedText.opacity(0.85)) : AnyShapeStyle(.tertiary))
            }
        }
    }

    private var accessibilityLabel: String {
        [item.title, item.subtitle].compactMap(\.self).joined(separator: ", ")
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if let isOn = item.isOn { parts.append(isOn ? String(localized: "On") : String(localized: "Off")) }
        if let shortcut = item.shortcut { parts.append(shortcut.accessibilityName) }
        return parts.joined(separator: ", ")
    }

    private static let selectedBackground = Color(nsColor: .selectedContentBackgroundColor)
    private static let selectedText = Color(nsColor: .alternateSelectedControlTextColor)
}
