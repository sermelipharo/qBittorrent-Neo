import Foundation

extension GUIPreferences {
    /// "Save path history length" for the Advanced page's spin field.
    var savePathHistoryLengthValue: Int64 {
        get { Int64(savePathHistoryLength) }
        set { savePathHistoryLength = Int(newValue) }
    }
}
