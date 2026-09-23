import SwiftUI
import UniformTypeIdentifiers

struct AppTabView: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var searchText: String = ""

    @State private var showImporter = false
    @State private var importSummary: ImportService.Summary?
    @State private var showImportSummary = false
    @State private var exportedFile: ExportedFile?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showSettings = false

    private var supportsLiquidGlass: Bool {
        horizontalSizeClass == .regular && verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    private var adaptiveSheetDetents: Set<PresentationDetent> {
        supportsLiquidGlass ? [.fraction(0.75), .fraction(0.9), .large] : [.large]
    }

    private var adaptiveSheetCornerRadius: CGFloat {
        supportsLiquidGlass ? 32 : 20
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if supportsLiquidGlass {
                LiquidGlassTabBackground()
                    .transition(.opacity)
            }

            tabView
        }
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
                NavigationStack {
                    SearchTabView(searchText: $searchText,
                                  onShowSettings: { showSettings = true })
                        .navigationTitle("Search")
                }
                .searchable(text: $searchText, prompt: Text("Search"))
            }
        }
        .tabViewStyle(.automatic)
        .toolbarBackground(supportsLiquidGlass ? .hidden : .visible, for: .tabBar)
        .toolbarBackground(supportsLiquidGlass ? .hidden : .visible, for: .bottomBar)
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let summary = ImportService(store: store).importEntries(from: url)
            importSummary = summary
            showImportSummary = true
        case .failure(let error):
            let status = ImportService.RowStatus(title: "Import Failed", state: .skipped(error.localizedDescription))
            importSummary = ImportService.Summary(statuses: [status])
            showImportSummary = true
        }
    }

    private func exportEntries() {
        do {
            let items = store.allItems()
            guard !items.isEmpty else {
                errorMessage = "Nothing to export yet. Add an entry first."
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

private struct LiquidGlassTabBackground: View {
    private let cornerRadius: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width - 48, 620)

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0.05)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .blendMode(.plusLighter)
                            .opacity(0.7)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 12)
                    .frame(width: width, height: 72)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}

private struct ExportedFile: Identifiable {
    let id = UUID()
    let url: URL
}
