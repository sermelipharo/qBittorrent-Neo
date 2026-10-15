import Foundation

/// Background macOS integration owned by the app delegate: power
/// management and the "On Downloads Done" actions.
@MainActor
final class SystemIntegration {
    private let power: PowerManager
    private let completion: CompletionActionController

    init(app: AppModel) {
        power = PowerManager(app: app)
        completion = CompletionActionController(app: app)
        power.start()
        completion.start()
    }
}
