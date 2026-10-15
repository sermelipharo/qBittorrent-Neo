import Foundation

/// The list the palette shows: everything, or a nested list reached with
/// Tab / → / Return on a row that has one.
enum PaletteMode: Equatable {
    case root
    /// The actions for one torrent.
    case torrent(String)
    /// Category picker for the targets.
    case categories([String])
    /// Tag picker for the targets.
    case tags([String])
}
