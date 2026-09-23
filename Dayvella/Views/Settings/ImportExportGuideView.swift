import SwiftUI

struct ImportExportGuideView: View {
    @Environment(\.dismiss) private var dismiss
    let onImport: () -> Void
    let onExport: () -> Void

    private var sampleURL: URL? {
        Bundle.main.url(forResource: "sample_import", withExtension: "json")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionHeader(title: "Import JSON", systemImage: "tray.and.arrow.down")
                Text("Dayvella imports JSON arrays where every item represents an entry. Each one can be a count-up or count-down with its own timezone.")
                    .foregroundStyle(.secondary)

                if let sampleURL {
                    ShareLink(item: sampleURL, subject: Text("sample_import.json")) {
                        Label("Share sample_import.json", systemImage: "square.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick checklist")
                        .font(.headline)
                    checklistRow(text: "Include a title for every entry")
                    checklistRow(text: "Set `type` to `countUp` or `countDown`")
                    checklistRow(text: "Provide the matching `start` or `target` date in ISO-8601 format")
                    checklistRow(text: "Use an IANA timezone identifier, e.g. Asia/Shanghai")
                    checklistRow(text: "Optional: `rangeStart`, `rangeEnd`, `outOfRangeBehavior`, `repeatRule`")
                }

                Button {
                    dismiss()
                    onImport()
                } label: {
                    Label("Choose JSON file", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Divider().padding(.vertical, 12)

                sectionHeader(title: "Export JSON", systemImage: "square.and.arrow.up")
                Text("Generate a snapshot of all entries in the same schema. You can archive it, hand it to friends, or re-import later.")
                    .foregroundStyle(.secondary)

                Button {
                    dismiss()
                    onExport()
                } label: {
                    Label("Export current entries", systemImage: "square.and.arrow.up.on.square")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text("Tip: Re-importing the exported file updates entries with matching IDs and adds any new ones.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }
            .padding()
        }
        .navigationTitle("Import & Export")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
    }

    private func checklistRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color(hex: "#00E0A4"))
            Text(text)
        }
        .font(.subheadline)
    }
}
