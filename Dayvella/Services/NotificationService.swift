import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func scheduleReminders(for entry: Entry, now: Date = .now) {
        #if DEBUG
        guard !ProcessInfo.processInfo.arguments.contains("-SeedStoreScreenshots") else { return }
        #endif
        cancelReminders(for: entry)
        guard entry.entryType == .countDown,
              !entry.isArchived,
              !entry.reminderOffsetsDays.isEmpty,
              let target = DayCounter.effectiveTargetDate(for: EntrySnapshot(entry: entry), now: now) else { return }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard granted, error == nil, let self else { return }
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = entry.timezone
            for offset in entry.reminderOffsetsDays {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: target) else { continue }
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = 8
                guard let fireDate = calendar.date(from: components), fireDate > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = entry.title
                content.body = offset == 0 ? String(localized: "Today is the day!") : String(localized: "\(offset) days to go")
                content.sound = .default
                let request = UNNotificationRequest(
                    identifier: self.identifier(for: entry.id, offset: offset),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                self.center.add(request)
            }
        }
    }

    func cancelReminders(for entry: Entry) {
        let offsets = Set(entry.reminderOffsetsDays).union([0, 1, 3, 7, 30])
        center.removePendingNotificationRequests(withIdentifiers: offsets.map { identifier(for: entry.id, offset: $0) })
    }

    func rescheduleAll(_ entries: [Entry]) {
        entries.forEach { scheduleReminders(for: $0) }
    }

    private func identifier(for id: UUID, offset: Int) -> String {
        "\(id.uuidString).reminder.\(offset)"
    }
}
