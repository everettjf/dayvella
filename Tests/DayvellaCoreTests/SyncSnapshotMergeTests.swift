import Foundation
import Testing
@testable import DayvellaCore

struct SyncSnapshotMergeTests {
    // MARK: - Union

    @Test("Entries added on different devices merge into a union")
    func disjointAdditionsFormUnion() {
        let fromA = entry(title: "From A", updatedAt: Date(timeIntervalSince1970: 100))
        let fromB = entry(title: "From B", updatedAt: Date(timeIntervalSince1970: 200))

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [fromA], deletedAt: [:]),
            SyncSnapshot(entries: [fromB], deletedAt: [:])
        )

        #expect(normalized(merged.entries) == normalized([fromA, fromB]))
    }

    @Test("Merging with an empty snapshot keeps local data (first sync)")
    func mergeWithEmptyRemoteKeepsLocalEntries() {
        let local = entry(title: "Local", updatedAt: Date(timeIntervalSince1970: 100))

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [local], deletedAt: [:]),
            SyncSnapshot(entries: [], deletedAt: [:])
        )

        #expect(merged.entries == [local])
    }

    @Test("Merging local emptiness with remote data adopts remote data (first sync)")
    func mergeWithEmptyLocalAdoptsRemoteEntries() {
        let remote = entry(title: "Remote", updatedAt: Date(timeIntervalSince1970: 100))
        let tombstoneID = UUID()

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [], deletedAt: [:]),
            SyncSnapshot(entries: [remote], deletedAt: [tombstoneID: Date(timeIntervalSince1970: 50)])
        )

        #expect(merged.entries == [remote])
        #expect(merged.deletedAt == [tombstoneID: Date(timeIntervalSince1970: 50)])
    }

    @Test("Merging two empty snapshots stays empty")
    func emptyMergeStaysEmpty() {
        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [], deletedAt: [:]),
            SyncSnapshot(entries: [], deletedAt: [:])
        )

        #expect(merged.entries.isEmpty)
        #expect(merged.deletedAt.isEmpty)
        #expect(merged.version == SyncSnapshot.currentVersion)
    }

    // MARK: - Conflicts

    @Test("When both devices edit the same entry the newer timestamp wins with all its fields")
    func newerEditWinsWithFullFieldSet() {
        let id = UUID()
        let loser = fullEntry(id: id, title: "Before", updatedAt: Date(timeIntervalSince1970: 100))
        var winner = fullEntry(id: id, title: "After", updatedAt: Date(timeIntervalSince1970: 200))
        winner.repeatRule = .weekly
        winner.isPinned = true
        winner.isArchived = false
        winner.notes = "Edited on device B"
        winner.colorHex = "#123456"

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [loser], deletedAt: [:]),
            SyncSnapshot(entries: [winner], deletedAt: [:])
        )

        #expect(merged.entries == [winner])
        #expect(merged.entries.first?.repeatRule == .weekly)
        #expect(merged.entries.first?.isPinned == true)
    }

    @Test("Equal timestamps resolve deterministically to the left-hand snapshot")
    func equalTimestampsPreferLeftHandSide() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 100)
        let lhsCopy = entry(id: id, title: "Left", updatedAt: timestamp)
        let rhsCopy = entry(id: id, title: "Right", updatedAt: timestamp)

        let leftFirst = SyncSnapshot.merging(
            SyncSnapshot(entries: [lhsCopy], deletedAt: [:]),
            SyncSnapshot(entries: [rhsCopy], deletedAt: [:])
        )
        let rightFirst = SyncSnapshot.merging(
            SyncSnapshot(entries: [rhsCopy], deletedAt: [:]),
            SyncSnapshot(entries: [lhsCopy], deletedAt: [:])
        )

        #expect(leftFirst.entries == [lhsCopy])
        #expect(rightFirst.entries == [rhsCopy])
    }

    @Test("Merge is commutative when no timestamps tie")
    func mergeIsCommutativeWithoutTies() {
        let shared = UUID()
        let a = SyncSnapshot(
            entries: [
                entry(title: "Only A", updatedAt: Date(timeIntervalSince1970: 100)),
                entry(id: shared, title: "Old", updatedAt: Date(timeIntervalSince1970: 100)),
            ],
            deletedAt: [UUID(): Date(timeIntervalSince1970: 150)]
        )
        let b = SyncSnapshot(
            entries: [
                entry(title: "Only B", updatedAt: Date(timeIntervalSince1970: 300)),
                entry(id: shared, title: "New", updatedAt: Date(timeIntervalSince1970: 200)),
            ],
            deletedAt: [UUID(): Date(timeIntervalSince1970: 250)]
        )

        let ab = SyncSnapshot.merging(a, b)
        let ba = SyncSnapshot.merging(b, a)

        #expect(normalized(ab.entries) == normalized(ba.entries))
        #expect(ab.deletedAt == ba.deletedAt)
        #expect(ab.entries.contains { $0.id == shared && $0.title == "New" })
    }

    @Test("Merging the result again is idempotent")
    func mergeIsIdempotent() {
        let shared = UUID()
        let deletedID = UUID()
        let a = SyncSnapshot(
            entries: [entry(id: shared, title: "Old", updatedAt: Date(timeIntervalSince1970: 100))],
            deletedAt: [deletedID: Date(timeIntervalSince1970: 200)]
        )
        let b = SyncSnapshot(
            entries: [entry(id: shared, title: "New", updatedAt: Date(timeIntervalSince1970: 300))],
            deletedAt: [:]
        )

        let merged = SyncSnapshot.merging(a, b)
        let remergedWithA = SyncSnapshot.merging(merged, a)
        let remergedWithB = SyncSnapshot.merging(merged, b)

        #expect(normalized(remergedWithA.entries) == normalized(merged.entries))
        #expect(remergedWithA.deletedAt == merged.deletedAt)
        #expect(normalized(remergedWithB.entries) == normalized(merged.entries))
        #expect(remergedWithB.deletedAt == merged.deletedAt)
    }

    // MARK: - Deletions and tombstones

    @Test("A deletion newer than the edit removes the entry")
    func deletionNewerThanEditRemovesEntry() {
        let id = UUID()
        let edited = entry(id: id, title: "Edited", updatedAt: Date(timeIntervalSince1970: 200))

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [edited], deletedAt: [:]),
            SyncSnapshot(entries: [], deletedAt: [id: Date(timeIntervalSince1970: 300)])
        )

        #expect(merged.entries.isEmpty)
        #expect(merged.deletedAt[id] == Date(timeIntervalSince1970: 300))
    }

    @Test("A deletion tying the edit timestamp still removes the entry")
    func deletionTieRemovesEntry() {
        let id = UUID()
        let timestamp = Date(timeIntervalSince1970: 200)
        let edited = entry(id: id, title: "Edited", updatedAt: timestamp)

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [edited], deletedAt: [:]),
            SyncSnapshot(entries: [], deletedAt: [id: timestamp])
        )

        #expect(merged.entries.isEmpty)
    }

    @Test("A stale snapshot cannot resurrect a deleted entry, even when merged twice")
    func tombstonePreventsResurrection() {
        let id = UUID()
        let stale = SyncSnapshot(
            entries: [entry(id: id, title: "Ghost", updatedAt: Date(timeIntervalSince1970: 100))],
            deletedAt: [:]
        )
        let deleted = SyncSnapshot(
            entries: [],
            deletedAt: [id: Date(timeIntervalSince1970: 200)]
        )

        let merged = SyncSnapshot.merging(stale, deleted)
        let remerged = SyncSnapshot.merging(merged, stale)

        #expect(merged.entries.isEmpty)
        #expect(remerged.entries.isEmpty)
        #expect(remerged.deletedAt[id] == Date(timeIntervalSince1970: 200))
    }

    @Test("Tombstones for the same entry keep the latest deletion date")
    func tombstonesKeepLatestDate() {
        let id = UUID()

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [], deletedAt: [id: Date(timeIntervalSince1970: 100)]),
            SyncSnapshot(entries: [], deletedAt: [id: Date(timeIntervalSince1970: 200)])
        )

        #expect(merged.deletedAt == [id: Date(timeIntervalSince1970: 200)])
    }

    @Test("Tombstones without any matching entry are preserved for future merges")
    func orphanTombstonesArePreserved() {
        let id = UUID()

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [], deletedAt: [id: Date(timeIntervalSince1970: 100)]),
            SyncSnapshot(entries: [], deletedAt: [:])
        )

        #expect(merged.entries.isEmpty)
        #expect(merged.deletedAt == [id: Date(timeIntervalSince1970: 100)])
    }

    // MARK: - Field preservation

    @Test("Repeat rule, pinned and archived flags survive the merge untouched")
    func repeatPinAndArchiveFieldsSurviveMerge() {
        let repeating = fullEntry(id: UUID(), title: "Weekly", updatedAt: Date(timeIntervalSince1970: 100))
            .updating { $0.repeatRule = .weekly }
        let pinned = fullEntry(id: UUID(), title: "Pinned", updatedAt: Date(timeIntervalSince1970: 200))
            .updating { $0.isPinned = true }
        let archived = fullEntry(id: UUID(), title: "Archived", updatedAt: Date(timeIntervalSince1970: 300))
            .updating {
                $0.isArchived = true
                $0.isPinned = false
                $0.repeatRule = .yearly
            }

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [repeating, pinned], deletedAt: [:]),
            SyncSnapshot(entries: [archived], deletedAt: [:])
        )

        #expect(normalized(merged.entries) == normalized([repeating, pinned, archived]))
        #expect(merged.entries.first { $0.id == repeating.id }?.repeatRule == .weekly)
        #expect(merged.entries.first { $0.id == pinned.id }?.isPinned == true)
        #expect(merged.entries.first { $0.id == archived.id }?.isArchived == true)
    }

    // MARK: - Coding

    @Test("A snapshot survives a JSON round trip with entries and tombstones intact")
    func snapshotRoundTripsThroughJSON() throws {
        let id = UUID()
        let snapshot = SyncSnapshot(
            entries: [fullEntry(id: UUID(), title: "Round trip", updatedAt: Date(timeIntervalSince1970: 100))],
            deletedAt: [id: Date(timeIntervalSince1970: 200)]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(SyncSnapshot.self, from: try encoder.encode(snapshot))

        #expect(decoded.version == SyncSnapshot.currentVersion)
        #expect(decoded.entries == snapshot.entries)
        #expect(decoded.deletedAt.count == 1)
        // ISO-8601 encoding drops sub-second precision; the tombstone survives to the second.
        #expect(decoded.deletedAt[id]?.timeIntervalSince1970 == 200)
    }

    @Test("Entries decode with defaults when optional fields are missing")
    func entryDecodingToleratesMissingFields() throws {
        let id = UUID()
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "Legacy",
            "entryType": "countDown",
            "targetDate": "2030-01-01T00:00:00Z"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let entry = try decoder.decode(Entry.self, from: Data(json.utf8))

        #expect(entry.id == id)
        #expect(entry.title == "Legacy")
        #expect(entry.repeatRule == .none)
        #expect(entry.outOfRangeBehavior == .zero)
        #expect(entry.isPinned == false)
        #expect(entry.isArchived == false)
        #expect(entry.colorHex == TrendingCardPalettes.defaultHex)
        #expect(!entry.timezoneID.isEmpty)
        #expect(entry.notes == nil)
        #expect(entry.iconEmoji == nil)
        #expect(entry.reminderOffsetsDays == [0])
    }

    @Test("Reminder offsets survive an entry JSON round trip")
    func reminderOffsetsRoundTrip() throws {
        var entry = fullEntry(id: UUID(), title: "Launch", updatedAt: .now)
        entry.reminderOffsetsDays = [30, 7, 1, 0]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(Entry.self, from: encoder.encode(entry))

        #expect(decoded.reminderOffsetsDays == [30, 7, 1, 0])
    }

    @Test("Entry decoding fails when a required field is missing")
    func entryDecodingRejectsMissingRequiredFields() {
        let json = """
        { "id": "\(UUID().uuidString)", "entryType": "countUp" }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(throws: (any Error).self) {
            _ = try decoder.decode(Entry.self, from: Data(json.utf8))
        }
    }

    @Test("Corrupted snapshot data fails to decode instead of merging garbage")
    func corruptedSnapshotDataFailsDecoding() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #expect(throws: (any Error).self) {
            _ = try decoder.decode(SyncSnapshot.self, from: Data("not json".utf8))
        }
        #expect(throws: (any Error).self) {
            _ = try decoder.decode(SyncSnapshot.self, from: Data(#"{"entries": "nope"}"#.utf8))
        }
    }

    // MARK: - Helpers

    private func normalized(_ entries: [Entry]) -> [Entry] {
        entries.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    private func entry(title: String, updatedAt: Date) -> Entry {
        entry(id: UUID(), title: title, updatedAt: updatedAt)
    }

    private func entry(id: UUID, title: String, updatedAt: Date) -> Entry {
        Entry(
            id: id,
            title: title,
            entryType: .countUp,
            startDate: Date(timeIntervalSince1970: 0),
            updatedAt: updatedAt
        )
    }

    private func fullEntry(id: UUID, title: String, updatedAt: Date) -> Entry {
        Entry(
            id: id,
            title: title,
            entryType: .countDown,
            startDate: nil,
            targetDate: Date(timeIntervalSince1970: 86_400),
            rangeStart: Date(timeIntervalSince1970: 0),
            rangeEnd: Date(timeIntervalSince1970: 172_800),
            outOfRangeBehavior: .freeze,
            repeatRule: .monthly,
            timezoneID: "Asia/Tokyo",
            colorHex: "#A1B2C3",
            iconEmoji: "🎯",
            notes: "notes",
            isPinned: false,
            isArchived: false,
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: updatedAt
        )
    }
}
