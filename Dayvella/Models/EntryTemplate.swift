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
        case .birthday: String(localized: "Birthday")
        case .anniversary: String(localized: "Anniversary")
        case .trip: String(localized: "Trip")
        case .exam: String(localized: "Exam")
        case .habit: String(localized: "Habit Days")
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
            return EntryDraft(title: String(localized: "Birthday"), entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .month, value: 1, to: today),
                              repeatRule: .yearly, timezone: timezone, iconEmoji: "🎂",
                              reminderOffsetsDays: [0, 1, 7])
        case .anniversary:
            return EntryDraft(title: String(localized: "Anniversary"), entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .month, value: 1, to: today),
                              repeatRule: .yearly, timezone: timezone, iconEmoji: "❤️",
                              reminderOffsetsDays: [0, 1, 7, 30])
        case .trip:
            return EntryDraft(title: String(localized: "Trip"), entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .day, value: 30, to: today),
                              timezone: timezone, iconEmoji: "✈️", reminderOffsetsDays: [0, 1, 7, 30])
        case .exam:
            return EntryDraft(title: String(localized: "Exam"), entryType: .countDown,
                              targetDate: Calendar.current.date(byAdding: .day, value: 30, to: today),
                              timezone: timezone, iconEmoji: "🎓", reminderOffsetsDays: [0, 1, 3, 7])
        case .habit:
            return EntryDraft(title: String(localized: "New Habit"), entryType: .countUp, startDate: today,
                              timezone: timezone, iconEmoji: "🔥", reminderOffsetsDays: [])
        }
    }
}
