import SwiftUI

/// A form section whose header is a checkbox that enables its rows — the
/// equivalent of Qt's checkable group boxes.
struct CheckableSection<Content: View>: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    var help: LocalizedStringKey?
    @ViewBuilder let content: Content

    var body: some View {
        Section {
            content
                .disabled(!isOn)
        } header: {
            Toggle(title, isOn: $isOn)
                .toggleStyle(.checkbox)
                .help(help.map { Text($0) } ?? Text(""))
        }
    }
}
