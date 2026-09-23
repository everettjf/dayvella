import Foundation

struct ExportService {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    func export(entries: [Entry]) throws -> URL {
        let payload = entries.map { ExportEntry(entry: $0) }
        let data = try encoder.encode(payload)
        let filename = "Dayvella-export-\(ExportService.timestamp()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}

private struct ExportEntry: Codable {
    let id: UUID
    let title: String
    let type: String
    let start: Date?
    let target: Date?
    let rangeStart: Date?
    let rangeEnd: Date?
    let outOfRangeBehavior: String
    let repeatRule: String
    let timezone: String
    let color: String
    let icon: String?
    let notes: String?
    let reminderOffsetsDays: [Int]
    let pinned: Bool
    let archived: Bool

    init(entry: Entry) {
        id = entry.id
        title = entry.title
        type = entry.entryType.rawValue
        start = entry.startDate
        target = entry.targetDate
        rangeStart = entry.rangeStart
        rangeEnd = entry.rangeEnd
        outOfRangeBehavior = entry.outOfRangeBehavior.rawValue
        repeatRule = entry.repeatRule.rawValue
        timezone = entry.timezoneID
        color = entry.colorHex
        icon = entry.iconEmoji
        notes = entry.notes
        reminderOffsetsDays = entry.reminderOffsetsDays
        pinned = entry.isPinned
        archived = entry.isArchived
    }
}

private extension ExportEntry {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case start
        case target
        case rangeStart
        case rangeEnd
        case outOfRangeBehavior
        case repeatRule
        case timezone
        case color
        case icon
        case notes
        case reminderOffsetsDays
        case pinned
        case archived
    }
}

private extension ExportEntry {
    init(_ entry: Entry) {
        self.init(entry: entry)
    }
}
