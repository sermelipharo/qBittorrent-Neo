import SwiftUI

/// Sheets, alerts, confirmations and open panels of the main window.
struct MainPresentations: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        @Bindable var model = model
        content
            .sheet(item: $model.sheet) { sheet in
                MainSheetContent(sheet: sheet)
                    .environment(model)
                    .environment(model.gui)
            }
            .alert(model.alert?.title ?? "", isPresented: $model.isAlertPresented, presenting: model.alert) { _ in
                Button("OK") {}
            } message: { alert in
                Text(alert.message)
            }
            .confirmationDialog(model.confirmation?.title ?? "", isPresented: $model.isConfirmationPresented,
                                presenting: model.confirmation) { confirmation in
                Button(confirmation.confirmTitle, role: confirmation.isDestructive ? .destructive : nil) {
                    model.confirm(confirmation)
                }
                Button("Cancel", role: .cancel) {}
            } message: { confirmation in
                Text(confirmation.message)
            }
            .fileImporter(
                isPresented: $model.isFileImporterPresented,
                allowedContentTypes: model.fileImport?.contentTypes ?? [.item],
                allowsMultipleSelection: model.fileImport?.allowsMultipleSelection ?? false
            ) { result in
                model.completeFileImport(result)
            }
            .fileDialogDefaultDirectory(model.fileImportDirectory)
    }
}
