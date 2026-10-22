import SwiftUI

/// Window hosting one "Add new torrent" dialog (one window per torrent, like
/// qBittorrent on macOS). Closing the window cancels metadata retrieval.
struct AddTorrentWindow: View {
    let dialogID: UUID?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let dialogID, let dialog = model.addDialog(dialogID) {
                AddTorrentView(dialog: dialog, onAccept: {
                    model.accept(dialogID)
                    dismiss()
                }, onCancel: {
                    model.closeAddDialog(dialogID)
                    dismiss()
                })
                .navigationTitle(dialog.title)
                .onChange(of: dialog.phase) { _, phase in
                    if phase == .duplicate { dismiss() }
                }
            } else {
                ContentUnavailableView("Nothing to Add", systemImage: Symbol.docBadgePlus)
                    .frame(width: 400, height: 240)
            }
        }
        .background(WindowObserver(onVisibilityChange: { _ in }, onWindow: Self.bringToFront))
        .onDisappear {
            if let dialogID { model.closeAddDialog(dialogID) }
        }
    }

    /// A magnet link or file opened from another app also brings the main
    /// window forward as the app activates, sometimes after this window
    /// appeared; once the app is active, this window goes back on top.
    private static func bringToFront(_ window: NSWindow) {
        Task { @MainActor [weak window] in
            let deadline = ContinuousClock.now + .seconds(2)
            while !NSApp.isActive, ContinuousClock.now < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }
            try? await Task.sleep(for: .milliseconds(100))
            guard let window, window.isVisible else { return }
            window.makeKeyAndOrderFront(nil)
        }
    }
}
