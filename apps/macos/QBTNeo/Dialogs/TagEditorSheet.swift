import SwiftUI

/// "Add Tag" / "Edit Tag": the tag name (new tags only), its icon and color.
struct TagEditorSheet: View {
    let request: TagEditorRequest
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var appearance = LabelAppearance()
    @State private var error: String?
    @FocusState private var nameFocused: Bool

    var body: some View {
        DialogContainer(title: isEditing ? "Edit Tag" : "Add Tag",
                        isConfirmDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                        width: Design.Window.wideDialogWidth, onConfirm: save) {
            Form {
                TextField("Tag:", text: $name)
                    .disabled(isEditing)
                    .focused($nameFocused)
                    .onSubmit(save)
                LabelAppearanceFields(kind: .tag, appearance: $appearance)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
            if let error {
                Label(error, systemImage: Symbol.exclamationmarkTriangleFill)
                    .foregroundStyle(TorrentState.error.color)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: load)
    }

    private var isEditing: Bool {
        if case .edit = request.mode { return true }
        return false
    }

    private func load() {
        switch request.mode {
        case .new:
            nameFocused = true
        case .edit(let tag):
            name = tag
            appearance = model.labels.tag(tag)
        }
    }

    private func save() {
        if let message = model.saveTag(request, name: name, appearance: appearance) {
            error = message
        } else {
            dismiss()
        }
    }
}
