import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onImport: () -> Void
    let onExport: () -> Void

    @State private var showClearAllSheet = false
    @State private var showClearSuccessAlert = false

    private var layout: SettingsLayout {
        SettingsLayout(horizontalSizeClass: horizontalSizeClass, dynamicTypeSize: dynamicTypeSize)
    }

    private let supportEmailURL = URL(string: "mailto:xnuapp@gmail.com")
    private let websiteURL = URL(string: "https://xnu.app/dayvella")

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        Spacer()
                        Text("Automatic")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        ImportExportGuideView(onImport: { dismissAnd(onImport) },
                                               onExport: { dismissAnd(onExport) })
                    } label: {
                        Label("Import & Export Guide", systemImage: "questionmark.circle")
                    }

                    Button {
                        dismissAnd(onImport)
                    } label: {
                        Label("Import JSON", systemImage: "tray.and.arrow.down")
                    }

                    Button {
                        dismissAnd(onExport)
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }

                }

                Section("Support") {
                    if let websiteURL {
                        Button {
                            dismissAndOpen(websiteURL)
                        } label: {
                            Label("Visit Website", systemImage: "globe")
                        }
                    }
                    if let supportEmailURL {
                        Button {
                            dismissAndOpen(supportEmailURL)
                        } label: {
                            Label("Email Support", systemImage: "envelope")
                        }
                    }
                }

                Section("About") {

                    HStack {
                        Label("Version", systemImage: "number")
                        Spacer()
                        Text(Bundle.main.formattedVersion)
                            .foregroundStyle(.secondary)
                    }

                    if !store.allItems().isEmpty {
                        Button(role: .cancel) {
                            showClearAllSheet = true
                        } label: {
                            Label("Delete All Entries", systemImage: "trash")
                        }
                    }
                }

                Section("More Apps") {
                    appStoreButton("BSSID SCAN", icon: "wifi", url: "https://apps.apple.com/us/app/bssid-scan/id1442586100")
                    appStoreButton("Remote Keyboard", icon: "keyboard", url: "https://apps.apple.com/us/app/remote-keyboard/id1474458879")
                    appStoreButton("ScriptWidget", icon: "curlybraces.square", url: "https://apps.apple.com/us/app/scriptwidget/id1555600758")
                }

            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .modifier(CenteredListModifier(layout: layout))
        }
        .sheet(isPresented: $showClearAllSheet) {
            ClearAllDataView {
                showClearSuccessAlert = true
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
        }
        .alert("All entries deleted", isPresented: $showClearSuccessAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private func dismissAnd(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.async { action() }
    }

    private func dismissAndOpen(_ url: URL) {
        dismiss()
        DispatchQueue.main.async {
            openURL(url)
        }
    }

    private func appStoreButton(_ name: String, icon: String, url: String) -> some View {
        Button {
            if let destination = URL(string: url) {
                openURL(destination)
            }
        } label: {
            HStack {
                Label(name, systemImage: icon)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SettingsLayout {
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat

    init(horizontalSizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) {
        let useWideLayout = horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
        contentWidth = useWideLayout ? 900 : nil
        horizontalPadding = useWideLayout ? 40 : 0
    }
}

private struct CenteredListModifier: ViewModifier {
    let layout: SettingsLayout

    func body(content: Content) -> some View {
        Group {
            if let width = layout.contentWidth {
                content
                    .frame(maxWidth: width)
                    .padding(.horizontal, layout.horizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
}
