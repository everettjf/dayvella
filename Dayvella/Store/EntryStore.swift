import Combine
import Foundation


final class EntryStore: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case pinned
        case archived

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .pinned: return "Pinned"
            case .archived: return "Archived"
            }
        }
    }

    @Published private(set) var entries: [Entry] = []

    private var allEntries: [Entry] = []
    private var deletedAt: [UUID: Date] = [:]
    private var filter: Filter = .all
    private var searchText: String = ""
    private var iCloudObserver: AnyCancellable?

    private let storageURL: URL
    private let iCloudStore: NSUbiquitousKeyValueStore
    private static let iCloudSnapshotKey = "entries.sync-snapshot.v1"
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(
        fileManager: FileManager = .default,
        iCloudStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.iCloudStore = iCloudStore
        let folder = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        // Keep the pre-Dayvella directory so existing installations retain their data.
        let directory = folder.appendingPathComponent("CountMyDays", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        storageURL = directory.appendingPathComponent("entries.json")
        load()
        startICloudSync()
    }

    func set(filter: Filter) {
        guard self.filter != filter else { return }
        self.filter = filter
        applyFilters()
    }

    func set(search text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard searchText != normalized else { return }
        searchText = normalized
        applyFilters()
    }

    func entry(with id: UUID) -> Entry? {
        allEntries.first { $0.id == id }
    }

    @discardableResult
    func upsert(from draft: EntryDraft) throws -> Entry {
        let existingIndex = allEntries.firstIndex { $0.id == draft.id }
        let existing = existingIndex.map { allEntries[$0] }
        var entry = draft.makeEntry(existing: existing)
        let timezone = entry.timezone
        if entry.entryType == .countUp && entry.startDate == nil {
            entry.startDate = DayCounter.startOfDay(Date(), in: timezone)
        }
        if entry.entryType == .countDown && entry.targetDate == nil {
            entry.targetDate = DayCounter.startOfDay(Date().addingTimeInterval(86_400), in: timezone)
        }
        if let existingIndex {
            allEntries[existingIndex] = entry
        } else {
            allEntries.append(entry)
        }
        try save()
        applyFilters()
        NotificationService.shared.scheduleReminders(for: entry)
        return entry
    }

    func delete(_ entry: Entry) throws {
        NotificationService.shared.cancelReminders(for: entry)
        allEntries.removeAll { $0.id == entry.id }
        deletedAt[entry.id] = Date()
        try save()
        applyFilters()
    }

    func togglePin(_ entry: Entry) {
        guard let index = allEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        var item = allEntries[index]
        if item.isArchived { return }
        item.isPinned.toggle()
        item.stampTimestamps(asNew: false)
        allEntries[index] = item
        persistSilently()
        if item.isArchived {
            NotificationService.shared.cancelReminders(for: item)
        } else {
            NotificationService.shared.scheduleReminders(for: item)
        }
    }

    func toggleArchive(_ entry: Entry) {
        guard let index = allEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        var item = allEntries[index]
        item.isArchived.toggle()
        if item.isArchived {
            item.isPinned = false
        }
        item.stampTimestamps(asNew: false)
        allEntries[index] = item
        persistSilently()
    }

    func duplicate(_ entry: Entry) {
        var copy = entry
        copy.id = UUID()
        copy.isPinned = false
        copy.isArchived = false
        copy.title += " (Copy)"
        let timezone = copy.timezone
        if let start = copy.startDate {
            copy.startDate = DayCounter.startOfDay(start, in: timezone)
        }
        if let target = copy.targetDate {
            copy.targetDate = DayCounter.startOfDay(target, in: timezone)
        }
        if let rangeStart = copy.rangeStart {
            copy.rangeStart = DayCounter.startOfDay(rangeStart, in: timezone)
        }
        if let rangeEnd = copy.rangeEnd {
            copy.rangeEnd = DayCounter.startOfDay(rangeEnd, in: timezone)
        }
        copy.stampTimestamps(asNew: true)
        allEntries.append(copy)
        persistSilently()
        NotificationService.shared.scheduleReminders(for: copy)
    }

    func importEntries(_ newEntries: [Entry]) {
        for entry in newEntries {
            deletedAt.removeValue(forKey: entry.id)
            if let index = allEntries.firstIndex(where: { $0.id == entry.id }) {
                allEntries[index] = entry
            } else {
                allEntries.append(entry)
            }
        }
        persistSilently()
        newEntries.forEach { entry in
            if entry.isArchived {
                NotificationService.shared.cancelReminders(for: entry)
            } else {
                NotificationService.shared.scheduleReminders(for: entry)
            }
        }
    }

    func removeAllEntries() throws {
        guard !allEntries.isEmpty else { return }
        let deletionDate = Date()
        for entry in allEntries {
            NotificationService.shared.cancelReminders(for: entry)
            deletedAt[entry.id] = deletionDate
        }
        allEntries.removeAll()
        try save()
        applyFilters()
    }

    func allItems() -> [Entry] {
        allEntries.sorted(by: sortPredicate)
    }

    func refresh() {
        mergeFromICloud()
        applyFilters()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storageURL)
            if let snapshot = try? decoder.decode(SyncSnapshot.self, from: data) {
                allEntries = snapshot.entries
                deletedAt = snapshot.deletedAt
            } else {
                allEntries = try decoder.decode([Entry].self, from: data)
            }
        } catch {
            allEntries = []
        }
        applyFilters()
    }

    private func save() throws {
        let sorted = allEntries.sorted(by: sortPredicate)
        let snapshot = SyncSnapshot(entries: sorted, deletedAt: deletedAt)
        let data = try encoder.encode(snapshot)
        try data.write(to: storageURL, options: [.atomic])
        allEntries = sorted
        WidgetSnapshotService().save(entries: sorted)
        pushToICloud(snapshot)
    }

    private func persistSilently() {
        do {
            try save()
            applyFilters()
        } catch {
            assertionFailure("Failed to persist entries: \(error)")
        }
    }

    private func startICloudSync() {
        iCloudObserver = NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.mergeFromICloud()
        }

        iCloudStore.synchronize()
        if iCloudStore.data(forKey: Self.iCloudSnapshotKey) == nil {
            pushToICloud(SyncSnapshot(entries: allEntries, deletedAt: deletedAt))
        } else {
            mergeFromICloud()
        }
    }

    private func mergeFromICloud() {
        guard let data = iCloudStore.data(forKey: Self.iCloudSnapshotKey),
              let remote = try? decoder.decode(SyncSnapshot.self, from: data) else {
            return
        }

        let local = SyncSnapshot(entries: allEntries, deletedAt: deletedAt)
        let merged = SyncSnapshot.merging(local, remote)
        guard merged != local else { return }

        allEntries = merged.entries
        deletedAt = merged.deletedAt
        persistSilently()
    }

    private func pushToICloud(_ snapshot: SyncSnapshot) {
        var snapshotToUpload = snapshot
        if let remoteData = iCloudStore.data(forKey: Self.iCloudSnapshotKey),
           let remote = try? decoder.decode(SyncSnapshot.self, from: remoteData) {
            snapshotToUpload = SyncSnapshot.merging(snapshot, remote)
        }
        guard let data = try? encoder.encode(snapshotToUpload) else { return }
        if snapshotToUpload != snapshot {
            allEntries = snapshotToUpload.entries.sorted(by: sortPredicate)
            deletedAt = snapshotToUpload.deletedAt
            try? data.write(to: storageURL, options: [.atomic])
        }
        iCloudStore.set(data, forKey: Self.iCloudSnapshotKey)
        iCloudStore.synchronize()
    }

    private func applyFilters() {
        let filtered = allEntries
            .filter(filterPredicate)
            .filter(searchPredicate)
            .sorted(by: sortPredicate)
        DispatchQueue.main.async {
            self.entries = filtered
        }
    }

    private func filterPredicate(_ entry: Entry) -> Bool {
        switch filter {
        case .all:
            return !entry.isArchived
        case .pinned:
            return entry.isPinned && !entry.isArchived
        case .archived:
            return entry.isArchived
        }
    }

    private func searchPredicate(_ entry: Entry) -> Bool {
        guard !searchText.isEmpty else { return true }
        let lower = searchText.lowercased()
        let titleMatch = entry.title.lowercased().contains(lower)
        let notesMatch = entry.notes?.lowercased().contains(lower) ?? false
        return titleMatch || notesMatch
    }

    private func sortPredicate(_ lhs: Entry, _ rhs: Entry) -> Bool {
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned && !rhs.isPinned
        }
        return lhs.updatedAt > rhs.updatedAt
    }
}
