import Foundation

/// Tabs of the About window.
enum AboutTab: Hashable {
    case about
    case credits
    case license
    case software

    var title: String {
        switch self {
        case .about: String(localized: "About")
        case .credits: String(localized: "Credits")
        case .license: String(localized: "License")
        case .software: String(localized: "Software Used")
        }
    }
}
