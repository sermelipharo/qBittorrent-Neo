import SwiftUI

/// Draws SwiftUI controls (the default button's accent) as in the key
/// window for `ActiveSnapshotWindow` renders; otherwise leaves the state alone.
struct SnapshotKeyAppearance: ViewModifier {
    let isActive: Bool
    @Environment(\.controlActiveState) private var state

    func body(content: Content) -> some View {
        content.environment(\.controlActiveState, isActive ? .key : state)
    }
}
