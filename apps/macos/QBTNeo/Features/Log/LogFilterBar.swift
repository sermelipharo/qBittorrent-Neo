import SwiftUI

/// Bottom bar of the Execution Log: message-type checkboxes (persisted in
/// `GUI/Log/Types`, shared with View › Log), the line count and Clear.
struct LogFilterBar: View {
    let model: ExecutionLogModel
    @Bindable var gui: GUIPreferences
    let clear: () -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.large) {
            if model.tab == .general {
                Toggle("Normal", isOn: $gui[logType: LogLevel.normal.filterFlag])
                Toggle("Information", isOn: $gui[logType: LogLevel.info.filterFlag])
                    .foregroundStyle(FeatureDesign.Palette.logInfo)
                Toggle("Warning", isOn: $gui[logType: LogLevel.warning.filterFlag])
                    .foregroundStyle(FeatureDesign.Palette.logWarning)
                Toggle("Critical", isOn: $gui[logType: LogLevel.critical.filterFlag])
                    .foregroundStyle(FeatureDesign.Palette.logCritical)
            }
            Spacer()
            Text("^[\(model.visibleLines.count) entry](inflect: true)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Button("Clear", action: clear)
                .disabled(model.visibleLines.isEmpty)
        }
        .toggleStyle(.checkbox)
        .controlSize(.small)
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.vertical, Design.Spacing.small)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
