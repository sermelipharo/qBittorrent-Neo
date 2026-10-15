import SwiftUI

/// Sidebar row: a white symbol on a tinted rounded square, like System Settings.
struct PreferencesPageLabel: View {
    let page: PreferencesPage

    var body: some View {
        Label {
            Text(page.title)
        } icon: {
            Image(systemName: page.systemImage)
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(page.tint.gradient, in: .rect(cornerRadius: Design.Radius.medium))
        }
    }
}
