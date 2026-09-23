import Foundation

struct Entry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var entryType: EntryType
    var startDate: Date?
    var targetDate: Date?
    var rangeStart: Date?
    var rangeEnd: Date?
    var outOfRangeBehavior: OutOfRangeBehavior
    var repeatRule: RepeatRule
    var timezoneID: String
    var colorHex: String
    var iconEmoji: String?
    var notes: String?
    var reminderOffsetsDays: [Int]
    var isPinned: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         title: String,
         entryType: EntryType,
         startDate: Date? = nil,
         targetDate: Date? = nil,
         rangeStart: Date? = nil,
         rangeEnd: Date? = nil,
         outOfRangeBehavior: OutOfRangeBehavior = .zero,
         repeatRule: RepeatRule = .none,
         timezoneID: String = TimeZone.current.identifier,
         colorHex: String = TrendingCardPalettes.defaultHex,
         iconEmoji: String? = nil,
         notes: String? = nil,
         reminderOffsetsDays: [Int] = [0],
         isPinned: Bool = false,
         isArchived: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.entryType = entryType
        self.startDate = startDate
        self.targetDate = targetDate
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.outOfRangeBehavior = outOfRangeBehavior
        self.repeatRule = repeatRule
        self.timezoneID = timezoneID
        self.colorHex = colorHex
        self.iconEmoji = iconEmoji
        self.notes = notes
        self.reminderOffsetsDays = reminderOffsetsDays
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var timezone: TimeZone {
        TimeZone(identifier: timezoneID) ?? .current
    }

    func updating(_ block: (inout Entry) -> Void) -> Entry {
        var copy = self
        block(&copy)
        return copy
    }

    mutating func stampTimestamps(asNew: Bool) {
        let now = Date()
        if asNew {
            createdAt = now
        }
        updatedAt = now
        if colorHex.isEmpty { colorHex = TrendingCardPalettes.defaultHex }
        if timezoneID.isEmpty { timezoneID = TimeZone.current.identifier }
    }
}

extension Entry {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case entryType
        case startDate
        case targetDate
        case rangeStart
        case rangeEnd
        case outOfRangeBehavior
        case repeatRule
        case timezoneID
        case colorHex
        case iconEmoji
        case notes
        case reminderOffsetsDays
        case isPinned
        case isArchived
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        entryType = try container.decode(EntryType.self, forKey: .entryType)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        rangeStart = try container.decodeIfPresent(Date.self, forKey: .rangeStart)
        rangeEnd = try container.decodeIfPresent(Date.self, forKey: .rangeEnd)
        outOfRangeBehavior = try container.decodeIfPresent(OutOfRangeBehavior.self, forKey: .outOfRangeBehavior) ?? .zero
        repeatRule = try container.decodeIfPresent(RepeatRule.self, forKey: .repeatRule) ?? .none
        timezoneID = try container.decodeIfPresent(String.self, forKey: .timezoneID) ?? TimeZone.current.identifier
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? TrendingCardPalettes.defaultHex
        iconEmoji = try container.decodeIfPresent(String.self, forKey: .iconEmoji)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reminderOffsetsDays = try container.decodeIfPresent([Int].self, forKey: .reminderOffsetsDays) ?? [0]
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(entryType, forKey: .entryType)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(targetDate, forKey: .targetDate)
        try container.encodeIfPresent(rangeStart, forKey: .rangeStart)
        try container.encodeIfPresent(rangeEnd, forKey: .rangeEnd)
        try container.encode(outOfRangeBehavior, forKey: .outOfRangeBehavior)
        try container.encode(repeatRule, forKey: .repeatRule)
        try container.encode(timezoneID, forKey: .timezoneID)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(iconEmoji, forKey: .iconEmoji)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(reminderOffsetsDays, forKey: .reminderOffsetsDays)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
