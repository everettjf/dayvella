import SwiftUI

struct ClearAllDataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: EntryStore

    @State private var confirmationText: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    let onCleared: () -> Void

    private var entryCount: Int {
        store.allItems().count
    }

    private var normalizedConfirmation: String {
        confirmationText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canConfirm: Bool {
        normalizedConfirmation == "delete all"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This will permanently delete all entries, including archived and pinned items.")
                    if entryCount > 0 {
                        Text("You currently have \(entryCount) entr\(entryCount == 1 ? "y" : "ies").")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Type `delete all` to confirm")
                        .font(.subheadline.weight(.semibold))
                    TextField("delete all", text: $confirmationText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(role: .destructive) {
                        clearAll()
                    } label: {
                        Label("Delete Everything", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canConfirm)

                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .navigationTitle("Delete All Data")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Unable to Delete", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func clearAll() {
        do {
            try store.removeAllEntries()
            dismiss()
            DispatchQueue.main.async {
                onCleared()
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
