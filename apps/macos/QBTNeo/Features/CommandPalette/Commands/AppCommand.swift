import Foundation

/// One app command: everything a menu item and a Command Palette row need.
/// Commands live in `CommandRegistry`, the single list both read from.
@MainActor
struct AppCommand: Identifiable {
    /// What choosing the command in the palette does besides `perform`.
    enum Follow {
        /// Shows a nested list (category or tag picker) instead of running.
        case categories
        case tags
    }

    let id: CommandID
    /// Localized title, identical to the menu item's.
    let title: String
    /// Extra search words (localized), e.g. "pause" for Stop.
    let keywords: [String]
    let symbol: String
    let shortcut: CommandShortcut?
    /// Acts on torrents (the selection or the palette's torrent).
    let needsTargets: Bool
    /// The palette hides, and menus disable, commands that do not apply.
    private(set) var isAvailable: @MainActor (CommandContext) -> Bool = { _ in true }
    /// The current value of an on/off command (the palette shows its state).
    private(set) var isOn: (@MainActor (AppModel) -> Bool)?
    let follow: Follow?
    let perform: @MainActor (CommandContext) -> Void

    init(
        _ id: CommandID, _ title: String, symbol: String, shortcut: CommandShortcut? = nil, keywords: [String] = [],
        needsTargets: Bool = false, follow: Follow? = nil,
        perform: @escaping @MainActor (CommandContext) -> Void
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.shortcut = shortcut
        self.keywords = keywords
        self.needsTargets = needsTargets
        self.follow = follow
        self.perform = perform
    }

    /// The command with an availability rule.
    func available(_ rule: @escaping @MainActor (CommandContext) -> Bool) -> Self {
        var command = self
        command.isAvailable = rule
        return command
    }

    /// The command as an on/off switch reading its current value.
    func state(_ value: @escaping @MainActor (AppModel) -> Bool) -> Self {
        var command = self
        command.isOn = value
        return command
    }

    /// Whether the command can run now: torrent commands need targets.
    func canRun(in context: CommandContext) -> Bool {
        if needsTargets, !context.hasTargets { return false }
        return isAvailable(context)
    }
}
