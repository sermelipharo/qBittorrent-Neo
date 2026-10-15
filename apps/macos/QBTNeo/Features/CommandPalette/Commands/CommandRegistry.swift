import Foundation

/// The single list of app commands. Menus render their items from it
/// (`CommandMenuItem`) and the Command Palette searches it, so titles,
/// symbols, shortcuts and availability stay the same in both.
@MainActor
enum CommandRegistry {
    /// Every command in menu order (torrent commands first, as in the palette's actions).
    static let all: [AppCommand] = torrentCommands + appCommands

    private static let byID: [CommandID: AppCommand] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static subscript(_ id: CommandID) -> AppCommand {
        guard let command = byID[id] else { fatalError("Command \(id) is missing from CommandRegistry") }
        return command
    }

    /// Splits a localized, comma-separated keyword list.
    static func words(_ list: String) -> [String] {
        list.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    #if DEBUG
    /// Every identifier has exactly one command.
    static func verify() {
        let ids = all.map(\.id)
        assert(Set(ids).count == ids.count, "Duplicate command identifiers")
        assert(Set(ids) == Set(CommandID.allCases), "Commands missing from CommandRegistry")
    }
    #endif
}
