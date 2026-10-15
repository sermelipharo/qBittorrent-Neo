import Foundation

extension Optional {
    /// Whether a value is present; writing `false` clears it. Lets APIs
    /// that only take a Boolean (e.g. `fileExporter`) follow an optional.
    var isPresentedFlag: Bool {
        get { self != nil }
        set { if !newValue { self = nil } }
    }
}
