import SwiftUI
import UniformTypeIdentifiers

/// Exported RSS download rules for `fileExporter`.
struct RulesDocument: FileDocument {
    static let readableContentTypes: [UTType] = RulesExport.types

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
