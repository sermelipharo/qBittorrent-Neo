import SwiftUI

/// Edit menu: Start, Stop, Remove and the queue actions (when queueing is on),
/// rendered from the command registry.
struct TransferEditCommands: View {
    let model: AppModel

    var body: some View {
        let context = CommandContext(selectionOf: model)
        Divider()
        ForEach([CommandID.start, .stop, .forceStart, .remove, .forceRecheck], id: \.self) { id in
            CommandMenuItem(id, context: context)
        }
        if model.queueingEnabled {
            Divider()
            ForEach([CommandID.queueTop, .queueUp, .queueDown, .queueBottom], id: \.self) { id in
                CommandMenuItem(id, context: context)
            }
        }
        Divider()
        CommandMenuItem(.startAll, context: context)
        CommandMenuItem(.stopAll, context: context)
    }
}
