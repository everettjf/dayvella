import Foundation

enum EntryTemplate: String, CaseIterable, Identifiable {
    case birthday
    case anniversary
    case trip
    case exam
    case habit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .trip: "Trip"
        case .exam: "Exam"
        case .habit: "Habit Days"
        }
    }

    var symbol: String {
        switch self {
        case .birthday: "birthday.cake"
        case .anniversary: "heart"
        case .trip: "airplane"
        case .exam: "graduationcap"
        case .habit: "flame"
        }
    }

    func draft(now: Date = .now, timezone: TimeZone = .current) -> EntryDraft {
        let today = DayCounter.startOfDay(now, in: timezone)
        switch self {
        case .birthday:
            return EntryDraft(title: "Birthday", entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .month, value: 1, to: today),
                              repeatRule: .yearly, timezone: timezone, iconEmoji: "🎂",
                              reminderOffsetsDays: [0, 1, 7])
        case .anniversary:
            return EntryDraft(title: "Anniversary", entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .month, value: 1, to: today),
                              repeatRule: .yearly, timezone: timezone, iconEmoji: "❤️",
                              reminderOffsetsDays: [0, 1, 7, 30])
        case .trip:
            return EntryDraft(title: "Trip", entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .day, value: 30, to: today),
                              timezone: timezone, iconEmoji: "✈️", reminderOffsetsDays: [0, 1, 7, 30])
        case .exam:
            return EntryDraft(title: "Exam", entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .day, value: 30, to: today),
                              timezone: timezone, iconEmoji: "🎓", reminderOffsetsDays: [0, 1, 3, 7])
        case .habit:
            return EntryDraft(title: "New Habit", entryType: .countUp, startDate: today,
                              timezone: timezone, iconEmoji: "🔥", reminderOffsetsDays: [])
        }
    }
}
