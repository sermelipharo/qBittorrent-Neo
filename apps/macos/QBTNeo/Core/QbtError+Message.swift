import Foundation

extension QbtError {
    /// The message carried by the error, without the category prefix.
    var message: String {
        switch self {
        case .NotFound(let message), .InvalidArgument(let message), .Conflict(let message),
             .Io(let message), .Network(let message), .Engine(let message),
             .Unsupported(let message), .Other(let message):
            message
        }
    }

    /// Short category title for alerts.
    var title: String {
        switch self {
        case .NotFound: String(localized: "Not found")
        case .InvalidArgument: String(localized: "Invalid argument")
        case .Conflict: String(localized: "Conflict")
        case .Io: String(localized: "I/O error")
        case .Network: String(localized: "Network error")
        case .Engine: String(localized: "Engine error")
        case .Unsupported: String(localized: "Not supported yet")
        case .Other: String(localized: "Error")
        }
    }
}

extension Error {
    /// A user-facing description for any error thrown by the core or the app.
    var userMessage: String {
        if let error = self as? QbtError { return error.message }
        return localizedDescription
    }
}
