import SwiftUI

/// "2 advanced settings on this pane are changed. Show" — shown while advanced
/// settings are hidden and some of them differ from their defaults, so a
/// hidden custom value never becomes a mystery.
struct HiddenChangesFooter: View {
    let pane: SettingsPane
    let model: PreferencesModel
    @Environment(SettingsNavigator.self) private var navigator
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        let changed = SettingsCatalog.advancedSpecs(in: pane).filter { spec in
            !navigator.shows(spec) && !(spec.check?.isDefault(model.draft, gui) ?? true)
        }
        if model.isLoaded, !changed.isEmpty {
            HStack(spacing: Design.Spacing.small) {
                Image(systemName: Symbol.infoCircle)
                    .foregroundStyle(.secondary)
                Text("\(changed.count) advanced settings on this pane are changed.")
                    .foregroundStyle(.secondary)
                Button("Show") { navigator.revealAdvanced(in: pane, scrollingTo: changed.first) }
                    .buttonStyle(.link)
            }
            .font(.callout)
            .frame(maxWidth: .infinity)
            .padding(.top, Design.Spacing.large)
        }
    }
}
