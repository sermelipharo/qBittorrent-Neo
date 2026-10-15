import SwiftUI

/// "New rule name" / "Rule renaming" prompt; a name conflict keeps the
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
