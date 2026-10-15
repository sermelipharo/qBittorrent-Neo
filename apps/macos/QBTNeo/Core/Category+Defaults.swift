import Foundation

extension Category {
    /// A category whose share limits follow the global settings (-2 / Default).
    init(name: String, savePath: String, downloadPath: CategoryDownloadPath) {
        self.init(
            name: name, savePath: savePath, downloadPath: downloadPath, ratioLimit: -2, seedingTimeLimit: -2,
            inactiveSeedingTimeLimit: -2, shareLimitAction: .default
        )
    }
}
