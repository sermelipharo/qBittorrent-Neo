import UniformTypeIdentifiers

/// A pending rules export (document + chosen format).
struct RulesExport {
    static let legacyType = UTType(filenameExtension: "rssrules", conformingTo: .data) ?? .data
    static var types: [UTType] { [.json, legacyType] }

    let document: RulesDocument
    let type: UTType
}
