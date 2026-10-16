import SwiftUI

extension EnvironmentValues {
    /// The pane's form layout; `SettingsGroup` draws its title to match.
    @Entry var settingsFormIsGrouped = false
}

/// The frame of one Settings pane: a centered column form at the fixed
/// content width, as tall as its content (so the window follows the pane) up
/// to a limit, after which it scrolls. The Advanced pane uses a grouped list
/// instead (long libtorrent labels). Scrolls to and highlights search targets
/// and lists hidden advanced settings that were changed.
struct SettingsPaneView<Header: View, Content: View>: View {
    let pane: SettingsPane
    let model: PreferencesModel
    /// Fixed height of a grouped pane (nil = column form that fits its content).
    var groupedHeight: Double?
    @ViewBuilder let header: Header
    @ViewBuilder let content: Content

    @Environment(SettingsNavigator.self) private var navigator
    @State private var contentHeight = 400.0
    @State private var highlighted: String?

    init(
        _ pane: SettingsPane, model: PreferencesModel, groupedHeight: Double? = nil,
        @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content
    ) {
        self.pane = pane
        self.model = model
        self.groupedHeight = groupedHeight
        self.header = header()
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if let groupedHeight {
                    Form {
                        header
                        content
                        HiddenChangesFooter(pane: pane, model: model)
                    }
                    .formStyle(.grouped)
                    .environment(\.settingsFormIsGrouped, true)
                    .frame(width: SettingsLayout.windowWidth, height: min(groupedHeight, SettingsLayout.maxPaneHeight))
                } else {
                    columns
                }
            }
            .environment(\.highlightedSetting, highlighted)
            .disabled(!model.isLoaded)
            .task(id: navigator.target) { await reveal(navigator.target, with: proxy) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let error = model.applyError {
                InlineMessage(text: String(localized: "Couldn't save the settings: \(error)"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Design.Spacing.medium)
                    .background(.bar)
            }
        }
    }

    private var columns: some View {
        ScrollView {
            SettingsColumn(minWidth: SettingsLayout.minColumnWidth, maxWidth: SettingsLayout.columnWidth) {
                VStack(spacing: 0) {
                    header
                    Form {
                        content
                    }
                    .formStyle(.columns)
                    .toggleStyle(WrappingCheckboxStyle())
                    HiddenChangesFooter(pane: pane, model: model)
                }
            }
            .padding(.horizontal, SettingsLayout.margin)
            .padding(.top, SettingsLayout.margin - SettingsLayout.sectionSpacing)
            .padding(.bottom, SettingsLayout.margin)
            .frame(width: SettingsLayout.windowWidth)
            .onGeometryChange(for: Double.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: SettingsLayout.windowWidth)
        .frame(height: min(max(contentHeight, SettingsLayout.minPaneHeight), SettingsLayout.maxPaneHeight))
    }

    private func reveal(_ target: SettingTarget?, with proxy: ScrollViewProxy) async {
        guard let target, target.pane == pane else { return }
        try? await Task.sleep(for: .milliseconds(200))
        let anchor = navigator.visibleAnchor(for: target.anchor)
        withAnimation { proxy.scrollTo(anchor, anchor: .center) }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation { highlighted = anchor }
        try? await Task.sleep(for: .seconds(1))
        withAnimation { highlighted = nil }
    }
}

extension SettingsPaneView where Header == EmptyView {
    init(_ pane: SettingsPane, model: PreferencesModel, groupedHeight: Double? = nil, @ViewBuilder content: () -> Content) {
        self.init(pane, model: model, groupedHeight: groupedHeight, header: { EmptyView() }, content: content)
    }
}
