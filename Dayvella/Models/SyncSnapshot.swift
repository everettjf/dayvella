import Foundation

struct SyncSnapshot: Codable, Equatable {
    static let currentVersion = 1

    var version: Int = currentVersion
    var entries: [Entry]
    var deletedAt: [UUID: Date]

    static func merging(_ lhs: SyncSnapshot, _ rhs: SyncSnapshot) -> SyncSnapshot {
        var deletions = lhs.deletedAt
        for (id, date) in rhs.deletedAt {
            deletions[id] = max(deletions[id] ?? .distantPast, date)
        }

        var entriesByID: [UUID: Entry] = [:]
        for entry in lhs.entries + rhs.entries {
            guard let existing = entriesByID[entry.id] else {
                entriesByID[entry.id] = entry
                continue
            }
            if entry.updatedAt > existing.updatedAt {
                entriesByID[entry.id] = entry
            }
        }

        let entries = entriesByID.values.filter { entry in
            guard let deletionDate = deletions[entry.id] else { return true }
            return entry.updatedAt > deletionDate
        }

        return SyncSnapshot(
            version: currentVersion,
            entries: entries,
            deletedAt: deletions
        )
    }
}
