import Foundation
import WidgetKit

@MainActor
struct WidgetSnapshotService {
    static let appGroupID = "group.com.xnu.countmydays"
    static let entriesKey = "widget.entries.v1"

    struct Item: Codable {
        let id: UUID
        let title: String
        let entryType: EntryType
        let startDate: Date?
        let targetDate: Date?
        let repeatRule: RepeatRule
        let timezoneID: String
        let colorHex: String
        let iconEmoji: String?
        let isPinned: Bool

        init(entry: Entry) {
            id = entry.id
            title = entry.title
            entryType = entry.entryType
            startDate = entry.startDate
            targetDate = entry.targetDate
            repeatRule = entry.repeatRule
            timezoneID = entry.timezoneID
            colorHex = entry.colorHex
            iconEmoji = entry.iconEmoji
            isPinned = entry.isPinned
        }
    }

    func save(entries: [Entry]) {
        let visible = entries.filter { !$0.isArchived }.map(Item.init)
        guard let data = try? JSONEncoder().encode(visible) else { return }
        UserDefaults(suiteName: Self.appGroupID)?.set(data, forKey: Self.entriesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
