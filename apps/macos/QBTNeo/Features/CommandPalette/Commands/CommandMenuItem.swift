import SwiftUI

/// A menu item rendered from the command registry: same title, symbol,
/// shortcut and availability as the command's Command Palette row.
struct CommandMenuItem: View {
    private let command: AppCommand
    private let context: CommandContext

    init(_ id: CommandID, context: CommandContext) {
        command = CommandRegistry[id]
        self.context = context
    }

    var body: some View {
        Button(command.title, systemImage: command.symbol) { command.perform(context) }
            .keyboardShortcut(command.shortcut?.keyboardShortcut)
            .disabled(!command.canRun(in: context))
    }
}
