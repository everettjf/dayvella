import Foundation

struct EntrySnapshot: Identifiable {
    let id: UUID
    let title: String
    let entryType: EntryType
    let startDate: Date?
    let targetDate: Date?
    let rangeStart: Date?
    let rangeEnd: Date?
    let outOfRangeBehavior: OutOfRangeBehavior
    let repeatRule: RepeatRule
    let timezone: TimeZone
    let colorHex: String
    let iconEmoji: String?
    let notes: String?
    let reminderOffsetsDays: [Int]
    let isPinned: Bool
    let isArchived: Bool

    init(id: UUID,
         title: String,
         entryType: EntryType,
         startDate: Date?,
         targetDate: Date?,
         rangeStart: Date?,
         rangeEnd: Date?,
         outOfRangeBehavior: OutOfRangeBehavior,
         repeatRule: RepeatRule,
         timezone: TimeZone,
         colorHex: String,
         iconEmoji: String?,
         notes: String?,
         reminderOffsetsDays: [Int] = [0],
         isPinned: Bool,
         isArchived: Bool) {
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

    init(draft: EntryDraft) {
        id = draft.id
        title = draft.title
        entryType = draft.entryType
        startDate = draft.startDate
        targetDate = draft.targetDate
        rangeStart = draft.rangeStart
        rangeEnd = draft.rangeEnd
        outOfRangeBehavior = draft.outOfRangeBehavior
        repeatRule = draft.repeatRule
        timezone = draft.timezone
        colorHex = draft.colorHex
        iconEmoji = draft.iconEmoji
        notes = draft.notes
        reminderOffsetsDays = draft.reminderOffsetsDays
        isPinned = draft.isPinned
        isArchived = draft.isArchived
    }
}
