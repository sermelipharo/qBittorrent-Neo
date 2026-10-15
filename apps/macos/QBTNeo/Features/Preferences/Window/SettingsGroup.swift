import SwiftUI

/// One section of a Settings pane in the classic Mac column layout: the
/// section title is a semibold label in the label column, on the same line
/// as the section's first control when that control has no label of its own
/// (`lead`), otherwise on its own line. Sections are separated by space.
/// An advanced section is hidden while advanced settings are off (unless
/// revealed by search).
struct SettingsGroup<Lead: View, Content: View, Footer: View>: View {
    let section: SettingsSection
    @ViewBuilder let lead: Lead
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer
    @Environment(SettingsNavigator.self) private var navigator
    @Environment(\.settingsFormIsGrouped) private var isGrouped

    init(
        _ section: SettingsSection, @ViewBuilder lead: () -> Lead, @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.section = section
        self.lead = lead()
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        if navigator.shows(section), isGrouped {
            Section {
                lead
                content
            } header: {
                title
            } footer: {
                footer
            }
        } else if navigator.shows(section) {
            Section {
                if Lead.self == EmptyView.self {
                    LabeledContent {
                        Color.clear.frame(width: 1, height: 1)
                    } label: {
                        title
                    }
                    .padding(.top, SettingsLayout.sectionSpacing)
                } else {
                    LabeledContent {
                        // The lead row's footnote goes under it, not beside it.
                        VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                            lead
                        }
                    } label: {
                        title
                    }
                    .padding(.top, SettingsLayout.sectionSpacing)
                }
                content
                footer
            }
        }
    }

    private var title: some View {
        Text(section.title)
            .fontWeight(.semibold)
            .id(section.anchor)
    }
}

extension SettingsGroup where Lead == EmptyView, Footer == EmptyView {
    init(_ section: SettingsSection, @ViewBuilder content: () -> Content) {
        self.init(section, lead: { EmptyView() }, content: content, footer: { EmptyView() })
    }
}

extension SettingsGroup where Lead == EmptyView {
    init(_ section: SettingsSection, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.init(section, lead: { EmptyView() }, content: content, footer: footer)
    }
}

extension SettingsGroup where Footer == EmptyView {
    init(_ section: SettingsSection, @ViewBuilder lead: () -> Lead, @ViewBuilder content: () -> Content) {
        self.init(section, lead: lead, content: content, footer: { EmptyView() })
    }
}
