import SwiftUI

/// Edit menu: Start, Stop, Remove and the queue actions (when queueing is on).
struct TransferEditCommands: View {
    let model: AppModel

    var body: some View {
        let ids = model.list.selectedIDs
        Divider()
        Button("Start", systemImage: "play.fill") { model.start(ids) }
            .keyboardShortcut("s")
            .disabled(ids.isEmpty)
        Button("Stop", systemImage: "pause.fill") { model.stop(ids) }
            .keyboardShortcut("p")
            .disabled(ids.isEmpty)
        Button("Force Start", systemImage: "forward.fill") { model.forceStart(ids) }
            .disabled(ids.isEmpty)
        Button("Remove", systemImage: "trash") { model.requestRemove(ids) }
            .keyboardShortcut(.delete)
            .disabled(ids.isEmpty)
        Button("Force Recheck", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") { model.requestRecheck(ids) }
            .keyboardShortcut("r")
            .disabled(ids.isEmpty)
        if model.queueingEnabled {
            Divider()
            Button("Top of Queue", systemImage: "arrow.up.to.line") { model.queue(ids, .top) }
                .keyboardShortcut("+", modifiers: [.command, .shift])
                .disabled(ids.isEmpty)
            Button("Move Up Queue", systemImage: "chevron.up") { model.queue(ids, .up) }
                .keyboardShortcut("+")
                .disabled(ids.isEmpty)
            Button("Move Down Queue", systemImage: "chevron.down") { model.queue(ids, .down) }
                .keyboardShortcut("-")
                .disabled(ids.isEmpty)
            Button("Bottom of Queue", systemImage: "arrow.down.to.line") { model.queue(ids, .bottom) }
                .keyboardShortcut("-", modifiers: [.command, .shift])
                .disabled(ids.isEmpty)
        }
        Divider()
        Button("Start All Torrents") { model.startAll() }
        Button("Stop All Torrents") { model.stopAll() }
    }
}
