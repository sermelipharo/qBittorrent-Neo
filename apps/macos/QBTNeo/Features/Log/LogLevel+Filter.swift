import Foundation

extension LogLevel {
    /// `Log::MsgType` flag used by the `GUI/Log/Types` filter.
    var filterFlag: Int {
        switch self {
        case .normal: 0x1
        case .info: 0x2
        case .warning: 0x4
        case .critical: 0x8
        }
    }
}
