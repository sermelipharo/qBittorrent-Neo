import Foundation

/// Check state of a feed in "Apply Rule to Feeds:" (mixed when only some of
/// the selected rules include it).
enum FeedCheckState {
    case off
    case on
    case mixed
}
