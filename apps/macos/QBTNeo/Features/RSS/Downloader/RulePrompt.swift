import Foundation

/// New-rule, rename and clone prompts of the rule list.
enum RulePrompt: Identifiable {
    case add
    case rename(String)
    case clone(String)

    var id: String {
        switch self {
        case .add: "add"
        case .rename(let name): "rename-\(name)"
        case .clone(let name): "clone-\(name)"
        }
    }
}
