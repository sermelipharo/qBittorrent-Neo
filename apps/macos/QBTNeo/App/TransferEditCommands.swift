import SwiftUI

/// Edit menu: Start, Stop, Remove and the queue actions (when queueing is on).
struct TransferEditCommands: View {
    let model: AppModel

    var body: some View {
        let ids = model.list.selectedIDs
        Divider()
        Button("Start", systemImage: Symbol.playFill) { model.start(ids) }
            .keyboardShortcut("s")
            .disabled(ids.isEmpty)
        Button("Stop", systemImage: Symbol.pauseFill) { model.stop(ids) }
            .keyboardShortcut("p")
            .disabled(ids.isEmpty)
        Button("Force Start", systemImage: Symbol.forwardFill) { model.forceStart(ids) }
            .disabled(ids.isEmpty)
        Button("Remove", systemImage: Symbol.trash) { model.requestRemove(ids) }
            .keyboardShortcut(.delete)
            .disabled(ids.isEmpty)
        Button("Force Recheck", systemImage: Symbol.arrowTrianglehead2ClockwiseRotate90) { model.requestRecheck(ids) }
            .keyboardShortcut("r")
            .disabled(ids.isEmpty)
        if model.queueingEnabled {
            Divider()
            Button("Top of Queue", systemImage: Symbol.arrowUpToLine) { model.queue(ids, .top) }
                .keyboardShortcut("+", modifiers: [.command, .shift])
                .disabled(ids.isEmpty)
            Button("Move Up Queue", systemImage: Symbol.chevronUp) { model.queue(ids, .up) }
                .keyboardShortcut("+")
                .disabled(ids.isEmpty)
            Button("Move Down Queue", systemImage: Symbol.chevronDown) { model.queue(ids, .down) }
                .keyboardShortcut("-")
                .disabled(ids.isEmpty)
            Button("Bottom of Queue", systemImage: Symbol.arrowDownToLine) { model.queue(ids, .bottom) }
                .keyboardShortcut("-", modifiers: [.command, .shift])
                .disabled(ids.isEmpty)
        }
        Divider()
        Button("Start All Torrents") { model.startAll() }
        Button("Stop All Torrents") { model.stopAll() }
    }
}
