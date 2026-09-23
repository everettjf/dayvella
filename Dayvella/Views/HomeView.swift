import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var filter: EntryStore.Filter
    @State private var searchText: String = ""
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

    private var entries: [Entry] { store.entries }
    private var layout: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: horizontalSizeClass,
                      verticalSizeClass: verticalSizeClass,
                      dynamicTypeSize: dynamicTypeSize,
                      showsFilterPicker: showsFilterPicker)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: layout.minColumnWidth, maximum: layout.maxColumnWidth),
                  spacing: layout.gridSpacing)]
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
        .sheet(item: $activeDraft, content: editorSheet(for:))
        .sheet(item: $sharePayload) { payload in
            ShareSheet(activityItems: [payload.image])
        }
        .onAppear(perform: configureInitialFilter)
        .onChange(of: filter) { _, newFilter in
            updateFilter(newFilter)
        }
        .onChange(of: searchText) { _, newSearch in
            updateSearch(newSearch)
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

    private var header: some View {
        Group {
            if showsFilterPicker {
                contentContainer {
                    if layout.usesHorizontalHeader {
                        HStack(alignment: .center, spacing: layout.horizontalHeaderSpacing) {
                            filterPickerView
                                .frame(maxWidth: layout.filterMaxWidth ?? .infinity, alignment: .leading)
                            Spacer(minLength: 0)
                        }
                    } else {
                        filterPickerView
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, layout.headerTopPadding)
                .padding(.bottom, layout.headerBottomPadding)
            }
        }
    }

    private var navigationContent: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Dayvella")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent() }
        }
    }

    private var entriesGrid: some View {
        contentContainer {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: layout.gridSpacing) {
                ForEach(entries) { entry in
                    entryItem(for: entry)
                }
            }
            .padding(.top, layout.gridTopPadding)
            .padding(.bottom, layout.gridBottomPadding)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("No entries yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color(.label))
                Text("Use the plus button to start your first countdown or tracker.")
                    .font(.body)
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, layout.emptyStatePadding)
        .padding(.horizontal, layout.emptyStatePadding)
        .frame(maxWidth: layout.emptyStateMaxWidth)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            Color.accentColor.opacity(0.22),
                            Color.accentColor.opacity(0.08)
                        ],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)
        .frame(maxWidth: .infinity)
    }

    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                
                if entries.isEmpty {
                    VStack {
                        Spacer()
                        emptyState
                        Spacer()
                    }
                } else {
                    ScrollView {
                        entriesGrid
                    }
                    .scrollIndicators(.hidden)
                }
            }
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

    @ViewBuilder
    private func entryItem(for entry: Entry) -> some View {
        EntryListItemView(entry: entry) { tappedEntry, action in
            handle(action: action, for: tappedEntry)
        }
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

    private func save(draft: EntryDraft) {
        do {
            try store.upsert(from: draft)
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
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        activeDraft = nil
        editingEntry = nil
        entryPendingDeletion = nil
        showDeleteConfirm = false
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

    private func editorSheet(for draft: EntryDraft) -> some View {
        EntryEditView(draft: draft, isNew: editingEntry == nil) { newDraft in
            save(draft: newDraft)
        } onDelete: {
            if let entry = editingEntry {
                delete(entry: entry)
            }
        }
        .presentationDetents(Set(layout.sheetDetents), selection: .constant(layout.defaultSheetDetent))
        .presentationCornerRadius(layout.sheetCornerRadius)
        .presentationDragIndicator(.visible)
    }

    private func configureInitialFilter() {
        store.set(filter: filter)
    }

    private func updateFilter(_ filter: EntryStore.Filter) {
        store.set(filter: filter)
    }

    private func updateSearch(_ text: String) {
        guard allowsSearch else { return }
        store.set(search: text)
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
        editingEntry = nil
        let timezone = TimeZone.current
        let defaultDate = DayCounter.startOfDay(Date(), in: timezone)
        activeDraft = EntryDraft(entryType: .countUp,
                                 startDate: defaultDate,
                                 timezone: timezone)
    }

    private func startNewEntry(template: EntryTemplate) {
        editingEntry = nil
        activeDraft = template.draft()
    }
}

// MARK: - Layout Helpers

private extension HomeView {
    func contentContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if let width = layout.contentWidth {
                content()
                    .frame(maxWidth: width, alignment: .leading)
            } else {
                content()
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: layout.contentAlignment)
    }

    var filterPickerView: some View {
        Picker("Filter", selection: $filter) {
            ForEach(EntryStore.Filter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

}

private struct LayoutMetrics {
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat
    let usesHorizontalHeader: Bool
    let horizontalHeaderSpacing: CGFloat
    let filterMaxWidth: CGFloat?
    let headerTopPadding: CGFloat
    let headerBottomPadding: CGFloat
    let gridSpacing: CGFloat
    let gridTopPadding: CGFloat
    let gridBottomPadding: CGFloat
    let emptyStatePadding: CGFloat
    let emptyStateMaxWidth: CGFloat
    let minColumnWidth: CGFloat
    let maxColumnWidth: CGFloat
    let contentAlignment: Alignment
    let showsFilterPicker: Bool
    let sheetDetents: [PresentationDetent]
    let defaultSheetDetent: PresentationDetent
    let sheetCornerRadius: CGFloat

    init(horizontalSizeClass: UserInterfaceSizeClass?,
         verticalSizeClass: UserInterfaceSizeClass?,
         dynamicTypeSize: DynamicTypeSize,
         showsFilterPicker: Bool) {
        let prefersWideLayout = horizontalSizeClass == .regular && verticalSizeClass != .compact
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        let useWide = prefersWideLayout && !isAccessibility

        usesHorizontalHeader = useWide
        contentWidth = useWide ? 840 : nil
        horizontalPadding = useWide ? 32 : 16
        horizontalHeaderSpacing = useWide ? 20 : 12
        filterMaxWidth = useWide ? 340 : nil
        headerTopPadding = showsFilterPicker ? (useWide ? 28 : 12) : (useWide ? 18 : 10)
        headerBottomPadding = showsFilterPicker ? (useWide ? 8 : 12) : (useWide ? 16 : 14)
        gridSpacing = useWide ? 28 : 20
        gridTopPadding = useWide ? 8 : 12
        gridBottomPadding = useWide ? 140 : 84
        emptyStatePadding = useWide ? 28 : 20
        emptyStateMaxWidth = useWide ? 500 : 400
        minColumnWidth = useWide ? 320 : 260
        maxColumnWidth = useWide ? 420 : 360
        contentAlignment = useWide ? .center : .leading
        self.showsFilterPicker = showsFilterPicker
        if useWide {
            sheetDetents = [.fraction(0.75), .fraction(0.9), .large]
            defaultSheetDetent = .large
            sheetCornerRadius = 32
        } else {
            sheetDetents = [.large]
            defaultSheetDetent = .large
            sheetCornerRadius = 24
        }
    }
}
