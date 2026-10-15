import Foundation

/// Tabs of the About window.
enum AboutTab: Hashable {
    case about
    case authors
    case license
    case software

    var title: String {
        switch self {
        case .about: String(localized: "About")
        case .authors: String(localized: "Authors")
        case .license: String(localized: "License")
        case .software: String(localized: "Software Used")
        }
    }
}
