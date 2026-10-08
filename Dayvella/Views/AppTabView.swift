import SwiftUI
import UniformTypeIdentifiers

struct AppTabView: View {
    @EnvironmentObject private var store: EntryStore

    @State private var showImporter = false
    @State private var importSummary: ImportService.Summary?
    @State private var showImportSummary = false
    @State private var exportedFile: ExportedFile?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showSettings = false

    private var adaptiveSheetDetents: Set<PresentationDetent> {
        [.large]
    }

    private var adaptiveSheetCornerRadius: CGFloat {
        24
    }

    var body: some View {
        tabView
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], onCompletion: handleFileImport)
        .sheet(isPresented: $showImportSummary, content: importSummarySheet)
        .sheet(item: $exportedFile) { file in
            shareSheet(for: file.url)
        }
        .sheet(isPresented: $showSettings, content: settingsSheet)
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { showErrorAlert = false }
        }, message: {
            Text(errorMessage)
        })
    }

    private var tabView: some View {
        TabView {
            Tab("All", systemImage: "square.grid.2x2") {
                HomeView(initialFilter: .all,
                         showsFilterPicker: false,
                         allowsSearch: false,
                         onShowSettings: { showSettings = true })
            }

            Tab("Pinned", systemImage: "pin") {
                HomeView(initialFilter: .pinned,
                         showsFilterPicker: false,
                         allowsSearch: false,
                         onShowSettings: { showSettings = true })
            }

            Tab("Archived", systemImage: "archivebox") {
                HomeView(initialFilter: .archived,
                         showsFilterPicker: false,
                         allowsSearch: false,
                         onShowSettings: { showSettings = true })
            }

            Tab(role: .search) {
                HomeView(initialFilter: .all,
                         showsFilterPicker: false,
                         allowsSearch: true,
                         onShowSettings: { showSettings = true })
            }
        }
        .tabViewStyle(.automatic)
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let summary = ImportService(store: store).importEntries(from: url)
            importSummary = summary
            showImportSummary = true
        case .failure(let error):
            let status = ImportService.RowStatus(title: String(localized: "Import Failed"), state: .skipped(error.localizedDescription))
            importSummary = ImportService.Summary(statuses: [status])
            showImportSummary = true
        }
    }

    private func exportEntries() {
        do {
            let items = store.allItems()
            guard !items.isEmpty else {
                errorMessage = String(localized: "Nothing to export yet. Add an entry first.")
                showErrorAlert = true
                return
            }
            let url = try ExportService().export(entries: items)
            exportedFile = ExportedFile(url: url)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    @ViewBuilder
    private func importSummarySheet() -> some View {
        if let summary = importSummary {
            ImportSummaryView(summary: summary)
                .presentationDetents(adaptiveSheetDetents)
                .presentationCornerRadius(adaptiveSheetCornerRadius)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func shareSheet(for url: URL) -> some View {
        ShareSheet(activityItems: [url])
            .presentationDetents(adaptiveSheetDetents)
            .presentationCornerRadius(adaptiveSheetCornerRadius)
    }

    @ViewBuilder
    private func settingsSheet() -> some View {
        SettingsView(onImport: {
            showImporter = true
        },
                     onExport: exportEntries)
        .presentationDetents(adaptiveSheetDetents, selection: .constant(.large))
        .presentationCornerRadius(adaptiveSheetCornerRadius)
        .presentationDragIndicator(.visible)
    }
}

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}
