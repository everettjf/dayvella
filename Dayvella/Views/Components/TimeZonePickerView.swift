import SwiftUI

struct TimeZonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    let onSelect: (TimeZone) -> Void

    private var filteredZones: [TimeZoneEntry] {
        let base = TimeZoneCatalog.all
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.id.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section("Featured") {
                        ForEach(TimeZoneCatalog.featured) { entry in
                            zoneButton(entry)
                        }
                    }
                }
                Section("All Time Zones") {
                    ForEach(filteredZones) { entry in
                        zoneButton(entry)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Time Zone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search"))
        }
    }

    private func zoneButton(_ entry: TimeZoneEntry) -> some View {
        Button {
            onSelect(entry.timeZone)
            dismiss()
        } label: {
            VStack(alignment: .leading) {
                Text(entry.name)
                    .font(.body)
                Text(entry.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
