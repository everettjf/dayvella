import SwiftUI

struct SearchTabView: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding private var searchText: String
    @State private var activeDraft: EntryDraft?
    @State private var editingEntry: Entry?
    @State private var showDeleteConfirm = false
    @State private var entryPendingDeletion: Entry?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var sharePayload: CardShareService.Payload?
    @Environment(\.colorScheme) private var colorScheme

    private let onShowSettings: (() -> Void)?

    init(searchText: Binding<String>, onShowSettings: (() -> Void)? = nil) {
        _searchText = searchText
        self.onShowSettings = onShowSettings
    }

    private var layout: SearchLayout {
        SearchLayout(horizontalSizeClass: horizontalSizeClass,
                     verticalSizeClass: verticalSizeClass,
                     dynamicTypeSize: dynamicTypeSize)
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasQuery: Bool { !trimmedQuery.isEmpty }

    private var results: [Entry] {
        guard hasQuery else { return [] }
        let query = trimmedQuery.lowercased()
        return store.allItems().filter { entryMatches($0, query: query) }
    }

    var body: some View {
        Group {
            if !hasQuery {
                searchPlaceholder
            } else if results.isEmpty {
                emptyResults
            } else {
                resultsGrid
            }
        }
        .toolbar { toolbarContent() }
        .sheet(item: $activeDraft, content: editorSheet(for:))
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: [payload.image])
        }
        .confirmationDialog("Delete Entry?", isPresented: $showDeleteConfirm, presenting: entryPendingDeletion, actions: { entry in
            deleteDialogActions(for: entry)
        }, message: { _ in
            Text("This action cannot be undone.")
        })
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK") { showErrorAlert = false }
        }, message: {
            Text(errorMessage)
        })
    }

    private var searchPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Search your entries")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Find anything by title or notes. Start typing to see matches.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private var emptyResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.folder")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No results")
                .font(.title3.weight(.semibold))
            Text("Try a different keyword or adjust the spelling.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private var resultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: layout.columns, alignment: .leading, spacing: layout.gridSpacing) {
                ForEach(results) { entry in
                    EntryListItemView(entry: entry) { tappedEntry, action in
                        handle(action: action, for: tappedEntry)
                    }
                }
            }
            .padding(.horizontal, layout.horizontalPadding)
            .padding(.top, layout.contentTopPadding)
            .padding(.bottom, layout.contentBottomPadding)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if let onShowSettings {
                Button(action: onShowSettings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                editingEntry = nil
                activeDraft = EntryDraft(entryType: .countUp, startDate: Date(), timezone: .current)
            } label: {
                Label("Add Entry", systemImage: "plus")
            }
        }
    }

    private func entryMatches(_ entry: Entry, query: String) -> Bool {
        if entry.title.lowercased().contains(query) { return true }

        if let notes = entry.notes?.lowercased(), notes.contains(query) { return true }

        if entry.entryType.label.lowercased().contains(query) { return true }

        if let emoji = entry.iconEmoji?.lowercased(), emoji.contains(query) { return true }

        return false
    }

    private func handle(action: EntryAction, for entry: Entry) {
        switch action {
        case .edit:
            editingEntry = entry
            activeDraft = EntryDraft(entry: entry)
        case .togglePin:
            store.togglePin(entry)
        case .duplicate:
            store.duplicate(entry)
        case .share:
            sharePayload = CardShareService().render(entry: entry, colorScheme: colorScheme)
        case .toggleArchive:
            store.toggleArchive(entry)
        case .delete:
            requestDelete(entry)
        }
    }

    private func requestDelete(_ entry: Entry) {
        entryPendingDeletion = entry
        showDeleteConfirm = true
    }

    private func delete(entry: Entry) {
        do {
            try store.delete(entry)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        activeDraft = nil
        editingEntry = nil
        entryPendingDeletion = nil
        showDeleteConfirm = false
    }

    private func save(draft: EntryDraft) {
        do {
            try store.upsert(from: draft)
            editingEntry = nil
            activeDraft = nil
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func editorSheet(for draft: EntryDraft) -> some View {
        EntryEditView(draft: draft, isNew: editingEntry == nil) { newDraft in
            save(draft: newDraft)
        } onDelete: {
            if let entry = editingEntry {
                delete(entry: entry)
            }
        }
        .presentationDetents(layout.sheetDetents)
        .presentationCornerRadius(layout.sheetCornerRadius)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func deleteDialogActions(for entry: Entry) -> some View {
        Button("Delete", role: .destructive) {
            delete(entry: entry)
        }
        Button("Cancel", role: .cancel) {}
    }
}

private struct SearchLayout {
    let columns: [GridItem]
    let horizontalPadding: CGFloat
    let gridSpacing: CGFloat
    let contentTopPadding: CGFloat
    let contentBottomPadding: CGFloat
    let sheetDetents: Set<PresentationDetent>
    let sheetCornerRadius: CGFloat

    init(horizontalSizeClass: UserInterfaceSizeClass?,
         verticalSizeClass: UserInterfaceSizeClass?,
         dynamicTypeSize: DynamicTypeSize) {
        let prefersWideLayout = horizontalSizeClass == .regular && verticalSizeClass != .compact
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        let useWide = prefersWideLayout && !isAccessibility

        let minColumn: CGFloat = useWide ? 320 : 260
        let maxColumn: CGFloat = useWide ? 420 : 360
        gridSpacing = useWide ? 28 : 20
        horizontalPadding = useWide ? 32 : 16
        contentTopPadding = useWide ? 24 : 16
        contentBottomPadding = useWide ? 140 : 84

        columns = [GridItem(.adaptive(minimum: minColumn, maximum: maxColumn), spacing: gridSpacing)]

        if useWide {
            sheetDetents = [.fraction(0.66), .fraction(0.9)]
            sheetCornerRadius = 32
        } else {
            sheetDetents = [.large]
            sheetCornerRadius = 0
        }
    }
}
