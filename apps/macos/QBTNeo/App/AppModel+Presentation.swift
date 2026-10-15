import Foundation

/// Bindable presentation flags and open-panel completion.
extension AppModel {
    var isAlertPresented: Bool {
        get { alert != nil }
        set { if !newValue { alert = nil } }
    }

    var isConfirmationPresented: Bool {
        get { confirmation != nil }
        set { if !newValue { confirmation = nil } }
    }

    var isFileImporterPresented: Bool {
        get { fileImport != nil }
        set { if !newValue { fileImport = nil } }
    }

    /// Start folder of the open panel.
    var fileImportDirectory: URL? {
        switch fileImport {
        case .torrentFiles: URL(filePath: gui.lastOpenDirectory, directoryHint: .isDirectory)
        case .setLocation(_, let path): path.isEmpty ? nil : URL(filePath: path, directoryHint: .isDirectory)
        case .exportTorrents, nil: nil
        }
    }

    func completeFileImport(_ result: Result<[URL], Error>) {
        guard let request = fileImport else { return }
        fileImport = nil
        switch result {
        case .success(let urls):
            switch request {
            case .torrentFiles:
                addTorrentFiles(urls)
            case .setLocation(let ids, _):
                if let folder = urls.first { setLocation(ids, to: folder) }
            case .exportTorrents(let ids):
                if let folder = urls.first { export(ids, to: folder) }
            }
        case .failure(let error):
            present(error)
        }
    }
}
