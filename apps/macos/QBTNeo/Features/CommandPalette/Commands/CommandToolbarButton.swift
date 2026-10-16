import SwiftUI

/// A toolbar button rendered from the command registry: same title, symbol,
/// shortcut, availability and on/off state as the command's menu item and
/// Command Palette row.
///
/// The button reads the transfer-list selection itself, and once more when it
/// is clicked: SwiftUI keeps toolbar items alive across selection changes, so
/// a context captured when the toolbar was built would act on a stale (often
/// empty) selection.
struct CommandToolbarButton: View {
    private let command: AppCommand
    private let model: AppModel
    private let label: String?

    /// - Parameter label: A shorter toolbar label; defaults to the command's
    ///   title without a trailing ellipsis.
    init(_ id: CommandID, model: AppModel, label: String? = nil) {
        command = CommandRegistry[id]
        self.model = model
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
        Button(title, systemImage: command.symbol, action: run)
            .disabled(!command.canRun(in: CommandContext(selectionOf: model)))
            .help(tooltip)
            .accessibilityValue(stateDescription)
    }

    /// Runs the command on the selection as it is at the time of the click.
    private func run() {
        let context = CommandContext(selectionOf: model)
        guard command.canRun(in: context) else { return }
        command.perform(context)
    }

    /// "On"/"Off" for switch commands (e.g. Alternative Speed Limits); empty otherwise.
    private var stateDescription: String {
        guard let isOn = command.isOn else { return "" }
        return isOn(model) ? String(localized: "On") : String(localized: "Off")
    }
}
