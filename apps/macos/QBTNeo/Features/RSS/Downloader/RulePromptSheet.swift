import SwiftUI

/// "New rule name" / "Rule renaming" / "Rule cloning" prompt; a name conflict keeps the
/// sheet open with a warning ("Rule name conflict").
struct RulePromptSheet: View {
    let prompt: RulePrompt
    let model: RSSDownloaderModel
    @State private var conflict: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch prompt {
            case .add:
                NamePromptSheet(title: "Please type the name of the new download rule.", label: "New rule name", initial: "") { name in
                    await handle(model.addRule(named: name))
                }
            case .rename(let old):
                NamePromptSheet(title: "Please type the new rule name", label: "Rule renaming", initial: old) { name in
                    await handle(model.renameRule(old, to: name))
                }
            case .clone(let source):
                NamePromptSheet(title: "Please type the name for the clone of the download rule.", label: "Rule cloning", initial: source) { name in
                    await handle(model.cloneRule(source, to: name))
                }
            }
            if let conflict {
                InlineMessage(text: conflict)
                    .padding([.horizontal, .bottom], Design.Spacing.xLarge)
            }
        }
    }

    private func handle(_ error: String?) -> Bool {
        conflict = error
        return error == nil
    }
}
