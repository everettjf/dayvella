import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: EntryStore

    @State private var filter: EntryStore.Filter
    @State private var searchText: String = ""
    @State private var selectedEntryID: UUID?
    @State private var preferredColumn: NavigationSplitViewColumn = .sidebar
    @State private var showDiscardConfirmation = false
    @State private var pendingSelection: UUID?
    @State private var pendingDraft: EntryDraft?
    @State private var editingEntry: Entry?
    @State private var activeDraft: EntryDraft?
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showDeleteConfirm = false
    @State private var entryPendingDeletion: Entry?
    @State private var sharePayload: CardShareService.Payload?
    @Environment(\.colorScheme) private var colorScheme

    private let showsFilterPicker: Bool
    private let allowsSearch: Bool
    private let onShowSettings: (() -> Void)?

    private var entries: [Entry] {
        store.allItems().filter { entry in
            let matchesFilter = allowsSearch || (filter == .archived ? entry.isArchived : !entry.isArchived && (filter != .pinned || entry.isPinned))
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return matchesFilter && (query.isEmpty || entry.title.localizedStandardContains(query) || (entry.notes?.localizedStandardContains(query) ?? false) || entry.entryType.label.localizedStandardContains(query))
        }.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            if $0.updatedAt != $1.updatedAt { return $0.updatedAt > $1.updatedAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    private var selectedEntry: Entry? {
        entries.first { $0.id == selectedEntryID } ?? entries.first
    }
    init(initialFilter: EntryStore.Filter = .all,
         showsFilterPicker: Bool = true,
         allowsSearch: Bool = false,
         onShowSettings: (() -> Void)? = nil) {
        _filter = State(initialValue: initialFilter)
        self.showsFilterPicker = showsFilterPicker
        self.allowsSearch = allowsSearch
        self.onShowSettings = onShowSettings
    }

    var body: some View {
        Group {
            if allowsSearch {
                navigationContent
                    .searchable(text: $searchText,
                                placement: .navigationBarDrawer(displayMode: .always),
                                prompt: Text("Search entries"))
            } else {
                navigationContent
            }
        }
        .confirmationDialog("Delete Entry?", isPresented: $showDeleteConfirm, presenting: entryPendingDeletion, actions: { entry in
            deleteDialogActions(for: entry)
        }, message: { entry in
            deleteDialogMessage(entry)
        })
        .confirmationDialog("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Discard Changes", role: .destructive) {
                activeDraft = nil
                editingEntry = nil
                if let draft = pendingDraft { beginDraft(draft) }
                else { selectEntry(pendingSelection) }
                pendingDraft = nil
                pendingSelection = nil
            }
            Button("Cancel", role: .cancel) { pendingDraft = nil; pendingSelection = nil }
        }
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: [payload.image])
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            errorAlertActions()
        }, message: {
            errorAlertMessage()
        })
        .onChange(of: activeDraft) { _, newDraft in
            syncEditingEntry(newDraft)
        }
    }

    @ViewBuilder
    private var navigationContent: some View {
        if entries.isEmpty && activeDraft == nil {
            NavigationStack {
                ScrollView { emptyState }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle(allowsSearch ? String(localized: "Search") : "Dayvella")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbarContent() }
            }
        } else {
            entryWorkspace
        }
    }

    private var entryWorkspace: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            sidebarContent
                .navigationTitle(allowsSearch ? String(localized: "Search") : "Dayvella")
                .navigationBarTitleDisplayMode(.inline)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 420)
                .toolbar { toolbarContent() }
        } detail: {
            if let draft = activeDraft {
                EntryEditView(draft: draft, isNew: editingEntry == nil, onSave: save,
                              onDelete: editingEntry.map { entry in { delete(entry: entry) } },
                              onCancel: cancelDraft,
                              onDraftChange: { activeDraft = $0 })
                    .id(draft.id)
                    .interactiveDismissDisabled()
            } else if let entry = selectedEntry {
                NavigationStack {
                    EntryDetailView(entry: entry) { action in handle(action: action, for: entry) }
                }
            } else {
                ContentUnavailableView("Select an entry", systemImage: "calendar",
                                       description: Text("Your dates stay close at hand."))
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        if entries.isEmpty {
            ScrollView { emptyState }
                .background(Color(.systemGroupedBackground))
        } else {
            List {
                if showsFilterPicker { filterPickerView.listRowSeparator(.hidden) }
                ForEach(entries) { entry in
                    Button { requestSelection(entry.id) } label: {
                        EntrySummaryRow(entry: entry, isSelected: entry.id == selectedEntry?.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("entry-" + entry.id.uuidString)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .contextMenu {
                        Button("Edit") { handle(action: .edit, for: entry) }
                        Button(entry.isPinned ? String(localized: "Unpin") : String(localized: "Pin")) { handle(action: .togglePin, for: entry) }
                        Button(entry.isArchived ? String(localized: "Unarchive") : String(localized: "Archive")) { handle(action: .toggleArchive, for: entry) }
                        Button("Duplicate") { handle(action: .duplicate, for: entry) }
                        Button("Share Card", systemImage: "square.and.arrow.up") { handle(action: .share, for: entry) }
                        Button("Delete", role: .destructive) { requestDelete(entry) }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
        }
    }

    private func requestSelection(_ id: UUID) {
        if activeDraft != nil {
            pendingSelection = id
            pendingDraft = nil
            showDiscardConfirmation = true
        } else { selectEntry(id) }
    }

    private func selectEntry(_ id: UUID?) {
        selectedEntryID = id
        preferredColumn = .detail
    }

    private func beginDraft(_ draft: EntryDraft) {
        if activeDraft != nil {
            pendingDraft = draft
            pendingSelection = nil
            showDiscardConfirmation = true
            return
        }
        editingEntry = store.entry(with: draft.id)
        selectedEntryID = editingEntry?.id
        activeDraft = draft
        preferredColumn = .detail
    }

    private var emptyState: some View {
        VStack(spacing: 32) {
            emptyStateIllustration

            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if filter == .all && !allowsSearch {
                VStack(spacing: 24) {
                    Button(action: startNewEntry) {
                        Label("Create your first entry", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    VStack(spacing: 12) {
                        Text("OR START WITH A TEMPLATE")
                            .font(.caption2.weight(.semibold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) { quickStartButtons }
                            VStack(spacing: 10) { quickStartButtons }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 28)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity)
    }

    private var emptyStateTitle: String {
        if allowsSearch { return searchText.isEmpty ? String(localized: "Search your entries") : String(localized: "No results") }
        return switch filter {
        case .all: String(localized: "Make every day count")
        case .pinned: String(localized: "Keep favorites close")
        case .archived: String(localized: "A place for past moments")
        }
    }

    private var emptyStateMessage: String {
        if allowsSearch { return searchText.isEmpty ? String(localized: "Find anything by title or notes. Start typing to see matches.") : String(localized: "Try a different keyword or adjust the spelling.") }
        return switch filter {
        case .all: String(localized: "Count down to something special, or track how far you’ve come.")
        case .pinned: String(localized: "Pin an entry to find it here and keep it on your widgets.")
        case .archived: String(localized: "Archived entries appear here, ready to revisit whenever you like.")
        }
    }

    private var emptyStateIllustration: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.08 : 0.06))
                .frame(width: 184, height: 184)
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.accentColor.opacity(0.12))
                .frame(width: 112, height: 126)
                .rotationEffect(.degrees(-12))
                .offset(x: -12, y: 4)
            VStack(spacing: 14) {
                HStack(spacing: 30) {
                    Capsule().frame(width: 6, height: 14)
                    Capsule().frame(width: 6, height: 14)
                }
                .foregroundStyle(Color.accentColor.opacity(0.55))
                Image(systemName: allowsSearch ? "magnifyingglass" : filter == .all ? "sparkles" : filter == .pinned ? "pin.fill" : "archivebox.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 112, height: 126)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26))
            .overlay {
                RoundedRectangle(cornerRadius: 26)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .rotationEffect(.degrees(8))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        }
        .accessibilityHidden(true)
    }

    private var quickStartButtons: some View {
        ForEach([EntryTemplate.birthday, .trip, .habit]) { template in
            Button {
                startNewEntry(template: template)
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: template.symbol)
                        .font(.title3)
                    Text(template == .habit ? String(localized: "Habit") : template.title)
                        .font(.footnote.weight(.medium))
                        .frame(minHeight: 34)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if let onShowSettings {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onShowSettings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("Blank Entry", systemImage: "plus") { startNewEntry() }
                Section("Quick Start") {
                    ForEach(EntryTemplate.allCases) { template in
                        Button(template.title, systemImage: template.symbol) {
                            startNewEntry(template: template)
                        }
                    }
                }
            } label: {
                Label("Add Entry", systemImage: "plus")
            }
        }
    }

    private func handle(action: EntryAction, for entry: Entry) {
        switch action {
        case .edit:
            beginDraft(EntryDraft(entry: entry))
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

    private func cancelDraft() {
        activeDraft = nil
        editingEntry = nil
        if selectedEntryID == nil { preferredColumn = .sidebar }
    }

    private func save(draft: EntryDraft) {
        do {
            let entry = try store.upsert(from: draft)
            selectedEntryID = entry.id
            editingEntry = nil
            activeDraft = nil
            AppReviewManager.registerSuccessfulSave()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func requestDelete(_ entry: Entry) {
        entryPendingDeletion = entry
        showDeleteConfirm = true
    }

    private func delete(entry: Entry) {
        do {
            try store.delete(entry)
            if activeDraft?.id == entry.id { activeDraft = nil; editingEntry = nil }
            if selectedEntryID == entry.id { selectedEntryID = nil }
            if entries.isEmpty { preferredColumn = .sidebar }
            entryPendingDeletion = nil
            showDeleteConfirm = false
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    @ViewBuilder
    private func deleteDialogActions(for entry: Entry) -> some View {
        Button("Delete", role: .destructive) {
            delete(entry: entry)
        }
        Button("Cancel", role: .cancel) {}
    }

    private func deleteDialogMessage(_ entry: Entry) -> Text {
        Text("This action cannot be undone.")
    }

    @ViewBuilder
    private func errorAlertActions() -> some View {
        Button("OK") { showErrorAlert = false }
    }

    private func errorAlertMessage() -> Text {
        Text(errorMessage)
    }

    private func syncEditingEntry(_ draft: EntryDraft?) {
        if draft == nil {
            editingEntry = nil
        }
    }

    private func startNewEntry() {
        let timezone = TimeZone.current
        let defaultDate = DayCounter.startOfDay(Date(), in: timezone)
        beginDraft(EntryDraft(entryType: .countUp,
                                 startDate: defaultDate,
                                 timezone: timezone))
    }

    private func startNewEntry(template: EntryTemplate) {
        beginDraft(template.draft())
    }
}

private extension HomeView {
    var filterPickerView: some View {
        Picker("Filter", selection: $filter) {
            ForEach(EntryStore.Filter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }.pickerStyle(.segmented)
    }
}
