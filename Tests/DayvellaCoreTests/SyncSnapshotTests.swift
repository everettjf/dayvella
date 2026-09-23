import Foundation
import Testing
@testable import DayvellaCore

struct SyncSnapshotTests {
    @Test("Legacy palette colors resolve to their refined replacements")
    func legacyPaletteColorsResolveToNewPalette() {
        #expect(TrendingCardPalettes.resolvedPrimaryHex(for: "#606C38") == "#789184")
        #expect(TrendingCardPalettes.resolvedPrimaryHex(for: "ffc3d8") == "#C98FA3")
        #expect(TrendingCardPalettes.resolvedPrimaryHex(for: "#123456") == "#123456")
    }

    @Test("The newest edit wins when devices merge")
    func newestEditWins() {
        let id = UUID()
        let older = entry(id: id, title: "Older", updatedAt: Date(timeIntervalSince1970: 100))
        let newer = entry(id: id, title: "Newer", updatedAt: Date(timeIntervalSince1970: 200))

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [older], deletedAt: [:]),
            SyncSnapshot(entries: [newer], deletedAt: [:])
        )

        #expect(merged.entries == [newer])
    }

    @Test("A deletion is not undone by an older device")
    func deletionWinsOverOlderEntry() {
        let id = UUID()
        let item = entry(id: id, title: "Deleted", updatedAt: Date(timeIntervalSince1970: 100))
        let deletionDate = Date(timeIntervalSince1970: 200)

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [item], deletedAt: [:]),
            SyncSnapshot(entries: [], deletedAt: [id: deletionDate])
        )

        #expect(merged.entries.isEmpty)
        #expect(merged.deletedAt[id] == deletionDate)
    }

    @Test("An edit made after deletion restores the entry")
    func newerEditRestoresDeletedEntry() {
        let id = UUID()
        let restored = entry(id: id, title: "Restored", updatedAt: Date(timeIntervalSince1970: 300))

        let merged = SyncSnapshot.merging(
            SyncSnapshot(entries: [], deletedAt: [id: Date(timeIntervalSince1970: 200)]),
            SyncSnapshot(entries: [restored], deletedAt: [:])
        )

        #expect(merged.entries == [restored])
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
}
