import Foundation

/// A watched folder being added (`index == nil`) or edited.
struct WatchedFolderEdit: Identifiable {
    let id = UUID()
    let index: Int?
    var folder: WatchedFolder
}
