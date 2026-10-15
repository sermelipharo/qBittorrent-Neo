import SwiftUI

extension SettingsCatalog {
    /// The row label as a title for the shared fields (already localized, shown as is).
    static func key(_ id: String) -> LocalizedStringKey {
        LocalizedStringKey(title(id))
    }
}
