import Foundation

/// An informational or error alert shown on the main window.
struct AppAlert: Identifiable {
    let id = UUID()
    var title: String
    var message: String
}
