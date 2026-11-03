import SwiftUI

/// Settings › Search: why the search engine can't run, with "Fix" when a
/// custom Python path is the cause (clearing it falls back to the bundled one).
struct PythonProblemRow: View {
    let status: SearchEngineStatus
    let usesCustomPath: Bool
    let fix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            InlineMessage(text: status.message, style: .warning)
                .help(status.pythonPath)
                // Wraps within the controls column instead of widening it.
                .frame(idealWidth: 0, maxWidth: .infinity, alignment: .leading)
            if usesCustomPath {
                Button("Fix", action: fix)
                    .help("Clear the Python path to use the bundled Python")
            }
        }
    }
}
