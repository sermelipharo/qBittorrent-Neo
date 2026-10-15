import SwiftUI

extension EnvironmentValues {
    /// True while rendering off-screen snapshots; behind-window materials
    /// (the sidebar glass) cannot be captured there, so views use opaque
    /// backgrounds instead.
    @Entry var isSnapshotRendering = false
}
