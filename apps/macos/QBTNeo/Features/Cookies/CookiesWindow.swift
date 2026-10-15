import SwiftUI

/// Tools › Manage Cookies (features.md §3.17): an editable table of the
/// download manager's cookies. Session and expired cookies are dropped by
/// the core when saving.
struct CookiesWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = CookiesModel()

    var body: some View {
        @Bindable var model = model
        Table(model.rows, selection: $model.selection, sortOrder: $model.sortOrder) {
            TableColumn("Domain", value: \.domain) { row in
                TextField("Domain", text: $model[row: row.id].domain)
            }
            .width(min: 120, ideal: 170)
            TableColumn("Path", value: \.path) { row in
                TextField("Path", text: $model[row: row.id].path)
            }
            .width(min: 50, ideal: 70)
            TableColumn("Name", value: \.name) { row in
                TextField("Name", text: $model[row: row.id].name)
            }
            .width(min: 80, ideal: 110)
            TableColumn("Value", value: \.value) { row in
                TextField("Value", text: $model[row: row.id].value)
            }
            .width(min: 100, ideal: 180)
            TableColumn("Expiration Date", value: \.expiration) { row in
                DatePicker("Expiration Date", selection: $model[row: row.id].expiration)
                    .datePickerStyle(.field)
            }
            .width(min: 150, ideal: 170)
        }
        .textFieldStyle(.plain)
        .labelsHidden()
        .onChange(of: model.sortOrder) { model.sort() }
        .onDeleteCommand(perform: model.removeSelected)
        .overlay {
            if model.rows.isEmpty {
                ContentUnavailableView("No Cookies", systemImage: "list.bullet.rectangle",
                                       description: Text("Click + to add a cookie for a tracker or website."))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CookiesBottomBar(model: model)
        }
        .frame(minWidth: FeatureDesign.Window.cookiesMin.width, minHeight: FeatureDesign.Window.cookiesMin.height)
        .navigationTitle(AppWindowID.cookies.title)
        .task(id: app.phase) { await model.load(client: app.client) }
    }
}
