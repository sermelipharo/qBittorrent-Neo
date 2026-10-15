import Foundation

/// An entry of the "Language:" picker; "" follows the system language.
struct LanguageChoice: Identifiable, Hashable {
    let code: String
    let title: String

    var id: String { code }

    /// System default plus the bundled localizations, keeping an unknown
    /// stored code selectable.
    static func choices(including current: String) -> [Self] {
        var codes = Bundle.main.localizations.filter { $0 != "Base" }
        if codes.isEmpty { codes = ["en"] }
        if !current.isEmpty, !codes.contains(current) { codes.append(current) }
        let locale = Locale.current
        let languages = codes.map { code in
            Self(code: code, title: locale.localizedString(forIdentifier: code)?.localizedCapitalized ?? code)
        }
        return [Self(code: "", title: String(localized: "System default"))] + languages.sorted { $0.title < $1.title }
    }
}
