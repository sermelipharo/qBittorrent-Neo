import SwiftUI

/// A toolbar button rendered from the command registry: same title, symbol,
/// shortcut, availability and on/off state as the command's menu item and
/// Command Palette row.
struct CommandToolbarButton: View {
    private let command: AppCommand
    private let context: CommandContext
    private let label: String?

    /// - Parameter label: A shorter toolbar label; defaults to the command's
    ///   title without a trailing ellipsis.
    init(_ id: CommandID, context: CommandContext, label: String? = nil) {
        command = CommandRegistry[id]
        self.context = context
        self.label = label
    }

    private var title: String {
        label ?? command.title.replacing(/…$/, with: "")
    }

    private var tooltip: String {
        guard let shortcut = command.shortcut else { return command.title }
        return "\(command.title) (\(shortcut.display))"
    }

    var body: some View {
        Button(title, systemImage: command.symbol) { command.perform(context) }
            .disabled(!command.canRun(in: context))
            .help(tooltip)
            .accessibilityValue(stateDescription)
    }

    /// "On"/"Off" for switch commands (e.g. Alternative Speed Limits); empty otherwise.
    private var stateDescription: String {
        guard let isOn = command.isOn else { return "" }
        return isOn(context.model) ? String(localized: "On") : String(localized: "Off")
    }
}
