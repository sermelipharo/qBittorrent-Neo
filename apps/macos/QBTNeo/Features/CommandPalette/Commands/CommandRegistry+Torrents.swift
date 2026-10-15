import Foundation

/// Commands acting on torrents (Edit menu, toolbar, context menu).
extension CommandRegistry {
    static var torrentCommands: [AppCommand] {
        let queueWords = words(String(localized: "palette.keywords.queue", defaultValue: "queue, priority",
                                      comment: "Command Palette search words, comma-separated"))
        return [
            AppCommand(.start, String(localized: "Start"), symbol: Symbol.playFill, shortcut: CommandShortcut("s"),
                       keywords: words(String(localized: "palette.keywords.start", defaultValue: "resume, play, run",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.start($0.ids) }
                .available { $0.selection.needsStart },
            AppCommand(.stop, String(localized: "Stop"), symbol: Symbol.pauseFill, shortcut: CommandShortcut("p"),
                       keywords: words(String(localized: "palette.keywords.stop", defaultValue: "pause, halt",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.stop($0.ids) }
                .available { $0.selection.needsStop },
            AppCommand(.forceStart, String(localized: "Force Start"), symbol: Symbol.forwardFill,
                       needsTargets: true) { $0.model.forceStart($0.ids) }
                .available { $0.selection.needsForce },
            AppCommand(.remove, String(localized: "Remove"), symbol: Symbol.trash, shortcut: CommandShortcut(.delete),
                       keywords: words(String(localized: "palette.keywords.remove", defaultValue: "delete, trash",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.requestRemove($0.ids) },
            AppCommand(.forceRecheck, String(localized: "Force Recheck"), symbol: Symbol.arrowTrianglehead2ClockwiseRotate90,
                       shortcut: CommandShortcut("r"),
                       keywords: words(String(localized: "palette.keywords.recheck", defaultValue: "verify, check, hash",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.requestRecheck($0.ids) }
                .available { $0.selection.hasMetadata },
            AppCommand(.forceReannounce, String(localized: "Force Reannounce"), symbol: Symbol.arrowClockwise,
                       keywords: words(String(localized: "palette.keywords.reannounce", defaultValue: "announce, tracker, update",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.reannounce($0.ids) }
                .available { $0.selection.canReannounce },
            AppCommand(.setLocation, String(localized: "Set Location…"), symbol: Symbol.folder,
                       keywords: words(String(localized: "palette.keywords.location", defaultValue: "move, save path, folder",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.requestSetLocation($0.ids) },
            AppCommand(.rename, String(localized: "Rename…"), symbol: Symbol.pencil,
                       needsTargets: true) { $0.model.requestRename($0.ids[0]) }
                .available { $0.ids.count == 1 },
            AppCommand(.editTrackers, String(localized: "Edit Trackers…"), symbol: Symbol.antennaRadiowavesLeftAndRight,
                       needsTargets: true) { $0.model.sheet = .editTrackers(ids: $0.ids) },
            AppCommand(.setCategory, String(localized: "Category"), symbol: Symbol.folder, needsTargets: true, follow: .categories) { _ in },
            AppCommand(.editTags, String(localized: "Tags"), symbol: Symbol.tag, needsTargets: true, follow: .tags) { _ in },
            AppCommand(.torrentOptions, String(localized: "Torrent Options…"), symbol: Symbol.sliderHorizontal3,
                       keywords: words(String(localized: "palette.keywords.options", defaultValue: "limits, ratio, speed",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.sheet = .torrentOptions(ids: $0.ids) },
            AppCommand(.previewFile, String(localized: "Preview File…"), symbol: Symbol.eye,
                       needsTargets: true) { context in
                if let item = context.selection.items.first(where: \.hasMetadata) { context.model.requestPreview(item.id) }
            }
            .available { $0.selection.hasMetadata },
            AppCommand(.openDestination, String(localized: "Open Destination Folder"), symbol: Symbol.folderBadgeGearshape,
                       keywords: words(String(localized: "palette.keywords.reveal", defaultValue: "reveal, finder, show",
                                              comment: "Command Palette search words, comma-separated")),
                       needsTargets: true) { $0.model.openDestination($0.ids) },
            AppCommand(.exportTorrent, String(localized: "Export .torrent…"), symbol: Symbol.squareAndArrowUp,
                       needsTargets: true) { $0.model.requestExport($0.ids) },
            AppCommand(.queueTop, String(localized: "Top of Queue"), symbol: Symbol.arrowUpToLine,
                       shortcut: CommandShortcut("+", [.command, .shift]), keywords: queueWords, needsTargets: true) { $0.model.queue($0.ids, .top) }
                .available { $0.model.queueingEnabled },
            AppCommand(.queueUp, String(localized: "Move Up Queue"), symbol: Symbol.chevronUp,
                       shortcut: CommandShortcut("+"), keywords: queueWords, needsTargets: true) { $0.model.queue($0.ids, .up) }
                .available { $0.model.queueingEnabled },
            AppCommand(.queueDown, String(localized: "Move Down Queue"), symbol: Symbol.chevronDown,
                       shortcut: CommandShortcut("-"), keywords: queueWords, needsTargets: true) { $0.model.queue($0.ids, .down) }
                .available { $0.model.queueingEnabled },
            AppCommand(.queueBottom, String(localized: "Bottom of Queue"), symbol: Symbol.arrowDownToLine,
                       shortcut: CommandShortcut("-", [.command, .shift]), keywords: queueWords, needsTargets: true) { $0.model.queue($0.ids, .bottom) }
                .available { $0.model.queueingEnabled },
            AppCommand(.startAll, String(localized: "Start All Torrents"), symbol: Symbol.playFill) { $0.model.startAll() }
                .available { !$0.model.transfers.items.isEmpty },
            AppCommand(.stopAll, String(localized: "Stop All Torrents"), symbol: Symbol.pauseFill) { $0.model.stopAll() }
                .available { !$0.model.transfers.items.isEmpty },
        ]
    }
}
