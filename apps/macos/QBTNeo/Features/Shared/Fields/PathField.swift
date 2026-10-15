import SwiftUI

/// A labelled path row: `PathControl` in a `LabeledContent`.
struct PathField: View {
    let title: LocalizedStringKey
    @Binding var path: String
    var kind = PathKind.directory
    var placeholder: String?
    var panelMessage: String?
    var validates = true

    var body: some View {
        LabeledContent(title) {
            PathControl(
                title: title, path: $path, kind: kind, placeholder: placeholder, panelMessage: panelMessage, validates: validates
            )
        }
    }
}
