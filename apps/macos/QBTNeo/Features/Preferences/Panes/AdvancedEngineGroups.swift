import SwiftUI

/// Advanced › Disk & Memory (expert): libtorrent's disk settings.
struct AdvancedEngineGroups: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        SettingsGroup(.diskMemory) {
            spin("async_io_threads", $model.draft.advanced.asyncIoThreads, 1...1_024)
            spin("hashing_threads", $model.draft.advanced.hashingThreads, 1...1_024)
            spin("file_pool_size", $model.draft.advanced.filePoolSize, 1...Int64(Int32.max))
            spin("checking_memory_use", $model.draft.advanced.checkingMemoryUse, 1...1_024, unit: UnitFormatter.mib)
            spin("disk_queue_size", $model.diskQueueSizeKiB, 1...Int64(Int32.max), unit: UnitFormatter.kib, wide: true)
            Picker(SettingsCatalog.title("disk_io_type"), selection: $model.draft.advanced.diskIoType) {
                ForEach(AdvancedChoices.diskIOTypes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("disk_io_type")
            Picker(SettingsCatalog.title("disk_io_read_mode"), selection: $model.draft.advanced.diskIoReadMode) {
                ForEach(AdvancedChoices.readModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("disk_io_read_mode")
            Picker(SettingsCatalog.title("disk_io_write_mode"), selection: $model.draft.advanced.diskIoWriteMode) {
                ForEach(AdvancedChoices.writeModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("disk_io_write_mode")
            Toggle(SettingsCatalog.title("enable_piece_extent_affinity"), isOn: $model.draft.advanced.enablePieceExtentAffinity)
                .setting("enable_piece_extent_affinity")
        }
    }

    private func spin(_ id: String, _ value: Binding<Int64>, _ range: ClosedRange<Int64>, unit: String? = nil, wide: Bool = false) -> some View {
        SpinField(title: SettingsCatalog.key(id), value: value, range: range, unit: unit,
                  width: wide ? FeatureDesign.Width.wideSpinField : FeatureDesign.Width.spinField)
            .setting(id)
    }
}
