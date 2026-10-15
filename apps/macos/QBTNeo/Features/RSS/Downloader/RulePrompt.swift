import Foundation

/// New-rule and rename prompts of the rule list.
enum RulePrompt: Identifiable {
    case add
    case rename(String)

    var id: String {
        switch self {
        case .add: "add"
        case .rename(let name): "rename-\(name)"
        }
    }
}
