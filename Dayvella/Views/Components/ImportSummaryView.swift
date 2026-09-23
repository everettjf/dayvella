import SwiftUI

struct ImportSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let summary: ImportService.Summary

    var body: some View {
        NavigationStack {
            List {
                Section("Results") {
                    ForEach(summary.statuses) { status in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: icon(for: status.state))
                                .foregroundStyle(color(for: status.state))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(status.title)
                                    .font(.headline)
                                if case .skipped(let reason) = status.state {
                                    Text(reason)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Import Summary")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func icon(for state: ImportService.RowStatus.State) -> String {
        switch state {
        case .success: return "checkmark.circle.fill"
        case .skipped: return "exclamationmark.triangle.fill"
        }
    }

    private func color(for state: ImportService.RowStatus.State) -> Color {
        switch state {
        case .success: return Color(hex: "#00E0A4")
        case .skipped: return Color(hex: "#FF2D55")
        }
    }
}
