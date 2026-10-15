import SwiftUI
import UniformTypeIdentifiers

/// A .torrent file for `fileExporter` ("Save as .torrent file…").
struct TorrentFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.torrent]
    var data: Data

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
