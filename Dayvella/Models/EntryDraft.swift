import Foundation

struct EntryDraft: Identifiable, Equatable {
    var id: UUID
    var title: String
    var entryType: EntryType
    var startDate: Date?
    var targetDate: Date?
    var rangeStart: Date?
    var rangeEnd: Date?
    var outOfRangeBehavior: OutOfRangeBehavior
    var repeatRule: RepeatRule
    var timezone: TimeZone
    var colorHex: String
    var iconEmoji: String?
    var notes: String?
    var reminderOffsetsDays: [Int]
    var isPinned: Bool
    var isArchived: Bool

    init(id: UUID = UUID(),
         title: String = "",
         entryType: EntryType = .countUp,
         startDate: Date? = nil,
         targetDate: Date? = nil,
         rangeStart: Date? = nil,
         rangeEnd: Date? = nil,
         outOfRangeBehavior: OutOfRangeBehavior = .zero,
         repeatRule: RepeatRule = .none,
         timezone: TimeZone = .current,
         colorHex: String = TrendingCardPalettes.defaultHex,
         iconEmoji: String? = nil,
         notes: String? = nil,
         reminderOffsetsDays: [Int] = [0],
         isPinned: Bool = false,
         isArchived: Bool = false) {
        self.id = id
        self.title = title
        self.entryType = entryType
        self.startDate = startDate
        self.targetDate = targetDate
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.outOfRangeBehavior = outOfRangeBehavior
        self.repeatRule = repeatRule
        self.timezone = timezone
        self.colorHex = colorHex
        self.iconEmoji = iconEmoji
        self.notes = notes
        self.reminderOffsetsDays = reminderOffsetsDays
        self.isPinned = isPinned
        self.isArchived = isArchived
    }

    init(entry: Entry) {
        id = entry.id
        title = entry.title
        entryType = entry.entryType
        startDate = entry.startDate
        targetDate = entry.targetDate
        rangeStart = entry.rangeStart
        rangeEnd = entry.rangeEnd
        outOfRangeBehavior = entry.outOfRangeBehavior
        repeatRule = entry.repeatRule
        timezone = entry.timezone
        colorHex = entry.colorHex
        iconEmoji = entry.iconEmoji
        notes = entry.notes
        reminderOffsetsDays = entry.reminderOffsetsDays
        isPinned = entry.isPinned
        isArchived = entry.isArchived
    }

    var dateForDisplay: Date? {
        entryType == .countUp ? startDate : targetDate
    }
}


extension EntryDraft {
    func makeEntry(existing: Entry?) -> Entry {
        let isNew = existing == nil
        var entry = existing ?? Entry(title: title, entryType: entryType)
        entry.id = id
        entry.title = title
        entry.entryType = entryType
        let tz = timezone
        entry.startDate = entryType == .countUp ? startDate.map { DayCounter.startOfDay($0, in: tz) } : nil
        entry.targetDate = entryType == .countDown ? targetDate.map { DayCounter.startOfDay($0, in: tz) } : nil
        entry.repeatRule = entryType == .countDown ? repeatRule : .none
        entry.rangeStart = rangeStart.map { DayCounter.startOfDay($0, in: tz) }
        entry.rangeEnd = rangeEnd.map { DayCounter.startOfDay($0, in: tz) }
        if let start = entry.rangeStart, let end = entry.rangeEnd, start > end {
            entry.rangeStart = end
            entry.rangeEnd = start
        }
        entry.outOfRangeBehavior = outOfRangeBehavior
        entry.colorHex = colorHex.isEmpty ? TrendingCardPalettes.defaultHex : colorHex
        entry.iconEmoji = iconEmoji?.isEmpty == true ? nil : iconEmoji
        entry.notes = notes?.isEmpty == true ? nil : notes
        entry.reminderOffsetsDays = entryType == .countDown
            ? Array(Set(reminderOffsetsDays.filter { $0 >= 0 && $0 <= 3650 })).sorted()
            : []
        entry.isPinned = isPinned && !isArchived
        entry.isArchived = isArchived
        entry.timezoneID = timezone.identifier
        entry.stampTimestamps(asNew: isNew)
        return entry
    }
}
