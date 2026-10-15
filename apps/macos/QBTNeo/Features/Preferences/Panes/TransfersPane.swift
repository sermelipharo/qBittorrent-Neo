import SwiftUI

/// Settings › Transfers: where downloads go, how torrents are added and when
/// seeding stops, in four segments (Adding · Files · Seeding & Queue · Search & RSS).
struct TransfersPane: View {
    @Bindable var model: PreferencesModel
    @Environment(SettingsNavigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        SettingsPaneView(.transfers, model: model) {
            Picker("Transfers", selection: $navigator.segment) {
                ForEach(TransfersSegment.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.top, SettingsLayout.sectionSpacing)
            .padding(.bottom, Design.Spacing.small)
        } content: {
            switch navigator.segment {
            case .adding: TransfersAddingSegment(model: model)
            case .files: TransfersFilesSegment(model: model)
            case .seedingQueue: TransfersSeedingSegment(model: model)
            case .searchRSS: TransfersSearchRSSSegment(model: model)
            }
        }
    }
}
